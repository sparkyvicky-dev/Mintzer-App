<?php
/**
 * One-shot: add orders.store_order_at for the admin clock on Store ID.
 * Visit once, then delete this file.
 */
$key = $_GET['key'] ?? '';
if ($key !== 'mintzer-store-order-at') {
    http_response_code(403);
    echo 'forbidden';
    exit;
}

require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

try {
    if (!Schema::hasColumn('orders', 'store_order_at')) {
        DB::statement('ALTER TABLE orders ADD COLUMN store_order_at DATETIME NULL DEFAULT NULL AFTER store_order_id');
        echo "OK: added orders.store_order_at\n";
    } else {
        echo "OK: orders.store_order_at already exists\n";
    }
} catch (Throwable $e) {
    http_response_code(500);
    echo 'ERR: ' . $e->getMessage();
}
