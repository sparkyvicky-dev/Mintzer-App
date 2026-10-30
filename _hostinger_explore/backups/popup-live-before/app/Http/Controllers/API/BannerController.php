<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

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
        $banners = Banner::where('status', 1)->get();
        $data = [];
        foreach ($banners as $banner) {
            $bannerdata = [
                'id' => $banner->id,
                'banner_name' => $banner->name,
                'banner_image' => url($banner->image),
                'banner_url' => $banner->url,
                'banner_discription' => $banner->short_description ?? null,
            ];
            $data[] = $bannerdata;
        }

        return response()->json([
            'data' => $data,
            'unread_notification' => $unread_notification
        ], 200);
    }
}
