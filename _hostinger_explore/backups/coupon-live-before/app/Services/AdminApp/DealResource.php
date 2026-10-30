<?php

namespace App\Services\AdminApp;

use App\Models\Deal;
use Illuminate\Support\Facades\DB;

class DealResource
{
    public static function fromModel(Deal $deal, bool $includeUsers = false): array
    {
        $deal->loadMissing(['store', 'dealer', 'bankCard']);

        $additional = DB::table('deal_images')
            ->where('deal_id', $deal->id)
            ->pluck('image')
            ->toArray();

        $labels = [];
        if ($deal->image) {
            $labels[] = basename($deal->image);
        }
        foreach ($additional as $path) {
            if ($path) {
                $labels[] = basename($path);
            }
        }
        if ($labels === [] && $deal->name) {
            $labels = [$deal->name];
        }

        $payload = [
            'id' => 'd' . $deal->id,
            'server_id' => (int) $deal->id,
            'name' => $deal->name,
            'color' => $deal->color ?? '',
            'storeName' => $deal->store->name ?? '',
            'store_id' => $deal->store_id,
            'dealerName' => $deal->dealer->display_name ?? $deal->dealer->name ?? '',
            'dealer_id' => $deal->dealer_id,
            'cardName' => $deal->bankCard->name ?? '',
            'card_id' => $deal->bank_card_id,
            'orderQty' => (string) ($deal->order_qty ?? '0'),
            'spend' => self::money($deal->card_holder_spend),
            'earn' => self::money($deal->card_holder_earn),
            'receive' => self::money($deal->card_holder_recieve),
            'offerLink' => $deal->offer_link1 ?? '',
            'productPrice' => self::money($deal->product_price),
            'offerText' => $deal->offer_text ?? '',
            'discount' => self::money($deal->discount),
            'cashback' => self::money($deal->cashback),
            'cashReward' => self::money($deal->cash_reward),
            'gstNumber' => $deal->gst_number ?? '',
            'companyName' => $deal->company_name ?? '',
            'gstContent' => $deal->gst_content ?? '',
            'instruction' => $deal->instruction ?? '',
            'extraNotes' => $deal->extra_note ?? '',
            'pineLab' => (bool) $deal->is_pine_lab,
            'pineLabLink' => $deal->pine_lab_url ?? '',
            'status' => (int) ($deal->status ?? 1),
            'createdAt' => optional($deal->created_at)->toIso8601String(),
            'imageLabels' => $labels,
            'image_url' => $deal->image ? asset($deal->image) : null,
            'image_path' => $deal->image,
            'copiedFrom' => null,
        ];

        return DealIntelService::enrichPayload($payload, $includeUsers);
    }

    private static function money($value): string
    {
        if ($value === null || $value === '') {
            return '0';
        }

        return (string) (is_numeric($value) ? (int) round((float) $value) : $value);
    }
}
