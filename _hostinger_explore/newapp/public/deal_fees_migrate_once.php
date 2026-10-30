<?php
/**
 * One-shot: add deals.platform_fee + deals.card_fee for checkout calc.
 * Visit once, then delete this file.
 * URL: https://app.mintzer.in/deal_fees_migrate_once.php?key=mintzer-deal-fees
 */
$key = $_GET['key'] ?? '';
if ($key !== 'mintzer-deal-fees') {
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
    $out = [];
    if (!Schema::hasColumn('deals', 'platform_fee')) {
        DB::statement('ALTER TABLE deals ADD COLUMN platform_fee DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER discount');
        $out[] = 'OK: added deals.platform_fee';
    } else {
        $out[] = 'OK: deals.platform_fee already exists';
    }
    if (!Schema::hasColumn('deals', 'card_fee')) {
        DB::statement('ALTER TABLE deals ADD COLUMN card_fee DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER platform_fee');
        $out[] = 'OK: added deals.card_fee';
    } else {
        $out[] = 'OK: deals.card_fee already exists';
    }
    echo implode("\n", $out) . "\n";
} catch (Throwable $e) {
    http_response_code(500);
    echo 'ERR: ' . $e->getMessage();
}
