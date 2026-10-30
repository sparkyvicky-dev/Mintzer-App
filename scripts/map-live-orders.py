"""Parse Phpadmin/orders.sql and run live-order mapper. Never touches Hostinger."""
from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "Phpadmin" / "orders.sql"
OUT = ROOT / "Phpadmin" / "mapper-report.json"

COLS = [
    "id",
    "order_number",
    "user_id",
    "deal_id",
    "address_id",
    "order_amount",
    "account_mobile_number",
    "store_order_id",
    "account_order_pdf",
    "account_order_screenshot",
    "order_start",
    "order_end",
    "order_status",
    "is_admin_cancelled",
    "cancel_reason",
    "total_amount",
    "to_card_holder",
    "earnings",
    "delivery_partner_id",
    "order_tracking_id",
    "order_delivery_otp",
    "order_gst",
    "order_date",
    "shipped_date",
    "out_for_delivery_date",
    "delivery_date",
    "verification_status",
    "is_ready_for_payout",
    "is_payout_requested",
    "is_payout",
    "is_active",
    "transaction_id",
    "transaction_file",
    "payout_notes",
    "is_pine_lab_deal",
    "payment_screenshot",
    "is_payment_verified",
    "tds_amount",
    "created_at",
    "updated_at",
    "deleted_at",
    "invoice_upload_date",
]


def split_values(s: str) -> list[list[str]]:
    rows: list[list[str]] = []
    i = 0
    n = len(s)
    while i < n:
        while i < n and s[i] in " \n\r\t,":
            i += 1
        if i >= n:
            break
        if s[i] != "(":
            i += 1
            continue
        i += 1
        vals: list[str] = []
        cur: list[str] = []
        in_str = False
        esc = False
        while i < n:
            ch = s[i]
            if in_str:
                if esc:
                    cur.append(ch)
                    esc = False
                elif ch == "\\":
                    cur.append(ch)
                    esc = True
                elif ch == "'":
                    if i + 1 < n and s[i + 1] == "'":
                        cur.append("'")
                        i += 1
                    else:
                        in_str = False
                else:
                    cur.append(ch)
            else:
                if ch == "'":
                    in_str = True
                elif ch == ",":
                    vals.append("".join(cur).strip())
                    cur = []
                elif ch == ")":
                    vals.append("".join(cur).strip())
                    i += 1
                    break
                else:
                    cur.append(ch)
            i += 1
        rows.append(vals)
    return rows


def clean(v: str | None):
    if v is None:
        return None
    if v.upper() == "NULL" or v == "":
        return None
    if len(v) >= 2 and v[0] == "'" and v[-1] == "'":
        return v[1:-1]
    return v


def has(s) -> bool:
    return s is not None and str(s).strip() != "" and str(s).strip().lower() != "null"


def as_int(v, default=0) -> int:
    try:
        return int(float(v))
    except Exception:
        return default


def map_row(r: dict) -> str:
    # Same algorithm as app/lib/live/order_mapper.dart
    if has(r.get("deleted_at")) and not has(r.get("store_order_id")):
        return "hide"
    st = (r.get("order_status") or "").strip().lower()
    if st in {"cancelled", "canceled", "rejected", "declined"}:
        return "canceled"
    if as_int(r.get("is_payout")) == 1 or has(r.get("transaction_id")):
        return "paid"
    if as_int(r.get("is_pine_lab_deal")) == 1:
        if not has(r.get("payment_screenshot")):
            return "invoice"
        if as_int(r.get("is_payment_verified")) != 1:
            return "invoiceVerifying"
        return "payment"
    v = (r.get("verification_status") or "").strip()
    if v in ("Re-Upload", "Alerted"):
        return "invoiceRejected"
    if has(r.get("account_order_pdf")) and not has(v):
        return "invoiceVerifying"
    if has(r.get("account_order_pdf")) and v == "Verified":
        return "payment"
    if has(r.get("order_delivery_otp")) or st == "out for delivery":
        return "invoice"
    if has(r.get("order_tracking_id")) or st == "shipped":
        return "ofd"
    if has(r.get("store_order_id")):
        return "tracking"
    return "placement"


def main() -> None:
    text = SQL.read_text(encoding="utf-8", errors="replace")
    inserts = re.findall(r"INSERT INTO `orders`.*?VALUES\s*(.*?);", text, flags=re.S | re.I)
    all_rows: list[dict] = []
    for block in inserts:
        for vals in split_values(block):
            if len(vals) < len(COLS):
                vals = vals + ["NULL"] * (len(COLS) - len(vals))
            else:
                vals = vals[: len(COLS)]
            row = {c: clean(v) for c, v in zip(COLS, vals)}
            all_rows.append(row)

    counts: Counter[str] = Counter()
    examples: dict[str, list] = {k: [] for k in [
        "hide", "canceled", "paid", "payment", "invoice", "invoiceVerifying",
        "invoiceRejected", "ofd", "tracking", "placement",
    ]}
    crashes = 0
    for r in all_rows:
        try:
            step = map_row(r)
            counts[step] += 1
            if len(examples[step]) < 5:
                examples[step].append({
                    "id": r.get("id"),
                    "order_number": r.get("order_number"),
                    "store_order_id": r.get("store_order_id"),
                    "order_status": r.get("order_status"),
                    "tracking": r.get("order_tracking_id"),
                    "otp_present": has(r.get("order_delivery_otp")),
                    "pdf": has(r.get("account_order_pdf")),
                    "verification": r.get("verification_status"),
                    "is_payout": r.get("is_payout"),
                    "txn": r.get("transaction_id"),
                    "pine": r.get("is_pine_lab_deal"),
                    "deleted": has(r.get("deleted_at")),
                })
        except Exception as e:
            crashes += 1
            if crashes <= 3:
                print("crash", e, r.get("id"))

    report = {
        "source": str(SQL),
        "database": "u477988188_newdevdb",
        "total_rows": len(all_rows),
        "insert_blocks": len(inserts),
        "crashes": crashes,
        "counts": dict(counts.most_common()),
        "must_tests": {
            "tracking_due": counts.get("tracking", 0),
            "invoice_due": counts.get("invoice", 0) + counts.get("invoiceVerifying", 0) + counts.get("invoiceRejected", 0),
            "already_paid": counts.get("paid", 0),
            "pass": all([
                counts.get("tracking", 0) > 0,
                (counts.get("invoice", 0) + counts.get("invoiceVerifying", 0) + counts.get("invoiceRejected", 0)) > 0,
                counts.get("paid", 0) > 0,
                crashes == 0,
            ]),
        },
        "examples": {k: v for k, v in examples.items() if v},
    }
    OUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"rows={len(all_rows)} crashes={crashes}")
    print("counts:", dict(counts.most_common()))
    print("must_tests:", report["must_tests"])
    print("wrote", OUT)


if __name__ == "__main__":
    main()
