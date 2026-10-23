#!/usr/bin/env bash
# Phase 7 - PSPS / CODAC work environment. Guided: it prepares what it can
# and stops at every step that needs a decision or a credential.
#
# Runs natively on Linux. The ITER guide assumes WSL; none of that applies.

set -euo pipefail

WORK_DIR="${PSPS_DIR:-$HOME/Code}"
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
echo "==> Bitbucket SSH key"
if [ -f "$HOME/.ssh/bitbucket" ]; then
  grep -q 'bitbucket' "$HOME/.ssh/config" 2>/dev/null || cat >>"$HOME/.ssh/config" <<'SSHCFG'

Host git.iter.org
    IdentityFile ~/.ssh/bitbucket
    IdentitiesOnly yes
SSHCFG
  ssh-add "$HOME/.ssh/bitbucket" 2>/dev/null || true
  echo "    key in place"
else
  echo "    ~/.ssh/bitbucket missing - restore it (40-restore.sh) or generate a"
  echo "    new key and add it to Bitbucket before continuing."
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

setup_webapp() {
  local dir="$WORK_DIR/psps-webapp"
  [ -d "$dir" ] || return 0
  echo "==> psps-webapp"

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install "$NODE_VERSION"
  nvm use "$NODE_VERSION"
  echo "$NODE_VERSION" >"$dir/.nvmrc"

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
