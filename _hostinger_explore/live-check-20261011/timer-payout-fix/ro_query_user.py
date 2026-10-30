import json
import sys

try:
    import pymysql
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pymysql", "-q"])
    import pymysql

env_path = r"D:\dev\mintzer-app\_hostinger_explore\live-check-20261011\timer-payout-fix\.env.live-now"
env = {}
with open(env_path, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")

conn = pymysql.connect(
    host="31.170.164.117",
    user=env["DB_USERNAME"],
    password=env["DB_PASSWORD"],
    database=env["DB_DATABASE"],
    port=3306,
    connect_timeout=20,
    cursorclass=pymysql.cursors.DictCursor,
)
cur = conn.cursor()
mobile = "9698687607"
cur.execute(
    "SELECT id, name, mobile, created_at FROM users WHERE mobile=%s OR mobile LIKE %s LIMIT 5",
    (mobile, "%" + mobile),
)
users = cur.fetchall()
print("USERS")
print(json.dumps(users, default=str, indent=2))
if not users:
    sys.exit(0)
uid = users[0]["id"]
cur.execute(
    """
SELECT o.id, o.order_number, o.store_order_id, o.order_status, o.order_amount, o.total_amount,
 o.to_card_holder, o.tds_amount, o.earnings, o.is_payout, o.is_payout_requested, o.transaction_id,
 o.order_date, o.is_pine_lab_deal, o.deal_id,
 d.name AS deal_name, d.card_holder_spend, d.card_holder_earn, d.card_holder_recieve, d.cashback,
 d.cash_reward, d.discount, d.product_price,
 od.card_holder_receive AS od_receive, od.card_holder_earn AS od_earn, od.card_holder_spend AS od_spend,
 od.cashback AS od_cashback, od.cash_reward AS od_cash_reward
 FROM orders o
 LEFT JOIN deals d ON d.id = o.deal_id
 LEFT JOIN order_deal od ON od.order_id = o.id
 WHERE o.user_id = %s
 ORDER BY o.id DESC
 LIMIT 25
""",
    (uid,),
)
print("ORDERS")
print(json.dumps(cur.fetchall(), default=str, indent=2))
cur.execute("SHOW TABLES LIKE 'withdraw_requests'")
if cur.fetchone():
    cur.execute(
        "SELECT * FROM withdraw_requests WHERE user_id=%s ORDER BY id DESC LIMIT 10",
        (uid,),
    )
    print("WITHDRAW_REQUESTS")
    print(json.dumps(cur.fetchall(), default=str, indent=2))
conn.close()
