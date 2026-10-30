"""Fit each brand into a circle-ready square. No stretch. Flatten checkerboards."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(r"D:\dev\mintzer-app")
SRC_STORES = ROOT / "assets" / "Store logo png"
SRC_CARDS = ROOT / "assets" / "Bank Logo Png"
OUT_STORES = ROOT / "assets" / "logos" / "fitted" / "stores"
OUT_CARDS = ROOT / "assets" / "logos" / "fitted" / "cards"
SIZE = 160

STORES = {
    "flipkart": "flipkart.png",
    "amazon": "Amazon_icon.png",
    "apple": "Apple store logo.png",
    "iqoo": "iqoo store logo.png",
    "vivo": "vivo store png.png",
    "oppo": "oppo store png.png",
    "reliance-digital": "Reliance digital.jpg",
    "jiomart": "JioMart_logo.svg.webp",
    "sangeetha": "sangeetha png.png",
    "myntra": "myntra v2.webp",
    "motorola": "Motorola-Logo.png",
    "shopsy": "shopsy logo.jpg",
    "instamart": "instamart.png",
    "tata-neu": "tataneu logo.png",
    "imagine": "imagine store.png",
    "vijaysales": "vijay sales.png",
}

CARDS = {
    "axis": "axisbank.png",
    "hdfc": "hdfc.webp",
    "icici": "Icici.jpg",
    "pnb": "pnb bank.png",
    "rbl": "rbl v2.png",
    "sbi": "sbi card.png",
    "kotak": "kotak bank.png",
    "bob": "Bob card.jpg",
    "idfc": "idfc card.png",
    "amex": "amex card.jpg",
    "yes": "yes bank card.png",
    "canara": "canara bank logo.jpg",
    "hsbc": "hsbc logo.jpg",
    "onecard": "OneCard_Logo_OneCard_Logo_1.png",
    "indusind": "indus ind logo.png",
    "federal": "Federal logo png.png",
    "scapia": "scapia logo.png",
}

# zoom 1 = full mark. pad keeps artwork inside the CSS circle.
# Square color fields use pad 0 so the fill becomes a circle, not a box.
PROFILES = {
    "flipkart": {"pad": 0, "zoom": 1.0, "trim_black": True},
    "amazon": {"pad": 22, "zoom": 1.0},
    "apple": {"pad": 10, "zoom": 1.0, "flatten": True, "trim_black": False},
    "iqoo": {"pad": 0, "zoom": 1.0},
    "vivo": {"pad": 0, "zoom": 1.0},
    "oppo": {"pad": 0, "zoom": 1.0, "trim_black": True},
    "reliance-digital": {"pad": 0, "zoom": 1.0},
    "jiomart": {"pad": 0, "zoom": 1.0, "trim_black": True},
    "sangeetha": {"pad": 14, "zoom": 1.0, "crop_box": (440, 148, 582, 278)},
    "myntra": {"pad": 12, "zoom": 1.0, "flatten": True},
    "motorola": {"pad": 22, "zoom": 1.0, "bg": (0, 0, 0), "trim_white": False, "keep": "light"},
    "shopsy": {"pad": 0, "zoom": 1.0},
    "instamart": {"pad": 0, "zoom": 1.0, "trim_black": True, "crop": "left_square", "bleed": True},
    "tata-neu": {"pad": 0, "zoom": 1.0, "trim_black": True, "trim_white": False},
    "imagine": {"pad": 16, "zoom": 1.0, "bg": (0, 0, 0), "trim_white": False, "keep": "light", "crop_box": (16, 140, 286, 310)},
    "vijaysales": {"pad": 18, "zoom": 1.0},
    "axis": {"pad": 12, "zoom": 1.0},
    "hdfc": {"pad": 30, "zoom": 1.0, "kill_checker": True, "flatten": True, "crop_box": (90, 95, 930, 835)},
    "icici": {"pad": 12, "zoom": 1.0},
    "pnb": {"pad": 4, "zoom": 1.0},
    "rbl": {"pad": 24, "zoom": 1.0, "flatten": True, "crop": "rbl_v2"},
    "sbi": {"pad": 10, "zoom": 1.0, "crop": "sbi_circle"},
    "kotak": {"pad": 4, "zoom": 1.0, "trim_black": True},
    "bob": {"pad": 12, "zoom": 1.0},
    "idfc": {"pad": 4, "zoom": 1.0},
    "amex": {"pad": 10, "zoom": 1.0},
    "yes": {"pad": 16, "zoom": 1.0, "crop": "red_mark", "grow": 0.04},
    "canara": {"pad": 4, "zoom": 1.0},
    "hsbc": {"pad": 16, "zoom": 1.0, "crop": "red_mark", "grow": 0.04},
    "onecard": {"pad": 12, "zoom": 1.0, "flatten": True},
    "indusind": {"pad": 28, "zoom": 1.0, "flatten": True},
    "federal": {"pad": 24, "zoom": 1.0, "crop_box": (24, 20, 576, 438)},
    "scapia": {"pad": 18, "zoom": 1.0},
}


def luma(r: int, g: int, b: int) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def bbox(im: Image.Image, keep) -> tuple[int, int, int, int] | None:
    px = im.load()
    w, h = im.size
    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if keep(px[x, y]):
                if x < min_x:
                    min_x = x
                if y < min_y:
                    min_y = y
                if x > max_x:
                    max_x = x
                if y > max_y:
                    max_y = y
    if max_x < 0:
        return None
    return min_x, min_y, max_x + 1, max_y + 1


def is_clear_or_white(p) -> bool:
    r, g, b, a = p
    if a < 16:
        return True
    return r > 248 and g > 248 and b > 248 and a > 200


def is_clear_or_black(p) -> bool:
    r, g, b, a = p
    if a < 16:
        return True
    return luma(r, g, b) < 18 and a > 200


def is_light(p) -> bool:
    r, g, b, a = p
    return a > 20 and luma(r, g, b) > 40


def is_red_mark(p) -> bool:
    r, g, b, a = p
    return a > 30 and r > 150 and g < 100 and b < 100


def is_sangeetha_orange(p) -> bool:
    r, g, b, a = p
    return a > 30 and r > 150 and 40 < g < 210 and b < 110


def crop_to(im: Image.Image, box) -> Image.Image:
    return im if not box else im.crop(box)


def square_from(im: Image.Image, side: str) -> Image.Image:
    w, h = im.size
    side_px = min(w, h)
    if side == "left_square":
        return im.crop((0, 0, side_px, side_px if h >= side_px else h))
    if w >= h:
        return im.crop((w - side_px, 0, w, h if h <= side_px else side_px))
    return im.crop((0, h - side_px, w, h))


def square_around(im: Image.Image, box: tuple[int, int, int, int], grow: float = 0.12) -> Image.Image:
    x0, y0, x1, y1 = box
    w, h = im.size
    cx = (x0 + x1) / 2
    cy = (y0 + y1) / 2
    side = max(x1 - x0, y1 - y0) * (1 + grow)
    half = side / 2
    l = int(round(cx - half))
    t = int(round(cy - half))
    r = int(round(cx + half))
    b = int(round(cy + half))
    if l < 0:
        r -= l
        l = 0
    if t < 0:
        b -= t
        t = 0
    if r > w:
        l -= r - w
        r = w
    if b > h:
        t -= b - h
        b = h
    l, t = max(0, l), max(0, t)
    return im.crop((l, t, r, b))


def kill_checker(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if max(r, g, b) - min(r, g, b) <= 22 and luma(r, g, b) >= 198:
                px[x, y] = (255, 255, 255, 255)
    return im


def crop_sangeetha_check(im: Image.Image) -> Image.Image:
    box = bbox(im, is_sangeetha_orange)
    if not box:
        return square_from(im, "right_square")
    x0, y0, x1, y1 = box
    bw, bh = x1 - x0, y1 - y0
    x0 = max(0, int(x0 - bw * 0.40))
    y0 = max(0, int(y0 - bh * 0.28))
    x1 = min(im.size[0], int(x1 + bw * 0.10))
    y1 = min(im.size[1], int(y1 + bh * 0.10))
    return square_around(im, (x0, y0, x1, y1), grow=0.06)


def sample_bleed(im: Image.Image) -> tuple[int, int, int]:
    rgb = im.convert("RGB")
    w, h = rgb.size
    pts = [(2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3), (w // 2, 2), (2, h // 2)]
    best, best_s = rgb.getpixel((2, 2)), -1
    for p in pts:
        r, g, b = rgb.getpixel(p)
        sat = max(r, g, b) - min(r, g, b)
        if sat > best_s:
            best, best_s = (r, g, b), sat
    return best


def is_sbi_blue(p) -> bool:
    r, g, b, a = p
    return a > 40 and b > 140 and g > 80 and r < 130


def place(im: Image.Image, size: int, pad: int, zoom: float, bg: tuple[int, int, int]) -> Image.Image:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    cw, ch = im.size
    inner = max(1, size - pad * 2)
    scale = min(inner / cw, inner / ch) * max(1.0, zoom)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    fitted = im.resize((nw, nh), Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", (size, size), (*bg, 255))
    layer.paste(fitted, ((size - nw) // 2, (size - nh) // 2), fitted)
    rgb = Image.new("RGB", (size, size), bg)
    rgb.paste(layer.convert("RGB"))
    return rgb


def fit_one(kind: str, src: Path, dest: Path) -> str:
    cfg = PROFILES.get(kind, {"pad": 6})
    pad = int(cfg.get("pad", 6))
    zoom = float(cfg.get("zoom", 1.0))
    trim_white = cfg.get("trim_white", True)
    trim_black = cfg.get("trim_black", False)
    flatten = cfg.get("flatten", False)
    bg = cfg.get("bg", (255, 255, 255))
    crop = cfg.get("crop")
    keep = cfg.get("keep")
    grow = float(cfg.get("grow", 0.18))

    im = Image.open(src).convert("RGBA")
    note = kind

    if cfg.get("crop_box"):
        im = im.crop(tuple(cfg["crop_box"]))
        note += " box"

    if cfg.get("kill_checker"):
        im = kill_checker(im)
        note += " nocheck"

    if flatten:
        base = Image.new("RGBA", im.size, (255, 255, 255, 255))
        base.alpha_composite(im)
        im = base
        note += " flatten"

    if keep == "light":
        im = crop_to(im, bbox(im, is_light))
        note += " light"
    else:
        if trim_white:
            im = crop_to(im, bbox(im, lambda p: not is_clear_or_white(p)))
            note += " -w"
        if trim_black:
            im = crop_to(im, bbox(im, lambda p: not is_clear_or_black(p)))
            note += " -k"

    if cfg.get("top_frac"):
        w, h = im.size
        im = im.crop((0, 0, w, max(1, int(h * float(cfg["top_frac"])))))
        note += " top"

    if crop == "left_square":
        im = square_from(im, "left_square")
        note += " Lsq"
    elif crop == "right_square":
        im = square_from(im, "right_square")
        note += " Rsq"
    elif crop == "top_square":
        w, h = im.size
        im = im.crop((0, 0, w, min(h, w)))
        note += " Tsq"
    elif crop == "sangeetha_check":
        im = crop_sangeetha_check(im)
        note += " check"
    elif crop == "red_mark":
        box = bbox(im, is_red_mark)
        im = square_around(im, box, grow=grow) if box else square_from(im, "left_square")
        note += " red"
    elif crop == "rbl_v2":
        px = im.load()
        w, h = im.size
        first_red = 0
        for y in range(h):
            if any(
                p[0] > 150 and p[1] < 90 and p[3] > 20
                for p in (px[x, y] for x in range(0, w, 3))
            ):
                first_red = y
                break
        im = im.crop((0, max(0, first_red - 16), w, h))
        note += " rbl2"
    elif crop == "sbi_circle":
        px = im.load()
        w, h = im.size
        seen = False
        gap_y = None
        for y in range(h):
            n = sum(1 for x in range(0, w, 2) if is_sbi_blue(px[x, y]))
            if n > 30:
                seen = True
            elif seen and n == 0:
                gap_y = y
                break
        if gap_y:
            im = im.crop((0, 0, w, gap_y))
            im = crop_to(im, bbox(im, lambda p: not is_clear_or_white(p)))
        note += " disk"

    if cfg.get("bleed"):
        bg = sample_bleed(im)
        note += f" bleed{bg}"

    dest.parent.mkdir(parents=True, exist_ok=True)
    rgb = place(im, SIZE, pad, zoom, bg)
    rgb.save(dest, "PNG")
    return f"{dest.name:22} {im.size[0]}x{im.size[1]} zoom{zoom:.2f} pad{pad}  {note}"


def run(mapping: dict[str, str], src_dir: Path, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for kid, fname in mapping.items():
        src = src_dir / fname
        dest = out_dir / f"{kid}.png"
        if not src.exists():
            print("MISSING", src)
            continue
        print(fit_one(kid, src, dest))


if __name__ == "__main__":
    run(STORES, SRC_STORES, OUT_STORES)
    run(CARDS, SRC_CARDS, OUT_CARDS)
