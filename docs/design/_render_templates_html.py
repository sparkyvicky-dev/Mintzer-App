# -*- coding: utf-8 -*-
"""Render short/locked MD (and banks) to easy-read HTML for Brave."""
from __future__ import annotations

import html
import pathlib
import re
import sys


def inline(s: str) -> str:
    s = html.escape(s)
    s = re.sub(
        r"\[([^\]]+)\]\(([^)]+)\)",
        r'<a href="\2">\1</a>',
        s,
    )
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    return s


def sid_of(title: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")


def md_to_html(md_path: pathlib.Path, html_path: pathlib.Path, page_title: str) -> None:
    text = md_path.read_text(encoding="utf-8")
    lines = text.splitlines()
    body: list[str] = []
    para: list[str] = []
    i = 0

    def flush_para() -> None:
        if para:
            body.append("<p>" + inline(" ".join(para)) + "</p>")
            para.clear()

    while i < len(lines):
        line = lines[i]
        if line.strip() == "---":
            flush_para()
            body.append("<hr>")
            i += 1
            continue
        if line.startswith("|") and i + 1 < len(lines) and re.match(
            r"^\|[\s\-:|]+\|$", lines[i + 1].strip()
        ):
            flush_para()
            rows: list[list[str]] = []
            while i < len(lines) and lines[i].startswith("|"):
                cells = [c.strip() for c in lines[i].strip("|").split("|")]
                if not re.match(r"^[\s\-:]+$", "".join(cells)):
                    rows.append(cells)
                i += 1
            if rows:
                body.append('<div class="tw"><table>')
                body.append(
                    "<thead><tr>"
                    + "".join(f"<th>{inline(c)}</th>" for c in rows[0])
                    + "</tr></thead><tbody>"
                )
                for r in rows[1:]:
                    body.append(
                        "<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>"
                    )
                body.append("</tbody></table></div>")
            continue
        m = re.match(r"^(#{1,4})\s+(.*)$", line)
        if m:
            flush_para()
            level = len(m.group(1))
            title = m.group(2).strip()
            body.append(f'<h{level} id="{sid_of(title)}">{inline(title)}</h{level}>')
            i += 1
            continue
        if re.match(r"^[-*]\s+", line):
            flush_para()
            body.append("<ul>")
            while i < len(lines) and re.match(r"^[-*]\s+", lines[i]):
                item = re.sub(r"^[-*]\s+", "", lines[i])
                body.append(f"<li>{inline(item)}</li>")
                i += 1
            body.append("</ul>")
            continue
        if not line.strip():
            flush_para()
            i += 1
            continue
        para.append(line.strip())
        i += 1
    flush_para()

    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(page_title)}</title>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;600;700&family=JetBrains+Mono&display=swap" rel="stylesheet">
<style>
body {{ margin:0; font-family:"DM Sans",system-ui,sans-serif; background:#f6f4f1; color:#1c1917;
  line-height:1.65; font-size:18px; }}
main {{ max-width:720px; margin:24px auto; background:#fff; border:1px solid #e7e5e4;
  border-radius:18px; padding:32px 28px 48px; box-shadow:0 8px 30px rgba(0,0,0,.04); }}
h1 {{ font-size:1.75rem; margin:0 0 12px; letter-spacing:-.02em; }}
h2 {{ font-size:1.25rem; margin:28px 0 10px; border-top:1px solid #e7e5e4; padding-top:16px; }}
h3 {{ font-size:1.05rem; margin:22px 0 8px; }}
p {{ margin:0 0 12px; }}
a {{ color:#7B61FF; font-weight:600; }}
code {{ font-family:"JetBrains Mono",monospace; font-size:.86em; background:#f5f5f4;
  padding:2px 6px; border-radius:6px; }}
.tw {{ overflow:auto; margin:12px 0 18px; border:1px solid #e7e5e4; border-radius:12px; }}
table {{ width:100%; border-collapse:collapse; font-size:15px; }}
th, td {{ padding:10px 12px; text-align:left; border-bottom:1px solid #e7e5e4; vertical-align:top; }}
th {{ background:#fafaf9; font-size:11px; text-transform:uppercase; letter-spacing:.04em; color:#57534e; }}
.badge {{ display:inline-block; background:#efeaff; color:#7B61FF; font-weight:700;
  font-size:12px; padding:5px 10px; border-radius:99px; margin-bottom:12px; }}
@media (max-width:640px) {{ main {{ margin:12px; padding:22px 16px 36px; }} body {{ font-size:16.5px; }} }}
</style>
</head>
<body>
<main>
<div class="badge">LOCKED · easy read</div>
{"".join(body)}
</main>
</body>
</html>
"""
    html_path.write_text(doc, encoding="utf-8")
    print(f"Wrote {html_path} ({html_path.stat().st_size} bytes)")


def main() -> None:
    base = pathlib.Path(r"D:\dev\mintzer-app\docs\design")
    pairs = [
        (
            base / "NOTIFICATION-TEMPLATES-LOCKED.md",
            base / "NOTIFICATION-TEMPLATES-LOCKED.html",
            "Mintzer push templates (short)",
        ),
        (
            base / "NOTIFICATION-TEMPLATE-BANKS-LOCKED.md",
            base / "NOTIFICATION-TEMPLATE-BANKS.html",
            "Mintzer push banks",
        ),
    ]
    for md, ht, title in pairs:
        if md.exists():
            md_to_html(md, ht, title)


if __name__ == "__main__":
    main()
