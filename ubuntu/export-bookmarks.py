#!/usr/bin/env python3
"""Export a Firefox places.sqlite into a Netscape bookmarks.html file.

Usage: export-bookmarks.py <places.sqlite> <output.html>

Works on a copy of places.sqlite, so Firefox may stay open.
"""

import html
import sqlite3
import sys

ROOTS = [
    ("toolbar_____", "Bookmarks Toolbar", True),
    ("menu________", "Bookmarks Menu", False),
    ("unfiled_____", "Other Bookmarks", False),
    ("mobile______", "Mobile Bookmarks", False),
]

TYPE_BOOKMARK = 1
TYPE_FOLDER = 2


def children(cur, parent_id):
    cur.execute(
        """
        SELECT b.id, b.type, b.title, b.dateAdded, b.lastModified, p.url
        FROM moz_bookmarks b
        LEFT JOIN moz_places p ON b.fk = p.id
        WHERE b.parent = ?
        ORDER BY b.position
        """,
        (parent_id,),
    )
    return cur.fetchall()


def write_items(cur, parent_id, out, depth):
    pad = " " * (4 * depth)
    out.write(f"{pad}<DL><p>\n")
    for bid, btype, title, added, modified, url in children(cur, parent_id):
        title = html.escape(title or "")
        added = int((added or 0) / 1_000_000)
        modified = int((modified or 0) / 1_000_000)
        if btype == TYPE_FOLDER:
            out.write(
                f'{pad}    <DT><H3 ADD_DATE="{added}" '
                f'LAST_MODIFIED="{modified}">{title}</H3>\n'
            )
            write_items(cur, bid, out, depth + 1)
        elif btype == TYPE_BOOKMARK and url:
            if url.startswith(("place:", "about:")):
                continue
            out.write(
                f'{pad}    <DT><A HREF="{html.escape(url)}" '
                f'ADD_DATE="{added}" LAST_MODIFIED="{modified}">{title}</A>\n'
            )
    out.write(f"{pad}</DL><p>\n")


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    db, dest = sys.argv[1], sys.argv[2]
    conn = sqlite3.connect(f"file:{db}?immutable=1", uri=True)
    cur = conn.cursor()

    with open(dest, "w", encoding="utf-8") as out:
        out.write("<!DOCTYPE NETSCAPE-Bookmark-file-1>\n")
        out.write(
            '<META HTTP-EQUIV="Content-Type" '
            'CONTENT="text/html; charset=UTF-8">\n'
        )
        out.write("<TITLE>Bookmarks</TITLE>\n<H1>Bookmarks</H1>\n<DL><p>\n")

        for guid, label, is_toolbar in ROOTS:
            cur.execute(
                "SELECT id, title FROM moz_bookmarks WHERE guid = ?", (guid,)
            )
            row = cur.fetchone()
            if not row:
                continue
            root_id, root_title = row
            if not children(cur, root_id):
                continue
            attr = ' PERSONAL_TOOLBAR_FOLDER="true"' if is_toolbar else ""
            name = html.escape(root_title or label)
            out.write(f"    <DT><H3{attr}>{name}</H3>\n")
            write_items(cur, root_id, out, 1)

        out.write("</DL><p>\n")

    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
