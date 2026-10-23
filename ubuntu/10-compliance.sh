#!/usr/bin/env bash
# Phase 3 - the three agents CSW requires before the machine is allowed on
# the network: FortiClient ZTNA, Rapid7 Insight Agent, Defender for Endpoint.
#
# Tokens and signed URLs come from ubuntu/compliance.env (gitignored).
# Downloads land in their own empty directory and are installed by path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/compliance.env"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ENV_FILE"
else
  echo "==> $ENV_FILE not found"
  echo "    Copy compliance.env.example to compliance.env and fill it in from"
  echo "    the Help Desk Knowledge Base, then re-run."
  exit 1
fi

need() {
  if [ -z "${!1:-}" ]; then
    echo "    $1 is empty in compliance.env - skipping this agent" >&2
    return 1
  fi
}

# ---------------------------------------------------------------- FortiClient
install_forticlient() {
  echo "==> FortiClient ZTNA (7.4 repo; covers Ubuntu 24.04)"
  wget -qO- https://repo.fortinet.com/repo/forticlient/7.4/ubuntu/DEB-GPG-KEY |
    gpg --dearmor | sudo tee /usr/share/keyrings/repo.fortinet.com.gpg >/dev/null

  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/repo.fortinet.com.gpg] https://repo.fortinet.com/repo/forticlient/7.4/ubuntu/ stable non-free" |
    sudo tee /etc/apt/sources.list.d/repo.fortinet.com.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y forticlient

  echo
  echo "    MANUAL STEP: open FortiClient, go to Zero Trust Telemetry, enter"
  echo "    the registration code and press Connect. A browser opens for the"
  echo "    Azure AD sign-in; afterwards the client should read Connected."
  if [ -n "${FORTICLIENT_CODE:-}" ]; then
    echo "    code: $FORTICLIENT_CODE"
  fi
}

# -------------------------------------------------------------------- Rapid7
install_rapid7() {
  echo "==> Rapid7 Insight Agent"
  need RAPID7_DEB_URL || return 0
  need RAPID7_TOKEN || return 0

  local deb="$WORK_DIR/rapid7-insight-agent.deb"
  wget -q "$RAPID7_DEB_URL" -O "$deb"
  sudo apt-get install -y "$deb"

  local configure="/opt/rapid7/ir_agent/components/insight_agent/$RAPID7_VERSION/configure_agent.sh"
  if [ -x "$configure" ]; then
    sudo "$configure" --token="$RAPID7_TOKEN"
  else
    echo "    $configure not found."
    echo "    Installed versions:"
    ls /opt/rapid7/ir_agent/components/insight_agent/ 2>/dev/null | sed 's/^/      /'
    echo "    Set RAPID7_VERSION in compliance.env and re-run."
    return 0
  fi

  sudo systemctl start ir_agent.service
  sudo systemctl status ir_agent.service --no-pager || true

  if systemctl is-enabled --quiet auditd 2>/dev/null; then
    echo "    auditd is enabled - check the Rapid7 auditd compatibility notes."
  fi
}

# ------------------------------------------------------------------ Defender
install_defender() {
  echo "==> Defender for Endpoint"
  need DEFENDER_ONBOARDING_URL || return 0

  local dir="$WORK_DIR/defender"
  mkdir -p "$dir"

  wget -q https://github.com/microsoft/mdatp-xplat/raw/master/linux/installation/mde_installer.sh \
    -O "$dir/mde_installer.sh"
  wget -q "$DEFENDER_ONBOARDING_URL" -O "$dir/linux_onboarding_script.py"
  chmod 744 "$dir/mde_installer.sh"

  # On 24.04 the installer picks the 22.04 prod feed, which is what the KB
  # article specifies.
  sudo "$dir/mde_installer.sh" --install --channel prod \
    --onboard "$dir/linux_onboarding_script.py" --pre-req -y

  sudo mdatp config real-time-protection --value enabled
  mdatp health --field healthy || true
}

install_forticlient
echo
install_rapid7
echo
install_defender

echo
echo "==> Verify all three are reporting before going further:"
echo "    systemctl status ir_agent.service"
echo "    mdatp health"
echo "    FortiClient GUI shows Connected"
