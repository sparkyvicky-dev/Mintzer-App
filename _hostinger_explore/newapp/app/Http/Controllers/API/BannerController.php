<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class BannerController extends Controller
{
    function getbanners(Request $request)
    {
        $unread_notification = false;
        if($request->user_id){
            $notifications = Notification::where('user_id', $request->user_id)->get();
            foreach ($notifications as $notify) {
                if ($notify->is_readed == 0) {
                    $unread_notification = true;
                }
            }
        }

        $hasPopup = Schema::hasColumn('banners', 'is_popup');
        $query = Banner::where('status', 1);
        if ($hasPopup) {
            $query->where(function ($q) {
                $q->whereNull('is_popup')->orWhere('is_popup', 0);
            });
        }
        $banners = $query->get();
        $data = [];
        foreach ($banners as $banner) {
            $bannerdata = [
                'id' => $banner->id,
                'banner_name' => $banner->name,
                'banner_image' => url($banner->image),
                'banner_url' => $banner->url,
                'banner_discription' => $banner->short_description ?? null,
                'opens_cards' => (Schema::hasColumn('banners', 'opens_cards') && (int) $banner->opens_cards === 1) ? 1 : 0,
            ];
            $data[] = $bannerdata;
        }

        return response()->json([
            'data' => $data,
            'unread_notification' => $unread_notification,
            'home_popup' => $this->activeHomePopup($request),
        ], 200);
    }

    function markHomePopupSeen(Request $request)
    {
        $user = Auth::user();
        $bannerId = (int) $request->input('banner_id');
        if (!$user || $bannerId < 1 || !Schema::hasTable('home_popup_seen')) {
            return response()->json(['ok' => false], 200);
        }

        DB::table('home_popup_seen')->updateOrInsert(
            ['user_id' => $user->id, 'banner_id' => $bannerId],
            ['created_at' => now()]
        );

        return response()->json(['ok' => true], 200);
    }

    private function activeHomePopup(Request $request)
    {
        if (!Schema::hasColumn('banners', 'is_popup')) {
            return null;
        }

        $popup = Banner::where('status', 1)
            ->where('is_popup', 1)
            ->orderByDesc('id')
            ->first();

        if (!$popup || empty($popup->image)) {
            return null;
        }

        $uid = (int) $request->user_id;
        if ($uid > 0 && Schema::hasTable('home_popup_seen')) {
            $seen = DB::table('home_popup_seen')
                ->where('user_id', $uid)
                ->where('banner_id', $popup->id)
                ->exists();
            if ($seen) {
                return null;
            }
        }

        return [
            'id' => $popup->id,
            'image' => url($popup->image),
            'url' => $popup->url ?: '',
        ];
    }
}
