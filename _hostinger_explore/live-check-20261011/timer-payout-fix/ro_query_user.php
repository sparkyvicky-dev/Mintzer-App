<?php
$env = [];
foreach (file($argv[1], FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
  $line = trim($line);
  if ($line === "" || $line[0] === "#" || strpos($line, "=") === false) continue;
  [$k, $v] = explode("=", $line, 2);
  $env[trim($k)] = trim($v, " \t\"'");
}
$host = $argv[2];
$mysqli = @new mysqli($host, $env["DB_USERNAME"], $env["DB_PASSWORD"], $env["DB_DATABASE"], 3306);
if ($mysqli->connect_errno) {
  fwrite(STDERR, "CONNECT_FAIL " . $mysqli->connect_errno . "\n");
  exit(1);
}
$mobile = "9698687607";
$stmt = $mysqli->prepare("SELECT id, name, mobile, created_at FROM users WHERE mobile = ? OR mobile LIKE ? LIMIT 5");
$like = "%" . $mobile;
$stmt->bind_param("ss", $mobile, $like);
$stmt->execute();
$res = $stmt->get_result();
$users = [];
while ($row = $res->fetch_assoc()) $users[] = $row;
echo "USERS\n" . json_encode($users, JSON_PRETTY_PRINT) . "\n";
if (!$users) { exit(0); }
$uid = (int)$users[0]["id"];
$q = "SELECT o.id, o.order_number, o.store_order_id, o.order_status, o.order_amount, o.total_amount,
 o.to_card_holder, o.tds_amount, o.earnings, o.is_payout, o.is_payout_requested, o.transaction_id,
 o.order_date, o.is_pine_lab_deal, o.deal_id,
 d.name AS deal_name, d.card_holder_spend, d.card_holder_earn, d.card_holder_recieve, d.cashback, d.cash_reward, d.discount, d.product_price,
 od.card_holder_receive AS od_receive, od.card_holder_earn AS od_earn, od.card_holder_spend AS od_spend, od.cashback AS od_cashback, od.cash_reward AS od_cash_reward
 FROM orders o
 LEFT JOIN deals d ON d.id = o.deal_id
 LEFT JOIN order_deal od ON od.order_id = o.id
 WHERE o.user_id = ?
 ORDER BY o.id DESC
 LIMIT 20";
$stmt2 = $mysqli->prepare($q);
$stmt2->bind_param("i", $uid);
$stmt2->execute();
$res2 = $stmt2->get_result();
$orders = [];
while ($row = $res2->fetch_assoc()) $orders[] = $row;
echo "ORDERS\n" . json_encode($orders, JSON_PRETTY_PRINT) . "\n";
// withdraw / wallet if tables exist
foreach (["withdraw_requests", "transactions", "wallets"] as $t) {
  $check = $mysqli->query("SHOW TABLES LIKE '$t'");
  if ($check && $check->num_rows) {
    $r = $mysqli->query("SELECT * FROM `$t` WHERE user_id = $uid ORDER BY id DESC LIMIT 10");
    $rows = [];
    if ($r) while ($row = $r->fetch_assoc()) $rows[] = $row;
    echo strtoupper($t) . "\n" . json_encode($rows, JSON_PRETTY_PRINT) . "\n";
  }
}
$mysqli->close();
