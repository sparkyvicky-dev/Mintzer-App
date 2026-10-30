<?php

namespace App\Services\ApiSathi;

use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * API Sathi IFSC → bank and branch.
 * Key stays server-side (APISATHI_IFSC_API_KEY). Never ship in the APK.
 *
 * POST https://apisathi.in/gw/v1/ifsc-lookup-v1/
 * Body: { "ifsc": "HDFC0000001" }
 */
class ApiSathiIfscService
{
    public static function apiKey(): string
    {
        $key = (string) (config('services.apisathi.ifsc_key') ?? '');
        if ($key === '') {
            $key = (string) (env('APISATHI_IFSC_API_KEY') ?? '');
        }
        if ($key === '') {
            $g = getenv('APISATHI_IFSC_API_KEY');
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
        $path = (string) (env('APISATHI_IFSC_PATH') ?? '/ifsc-lookup-v1/');
        if ($path === '' || $path[0] !== '/') {
            $path = '/' . $path;
        }
        return rtrim($base, '/') . $path;
    }

    /**
     * @return array{ok:bool,bank:?string,branch:?string,city:?string,message:string}
     */
    public static function lookup(string $ifsc): array
    {
        $ifsc = strtoupper(preg_replace('/[^A-Z0-9]/i', '', $ifsc) ?? '');
        if (!preg_match('/^[A-Z]{4}0[A-Z0-9]{6}$/', $ifsc)) {
            return self::fail('Enter a valid IFSC code');
        }
        if (self::apiKey() === '') {
            return self::fail('IFSC lookup is not configured');
        }

        try {
            $response = Http::timeout(20)
                ->withHeaders([
                    'X-API-Key' => self::apiKey(),
                    'Accept' => 'application/json',
                    'Idempotency-Key' => 'mintzer-ifsc-' . hash('sha256', $ifsc),
                ])
                ->post(self::endpoint(), [
                    'ifsc' => $ifsc,
                ]);
        } catch (Throwable $e) {
            return self::fail('Could not reach IFSC lookup');
        }

        $status = $response->status();
        $body = $response->json();
        if (!is_array($body)) {
            $body = [];
        }

        if ($status === 422 || $status === 404) {
            return self::fail('Couldn’t find this IFSC. Check and try again.');
        }
        if ($status === 402) {
            return self::fail('IFSC lookup is temporarily unavailable');
        }
        if ($response->failed()) {
            return self::fail('Couldn’t find this IFSC. Check and try again.');
        }

        $valid = $body['valid'] ?? $body['verified'] ?? null;
        if ($valid === false || $valid === 0 || $valid === 'false') {
            return self::fail('Couldn’t find this IFSC. Check and try again.');
        }

        $bank = trim((string) ($body['bank'] ?? ''));
        $branch = trim((string) ($body['branch'] ?? ''));
        if ($bank === '') {
            return self::fail('Couldn’t find this IFSC. Check and try again.');
        }

        return [
            'ok' => true,
            'bank' => $bank,
            'branch' => $branch !== '' ? $branch : null,
            'city' => trim((string) ($body['city'] ?? '')) ?: null,
            'message' => 'IFSC found',
        ];
    }

    private static function fail(string $message): array
    {
        return [
            'ok' => false,
            'bank' => null,
            'branch' => null,
            'city' => null,
            'message' => $message,
        ];
    }
}
