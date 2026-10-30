# Expand each V3 push bank from 30 → 100 title/body variants.
# Keeps existing rows 1–N; generates more with same tokens + tone.

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(r"D:\dev\mintzer-app")
SRC = ROOT / "_hostinger_explore" / "newapp" / "resources" / "v3_push" / "templates.json"
DOCS = ROOT / "docs" / "design" / "v3_push_templates.json"
TARGET = 100

# Extra title/body seeds per bank (rotated + mixed with existing).
EXTRA: dict[str, list[tuple[str, str]]] = {
    "otp": [
        ("OTP please 🔐", "Add delivery OTP for Order {ref}."),
        ("Rider waiting 🙂", "Share OTP so {product} can be handed over."),
        ("Almost delivered 📦", "OTP still needed · Order {ref}."),
        ("One tap left ⚡", "Update OTP in Mintzer for Order {ref}."),
        ("Doorstep OTP 🚪", "Courier needs OTP for {product}."),
        ("Finish delivery 🛵", "Enter OTP · Order {ref}."),
        ("OTP unlocks drop ✅", "Order {ref} is waiting on your OTP."),
        ("Quick OTP nudge 🔔", "Please add OTP for {product} now."),
        ("Delivery stuck without OTP ⏸️", "Update OTP · Order {ref}."),
        ("Help the rider 🙌", "OTP for Order {ref} please."),
        ("Final mile OTP 🏁", "Share OTP to complete {product}."),
        ("Mintzer needs OTP 📲", "Order {ref} · enter the courier OTP."),
        ("SMS OTP → app 💬", "Paste OTP for Order {ref}."),
        ("Soft OTP reminder 🌤️", "Whenever ready — OTP for Order {ref}."),
        ("Firm OTP reminder 🔥", "Order {ref} still missing OTP. Update now."),
        ("OTP + last 4 📱", "Complete delivery details · Order {ref}."),
        ("Parcel at gate 🏡", "OTP required for {product}."),
        ("Don’t leave rider hanging 🙏", "Add OTP · Order {ref}."),
        ("Delivery OTP due ⏳", "Update now for Order {ref}."),
        ("Close the loop 🔁", "OTP for {product} · Order {ref}."),
        ("OFD needs you 🚚", "Enter OTP in Mintzer · Order {ref}."),
        ("OTP = done 🎯", "One field left for Order {ref}."),
        ("Courier SMS code 🔢", "Type it in for Order {ref}."),
        ("Keep it moving ➡️", "OTP update · Order {ref}."),
        ("Friendly OTP ping 😊", "Please share OTP for {product}."),
        ("Order {ref} OTP 📌", "Delivery can’t finish without it."),
        ("Drop confirmation 🔐", "Add OTP for Order {ref}."),
        ("Mintzer delivery step 📋", "OTP pending · {product}."),
        ("Out for delivery · OTP 🛵", "Update Order {ref} now."),
        ("You’re one code away ✨", "OTP for Order {ref}."),
        ("OTP check-in 🛎️", "Please update for {product}."),
        ("Delivery partner ping 📢", "OTP needed · Order {ref}."),
        ("Handover code 🏷️", "Enter OTP · Order {ref}."),
        ("Safe delivery OTP 🛡️", "Confirm with OTP for {product}."),
        ("App OTP field empty ✍️", "Fill it for Order {ref}."),
        ("Last step before invoice 📤", "OTP · Order {ref}."),
        ("Warehouse drop OTP 🏭", "Update OTP for Order {ref}."),
        ("OTP soft nudge 2 🌿", "Order {ref} still needs OTP."),
        ("OTP firm nudge 2 🚨", "Add OTP now · Order {ref}."),
        ("Don’t delay drop ⏱️", "OTP for {product} please."),
        ("Courier waiting room 🪑", "OTP · Order {ref}."),
        ("Mintzer OFD reminder 🔔", "Share OTP for Order {ref}."),
        ("Code from SMS 📩", "Paste into Order {ref}."),
        ("OTP helps mintzer confirm ✅", "Order {ref} · {product}."),
        ("Delivery can’t close 🛑", "Need OTP for Order {ref}."),
        ("Nearly there 🌙", "OTP update · Order {ref}."),
        ("Tap · type OTP · done 👍", "Order {ref}."),
        ("Rider at Mintzer address 📍", "OTP for Order {ref}."),
        ("OTP overdue soft 🎈", "Please add OTP · Order {ref}."),
        ("OTP overdue firm 🧨", "Order {ref} OTP still missing."),
        ("Complete OFD now 🚀", "OTP · {product}."),
        ("Delivery OTP alert ⚠️", "Update Order {ref}."),
        ("One more field 🧾", "OTP for Order {ref}."),
        ("Partner needs confirmation 🤝", "OTP · Order {ref}."),
        ("Mintzer waiting on OTP ⌛", "Order {ref} · {product}."),
        ("Open order · add OTP 📂", "Order {ref}."),
        ("OTP keeps payout path clear 💸", "Finish OFD · Order {ref}."),
        ("Drop code please 🔑", "Order {ref}."),
        ("Courier OTP now 📞", "Update for {product}."),
        ("Finish the mile 🛣️", "OTP · Order {ref}."),
        ("OTP reminder #extra 💫", "Please update Order {ref}."),
        ("Smooth delivery needs OTP 🌊", "Order {ref}."),
        ("Don’t skip OTP ⛔", "Required for Order {ref}."),
        ("App reminder · OTP 📲", "{product} · Order {ref}."),
        ("Warehouse OTP gate 🚪", "Enter code · Order {ref}."),
        ("OTP soft 3 🌼", "Whenever you can — Order {ref}."),
        ("OTP firm 3 🌋", "Update OTP immediately · Order {ref}."),
        ("Delivery clock ticking ⏰", "OTP for Order {ref}."),
        ("Help us confirm drop 📦", "OTP · {product}."),
        ("Order {ref} needs OTP 🧭", "Open Mintzer and update."),
        ("Last 4 + OTP pair 🔢", "Complete OFD · Order {ref}."),
        ("Courier SMS arrived? 📬", "Paste OTP · Order {ref}."),
        ("OTP = next step unlock 🔓", "Order {ref}."),
        ("Mintzer OFD soft ping 🌤️", "OTP for {product}."),
        ("Mintzer OFD firm ping 🔥", "OTP still pending · Order {ref}."),
    ],
    "tracking": [
        ("Tracking still empty 📭", "Add tracking ID for Order {ref}."),
        ("AWB missing 🏷️", "Paste courier ID · Order {ref}."),
        ("Ship update please 🚚", "Tracking for {product}."),
        ("Order {ref} needs AWB 📌", "Update tracking in Mintzer."),
        ("Dispatch waiting ⏳", "Add tracking ID now."),
        ("Courier link gap 🔗", "Tracking ID · Order {ref}."),
        ("Soft tracking nudge 🌤️", "Whenever ready — Order {ref}."),
        ("Firm tracking nudge 🔥", "Tracking still missing · Order {ref}."),
        ("Move the parcel ➡️", "Add tracking for {product}."),
        ("Shipping ID alert 🚨", "Order {ref} needs tracking."),
        ("Paste from SMS 📩", "Tracking ID · Order {ref}."),
        ("Store shipped? Tell us 🛍️", "Add tracking · Order {ref}."),
        ("Ops can’t follow air 🌫️", "Tracking ID required."),
        ("Unlock delivery map 🗺️", "Add tracking · Order {ref}."),
        ("Quick AWB reminder 🔔", "Order {ref} · {product}."),
        ("Tracking = progress 📈", "Update Order {ref}."),
        ("One field left ✍️", "Tracking for Order {ref}."),
        ("Help logistics 🙌", "Add AWB · Order {ref}."),
        ("Ekart / Delhivery ID? 📦", "Paste in Order {ref}."),
        ("Don’t stall dispatch 🛑", "Tracking · Order {ref}."),
        ("Accepted ✅ · Tracking ❓", "Order {ref} needs shipping ID."),
        ("Shipping details due 📝", "Update Order {ref}."),
        ("AWB unlocks next 🔓", "Add tracking · Order {ref}."),
        ("Parcel status unknown ❔", "Tracking ID for {product}."),
        ("Mintzer needs AWB 📋", "Order {ref}."),
        ("Courier ID please 🏷️", "Order {ref} · {product}."),
        ("Tracking soft 2 🌿", "Add when you have it · Order {ref}."),
        ("Tracking firm 2 🧨", "Update tracking now · Order {ref}."),
        ("Shipment proof 📄", "Tracking ID · Order {ref}."),
        ("Keep deal moving 🏃‍♂️", "Add tracking for Order {ref}."),
        ("Home shows next action 🏠", "Tracking · Order {ref}."),
        ("Order stuck without AWB ⏸️", "Update Order {ref}."),
        ("Flipkart / Amazon AWB 🛒", "Paste · Order {ref}."),
        ("Tracking overdue soft 🎈", "Order {ref} still needs ID."),
        ("Tracking overdue firm 🌋", "Submit tracking · Order {ref}."),
        ("Logistics handoff 🤝", "Add courier ID · Order {ref}."),
        ("Shipping ping 📢", "Tracking for {product}."),
        ("Mintzer tracking desk 🛎️", "Order {ref} awaiting AWB."),
        ("Paste · save · done 👍", "Tracking · Order {ref}."),
        ("Courier dropdown + ID 📦", "Complete Order {ref}."),
        ("No tracking, no updates 📡", "Add ID · Order {ref}."),
        ("Dispatch checklist ☑️", "Tracking missing · Order {ref}."),
        ("AWB soft 3 🌼", "Order {ref} · add when ready."),
        ("AWB firm 3 🚨", "Tracking required now · Order {ref}."),
        ("Ship it on paper too 🧾", "Tracking · Order {ref}."),
        ("Ops is waiting 🛎️", "Add tracking · Order {ref}."),
        ("Delivery flow paused ⏸️", "Tracking ID · Order {ref}."),
        ("Action: tracking ⚡", "Order {ref} · {product}."),
        ("Where’s the AWB? 👀", "Update Order {ref}."),
        ("Shipping update pending 🚚", "Order {ref}."),
        ("Tracking ID needed 📦", "{product} · Order {ref}."),
        ("Don’t forget AWB 🧠", "Order {ref}."),
        ("Courier name + ID 🚚", "Save tracking · Order {ref}."),
        ("Next stop: tracking 🏁", "Order {ref}."),
        ("Mintzer soft track 🌙", "Add AWB · Order {ref}."),
        ("Mintzer firm track 🔥", "Tracking still empty · Order {ref}."),
        ("Store order shipped? 📤", "Paste tracking · Order {ref}."),
        ("AWB from seller app 📱", "Enter in Mintzer · Order {ref}."),
        ("Tracking keeps earn path clear 💸", "Update Order {ref}."),
        ("One AWB away ✨", "Order {ref} · {product}."),
        ("Logistics blank 📭", "Fill tracking · Order {ref}."),
        ("Ship status please 📊", "Tracking ID · Order {ref}."),
        ("Courier pick + paste ✍️", "Order {ref}."),
        ("Tracking reminder extra 💫", "Please update Order {ref}."),
        ("Open order · add AWB 📂", "Order {ref}."),
        ("Parcel can’t be followed 🔍", "Need tracking · Order {ref}."),
        ("Dispatch queue 📥", "Tracking for Order {ref}."),
        ("AWB check-in 🏷️", "Order {ref} · {product}."),
        ("Shipping ID soft ping 🌤️", "Order {ref}."),
        ("Shipping ID firm ping 🔥", "Add tracking immediately · Order {ref}."),
    ],
}

