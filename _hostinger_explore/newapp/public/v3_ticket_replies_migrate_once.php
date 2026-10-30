<?php
/**
 * ONE-SHOT: ensure ticket_replies exists + user reply columns. Delete after success.
 * Visit: /v3_ticket_replies_migrate_once.php?token=mz_ticket_reply_20260922
 */
$tokenExpected = 'mz_ticket_reply_20260922';
if (!isset($_GET['token']) || $_GET['token'] !== $tokenExpected) {
    http_response_code(403);
    header('Content-Type: text/plain');
    echo "forbidden";
    exit;
}

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

header('Content-Type: application/json');

try {
    $created = false;
    $altered = [];

    if (!Schema::hasTable('ticket_replies')) {
        DB::statement("CREATE TABLE `ticket_replies` (
          `id` bigint unsigned NOT NULL AUTO_INCREMENT,
          `ticket_id` bigint unsigned NOT NULL,
          `staff_user_id` bigint unsigned DEFAULT NULL,
          `staff_name` varchar(255) DEFAULT NULL,
          `user_id` bigint unsigned DEFAULT NULL,
          `is_from_user` tinyint(1) NOT NULL DEFAULT 0,
          `message` text NOT NULL,
          `created_at` timestamp NULL DEFAULT NULL,
          `updated_at` timestamp NULL DEFAULT NULL,
          PRIMARY KEY (`id`),
          KEY `ticket_replies_ticket_id_index` (`ticket_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
        $created = true;
    } else {
        if (!Schema::hasColumn('ticket_replies', 'user_id')) {
            DB::statement('ALTER TABLE `ticket_replies` ADD COLUMN `user_id` bigint unsigned NULL AFTER `staff_name`');
            $altered[] = 'user_id';
        }
        if (!Schema::hasColumn('ticket_replies', 'is_from_user')) {
            DB::statement('ALTER TABLE `ticket_replies` ADD COLUMN `is_from_user` tinyint(1) NOT NULL DEFAULT 0 AFTER `user_id`');
            $altered[] = 'is_from_user';
        }
    }

    echo json_encode([
        'ok' => true,
        'table_created' => $created,
        'columns_added' => $altered,
        'has_table' => Schema::hasTable('ticket_replies'),
        'hint' => 'Delete this PHP file from public/ now.',
    ], JSON_PRETTY_PRINT);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'error' => $e->getMessage(),
    ], JSON_PRETTY_PRINT);
}
