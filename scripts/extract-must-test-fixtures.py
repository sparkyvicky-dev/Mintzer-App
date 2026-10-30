"""Extract curated live rows from orders.sql → Flutter asset JSON."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SQL = ROOT / "Phpadmin" / "orders.sql"
OUT = ROOT / "app" / "assets" / "live" / "must_test_orders.json"

# Reuse mapper helpers
import sys

sys.path.insert(0, str(ROOT / "scripts"))
from importlib.util import spec_from_loader, module_from_spec
import importlib.machinery

loader = importlib.machinery.SourceFileLoader("map_live", str(ROOT / "scripts" / "map-live-orders.py"))
spec = spec_from_loader("map_live", loader)
mod = module_from_spec(spec)
loader.exec_module(mod)

COLS = mod.COLS
split_values = mod.split_values
clean = mod.clean
has = mod.has
map_row = mod.map_row


def main() -> None:
    text = SQL.read_text(encoding="utf-8", errors="replace")
    inserts = re.findall(r"INSERT INTO `orders`.*?VALUES\s*(.*?);", text, flags=re.S | re.I)
    rows = []
    for block in inserts:
        for vals in split_values(block):
            if len(vals) < len(COLS):
                vals = vals + ["NULL"] * (len(COLS) - len(vals))
            else:
                vals = vals[: len(COLS)]
            rows.append({c: clean(v) for c, v in zip(COLS, vals)})

    by_step: dict[str, list] = {}
    for r in rows:
        step = map_row(r)
        by_step.setdefault(step, []).append(r)

    # Prefer non-deleted where possible for UI fixtures
    def pick(step: str, n: int, prefer_alive: bool = True) -> list:
        pool = by_step.get(step, [])
        if prefer_alive:
            alive = [r for r in pool if not has(r.get("deleted_at"))]
            if alive:
                pool = alive
        return pool[:n]

    selected = []
    selected += pick("tracking", 1)
    selected += pick("invoiceVerifying", 2)
    selected += pick("invoiceRejected", 1)
    selected += pick("payment", 2)
    # paid: prefer with txn, not deleted
    paid = by_step.get("paid", [])
    paid_alive = [r for r in paid if not has(r.get("deleted_at"))]
    paid_pool = paid_alive or paid
    paid_with_txn = [r for r in paid_pool if has(r.get("transaction_id"))]
    paid_no_txn = [r for r in paid_pool if not has(r.get("transaction_id"))]
    selected += (paid_with_txn[:1] or paid_pool[:1])
    selected += (paid_no_txn[:1] or paid_pool[1:2])
    selected += pick("canceled", 1)
    # sparse paid-like: is_payout only — already covered

    # Strip PII-ish phone; keep mapper fields only (getOrderList-shaped)
    slim = []
    for r in selected:
        slim.append({
            "id": int(r["id"]) if r.get("id") else None,
            "order_number": r.get("order_number"),
            "name": f"Live order {r.get('order_number') or r.get('id')}",
            "store_name": "Flipkart",
            "card_holder_recieve": r.get("to_card_holder") or r.get("earnings") or 0,
            "store_order_id": r.get("store_order_id"),
            "order_status": r.get("order_status"),
            "order_tracking_id": r.get("order_tracking_id"),
            "order_delivery_otp": r.get("order_delivery_otp"),
            "account_order_pdf": r.get("account_order_pdf"),
            "verification_status": r.get("verification_status"),
            "is_payout": int(float(r.get("is_payout") or 0)),
            "transaction_id": r.get("transaction_id"),
            "is_pine_lab_deal": int(float(r.get("is_pine_lab_deal") or 0)),
            "payment_screenshot": r.get("payment_screenshot"),
            "is_payment_verified": int(float(r.get("is_payment_verified") or 0)),
            "deleted_at": r.get("deleted_at"),
            "_mapped_step": map_row(r),
        })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(slim, indent=2), encoding="utf-8")
    print(f"wrote {len(slim)} rows -> {OUT}")
    for s in slim:
        print(f"  id={s['id']} step={s['_mapped_step']} store={s['store_order_id']} status={s['order_status']}")


if __name__ == "__main__":
    main()
