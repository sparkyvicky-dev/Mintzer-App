<?php

namespace App\Services\Cashfree;

use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * Cashfree Secure ID — typed PAN → registered name only.
 * Keys stay server-side. Never ship them in the APK.
 *
 * POST https://api.cashfree.com/verification/pan
 * Headers: x-client-id, x-client-secret, x-api-version
 * Body: { "pan": "ABCDE1234F" }
 *
 * The provider can also return Aadhaar-link status. This service drops that.
 * Only the registered name is returned to the app.
 */
class CashfreePanService
{
    public static function enabled(): bool
    {
        $flag = env('CASHFREE_PAN_ENABLED');
        if ($flag !== null && in_array(strtolower((string) $flag), ['0', 'false', 'off', 'no'], true)) {
            return false;
        }
        return self::clientId() !== '' && self::clientSecret() !== '';
    }

    public static function clientId(): string
    {
        $id = trim((string) (env('CASHFREE_CLIENT_ID') ?? ''));
        if ($id === '') {
            $g = getenv('CASHFREE_CLIENT_ID');
            $id = $g === false ? '' : trim((string) $g);
        }
        return $id;
    }

    public static function clientSecret(): string
    {
        $secret = trim((string) (env('CASHFREE_CLIENT_SECRET') ?? ''));
        if ($secret === '') {
            $g = getenv('CASHFREE_CLIENT_SECRET');
            $secret = $g === false ? '' : trim((string) $g);
        }
        return $secret;
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
            $response = Http::timeout(10)
                ->withHeaders([
                    'x-client-id' => self::clientId(),
                    'x-client-secret' => self::clientSecret(),
                    'x-api-version' => '2024-12-01',
                ])
                ->acceptJson()
                ->post('https://api.cashfree.com/verification/pan', [
                    'pan' => $pan,
                ]);
        } catch (Throwable $e) {
            return self::fail($pan, 'Could not reach PAN verification service');
        }

        $status = $response->status();
        $body = $response->json();
        $message = '';
        $valid = null;
        $name = null;
        if (is_array($body)) {
            if (isset($body['message']) && is_string($body['message'])) {
                $message = trim($body['message']);
            }
            $valid = $body['valid'] ?? null;
            $name = self::pickName($body);
        }
        unset($body);

        if ($status === 422) {
            return self::fail($pan, 'PAN verification wallet is empty. Please try again later.', 422);
        }

        if ($status === 401 || $status === 403) {
            return self::fail($pan, 'PAN verification is temporarily unavailable', $status);
        }

        if ($status === 502) {
            return self::fail($pan, 'Could not reach PAN verification service', 502);
        }

        if ($response->failed()) {
            return self::fail($pan, 'PAN could not be verified. Check the number and try again.', $status);
        }

        if ($valid === false || $valid === 0 || $valid === 'false' || strcasecmp($message, 'Invalid PAN') === 0) {
            return self::fail($pan, 'PAN not found. Check the number and try again.', $status);
        }

        if ($name === null || $name === '') {
            return self::fail($pan, 'PAN found, but name was missing from the provider response', $status);
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
        $maps = [$body];
        if (isset($body['data']) && is_array($body['data'])) {
            $maps[] = $body['data'];
        }
        $keys = ['registered_name', 'name_pan_card', 'full_name', 'name'];
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
