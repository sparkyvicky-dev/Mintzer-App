import hashlib, base64, subprocess, os, sys

kt = r"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
pkg = "com.mintzer"

def google_sms_hash(package: str, cert_der: bytes) -> str:
    message = package.encode("utf-8") + b" " + cert_der
    digest = hashlib.sha256(message).digest()
    return base64.b64encode(digest[:9]).decode("ascii").rstrip("=")[:11]

def export(alias, ks, storepass, keypass):
    return subprocess.check_output(
        [kt, "-exportcert", "-alias", alias, "-keystore", ks, "-storepass", storepass, "-keypass", keypass],
        stderr=subprocess.DEVNULL,
    )

debug = export("androiddebugkey", os.path.expanduser(r"~\.android\debug.keystore"), "android", "android")
print("debug_hash", google_sms_hash(pkg, debug))

# key.properties
props = {}
with open(r"D:\dev\mintzer-app\app\android\key.properties", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        props[k.strip()] = v.strip()

candidates = [
    r"D:\dev\mintzer-app\mintzer-keys\upload-keystore.jks",
    os.path.normpath(os.path.join(r"D:\dev\mintzer-app\app\android", props.get("storeFile", ""))),
]
uks = next((p for p in candidates if os.path.isfile(p)), None)
print("upload_ks", uks)
if uks:
    cert = export(props["keyAlias"], uks, props["storePassword"], props["keyPassword"])
    print("upload_hash", google_sms_hash(pkg, cert))

# Sample DLT bodies
h = google_sms_hash(pkg, debug)
body = (
    "Welcome to Mintzer! Here is your OTP 123456 to login into your mintzer account. "
    "For more details visit: mintzer.in Regards Mintzr.\n" + h
)
print("sms_char_len", len(body))
print("sms_sample_tail", repr(body[-40:]))
