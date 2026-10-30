<?php

namespace App\Services\Verifico;

use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * The Verifico — typed PAN → registered name (NSDL).
 * Key stays server-side (VERIFICO_API_KEY). Never ship in the APK.
 *
 * Host: https://api.theverifico.com  (api.verifico.com is gone / 410)
 * Endpoint: POST /api/v1/verify/pan  JSON { "pan_number": "ABCDE1234F" }
 */
class VerificoPanService
{
    public static function enabled(): bool
    {
        $flag = config('services.verifico.pan_enabled');
        if ($flag === false || $flag === 0 || $flag === '0' || $flag === 'false') {
            return false;
        }
        $envFlag = env('VERIFICO_PAN_ENABLED');
        if ($envFlag !== null && in_array(strtolower((string) $envFlag), ['0', 'false', 'off', 'no'], true)) {
            return false;
        }
        return self::apiKey() !== '';
    }

    public static function apiKey(): string
    {
        $key = (string) (config('services.verifico.key') ?? '');
        if ($key === '') {
            $key = (string) (env('VERIFICO_API_KEY') ?? '');
        }
        if ($key === '') {
            $g = getenv('VERIFICO_API_KEY');
            $key = $g === false ? '' : (string) $g;
        }
        return trim($key);
    }

    public static function baseUrl(): string
    {
        $base = (string) (config('services.verifico.base_url') ?? '');
        if ($base === '') {
            $base = (string) (env('VERIFICO_BASE_URL') ?? 'https://api.theverifico.com');
        }
        return rtrim($base, '/');
    }

    /**
     * @return array{ok:bool,name:?string,pan:?string,message:string,http_status:?int}
     */
    public static function verifyPan(string $pan): array
    {
        $pan = strtoupper(preg_replace('/[^A-Z0-9]/i', '', $pan) ?? '');
        if (!preg_match('/^[A-Z]{5}[0-9]{4}[A-Z]$/', $pan)) {
            return [
                'ok' => false,
                'name' => null,
                'pan' => $pan,
                'message' => 'PAN format is invalid',
                'http_status' => null,
            ];
        }

        if (!self::enabled()) {
            return [
                'ok' => false,
                'name' => null,
                'pan' => $pan,
                'message' => 'PAN verification is not configured',
                'http_status' => null,
            ];
        }

        try {
            $response = Http::timeout(25)
                ->withHeaders([
                    'X-API-Key' => self::apiKey(),
                    'Accept' => 'application/json',
                ])
                ->post(self::baseUrl() . '/api/v1/verify/pan', [
                    'pan_number' => $pan,
                ]);
        } catch (Throwable $e) {
            return [
                'ok' => false,
                'name' => null,
                'pan' => $pan,
                'message' => 'Could not reach PAN verification service',
                'http_status' => null,
            ];
        }

        $status = $response->status();
        $body = $response->json();
        if (!is_array($body)) {
            $body = [];
        }

        if ($status === 402) {
            return [
                'ok' => false,
                'name' => null,
                'pan' => $pan,
                'message' => 'PAN verification credits are not active yet. Please try again later.',
                'http_status' => 402,
            ];
        }

        if ($status === 401 || $status === 403) {
            return [
                'ok' => false,
                'name' => null,
                'pan' => $pan,
                'message' => 'PAN verification is temporarily unavailable',
                'http_status' => $status,
            ];
        }

        if ($response->failed()) {
            $msg = self::pickMessage($body) ?? 'PAN could not be verified';
            return [
                'ok' => false,
                'name' => null,
                'pan' => $pan,
                'message' => $msg,
                'http_status' => $status,
            ];
        }

        if (isset($body['success']) && $body['success'] === false) {
            return [
                'ok' => false,
                'name' => null,
                'pan' => $pan,
                'message' => self::pickMessage($body) ?? 'PAN not found',
                'http_status' => $status,
            ];
        }

        $name = self::pickName($body);
        if ($name === null || $name === '') {
            return [
                'ok' => false,
                'name' => null,
                'pan' => $pan,
                'message' => 'PAN found, but name was missing from the provider response',
                'http_status' => $status,
            ];
        }

        return [
            'ok' => true,
            'name' => $name,
            'pan' => $pan,
            'message' => 'Pan Verified Successfully.',
            'http_status' => $status,
        ];
    }

    private static function pickMessage(array $body): ?string
    {
        foreach (['message', 'error', 'detail'] as $k) {
            if (!isset($body[$k])) {
                continue;
            }
            $v = $body[$k];
            if (is_string($v) && trim($v) !== '') {
                return trim($v);
            }
        }
        return null;
    }

    private static function pickName(array $body): ?string
    {
        $candidates = [];

        $vd = $body['verification_data'] ?? null;
        if (is_array($vd)) {
            $candidates[] = $vd;
            if (isset($vd['data']) && is_array($vd['data'])) {
                $candidates[] = $vd['data'];
            }
            if (isset($vd['result']) && is_array($vd['result'])) {
                $candidates[] = $vd['result'];
            }
        }

        if (isset($body['data']) && is_array($body['data'])) {
            $candidates[] = $body['data'];
        }

        $candidates[] = $body;

        $keys = [
            'full_name',
            'registered_name',
            'name_on_card',
            'name',
            'full_name_as_per_pan',
            'pan_name',
            'fullName',
        ];

        foreach ($candidates as $map) {
            if (!is_array($map)) {
                continue;
            }
            foreach ($keys as $k) {
                if (!isset($map[$k])) {
                    continue;
                }
                $v = $map[$k];
                if (is_string($v) && trim($v) !== '') {
                    return trim($v);
                }
            }
        }

        return null;
    }
}
