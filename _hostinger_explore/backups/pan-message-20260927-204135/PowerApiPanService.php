<?php

namespace App\Services\PowerApi;

use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * PowerAPI — typed PAN → registered name only.
 * Key stays server-side (POWERAPI_PAN_KEY). Never ship in the APK.
 *
 * POST https://powerapi.in/api/v1/kyc/pan/verify-pan
 * Header: Authorization: Bearer
 * Body: { "pan_number": "ABCDE1234F" }
 *
 * The provider also returns address, phone, and a masked Aadhaar.
 * This service drops those fields. Only the name is returned to the app.
 */
class PowerApiPanService
{
    public static function enabled(): bool
    {
        $flag = env('POWERAPI_PAN_ENABLED');
        if ($flag !== null && in_array(strtolower((string) $flag), ['0', 'false', 'off', 'no'], true)) {
            return false;
        }
        return self::apiKey() !== '';
    }

    public static function apiKey(): string
    {
        $key = (string) (env('POWERAPI_PAN_KEY') ?? '');
        if ($key === '') {
            $g = getenv('POWERAPI_PAN_KEY');
            $key = $g === false ? '' : (string) $g;
        }
        return trim($key);
    }

    /**
     * @return array{ok:bool,name:?string,pan:?string,message:string,http_status:?int,sandbox:bool}
     */
    public static function verifyPan(string $pan): array
    {
        $pan = strtoupper(preg_replace('/[^A-Z0-9]/i', '', $pan) ?? '');
        if (!preg_match('/^[A-Z]{5}[0-9]{4}[A-Z]$/', $pan)) {
            return self::fail($pan, 'PAN format is invalid');
        }

        if (!self::enabled()) {
            return self::fail($pan, 'PAN verification is not configured');
        }

        try {
            $response = Http::timeout(16)
                ->withToken(self::apiKey())
                ->acceptJson()
                ->post('https://powerapi.in/api/v1/kyc/pan/verify-pan', [
                    'pan_number' => $pan,
                ]);
        } catch (Throwable $e) {
            return self::fail($pan, 'Could not reach PAN verification service');
        }

        $status = $response->status();
        $body = $response->json();
        $message = null;
        $success = null;
        $name = null;
        $dataKeys = '';
        if (is_array($body)) {
            if (isset($body['message']) && is_string($body['message'])) {
                $message = trim($body['message']);
            }
            $success = $body['success'] ?? null;
            $name = self::pickName($body);
            $data = $body['data'] ?? null;
            if (is_array($data)) {
                $dataKeys = implode(',', array_keys($data));
            }
        }
        unset($body);

        if ($status === 402) {
            return self::fail($pan, 'PAN verification wallet is empty. Please try again later.', 402);
        }

        if ($status === 401 || $status === 403) {
            return self::fail($pan, 'PAN verification is temporarily unavailable', $status);
        }

        if ($status === 502) {
            return self::fail($pan, 'Could not reach PAN verification service', 502);
        }

        if ($status === 422 || $response->failed() || $success === false || $success === 0 || $success === 'false') {
            return self::fail($pan, 'PAN could not be verified. Check the number and try again.', $status);
        }

        if ($name === null || $name === '') {
            $note = 'PAN found, but name was missing from the provider response';
            if ($dataKeys !== '') {
                $note .= ' [fields:' . $dataKeys . ']';
            }
            return self::fail($pan, $note, $status);
        }

        return [
            'ok' => true,
            'name' => $name,
            'pan' => $pan,
            'message' => 'Pan Verified Successfully.',
            'http_status' => $status,
            'sandbox' => false,
        ];
    }

    private static function pickName(array $body): ?string
    {
        $maps = [];
        $data = $body['data'] ?? null;
        if (is_array($data)) {
            if (isset($data[0]) && is_array($data[0])) {
                $maps[] = $data[0];
            } else {
                $maps[] = $data;
                if (isset($data['result']) && is_array($data['result'])) {
                    $maps[] = $data['result'];
                }
            }
        }
        $maps[] = $body;

        $keys = [
            'full_name',
            'registered_name',
            'name_on_card',
            'name',
            'full_name_as_per_pan',
            'pan_name',
            'fullName',
        ];
        foreach ($maps as $map) {
            if (!is_array($map)) {
                continue;
            }
            foreach ($keys as $k) {
                if (!isset($map[$k]) || !is_string($map[$k])) {
                    continue;
                }
                $v = trim($map[$k]);
                if ($v !== '') {
                    return $v;
                }
            }
            $parts = [];
            foreach (['first_name', 'middle_name', 'last_name'] as $k) {
                if (isset($map[$k]) && is_string($map[$k]) && trim($map[$k]) !== '') {
                    $parts[] = trim($map[$k]);
                }
            }
            if ($parts !== []) {
                return implode(' ', $parts);
            }
        }

        return null;
    }

    private static function fail(string $pan, string $message, ?int $status = null): array
    {
        return [
            'ok' => false,
            'name' => null,
            'pan' => $pan,
            'message' => $message,
            'http_status' => $status,
            'sandbox' => false,
        ];
    }
}
