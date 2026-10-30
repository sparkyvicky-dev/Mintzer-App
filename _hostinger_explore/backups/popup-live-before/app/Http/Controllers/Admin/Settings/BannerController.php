<?php

namespace App\Http\Controllers\Admin\Settings;

use App\Enums\LogType;
use App\Enums\MenuPermissionType;
use App\Http\Controllers\Controller;
use App\Models\Banner;
use App\Traits\Common;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class BannerController extends Controller
{
    use Common;
    public function banners()
    {
        try {
            $banners = Banner::get();
            return view('admin.settings.banners', compact('banners'));
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }


    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'txtBannerName' => [
                'required',
                Rule::unique('banners', 'name')->ignore($request->hdBannerId, 'id'),
            ],
            'txtbannermessage' => 'required',
        ], [
            'txtBannerName.unique' => 'Banner name already exists.',
            'txtbannermessage.required' => 'Banner message is required'
        ]);

        if ($validator->fails()) {
            return redirect()->back()->withInput()->withErrors($validator);
        }

        DB::beginTransaction();
        try {
            $banner = $request->hdBannerId ? Banner::findOrFail($request->hdBannerId) : new Banner();

            $banner->name = $request->txtBannerName;
            $banner->url = $request->txtbannerlink ?? null;
            $banner->short_description = $request->txtbannermessage;

            if ($request->hasFile('bannerImage')) {
                if ($banner->image) {
                    Storage::delete($banner->image);
                }

                $file = $request->file('bannerImage');
                $make_name = hexdec(uniqid()) . '.' . $file->getClientOriginalExtension();
                $directory = 'upload/bank';
                $file->move(public_path($directory), $make_name);
                $banner->image = $directory . '/' . $make_name;
            }

            $banner->save();

            DB::commit();

            $notification = array(
                'message' => $request->hdBannerId ? 'Banner Updated Successfully' : 'Banner Created Successfully',
                'alert-type' => 'success'
            );
            return redirect()->back()->with($notification);
        } catch (\Exception $e) {
            DB::rollback();
            $this->Log(__FUNCTION__, $request->method(), $e->getMessage(), Auth::user()->id, $request->ip(), gethostname(), 0, LogType::Error);
            $notification = array(
                'message' => 'Failed to update banner. Please try again.',
                'alert-type' => 'error'
            );
            return redirect()->back()->withInput()->with($notification);
        }
    }


    public function changestatus($id, $status)
    {
        try {
            Banner::findorfail($id)->update([
                'status' => $status
            ]);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, "POST", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }
    
    public function deleteBanner($id)
    {
        DB::beginTransaction();
        try {
            $banner = Banner::findorfail($id);
            $banner->delete();

            $notification = array(
                'message' => 'Banner Deleted Successfully',
                'alert' => 'success'
            );
            DB::commit();
            return response()->json([
                'responseData' => $notification
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            $notification = array(
                'message' => 'Banner could not be deleted',
                'alert' => 'error'
            );
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            return response()->json([
                'responseData' => $notification
            ]);
        }
    }

    public function getBannerData(Request $request)
    {
        try {
            $bannerData = Banner::all();

            return datatables()->of($bannerData)
                ->addColumn('action', function ($row) {
                    $html = "";
                    if ($this->isUserHavePermission(MenuPermissionType::Edit)) {
                        $html .= '<i class="text-primary ti ti-pencil me-1" onclick="doEdit(' . $row->id . ');"></i> ';
                    }
                    if ($this->isUserHavePermission(MenuPermissionType::Delete)) {
                        $html .= '<i class="text-danger ti ti-trash me-1" id="confirm-color(' . $row->id . ')" onclick="showDelete(' . $row->id . ');"></i>';
                    }
                    return $html;
                })->toJson();
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    // public function getBannerById($id)
    // {
    //     try {
    //         $banner = Banners::select('banners.*')->where('banners.id', $id)->whereNull('deleted_at')->first();
    //         return response()->json([
    //             'banner' => $banner
    //         ]);
    //     } catch (\Exception $e) {
    //         $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname());
    //     }
    // }


    // public function activeBannerStatus($id, $status)
    // {
    //     DB::beginTransaction();
    //     try {
    //         Banners::findorfail($id)->update([
    //             'is_active' => $status,
    //             'updated_by' => Auth::user()->id
    //         ]);
    //         DB::commit();
    //     } catch (\Exception $e) {
    //         DB::rollback();
    //         $this->Log(__FUNCTION__, 'POST', $e->getMessage(), Auth::user()->id, request()->ip(), gethostname());
    //     }
    // }
}
