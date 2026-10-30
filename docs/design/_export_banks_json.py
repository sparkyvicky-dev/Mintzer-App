# -*- coding: utf-8 -*-
"""Export NOTIFICATION-TEMPLATE-BANKS-LOCKED.md → templates.json (server banks)."""
import json
import re
from pathlib import Path

MD = Path(r"D:\dev\mintzer-app\docs\design\NOTIFICATION-TEMPLATE-BANKS-LOCKED.md")
OUTS = [
    Path(r"D:\dev\mintzer-app\_hostinger_explore\newapp\resources\v3_push\templates.json"),
    Path(r"D:\dev\mintzer-app\docs\design\v3_push_templates.json"),
]

KEY_MAP = [
    ("OTP pending", "otp"),
    ("Tracking ID needed", "tracking"),
    ("Tracking ID received", "tracking_done"),
    ("Store Order ID needed", "order_id"),
    ("Invoice upload needed", "invoice_needed"),
    ("Invoice re-upload", "invoice_reupload"),
    ("Invoice verified", "invoice_verified"),
    ("Payment verified", "payment_verified"),
    ("Payout sent to bank", "payout_sent"),
    ("Deal live (pro", "deal_live"),
    ("Deal live (screenshot", "deal_funny"),
    ("Ticket reply", "ticket_reply"),
    ("Placement timer — 5", "timer_5m"),
    ("Placement timer — 1", "timer_1m"),
    ("Deal relist", "deal_relist"),
    ("Viewed follow-up (30", "deal_viewed_early"),
    ("Viewed follow-up (~1.5", "deal_viewed_mid"),
    ("Still-live", "still_live"),
]

ROW_RE = re.compile(
    r"\|\s*(\d+)\s*\|\s*`([^`]*)`\s*\|\s*`([^`]*)`\s*\|"
)


def main() -> None:
    md = MD.read_text(encoding="utf-8")
    banks: dict[str, list] = {}
    sections = re.split(r"\n### ", md)
    for sec in sections[1:]:
        heading, _, rest = sec.partition("\n")
        key = None
        for frag, k in KEY_MAP:
            if frag in heading:
                key = k
                break
        if not key:
            print("SKIP", heading[:70])
            continue
        rows = [{"title": m.group(2), "body": m.group(3)} for m in ROW_RE.finditer(rest)]
        banks[key] = rows
        print(f"{key}: {len(rows)}")

    payload = {
        "version": 1,
        "updated": "2026-09-22",
        "note": "Edit this JSON on server (or v3_push_templates DB) — no APK needed for new copy.",
        "banks": banks,
    }
    for out in OUTS:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        print("wrote", out)

    total = sum(len(v) for v in banks.values())
    print("total templates", total)


if __name__ == "__main__":
    main()