# Generic expanders for banks without long EXTRA lists.
GENERIC_PREFIXES = [
    ("Update 🔔", "Please update {product} · Order {ref}."),
    ("Quick nudge ⚡", "Order {ref} needs a quick action."),
    ("Friendly reminder 😊", "Open Mintzer for Order {ref}."),
    ("Action needed 📌", "{product} · Order {ref} waiting on you."),
    ("Don’t delay ⏳", "Complete the next step · Order {ref}."),
    ("Almost there ✨", "One step left for Order {ref}."),
    ("Mintzer ping 🛎️", "Check Order {ref} in the app."),
    ("Soft reminder 🌤️", "Whenever ready — Order {ref}."),
    ("Firm reminder 🔥", "Order {ref} still needs your update."),
    ("Keep it moving ➡️", "{product} · Order {ref}."),
]


def expand_bank(key: str, rows: list[dict]) -> list[dict]:
    out = []
    seen = set()

    def add(title: str, body: str):
        t, b = title.strip(), body.strip()
        if not t or not b:
            return
        sig = (t.lower(), b.lower())
        if sig in seen:
            return
        seen.add(sig)
        out.append({"title": t, "body": b})

    for r in rows:
        add(str(r.get("title", "")), str(r.get("body", "")))

    for title, body in EXTRA.get(key, []):
        add(title, body)
        if len(out) >= TARGET:
            return out[:TARGET]

    # Paraphrase existing by light title variants.
    emojis = ["🔔", "⚡", "📌", "✨", "🚀", "📦", "🙏", "💬", "👉", "🎯"]
    base = list(out)
    i = 0
    while len(out) < TARGET and base:
        src = base[i % len(base)]
        em = emojis[i % len(emojis)]
        # Title variants
        title = src["title"]
        # strip trailing emoji cluster roughly
        core = re.sub(r"[\U0001F300-\U0001FAFF\u2600-\u27BF]+", "", title).strip()
        variants = [
            f"{core} {em}".strip(),
            f"{em} {core}".strip(),
            f"{core} · Mintzer {em}".strip(),
            f"Mintzer · {core} {em}".strip(),
        ]
        body = src["body"]
        body_vars = [
            body,
            body.replace("Please ", "").strip(),
            (body if body.endswith(".") else body + ".") + " Open the app.",
            "Quick update: " + body[:1].lower() + body[1:] if len(body) > 1 else body,
        ]
        add(variants[i % len(variants)], body_vars[i % len(body_vars)])
        if len(out) < TARGET:
            gtitle, gbody = GENERIC_PREFIXES[i % len(GENERIC_PREFIXES)]
            # bank-flavored generic
            add(f"{gtitle}", gbody)
        i += 1
        if i > TARGET * 8:
            break

    # Pad with numbered generics if still short
    n = 1
    while len(out) < TARGET:
        add(f"Mintzer update {n} 🔔", f"Open Order {{ref}} for the next step on {{product}}.")
        n += 1

    return out[:TARGET]


