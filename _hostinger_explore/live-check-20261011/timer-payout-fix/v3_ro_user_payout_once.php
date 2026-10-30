<?php
/**
 * One-shot READ-ONLY. No Laravel. Delete after use.
 */
header('Content-Type: application/json; charset=utf-8');
if (($_GET['k'] ?? '') !== 'ROLOOK_9698687607_ONCE') {
    http_response_code(404);
    echo '{"error":"not found"}';
    exit;
}

try {
    $envFile = dirname(__DIR__) . '/.env';
    if (!is_file($envFile)) {
        $envFile = __DIR__ . '/../.env';
    }
    if (!is_file($envFile)) {
        throw new Exception('env missing');
    }
    $env = [];
    foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        $line = trim($line);
        if ($line === '' || $line[0] === '#' || strpos($line, '=') === false) {
            continue;
        }
        [$k, $v] = explode('=', $line, 2);
        $env[trim($k)] = trim($v, " \t\"'");
    }
    $mysqli = new mysqli(
        $env['DB_HOST'] ?? 'localhost',
        $env['DB_USERNAME'] ?? '',
        $env['DB_PASSWORD'] ?? '',
        $env['DB_DATABASE'] ?? '',
        (int) ($env['DB_PORT'] ?? 3306)
    );
    if ($mysqli->connect_errno) {
        throw new Exception('db ' . $mysqli->connect_errno);
    }
    $mobile = preg_replace('/\D+/', '', (string) ($_GET['m'] ?? '9698687607'));
    $cols = [];
    $colRes = $mysqli->query('SHOW COLUMNS FROM users');
    while ($c = $colRes->fetch_assoc()) {
        $cols[] = $c['Field'];
    }
    $want = ['id', 'mobile', 'created_at', 'name', 'first_name', 'last_name', 'username', 'email', 'pan_name'];
    $select = [];
    foreach ($want as $w) {
        if (in_array($w, $cols, true)) {
            $select[] = $w;
        }
    }
    if (!$select) {
        $select = ['id', 'mobile'];
    }
    $sqlUser = 'SELECT ' . implode(', ', $select) . ' FROM users WHERE mobile = ? OR mobile LIKE ? LIMIT 5';
    $stmt = $mysqli->prepare($sqlUser);
    $like = '%' . $mobile;
    $stmt->bind_param('ss', $mobile, $like);
    $stmt->execute();
    $users = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
    if (!$users) {
        echo json_encode(['users' => [], 'orders' => []], JSON_PRETTY_PRINT);
        exit;
    }
    $uid = (int) $users[0]['id'];
    $stmt2 = $mysqli->prepare(
        'SELECT o.id, o.order_number, o.store_order_id, o.order_status, o.order_amount, o.total_amount,
         o.to_card_holder, o.tds_amount, o.earnings, o.is_payout, o.is_payout_requested, o.transaction_id,
         o.order_date, o.is_pine_lab_deal, o.deal_id,
         d.name AS deal_name, d.card_holder_spend, d.card_holder_earn, d.card_holder_recieve, d.cashback,
         d.cash_reward, d.discount, d.product_price,
         od.card_holder_receive AS od_receive, od.card_holder_earn AS od_earn, od.card_holder_spend AS od_spend,
         od.cashback AS od_cashback, od.cash_reward AS od_cash_reward
         FROM orders o
         LEFT JOIN deals d ON d.id = o.deal_id
         LEFT JOIN order_deal od ON od.order_id = o.id
         WHERE o.user_id = ?
         ORDER BY o.id DESC
         LIMIT 25'
    );
    $stmt2->bind_param('i', $uid);
    $stmt2->execute();
    $orders = $stmt2->get_result()->fetch_all(MYSQLI_ASSOC);
    $withdraw = [];
    $chk = $mysqli->query("SHOW TABLES LIKE 'withdraw_requests'");
    if ($chk && $chk->num_rows) {
        $stmt3 = $mysqli->prepare('SELECT * FROM withdraw_requests WHERE user_id = ? ORDER BY id DESC LIMIT 10');
        $stmt3->bind_param('i', $uid);
        $stmt3->execute();
        $withdraw = $stmt3->get_result()->fetch_all(MYSQLI_ASSOC);
    }
    echo json_encode([
        'users' => $users,
        'orders' => $orders,
        'withdraw_requests' => $withdraw,
    ], JSON_PRETTY_PRINT);
    $mysqli->close();
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => 'failed', 'msg' => $e->getMessage()]);
}