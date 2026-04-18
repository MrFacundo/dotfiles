#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/packages.sh"

README="$SCRIPT_DIR/../README.md"

pacman_list="${pacman_pkgs[*]}"
aur_list="${aur_pkgs[*]}"

python3 - "$README" "$pacman_list" "$aur_list" << 'PY'
import re
import sys

path = sys.argv[1]
pacman_list = sys.argv[2]
aur_list = sys.argv[3]

with open(path, 'r') as f:
    content = f.read()

pacman_block = f"""### Install Pacman packages:
```sh
yay -S {pacman_list}
```"""

aur_block = f"""### Install AUR packages:
```sh
yay -S {aur_list}
```"""

content = re.sub(r'### Install Pacman packages:\n```sh\nyay -S [^`]*\n```', pacman_block, content)
content = re.sub(r'### Install AUR packages:\n```sh\nyay -S [^`]*\n```', aur_block, content)

with open(path, 'w') as f:
    f.write(content)

print("README.md updated")
PY