def main():
    data = json.loads(SRC.read_text(encoding="utf-8"))
    banks = data.get("banks") or {}
    new_banks = {}
    for key, rows in banks.items():
        if not isinstance(rows, list):
            continue
        new_banks[key] = expand_bank(key, rows)
        print(f"{key}={len(new_banks[key])}")

    data["banks"] = new_banks
    data["meta"] = {
        **(data.get("meta") or {}),
        "variants_per_bank": TARGET,
        "note": "Expanded to 100 variants per bank 22 Sep 2026",
    }
    text = json.dumps(data, ensure_ascii=False, indent=2)
    SRC.write_text(text + "\n", encoding="utf-8")
    DOCS.parent.mkdir(parents=True, exist_ok=True)
    DOCS.write_text(text + "\n", encoding="utf-8")
    # Also sync design copy used by docs if present
    locked = ROOT / "docs" / "design" / "NOTIFICATION-TEMPLATE-BANKS-LOCKED.md"
    if locked.exists():
        raw = locked.read_text(encoding="utf-8")
        raw = raw.replace("30+ each", "100 each").replace("≥ 30", "≥ 100").replace("| 30 |", "| 100 |")
        raw = raw.replace("(30 variants)", "(100 variants)")
        raw = raw.replace("**≥ 30**", "**≥ 100**")
        locked.write_text(raw, encoding="utf-8")
    print("OK wrote", SRC)


if __name__ == "__main__":
    main()
