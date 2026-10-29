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

content, n_pacman = re.subn(
    r'### Install Pacman packages:\n```sh\nyay -S [^`]*\n```', pacman_block, content)
content, n_aur = re.subn(
    r'### Install AUR packages:\n```sh\nyay -S [^`]*\n```', aur_block, content)

# A silent no-op is the failure mode here: the lists drift apart and nobody
# notices until a fresh install misses a package.
if n_pacman != 1 or n_aur != 1:
    print(f'no match in {path}: pacman block x{n_pacman}, AUR block x{n_aur}',
          file=sys.stderr)
    print('the headings or the fenced blocks changed; fix the regex or the README',
          file=sys.stderr)
    raise SystemExit(1)

with open(path, 'w') as f:
    f.write(content)

print("README.md updated")
PY