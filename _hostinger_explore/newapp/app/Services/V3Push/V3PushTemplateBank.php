<?php

namespace App\Services\V3Push;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Server-side push copy banks. Edit JSON or DB — no APK update for new templates.
 *
 * Load order:
 *  1) v3_push_templates table (if present + rows for bank)
 *  2) resources/v3_push/templates.json
 */
class V3PushTemplateBank
{
    /** @var array<string, list<array{title:string,body:string}>>|null */
    private static $cache = null;

    /**
     * Pick one random title+body for a bank, with token substitution.
     *
     * @param  array<string, string|int|float|null>  $tokens
     * @return array{title:string,body:string,bank:string}
     */
    public static function pick(string $bank, array $tokens = []): array
    {
        $rows = self::rowsFor($bank);
        if (empty($rows)) {
            return [
                'title' => self::fill('Mintzer', $tokens),
                'body' => self::fill('Open the app.', $tokens),
                'bank' => $bank,
            ];
        }
        $row = $rows[array_rand($rows)];
        return [
            'title' => self::fill((string) ($row['title'] ?? ''), $tokens),
            'body' => self::fill((string) ($row['body'] ?? ''), $tokens),
            'bank' => $bank,
        ];
    }

    /** Randomly use pro or funny deal-live bank. */
    public static function pickDealLive(array $tokens = []): array
    {
        $bank = (random_int(0, 1) === 1) ? 'deal_funny' : 'deal_live';
        return self::pick($bank, $tokens);
    }

    /**
     * @return list<array{title:string,body:string}>
     */
    public static function rowsFor(string $bank): array
    {
        $fromDb = self::fromDb($bank);
        if (!empty($fromDb)) {
            return $fromDb;
        }
        $all = self::loadJsonBanks();
        return $all[$bank] ?? [];
    }

    public static function bankKeys(): array
    {
        return array_keys(self::loadJsonBanks());
    }

    public static function reload(): void
    {
        self::$cache = null;
    }

    /**
     * @return list<array{title:string,body:string}>
     */
    private static function fromDb(string $bank): array
    {
        try {
            if (!Schema::hasTable('v3_push_templates')) {
                return [];
            }
            $rows = DB::table('v3_push_templates')
                ->where('bank', $bank)
                ->where('active', 1)
                ->orderBy('id')
                ->get(['title', 'body']);
            $out = [];
            foreach ($rows as $r) {
                $out[] = ['title' => (string) $r->title, 'body' => (string) $r->body];
            }
            return $out;
        } catch (\Throwable $e) {
            return [];
        }
    }

    /**
     * @return array<string, list<array{title:string,body:string}>>
     */
    private static function loadJsonBanks(): array
    {
        if (self::$cache !== null) {
            return self::$cache;
        }
        $paths = [
            base_path('resources/v3_push/templates.json'),
            storage_path('app/v3_push/templates.json'),
        ];
        foreach ($paths as $path) {
            if (!is_readable($path)) {
                continue;
            }
            $raw = file_get_contents($path);
            $json = json_decode($raw ?: '', true);
            if (!is_array($json) || empty($json['banks']) || !is_array($json['banks'])) {
                continue;
            }
            $banks = [];
            foreach ($json['banks'] as $key => $rows) {
                if (!is_array($rows)) {
                    continue;
                }
                $list = [];
                foreach ($rows as $row) {
                    if (!is_array($row)) {
                        continue;
                    }
                    $list[] = [
                        'title' => (string) ($row['title'] ?? ''),
                        'body' => (string) ($row['body'] ?? ''),
                    ];
                }
                $banks[(string) $key] = $list;
            }
            self::$cache = $banks;
            return self::$cache;
        }
        self::$cache = [];
        return self::$cache;
    }

    /**
     * @param  array<string, string|int|float|null>  $tokens
     */
    public static function fill(string $text, array $tokens): string
    {
        $map = [];
        foreach ($tokens as $k => $v) {
            $key = trim((string) $k, '{}');
            $map['{' . $key . '}'] = (string) ($v ?? '');
        }
        return strtr($text, $map);
    }

    /**
     * Common deal tokens from a deals row.
     *
     * @param  object|array  $deal
     * @return array<string, string>
     */
    public static function tokensFromDeal($deal, ?int $dayN = null): array
    {
        $g = static function ($obj, string $key, $default = '') {
            if (is_array($obj)) {
                return $obj[$key] ?? $default;
            }
            return $obj->{$key} ?? $default;
        };

        $earn = (float) ($g($deal, 'card_holder_earn', null)
            ?? $g($deal, 'you_earn', null)
            ?? $g($deal, 'earn', null)
            ?? $g($deal, 'cashback', 0)
            ?? 0);
        $spend = (float) ($g($deal, 'selling_price', null)
            ?? $g($deal, 'order_amount', null)
            ?? $g($deal, 'amount', 0)
            ?? 0);
        $product = trim((string) ($g($deal, 'name', null)
            ?? $g($deal, 'product_name', null)
            ?? 'Deal'));
        $store = trim((string) ($g($deal, 'store_name', null)
            ?? $g($deal, 'store', null)
            ?? 'Store'));
        $card = trim((string) ($g($deal, 'card_name', null)
            ?? $g($deal, 'bank_card', null)
            ?? ''));

        $tokens = [
            'product' => $product !== '' ? $product : 'Deal',
            'store' => $store !== '' ? $store : 'Store',
            'earn' => (string) (int) round($earn),
            'spend' => (string) (int) round($spend),
            'card' => $card,
            'ref' => '',
            'expiry' => '',
            'endsAt' => '',
            'amount' => (string) (int) round($earn),
            'preview' => '',
            'reason' => '',
            'n' => $dayN !== null ? (string) $dayN : '2',
        ];
        return $tokens;
    }
}
