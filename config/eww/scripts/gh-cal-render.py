#!/usr/bin/env python3
"""Render a GitHub contributions calendar (green graph) as a PNG.

Two input modes, detected by content:
- JSON (GraphQL contributionsCollection): used when a token is configured,
  includes private contributions.
- HTML (public profile calendar table): fallback, public contributions only.

The PNG is only rewritten when the data is usable, so an eww defpoll never
breaks and the previous calendar survives a failed fetch.
"""
import json
import re
import sys

from PIL import Image, ImageDraw

# GitHub dark-theme calendar palette by level
LEVEL_COLORS = {
    0: (22, 27, 34),    # empty  #161b22
    1: (14, 68, 41),    # #0e4429
    2: (0, 109, 50),    # #006d32
    3: (38, 166, 65),   # #26a641
    4: (57, 211, 83),   # #39d353
}

# light-palette hexes the GraphQL API returns, mapped to dark equivalents
HEX_TO_LEVEL = {
    "ebedf0": 0, "9be9a8": 1, "40c463": 2, "30a14e": 3, "216e39": 4,
}

CELL, GAP, MARGIN = 10, 3, 6


def grid_to_png(weeks, out_path):
    """weeks: list of columns, each a list of (level, color_hex_or_None)."""
    cols = len(weeks)
    w = MARGIN * 2 + cols * CELL + (cols - 1) * GAP
    h = MARGIN * 2 + 7 * CELL + 6 * GAP
    im = Image.new("RGB", (w, h), (18, 18, 22))  # HUD surface color
    d = ImageDraw.Draw(im)
    for c, week in enumerate(weeks):
        for r, (level, _hex) in enumerate(week[:7]):
            x0 = MARGIN + c * (CELL + GAP)
            y0 = MARGIN + r * (CELL + GAP)
            d.rectangle([x0, y0, x0 + CELL - 1, y0 + CELL - 1],
                        fill=LEVEL_COLORS.get(level, LEVEL_COLORS[0]))
    im.save(out_path)


def level_from_count(n):
    if n <= 0:
        return 0
    if n <= 2:
        return 1
    if n <= 4:
        return 2
    if n <= 6:
        return 3
    return 4


def render_json(path, out_path):
    data = json.load(open(path, encoding="utf-8"))
    cal = data["data"]["user"]["contributionsCollection"]["contributionCalendar"]
    weeks = []
    for week in cal["weeks"]:
        col = []
        for day in week["contributionDays"]:
            n = day["contributionCount"]
            hexc = (day.get("color") or "").lstrip("#").lower()
            level = HEX_TO_LEVEL.get(hexc, level_from_count(n))
            col.append((level, hexc))
        weeks.append(col)
    grid_to_png(weeks, out_path)


def render_html(path, out_path):
    text = open(path, encoding="utf-8", errors="replace").read()
    # rows are weekdays (Sun..Sat); cells within a row are weeks
    rows = []
    for tr in re.findall(r"<tr[^>]*>(.*?)</tr>", text, re.S):
        cells = re.findall(
            r'data-date="(\d{4}-\d{2}-\d{2})"[^>]*data-level="(\d)"', tr)
        if cells:
            rows.append([(int(l), None) for _d, l in cells])
    if not rows:
        raise ValueError("no calendar data in html")
    # transpose: rows are weekdays, columns are weeks
    nweeks = max(len(r) for r in rows)
    weeks = [[(rows[r][c][0], None) if c < len(rows[r]) else (0, None)
              for r in range(7)] for c in range(nweeks)]
    grid_to_png(weeks, out_path)


def main(html_or_json: str, out_path: str) -> None:
    head = open(html_or_json, encoding="utf-8", errors="replace").read(64)
    if head.lstrip().startswith("{"):
        render_json(html_or_json, out_path)
    else:
        render_html(html_or_json, out_path)


if __name__ == "__main__":
    try:
        main(sys.argv[1], sys.argv[2])
    except Exception:
        pass  # never break the eww poll
