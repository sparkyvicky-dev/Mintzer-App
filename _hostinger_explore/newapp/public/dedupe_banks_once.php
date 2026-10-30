<?php
/**
 * One-shot: deactivate duplicate bank rows (keep newest id per normalized name).
 * Visit once: https://app.mintzer.in/dedupe_banks_once.php?key=mintzer-dedupe-banks
 * DELETE this file after OK.
 */
$key = $_GET['key'] ?? '';
if ($key !== 'mintzer-dedupe-banks') {
    http_response_code(403);
    echo "forbidden\n";
    exit;
}

require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$banks = DB::table('banks')->whereNull('deleted_at')->orderByDesc('id')->get();
$seen = [];
$deactivated = [];

foreach ($banks as $b) {
    $raw = strtolower(trim((string) $b->name));
    $norm = preg_replace('/\s+/', ' ', $raw);
    $norm = str_replace([' bank', ' credit card', ' card'], '', $norm);
    $norm = trim($norm);
    if ($norm === '' || $norm === 'any' || str_contains($norm, 'any card')) {
        continue;
    }
    // Group PNB variants together.
    if (str_contains($norm, 'pnb') || str_contains($norm, 'punjab')) {
        $norm = 'pnb';
    }
    if (isset($seen[$norm])) {
        DB::table('banks')->where('id', $b->id)->update(['status' => 0, 'updated_at' => now()]);
        $deactivated[] = "id={$b->id} name={$b->name} (kept id={$seen[$norm]})";
        continue;
    }
    $seen[$norm] = $b->id;
}

echo "OK deactivated " . count($deactivated) . "\n";
foreach ($deactivated as $line) {
    echo $line . "\n";
}
echo "DELETE this file after use.\n";
