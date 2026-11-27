#!/usr/bin/env python3
"""Git clean/smudge filter for the KDE config files Plasma rewrites at runtime.

Reads the file on stdin and writes the filtered file to stdout.

  shortcuts-clean   kglobalshortcutsrc: writes every [..][$InverseAction] pair
                    with the alphabetically smaller action as the key and
                    sorts the section, so KWin's pair flips produce no diff.
  applets-clean     plasma-org.kde.plasma.desktop-appletsrc: drops runtime
                    state (current wallpaper, window and popup sizes, desktop
                    widget geometries, the panel colorizer widget cache) and
                    replaces the home directory with @HOME@.
  applets-smudge    replaces @HOME@ with the home directory on checkout.

Registered by scripts/setup-git-filters.sh.
"""

import os
import re
import sys

HOME = os.path.expanduser("~").rstrip("/")
PLACEHOLDER = "@HOME@"

# Keys Plasma rewrites as state; none of them carries configuration.
VOLATILE_KEYS = re.compile(
    r"^(Image|PreviewImage|ItemGeometries[^=]*|popupHeight|popupWidth"
    r"|DialogHeight|DialogWidth|panelWidgets)="
)


def split_groups(text):
    """Returns [(header or None, [body lines])] in file order."""
    groups = [(None, [])]
    for line in text.split("\n"):
        if line.startswith("["):
            groups.append((line, []))
        else:
            groups[-1][1].append(line)
    return groups


def join_groups(groups):
    lines = []
    for header, body in groups:
        if header is not None:
            lines.append(header)
        lines.extend(body)
    return "\n".join(lines)


def shortcuts_clean(text):
    groups = []
    for header, body in split_groups(text):
        if header is not None and header.endswith("[$InverseAction]"):
            pairs = set()
            rest = []
            for line in body:
                if "=" in line:
                    pairs.add(tuple(sorted(line.split("=", 1))))
                else:
                    rest.append(line)
            body = [f"{a}={b}" for a, b in sorted(pairs)] + rest
        groups.append((header, body))
    return join_groups(groups)


def applets_clean(text):
    groups = []
    for header, body in split_groups(text):
        kept = [line for line in body if not VOLATILE_KEYS.match(line)]
        # A group left with no keys is dropped, as KConfig never writes one.
        if header is not None and len(kept) != len(body) and not any(kept):
            continue
        groups.append((header, kept))
    return join_groups(groups).replace(HOME + "/", PLACEHOLDER + "/")


def applets_smudge(text):
    return text.replace(PLACEHOLDER + "/", HOME + "/")


MODES = {
    "shortcuts-clean": shortcuts_clean,
    "applets-clean": applets_clean,
    "applets-smudge": applets_smudge,
}


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in MODES:
        sys.exit(f"usage: {sys.argv[0]} {{{'|'.join(MODES)}}}")
    data = sys.stdin.buffer.read().decode("utf-8", errors="surrogateescape")
    out = MODES[sys.argv[1]](data)
    sys.stdout.buffer.write(out.encode("utf-8", errors="surrogateescape"))


if __name__ == "__main__":
    main()
