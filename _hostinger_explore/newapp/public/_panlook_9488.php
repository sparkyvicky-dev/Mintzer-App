<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$users = App\Models\User::withTrashed()
    ->where('mobile', 'like', '%9488918666')
    ->get(['id', 'mobile', 'pan', 'pan_name', 'is_verified', 'deleted_at']);

$dummy = ['arun kumar', 'arun', 'arun k', 'member', 'there', 'mintzer wh / arun k'];
$out = [];
foreach ($users as $u) {
    $pan = strtoupper(preg_replace('/[^A-Z0-9]/', '', (string) $u->pan) ?? '');
    $name = trim((string) $u->pan_name);
    $kind = 'empty';
    if ($pan !== '' || $name !== '') {
        $kind = in_array(strtolower($name), $dummy, true) ? 'dummy' : 'saved';
    }
    $out[] = [
        'id' => $u->id,
        'mobile' => (string) $u->mobile,
        'pan_set' => $pan !== '',
        'pan_mask' => $pan === '' ? '' : (substr($pan, 0, 3) . '*****' . substr($pan, -2)),
        'pan_name' => $name,
        'is_verified' => (int) $u->is_verified,
        'deleted' => $u->deleted_at !== null,
        'kind' => $kind,
    ];
}
header('Content-Type: application/json');
echo json_encode(['count' => count($out), 'rows' => $out]);
