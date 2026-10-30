<?php

namespace App\Http\Controllers\API\Deal;

use App\Http\Controllers\Controller;
use App\Models\Deal;
use App\Models\Logistic;
use App\Traits\Common;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;

class dealController extends Controller
{
    use Common;
    function getDealdata(Request $request)
    {
        try {
            $store_id = $request->query('store_id');
            $search = $request->query('search');
            $cardId = $request->query('bankCard_id');
            $userId = $request->input('user_id');
            $isPineLab = $request->input('is_pine_lab');

            $query = Deal::with([
                'store',
                'bankCard',
                'dealImages:id,deal_id,image'
            ]);

            if ($store_id !== null) {
                $query->where('store_id', $store_id);
            }

            if ($cardId !== null) {
                $query->where('bank_card_id', $cardId);
            }

            if ($search) {
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                        ->orWhereHas('bankCard', function ($q2) use ($search) {
                            $q2->where('name', 'like', "%{$search}%");
                        });
                });
            }

            if ($isPineLab) {
                $query->where('is_pine_lab', 1);
            } else {
                $query->where('is_pine_lab', 0);
            }
            $is_filtered = ($store_id !== null || $search !== null || $cardId !== null);

            $deals = $query->where('status', 1)->where('order_qty', '>', 0)->orderBy('id', 'DESC')->get();
            $data = $this->dealDataFormat($deals, $userId);
            return response()->json(['data' => empty($data) ? [] : $data, 'is_filtered' => $is_filtered], 200);
        } catch (\Throwable $th) {
            // Handle exception
        }
    }

    public function getDealDetail(Request $request)
    {
        try {
            $id = $request->input('deal_id');
            $userId = $request->input('user_id');

            $deal = Deal::withTrashed()->with('store', 'bankCard')->findOrFail($id);

            $data = $this->dealDetailDataFormat($deal, $userId);

            return response()->json(['data' => $data], 200);
        } catch (ModelNotFoundException $ex) {
            return response()->json(['message' => 'Deal not found'], 404);
        } catch (\Throwable $th) {
            return response()->json(['error' => $th->getMessage()], 500);
        }
    }

    function getlogistics()
    {
        $logistics = Logistic::orderByRaw("id = 4 ASC")->get();
        $data = [];
        foreach ($logistics as $logistic) {
            $logisticdata = [
                'logistic_id' => $logistic->id,
                'logistic_name' => $logistic->logistic_name,
            ];
            $data[] = $logisticdata;
        }

        return response()->json(['data' => $data], 200);
    }
}
