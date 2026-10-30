<?php
/**
 * One-shot: add deals.coupon_code. Empty stays hidden in the app.
 * Visit once, then delete this file.
 */
$key = $_GET['key'] ?? '';
if ($key !== 'mintzer-coupon-code') {
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
    if (!Schema::hasColumn('deals', 'coupon_code')) {
        DB::statement('ALTER TABLE deals ADD COLUMN coupon_code VARCHAR(40) NULL DEFAULT NULL AFTER offer_text');
        echo "OK: added deals.coupon_code\n";
    } else {
        echo "OK: deals.coupon_code already exists\n";
    }
} catch (Throwable $e) {
    http_response_code(500);
    echo 'ERR: ' . $e->getMessage();
}
