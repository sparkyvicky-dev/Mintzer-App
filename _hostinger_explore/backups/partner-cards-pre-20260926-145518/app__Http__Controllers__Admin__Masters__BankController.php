<?php

namespace App\Http\Controllers\Admin\Masters;

use App\Enums\LogType;
use App\Http\Controllers\Controller;
use App\Models\Bank;
use App\Models\BankCard;
use App\Traits\Common;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Image;

class BankController extends Controller
{
    use Common;
    public function banks()
    {
        try {
            return view('admin.masters.banks');
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(),0,LogType::Error);
        }
    }

    public function getBankData()
    {
        $banks = Bank::whereNull('deleted_at')->get();
        return datatables()->of($banks)
            ->addColumn('action', function ($row) {
                $html = "";
                $html = '<i class="text-primary ti ti-pencil"></i> ';
                $html .= '<i class="text-danger ti ti-trash" onclick="showDelete(' . $row->id . ');"></i>';
                return $html;
            })->toJson();
    }

    public function createBank(Request $request)
{
    DB::beginTransaction();
    try {
        $rules = [
            'bank_name' => 'required|string|max:255',
        ];
        $messages = [
            'bank_name.required' => 'The bank name is required.',
        ];

        // CREATE → Image required
        if (!$request->filled('hdBankId')) {
            $rules['bank_image'] = 'required|image|mimes:jpeg,png,jpg,gif|max:5048';
            $messages['bank_image.required'] = 'Please upload a bank logo.';
        } else {
            // EDIT → Image required only if user removed the existing one
            if (empty($request->current_image)) {
                $rules['bank_image'] = 'required|image|mimes:jpeg,png,jpg,gif|max:5048';
                $messages['bank_image.required'] = 'You removed the logo. Please upload a new one.';
            } else {
                $rules['bank_image'] = 'nullable|image|mimes:jpeg,png,jpg,gif|max:5048';
            }
        }

        $validator = Validator::make($request->all(), $rules, $messages);
        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator)->withInput();
        }

        if (!$request->filled('hdBankId')) {
            // CREATE
            $bank = new Bank();
            $bank->name = $request->bank_name;
            $bank->apply_url = $request->filled('apply_url') ? trim($request->apply_url) : null;
            $bank->created_by = Auth::user()->id;
        } else {
            // UPDATE
            $bank = Bank::findOrFail($request->hdBankId);
            $bank->name = $request->bank_name;
            $bank->apply_url = $request->filled('apply_url') ? trim($request->apply_url) : null;
            $bank->updated_by = Auth::user()->id;
        }

        // Handle Image
        if ($request->hasFile('bank_image')) {
            // Delete old image if exists
            if ($bank->image && file_exists(public_path($bank->image))) {
                unlink(public_path($bank->image));
            }

            $file = $request->file('bank_image');
            $filename = hexdec(uniqid()) . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('upload/bank'), $filename);
            $bank->image = 'upload/bank/' . $filename;
        } else {
            // No new file
            if (empty($request->current_image)) {
                // User removed image → delete from server
                if ($bank->image && file_exists(public_path($bank->image))) {
                    unlink(public_path($bank->image));
                }
                $bank->image = null;
            }
            // Else keep existing
        }

        $bank->save();
        DB::commit();

        $notification = [
            'message' => $request->filled('hdBankId') ? 'Bank updated successfully' : 'Bank created successfully',
            'alert-type' => 'success'
        ];

        return redirect()->back()->with($notification);

    } catch (\Exception $th) {
        DB::rollback();
        $this->Log(__FUNCTION__, "POST", $th->getMessage(), Auth::user()->id ?? null, request()->ip(), gethostname(), 0, LogType::Error);
        return redirect()->back()->with(['message' => 'Something went wrong!', 'alert-type' => 'error']);
    }
}
    public function deleteBank($id)
    {
        try {
            $bank = Bank::find($id);
            if (!$bank) {
                return response()->json([
                    'responseData' => [
                        'message' => 'Bank not found',
                        'alert'   => 'error'
                    ]
                ]);
            } else {
                $isLinked = BankCard::where('bank_id', $bank->id)->exists();
                if ($isLinked) {
                    return response()->json([
                        'responseData' => [
                            'message' => 'Bank is associated with one or more bank cards. Cannot delete.',
                            'alert'   => 'error'
                        ]
                    ]);
                }
                $bank->delete();
                return response()->json([
                    'responseData' => [
                        'message' => 'Bank deleted successfully',
                        'alert'   => 'success'
                    ]
                ]);
            }
        } catch (Exception $e) {

            $notification = array('message' => 'Bank could not be deleted', 'alert' => 'error');
            return response()->json(['responseData' => $notification]);
        }
    }
}
