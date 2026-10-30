from PIL import Image
import os

src = r"D:\dev\mintzer-app\app\assets\logos\mintzer-mark-circle.png"
out_dir = r"D:\dev\mintzer-app\app\android\app\src\main\res"
assets = r"D:\dev\mintzer-app\app\assets\logos"

img = Image.open(src).convert("RGBA")
w, h = img.size
px = img.load()

out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
opx = out.load()
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a < 16:
            continue
        brightness = (r + g + b) / 3
        if brightness > 200 and r > 180 and g > 180:
            opx[x, y] = (255, 255, 255, a)
        elif brightness > 160 and r > 140:
            opx[x, y] = (min(255, r + 20), min(255, g + 20), min(255, b + 20), a)

bbox = out.getbbox()
logo = out.crop(bbox)

fg_size = 1080
fg = Image.new("RGBA", (fg_size, fg_size), (0, 0, 0, 0))
safe = int(fg_size * 0.66)
logo_fit = logo.copy()
logo_fit.thumbnail((safe, safe), Image.Resampling.LANCZOS)
ox = (fg_size - logo_fit.width) // 2
oy = (fg_size - logo_fit.height) // 2
fg.paste(logo_fit, (ox, oy), logo_fit)

fg_path = os.path.join(assets, "ic_launcher_foreground.png")
fg.save(fg_path, "PNG")
print("wrote", fg_path)

preview = Image.new("RGBA", (fg_size, fg_size), (123, 97, 255, 255))
preview.paste(fg, (0, 0), fg)
preview_path = os.path.join(assets, "ic_launcher_full.png")
preview.save(preview_path, "PNG")
print("wrote", preview_path)

# Legacy + adaptive mipmap densities
densities = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
for folder, size in densities.items():
    d = os.path.join(out_dir, folder)
    os.makedirs(d, exist_ok=True)
    icon = preview.resize((size, size), Image.Resampling.LANCZOS)
    icon.save(os.path.join(d, "ic_launcher.png"), "PNG")
    icon.save(os.path.join(d, "ic_launcher_round.png"), "PNG")
    print("wrote", folder, size)

drawable_fg = os.path.join(out_dir, "drawable", "ic_launcher_foreground.png")
os.makedirs(os.path.dirname(drawable_fg), exist_ok=True)
# Android adaptive FG often 432dp @ xxxhdpi ~ 1080; keep 1080
fg.save(drawable_fg, "PNG")
print("wrote", drawable_fg)

# Notification status icon (white only)
notif = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
nl = logo.copy()
nl.thumbnail((72, 72), Image.Resampling.LANCZOS)
px2 = nl.load()
for y in range(nl.height):
    for x in range(nl.width):
        r, g, b, a = px2[x, y]
        px2[x, y] = (255, 255, 255, 255) if a > 32 else (0, 0, 0, 0)
nx = (96 - nl.width) // 2
ny = (96 - nl.height) // 2
notif.paste(nl, (nx, ny), nl)
notif_path = os.path.join(out_dir, "drawable", "ic_stat_mintzer.png")
notif.save(notif_path, "PNG")
print("wrote", notif_path)

# Android 13+ monochrome adaptive layer (optional)
mono = fg.copy()
mp = mono.load()
for y in range(mono.height):
    for x in range(mono.width):
        r, g, b, a = mp[x, y]
        mp[x, y] = (0, 0, 0, a) if a > 16 else (0, 0, 0, 0)
mono_path = os.path.join(out_dir, "drawable", "ic_launcher_monochrome.png")
mono.save(mono_path, "PNG")
print("wrote", mono_path)
