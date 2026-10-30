<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\BusinessSettings;
use App\Models\Language;
use Illuminate\Http\Request;

class ConfigController extends Controller
{
    public function business_confiuration()
    {
        $key = ['business_name', 'mobile', 'whatsapp_link', 'telegram_link', 'youtube_link', 'whatsapp_group_link', 'deal_youtube_video'];

        $settings =  array_column(BusinessSettings::whereIn('key', $key)->get()->toArray(), 'value', 'key');

        return response()->json([
            'business_name' => $settings['business_name'],
            'mobile' => $settings['mobile'],
            'whatsapp_link' => $settings['whatsapp_link'],
            'telegram_link' => $settings['telegram_link'],
            'youtube_link' => $settings['youtube_link'],
            'whatsapp_group_link' => $settings['whatsapp_group_link'],
            'deal_youtube_video' => $settings['deal_youtube_video'],
        ]);
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
