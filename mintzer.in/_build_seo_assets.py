"""Build footer webp, OG image, multi-size favicons from brand mark."""
from pathlib import Path
from PIL import Image, ImageDraw
import io
import base64
import re

brand = Path(r"D:\dev\mintzer-app\mintzer.in\mintzer\mintzer\assets\images\branding")
footer_src = Path(
    r"D:\dev\mintzer-app\mintzer.in\mintzer\mintzer (2)\mintzer\assets\images\footer\final footer.png"
)
footer_dst = Path(
    r"D:\dev\mintzer-app\mintzer.in\mintzer\mintzer\assets\images\footer\hero-app-devices-mockup.webp"
)
preview = Path(r"D:\dev\mintzer-app\mintzer.in\_spell-preview")
preview.mkdir(exist_ok=True)

# --- footer ---
foot = Image.open(footer_src).convert("RGBA")
print("footer", foot.size, foot.mode)
# knock near-black bg from edges if any
from collections import deque

px = foot.load()
w, h = foot.size


def is_bg(r, g, b, a):
    if a < 15:
        return True
    return max(r, g, b) <= 12 and (max(r, g, b) - min(r, g, b)) <= 6


mask = [[False] * w for _ in range(h)]
q = deque()


def push(x, y):
    if 0 <= x < w and 0 <= y < h and not mask[y][x] and is_bg(*px[x, y]):
        mask[y][x] = True
        q.append((x, y))


for x in range(w):
    push(x, 0)
    push(x, h - 1)
for y in range(h):
    push(0, y)
    push(w - 1, y)
n = 0
while q:
    x, y = q.popleft()
    px[x, y] = (0, 0, 0, 0)
    n += 1
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        push(x + dx, y + dy)
print("footer cleared", n)
foot.save(footer_dst, "WEBP", quality=92, method=4)
print("footer webp", footer_dst.stat().st_size)

# --- favicons from existing 48 mark ---
base = Image.open(brand / "favicon-mintzer.png").convert("RGBA")
# upsample from apple-touch if better
base180 = Image.open(brand / "apple-touch-icon.png").convert("RGBA")
for size, name in [(16, "favicon-16.png"), (32, "favicon-32.png"), (48, "favicon-48.png"), (192, "favicon-192.png"), (512, "favicon-512.png")]:
    im = base180.resize((size, size), Image.Resampling.LANCZOS)
    im.save(brand / name, "PNG", optimize=True)
    print("wrote", name)

# ICO multi-size
ico_path = brand / "favicon.ico"
base180.resize((32, 32), Image.Resampling.LANCZOS).save(
    ico_path,
    format="ICO",
    sizes=[(16, 16), (32, 32), (48, 48)],
)
print("wrote favicon.ico", ico_path.stat().st_size)

# --- OG 1200x630 ---
og = Image.new("RGB", (1200, 630), (242, 240, 245))
draw = ImageDraw.Draw(og)
# purple panel left
draw.rounded_rectangle((60, 60, 520, 570), radius=40, fill=(156, 113, 228))
mark = base180.resize((280, 280), Image.Resampling.LANCZOS)
# center mark on purple panel
og.paste(mark, (60 + (460 - 280) // 2, 60 + (510 - 280) // 2), mark)
# right text area — simple wordmark bars as fallback without font issues
try:
    from PIL import ImageFont
    font_lg = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 72)
    font_sm = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 32)
except Exception:
    font_lg = ImageFont.load_default()
    font_sm = font_lg
draw.text((580, 220), "Mintzer", fill=(32, 32, 32), font=font_lg)
draw.text((580, 320), "Card deals. Bank payouts.", fill=(85, 85, 85), font=font_sm)
draw.text((580, 380), "mintzer.in", fill=(156, 113, 228), font=font_sm)
og_path = brand / "og-image.jpg"
og.save(og_path, "JPEG", quality=90, optimize=True)
og.save(preview / "og-image.jpg", "JPEG", quality=90)
print("og", og_path.stat().st_size, og.size)
