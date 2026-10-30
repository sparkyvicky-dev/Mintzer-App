<?php
/**
 * One-shot probe for DataTables Ajax error on /deals-data.
 * Delete immediately after use.
 */
$token = $_GET['t'] ?? '';
if (!hash_equals('mz-deal-probe-20261011', (string) $token)) {
    http_response_code(404);
    exit('not found');
}

header('Content-Type: application/json; charset=utf-8');

require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$out = [
    'ok' => false,
    'php' => PHP_VERSION,
    'memory_limit' => ini_get('memory_limit'),
    'deal_count_type0' => null,
    'pixel_rows' => [],
    'json_error' => null,
    'exception' => null,
    'sample_encode_ok' => null,
    'datatables_ok' => null,
    'bytes' => null,
];

try {
    $out['deal_count_type0'] = App\Models\Deal::whereNull('deleted_at')
        ->where('is_pine_lab', 0)
        ->count();

    $out['pixel_rows'] = App\Models\Deal::whereNull('deleted_at')
        ->where(function ($q) {
            $q->where('name', 'like', '%pixel%')
                ->orWhere('name', 'like', '%10a%')
                ->orWhere('name', 'like', '%Pixel%');
        })
        ->orderByDesc('id')
        ->limit(15)
        ->get(['id', 'name', 'dealer_id', 'store_id', 'bank_card_id', 'is_pine_lab', 'image', 'status', 'created_at'])
        ->map(function ($d) {
            return [
                'id' => $d->id,
                'name' => $d->name,
                'dealer_id' => $d->dealer_id,
                'store_id' => $d->store_id,
                'bank_card_id' => $d->bank_card_id,
                'is_pine_lab' => $d->is_pine_lab,
                'image' => $d->image,
                'status' => $d->status,
                'created_at' => (string) $d->created_at,
                'name_utf8' => mb_check_encoding((string) $d->name, 'UTF-8'),
            ];
        })
        ->all();

    $deals = App\Models\Deal::with(['dealer', 'store', 'bankCard'])
        ->whereNull('deleted_at')
        ->where('is_pine_lab', 0)
        ->orderBy('id', 'DESC')
        ->get();

    // Find first row that fails json_encode
    $bad = null;
    foreach ($deals as $row) {
        $payload = $row->toArray();
        $encoded = json_encode($payload);
        if ($encoded === false) {
            $bad = [
                'id' => $row->id,
                'name' => $row->name,
                'json_last_error' => json_last_error_msg(),
            ];
            // check fields
            foreach ($payload as $k => $v) {
                if (is_string($v) && !mb_check_encoding($v, 'UTF-8')) {
                    $bad['bad_field'] = $k;
                    $bad['bad_len'] = strlen($v);
                    break;
                }
            }
            break;
        }
    }
    $out['first_bad_row'] = $bad;
    $out['sample_encode_ok'] = $bad === null;

    // Mimic controller action column once
    $user = App\Models\User::where('role_id', 1)->first();
    if ($user) {
        auth()->login($user);
    }

    $json = datatables()->of($deals)
        ->addColumn('images', function ($row) {
            $html = '<div class="d-flex flex-wrap gap-2">';
            if ($row->image) {
                $html .= '<img src="' . asset($row->image) . '" class="rounded" width="60" height="60">';
            }
            $html .= '</div>';
            if (!$row->image) {
                $html = '<span class="text-muted">No images</span>';
            }
            return $html;
        })
        ->addColumn('action', function ($row) {
            $html = '<div class="d-flex align-items-center gap-2">';
            $html .= '<i onclick="sendDealNotify(' . $row->id . ');"></i>';
            $html .= '<i onclick="sendDealStockAlert(' . $row->id . ');"></i>';
            $html .= '<a href="deal-copy/' . $row->id . '">c</a>';
            $html .= '<a href="deal-edit/' . $row->id . '/' . $row->is_pine_lab . '">e</a> ';
            if (Auth::user() && Auth::user()->role_id == App\Enums\RoleTypes::Admin) {
                $html .= '<i onclick="showDelete(' . $row->id . ');"></i>';
            }
            $html .= '</div>';
            return $html;
        })
        ->rawColumns(['images', 'action'])
        ->toJson();

    $content = method_exists($json, 'getContent') ? $json->getContent() : (string) $json;
    $out['datatables_ok'] = true;
    $out['bytes'] = strlen($content);
    $out['memory_peak_mb'] = round(memory_get_peak_usage(true) / 1048576, 1);
    $out['ok'] = true;
} catch (Throwable $e) {
    $out['exception'] = [
        'class' => get_class($e),
        'message' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
    ];
    $out['memory_peak_mb'] = round(memory_get_peak_usage(true) / 1048576, 1);
}

echo json_encode($out, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
