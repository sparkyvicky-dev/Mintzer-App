import urllib.request
import ssl
import re
from pathlib import Path
from html.parser import HTMLParser

ctx = ssl.create_default_context()
UA = {"User-Agent": "Mozilla/5.0"}

def fetch(url):
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=20, context=ctx) as r:
            return r.status, r.read(), r.headers.get("Content-Type", "")
    except urllib.error.HTTPError as e:
        return e.code, e.read(), e.headers.get("Content-Type", "")
    except Exception as e:
        return None, str(e).encode(), ""

status, body, ctype = fetch("https://mintzer.in/")
print("HOME", status, ctype, "len", len(body) if isinstance(body, bytes) else body)
text = body.decode("utf-8", "replace") if isinstance(body, bytes) else ""

# extract img src and css url
srcs = re.findall(r'(?:src|href)=["\']([^"\']+)["\']', text)
urls = re.findall(r'url\(([^)]+)\)', text)
assets = []
for s in srcs + urls:
    s = s.strip().strip('"').strip("'")
    if any(s.lower().endswith(ext) for ext in (".webp", ".png", ".jpg", ".jpeg", ".svg", ".ico", ".css", ".js")):
        assets.append(s)
# unique preserve order
seen = set()
uniq = []
for a in assets:
    if a not in seen:
        seen.add(a)
        uniq.append(a)

print("ASSET REFS", len(uniq))
broken = []
ok = []
for a in uniq:
    if a.startswith("http"):
        url = a
    elif a.startswith("/"):
        url = "https://mintzer.in" + a
    else:
        url = "https://mintzer.in/" + a
    st, b, ct = fetch(url)
    size = len(b) if isinstance(b, bytes) else 0
    mark = "OK" if st == 200 and size > 50 else "BAD"
    print(f"  {mark} {st} {size:7d}  {a}")
    if mark == "BAD":
        broken.append((a, st, size))
    else:
        ok.append(a)

print("\nBROKEN COUNT", len(broken))
# compare local
local = Path(r"D:\dev\mintzer-app\mintzer.in\mintzer\mintzer")
print("local index exists", (local/"index.html").exists())
print("local hero", (local/"assets/images/hero/hero-mintzer-dashboard.webp").exists(), (local/"assets/images/hero/hero-mintzer-dashboard.webp").stat().st_size if (local/"assets/images/hero/hero-mintzer-dashboard.webp").exists() else 0)
print("local footer", (local/"assets/images/footer/hero-app-devices-mockup.webp").stat().st_size if (local/"assets/images/footer/hero-app-devices-mockup.webp").exists() else 0)
