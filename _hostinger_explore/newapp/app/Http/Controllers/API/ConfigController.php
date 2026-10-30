<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\BusinessSettings;
use App\Models\Language;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ConfigController extends Controller
{
    public function business_confiuration()
    {
        $key = [
            'business_name',
            'mobile',
            'whatsapp_link',
            'telegram_link',
            'youtube_link',
            'whatsapp_group_link',
            'deal_youtube_video',
            'home_social_proof_enabled',
            'home_social_proof_source',
            'home_social_proof_earned',
            'home_social_proof_orders',
        ];

        $settings =  array_column(BusinessSettings::whereIn('key', $key)->get()->toArray(), 'value', 'key');

        $enabled = (($settings['home_social_proof_enabled'] ?? '0') === '1');
        $source = (($settings['home_social_proof_source'] ?? 'live') === 'custom') ? 'custom' : 'live';
        $earned = (string) ($settings['home_social_proof_earned'] ?? '');
        $orders = (string) ($settings['home_social_proof_orders'] ?? '');
        $live = self::liveHomeLine();
        if ($enabled && $source === 'live') {
            $earned = $live['earned'];
            $orders = $live['orders'];
        } elseif ($enabled) {
            if ($earned === '') {
                $earned = $live['earned'];
            }
            if ($orders === '') {
                $orders = $live['orders'];
            }
        }

        return response()->json([
            'business_name' => $settings['business_name'],
            'mobile' => $settings['mobile'],
            'whatsapp_link' => $settings['whatsapp_link'],
            'telegram_link' => $settings['telegram_link'],
            'youtube_link' => $settings['youtube_link'],
            'whatsapp_group_link' => $settings['whatsapp_group_link'],
            'deal_youtube_video' => $settings['deal_youtube_video'],
            'home_social_proof_enabled' => $enabled,
            'home_social_proof_source' => $source,
            'home_social_proof_earned' => $earned,
            'home_social_proof_orders' => $orders,
        ]);
    }

    /** This week's payout total and today's order count. Cancelled orders are left out. */
    public static function liveHomeLine(): array
    {
        try {
            $startWeek = Carbon::now()->startOfWeek(Carbon::MONDAY);
            $startToday = Carbon::now()->startOfDay();
            $skip = ['Cancelled', 'Rejected', 'Declined'];
            $earned = Order::query()
                ->whereNotIn('order_status', $skip)
                ->where('created_at', '>=', $startWeek)
                ->sum('to_card_holder');
            $orders = Order::query()
                ->whereNotIn('order_status', $skip)
                ->where('created_at', '>=', $startToday)
                ->count();

            return [
                'earned' => self::compactInr($earned),
                'orders' => (string) $orders,
            ];
        } catch (\Throwable $e) {
            return ['earned' => '', 'orders' => ''];
        }
    }

    private static function compactInr($amount): string
    {
        $n = (float) $amount;
        if ($n < 0) {
            $n = 0;
        }
        if ($n >= 10000000) {
            return rtrim(rtrim(number_format($n / 10000000, 1, '.', ''), '0'), '.') . 'Cr';
        }
        if ($n >= 100000) {
            return rtrim(rtrim(number_format($n / 100000, 1, '.', ''), '0'), '.') . 'L';
        }

        return number_format($n, 0, '.', ',');
    }

    public function getLanguages()
    {
        $languages = Language::all();
        $data = [];
        foreach ($languages as $language) {
            $languagedata = [
                'language_id' => $language->id,
                'language' => $language->language,
                'language_code' => $language->lang_code
            ];
            $data[] = $languagedata;
        }

        return response()->json([
            'data' => $data
        ], 200);
    }
}
