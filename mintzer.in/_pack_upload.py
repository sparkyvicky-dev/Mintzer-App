"""Build mintzer.in upload zip: index.html at zip root. No nested folders. No .DS_Store."""
from pathlib import Path
import zipfile

src = Path(r"D:\dev\mintzer-app\mintzer.in\mintzer\mintzer")
dst = Path(r"D:\dev\mintzer-app\mintzer.in\mintzer-in-upload.zip")
skip_names = {".DS_Store"}
skip_prefixes = ("ChatGPT Image",)
count = 0
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zf:
    for path in src.rglob("*"):
        if not path.is_file():
            continue
        if path.name in skip_names or path.name.startswith("._") or path.name.startswith(skip_prefixes):
            continue
        rel = path.relative_to(src).as_posix()
        zf.write(path, rel)
        count += 1
print("files", count, "zip", dst, "bytes", dst.stat().st_size)
print("root sample", [n for n in zipfile.ZipFile(dst).namelist() if "/" not in n])
