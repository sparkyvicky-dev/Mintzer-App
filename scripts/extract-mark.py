import base64
import re
from pathlib import Path

p = Path(r"D:\dev\mintzer-app\app\assets\logos\mintzer-mark-circle.svg")
t = p.read_text(encoding="utf-8", errors="replace")
m = re.search(r"data:image/(png|jpeg|jpg|webp);base64,([A-Za-z0-9+/=]+)", t)
print("match", bool(m))
if not m:
    raise SystemExit(1)
raw = base64.b64decode(m.group(2))
out = p.with_name("mintzer-mark-glyph.png")
out.write_bytes(raw)
print("wrote", out, "bytes", len(raw))

# Also compose a simple circular app icon with purple bg using PIL if available
try:
    from PIL import Image

    glyph = Image.open(out).convert("RGBA")
    size = 512
    canvas = Image.new("RGBA", (size, size), (123, 97, 255, 255))
    # rounded mask
    mask = Image.new("L", (size, size), 0)
    from PIL import ImageDraw

    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size, size), fill=255)
    # fit glyph in center 50%
    g = glyph.copy()
    g.thumbnail((size // 2, size // 2), Image.Resampling.LANCZOS)
    x = (size - g.width) // 2
    y = (size - g.height) // 2
    canvas.paste(g, (x, y), g)
    circle = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    circle.paste(canvas, (0, 0))
    circle.putalpha(mask)
    mark = p.with_name("mintzer-mark-circle.png")
    circle.save(mark)
    print("composed", mark)
except Exception as e:
    print("PIL compose skip:", e)
