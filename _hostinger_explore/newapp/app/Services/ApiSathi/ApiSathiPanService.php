<?php

namespace App\Services\ApiSathi;

use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * API Sathi — typed PAN → registered name.
 * Key stays server-side (APISATHI_API_KEY). Never ship in the APK.
 *
 * POST https://apisathi.in/gw/v1/pan-verification-v1/
 * Header: X-API-Key
 * Body: { "pan": "ABCDE1234F" }
 *
 * A test_ key returns sandbox mock data for any PAN. Do not treat that name as NSDL.
 */
class ApiSathiPanService
{
    public static function enabled(): bool
    {
        $flag = config('services.apisathi.pan_enabled');
        if ($flag === false || $flag === 0 || $flag === '0' || $flag === 'false') {
            return false;
        }
        $envFlag = env('APISATHI_PAN_ENABLED');
        if ($envFlag !== null && in_array(strtolower((string) $envFlag), ['0', 'false', 'off', 'no'], true)) {
            return false;
        }
        return self::apiKey() !== '';
    }

    public static function apiKey(): string
    {
        $key = (string) (config('services.apisathi.key') ?? '');
        if ($key === '') {
            $key = (string) (env('APISATHI_API_KEY') ?? '');
        }
        if ($key === '') {
            $g = getenv('APISATHI_API_KEY');
            $key = $g === false ? '' : (string) $g;
        }
        return trim($key);
    }

    public static function endpoint(): string
    {
        $base = (string) (config('services.apisathi.base_url') ?? '');
        if ($base === '') {
            $base = (string) (env('APISATHI_BASE_URL') ?? 'https://apisathi.in/gw/v1');
        }
        $path = (string) (config('services.apisathi.pan_path') ?? '');
        if ($path === '') {
            $path = (string) (env('APISATHI_PAN_PATH') ?? '/pan-verification-v1/');
        }
        if ($path === '' || $path[0] !== '/') {
            $path = '/' . $path;
        }
        return rtrim($base, '/') . $path;
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

        $sandbox = strpos(self::apiKey(), 'test_') === 0;

        try {
            $response = Http::timeout(20)
                ->withHeaders([
                    'X-API-Key' => self::apiKey(),
                    'Accept' => 'application/json',
                    'Idempotency-Key' => 'mintzer-pan-' . hash('sha256', $pan . '|' . date('Y-m-d')),
                ])
                ->post(self::endpoint(), [
                    'pan' => $pan,
                ]);
        } catch (Throwable $e) {
            return self::fail($pan, 'Could not reach PAN verification service', null, $sandbox);
        }

        $status = $response->status();
        $body = $response->json();
        if (!is_array($body)) {
            $body = [];
        }

        if ($status === 402) {
            return self::fail($pan, 'PAN verification wallet is empty. Please try again later.', 402, $sandbox);
        }

        if ($status === 401 || $status === 403) {
            return self::fail($pan, 'PAN verification is temporarily unavailable', $status, $sandbox);
        }

        if ($status === 422) {
            return self::fail($pan, 'PAN could not be verified. Check the number and try again.', 422, $sandbox);
        }

        if ($response->failed()) {
            return self::fail($pan, self::pickMessage($body) ?? 'PAN could not be verified', $status, $sandbox);
        }

        $verified = $body['verified'] ?? null;
        if ($verified === false || $verified === 0 || $verified === 'false' || $verified === '0') {
            return self::fail($pan, self::pickMessage($body) ?? 'PAN not found', $status, $sandbox);
        }

        $name = self::pickName($body);
        if ($name === null || $name === '') {
            return self::fail($pan, 'PAN found, but name was missing from the provider response', $status, $sandbox);
        }

        return [
            'ok' => true,
            'name' => $name,
            'pan' => $pan,
            'message' => $sandbox
                ? 'Pan verified (sandbox mock — not a live NSDL name).'
                : 'Pan Verified Successfully.',
            'http_status' => $status,
            'sandbox' => $sandbox,
        ];
    }

    private static function fail(string $pan, string $message, ?int $status = null, bool $sandbox = false): array
    {
        return [
            'ok' => false,
            'name' => null,
            'pan' => $pan,
            'message' => $message,
            'http_status' => $status,
            'sandbox' => $sandbox,
        ];
    }

    private static function pickMessage(array $body): ?string
    {
        foreach (['message', 'error', 'detail', 'reason'] as $k) {
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
        $candidates = [$body];
        if (isset($body['data']) && is_array($body['data'])) {
            $candidates[] = $body['data'];
        }
        $keys = ['name', 'full_name', 'registered_name', 'name_on_card', 'pan_name'];
        foreach ($candidates as $map) {
            foreach ($keys as $k) {
                if (!isset($map[$k]) || !is_string($map[$k])) {
                    continue;
                }
                $v = trim($map[$k]);
                if ($v !== '') {
                    return $v;
                }
            }
        }
        return null;
    }
}
