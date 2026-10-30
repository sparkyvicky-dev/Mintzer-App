<?php
header('Content-Type: application/json; charset=utf-8');
if (($_GET['k'] ?? '') !== 'RO_PAIDAT_ONCE') { http_response_code(404); echo '{"e":1}'; exit; }
try {
  $envFile = dirname(__DIR__) . '/.env';
  $env = [];
  foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    $line = trim($line);
    if ($line === '' || $line[0] === '#' || strpos($line, '=') === false) continue;
    [$k,$v] = explode('=', $line, 2);
    $env[trim($k)] = trim($v, " \t\"'");
  }
  $db = new mysqli($env['DB_HOST']??'localhost', $env['DB_USERNAME']??'', $env['DB_PASSWORD']??'', $env['DB_DATABASE']??'', (int)($env['DB_PORT']??3306));
  $m = '9698687607';
  $st = $db->prepare('SELECT id FROM users WHERE mobile=? OR mobile LIKE ? LIMIT 1');
  $like = '%'.$m; $st->bind_param('ss',$m,$like); $st->execute();
  $u = $st->get_result()->fetch_assoc();
  if (!$u) { echo '{"orders":[]}'; exit; }
  $uid = (int)$u['id'];
  $st2 = $db->prepare("SELECT id, order_number, store_order_id, is_payout, transaction_id, order_date, updated_at, to_card_holder FROM orders WHERE user_id=? AND (order_number LIKE '%GVD9663%' OR store_order_id LIKE '%338787534076189100%') LIMIT 5");
  $st2->bind_param('i',$uid); $st2->execute();
  $rows = $st2->get_result()->fetch_all(MYSQLI_ASSOC);
  echo json_encode(['orders'=>$rows], JSON_PRETTY_PRINT);
  $db->close();
} catch (Throwable $e) { http_response_code(500); echo json_encode(['error'=>$e->getMessage()]); }
