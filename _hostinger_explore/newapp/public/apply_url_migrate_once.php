<?php
/**
 * One-shot: add banks.apply_url for Partner Apply links.
 * Visit once as admin, then delete this file.
 * URL: https://app.mintzer.in/apply_url_migrate_once.php?key=mintzer-apply-url
 */
$key = $_GET['key'] ?? '';
if ($key !== 'mintzer-apply-url') {
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
    if (!Schema::hasColumn('banks', 'apply_url')) {
        DB::statement('ALTER TABLE banks ADD COLUMN apply_url VARCHAR(500) NULL AFTER image');
        echo "OK: added banks.apply_url\n";
    } else {
        echo "OK: banks.apply_url already exists\n";
    }
} catch (Throwable $e) {
    http_response_code(500);
    echo 'ERR: ' . $e->getMessage();
}
