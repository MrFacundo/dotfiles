#!/usr/bin/env bash
# Phase 7 - PSPS / CODAC work environment. Guided: it prepares what it can
# and stops at every step that needs a decision or a credential.
#
# Runs natively on Linux. The ITER guide assumes WSL; none of that applies.

set -euo pipefail

WORK_DIR="${PSPS_DIR:-$HOME/Code}"
# Fallback only; setup_webapp reads the real requirement from package.json.
NODE_VERSION="20.18.0"

BITBUCKET="ssh://git@git.iter.org/coa"
REPOS=(
  coa-containers
  psps-deploy
  psps-webapp
)

# Branch checked out as a sibling worktree of psps-webapp.
WORKTREE_BRANCH="develop"
WORKTREE_DIR="psps-webapp-develop"

echo "==> Workspace: $WORK_DIR"
mkdir -p "$WORK_DIR"

# -------------------------------------------------------------------- ssh
echo "==> git.iter.org SSH key"
# The ITER Bitbucket account accepts id_ed25519; ~/.ssh/bitbucket is a second
# key kept for the repositories that were registered with it. Both are offered,
# id_ed25519 first.
if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/bitbucket" ]; then
  grep -q '^Host git.iter.org' "$HOME/.ssh/config" 2>/dev/null || cat >>"$HOME/.ssh/config" <<'SSHCFG'

Host git.iter.org
    IdentityFile ~/.ssh/id_ed25519
    IdentityFile ~/.ssh/bitbucket
    IdentitiesOnly yes
SSHCFG
  for key in id_ed25519 bitbucket; do
    [ -f "$HOME/.ssh/$key" ] && ssh-add "$HOME/.ssh/$key" 2>/dev/null || true
  done

  if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@git.iter.org 2>&1 |
    grep -q 'Permission denied'; then
    echo "    git.iter.org rejected every key offered." >&2
    echo "    Check which public key is registered under your Bitbucket profile." >&2
    exit 1
  fi
  echo "    key accepted by git.iter.org"
else
  echo "    no SSH key found - restore them (40-restore.sh) or generate one and"
  echo "    add it to your Bitbucket profile before continuing."
  exit 1
fi

# ------------------------------------------------------------------ clone
echo "==> Cloning"
for repo in "${REPOS[@]}"; do
  if [ -d "$WORK_DIR/$repo/.git" ]; then
    echo "    $repo already cloned"
  else
    git clone "$BITBUCKET/$repo.git" "$WORK_DIR/$repo" ||
      echo "    clone of $repo failed - check the URL and your SSH access"
  fi
done

# --------------------------------------------------------- worktree
setup_worktree() {
  local main="$WORK_DIR/psps-webapp"
  local tree="$WORK_DIR/$WORKTREE_DIR"
  [ -d "$main/.git" ] || return 0
  [ -e "$tree" ] && return 0

  echo "==> $WORKTREE_DIR worktree"
  (cd "$main" && git worktree add "$tree" "$WORKTREE_BRANCH") ||
    echo "    worktree add failed; check that the $WORKTREE_BRANCH branch exists"
}

# --------------------------------------------------------- coa-containers
setup_containers() {
  local dir="$WORK_DIR/coa-containers"
  [ -d "$dir" ] || return 0
  echo "==> coa-containers"

  if [ -f "$dir/env-defaults.sh" ] && [ ! -f "$dir/env.sh" ]; then
    cp "$dir/env-defaults.sh" "$dir/env.sh"
    # The ITER proxy is unreachable from outside the site network.
    sed -i 's|^\(export http_proxy=\)|# \1|; s|^\(export https_proxy=\)|# \1|' "$dir/env.sh"
    echo "    env.sh created, proxy lines commented out"
  fi

  # The repos carry CRLF line endings, which break the build scripts.
  echo "    normalising line endings and permissions on *.sh"
  find "$dir" -type f -name '*.sh' -exec sed -i 's/\r$//' {} +
  find "$dir" -type f -name '*.sh' -exec chmod +x {} +
}

setup_protocol() {
  local dir="$WORK_DIR/coa-containers/coa-psps-protocol"
  [ -d "$dir" ] || return 0
  echo "==> coa-psps-protocol"

  if [ -f "$dir/.env-defaults" ] && [ ! -f "$dir/.env" ]; then
    cp "$dir/.env-defaults" "$dir/.env"
    echo "    .env created"
  fi

  mkdir -p "$dir/secrets"
  if [ -d "$HOME/psps-secrets" ]; then
    cp -n "$HOME/psps-secrets/"* "$dir/secrets/" 2>/dev/null || true
    chmod 600 "$dir/secrets"/* 2>/dev/null || true
    echo "    secrets copied from ~/psps-secrets:"
    ls "$dir/secrets" | sed 's/^/      /'
    echo "    CHECK these against the screenshot in the setup guide - it calls"
    echo "    for two files, and the names must match exactly."
  else
    echo "    ~/psps-secrets missing; populate $dir/secrets by hand"
  fi
}

# Lowest node the repo's engines field accepts, e.g. ">=22.15.0" -> 22.15.0.
# Falls back to NODE_VERSION when package.json says nothing.
required_node() {
  local pkg="$1/package.json" v=""
  [ -f "$pkg" ] && v="$(python3 -c '
import json, re, sys
try:
    eng = json.load(open(sys.argv[1])).get("engines", {}).get("node", "")
except Exception:
    eng = ""
m = re.search(r"(\d+(?:\.\d+){0,2})", eng)
print(m.group(1) if m else "")
' "$pkg" 2>/dev/null)"
  echo "${v:-$NODE_VERSION}"
}

setup_webapp() {
  local dir="$WORK_DIR/psps-webapp"
  [ -d "$dir" ] || return 0
  echo "==> psps-webapp"

  local node_version
  node_version="$(required_node "$dir")"
  echo "    node $node_version (from package.json engines)"

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install "$node_version"
  nvm use "$node_version"

  # Never write .nvmrc when the repo tracks it: the file belongs to upstream,
  # and overwriting it both dirties the checkout and makes the .zshrc cd-hook
  # select a node the engines field rejects.
  if git -C "$dir" ls-files --error-unmatch .nvmrc >/dev/null 2>&1; then
    if [ "$(cat "$dir/.nvmrc" 2>/dev/null)" != "$node_version" ]; then
      echo "    .nvmrc is tracked and says $(cat "$dir/.nvmrc"), engines wants $node_version"
      echo "    leaving it alone - raise it upstream"
    fi
  else
    echo "$node_version" >"$dir/.nvmrc"
  fi

  (cd "$dir" && npm install)
}

setup_worktree
setup_containers
setup_protocol
setup_webapp

cat <<'CHECKLIST'

==> Manual steps left

  [ ] Backend build
        cd coa-containers && ./docker-build-all.sh
        cd coa-containers/coa-psps-protocol
        ./compose.sh min-devel build     # warnings about empty base images are expected
        ./compose.sh min-devel run
        ./compose.sh min-devel stop

  [ ] Frontend
        cd psps-webapp && nvm use && npm run dev

  [ ] Requestly
        The webapp returns Unauthorized locally because production uses ITER
        authentication. Install the Requestly browser extension and add the
        HTTP rule from the setup guide.

  [ ] coa-containers local edits
        The previous machine carried changes to env-defaults.sh and a deleted
        coa-psps-protocol/.env-defaults that a fresh clone does not reproduce.
        Re-apply them if the build needs them.

  [ ] Read the PSPS Editor User Manual on the ITER intranet before digging in.

CHECKLIST
