<?php

namespace App\Http\Controllers\Admin\Masters;

use App\Enums\LogType;
use App\Enums\RoleTypes;
use App\Http\Controllers\Controller;
use App\Models\BankCard;
use App\Models\BusinessSettings;
use App\Models\Deal;
use App\Models\DealerAddress;
use App\Models\DealImage;
use App\Models\Notification;
use App\Models\Store;
use App\Models\User;
use App\Traits\Common;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Image;
use Rap2hpoutre\FastExcel\FastExcel;

class DealsController extends Controller
{
    use Common;
    public function deals()
    {
        try {

            return view('admin.masters.deals.list');
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    public function getDealData($type = 0)
    {
        $deals = Deal::with([
            'dealer',
            'store',
            'bankCard'
        ])
            ->whereNull('deleted_at')
            ->where('is_pine_lab', $type)
            ->orderBy('id', 'DESC')
            ->get();

        return datatables()->of($deals)
            ->addColumn('images', function ($row) {
                $html = '<div class="d-flex flex-wrap gap-2">';

                // Main image first
                if ($row->image) {
                    $html .= '<img src="' . asset($row->image) . '" class="rounded" width="60" height="60" style="object-fit: cover;" title="Main Image">';
                }

                $html .= '</div>';

                if (!$row->image) {
                    $html = '<span class="text-muted">No images</span>';
                }

                return $html;
            })
            ->addColumn('action', function ($row) {
                $html = '<div class="d-flex align-items-center gap-2">'; // Flex container with spacing

                $html .= '<i class="text-info ti ti-bell-ringing fs-5 cursor-pointer" title="Notify this deal" onclick="sendDealNotify(' . $row->id . ');"></i>';
                $html .= '<i class="text-success ti ti-package fs-5 cursor-pointer" title="Stock alert for this deal" onclick="sendDealStockAlert(' . $row->id . ');"></i>';

                $html .= '<a href="deal-copy/' . $row->id . '"  class="text-warning">
                            <i class="ti ti-copy"></i>
                          </a>';
                $html .= '<a href="deal-edit/' . $row->id . '/' . $row->is_pine_lab . '"><i class="text-primary ti ti-pencil fs-5"></i></a> ';
                if (Auth::user()->role_id == RoleTypes::Admin) {
                    $html .= '<i class="text-danger ti ti-trash fs-5 cursor-pointer" onclick="showDelete(' . $row->id . ');"></i>';
                }
                $html .= '</div>';
                return $html;
            })
            ->rawColumns(['images', 'action'])
            ->toJson();
    }
    private function dealersWithAddressStats()
    {
        $dealers = User::where('role_id', 2)->get();
        $dealerAddressStats = DealerAddress::select(
            'dealer_id',
            DB::raw('COUNT(*) as total_addresses'),
            DB::raw('SUM(CASE WHEN is_ordered = 1 THEN 1 ELSE 0 END) as used_addresses')
        )
            ->whereNull('deleted_at')
            ->groupBy('dealer_id')
            ->get()
            ->keyBy('dealer_id');

        $dealers->transform(function ($dealer) use ($dealerAddressStats) {
            $stats = $dealerAddressStats->get($dealer->id);
            $total = (int) ($stats->total_addresses ?? 0);
            $used = (int) ($stats->used_addresses ?? 0);
            $left = max($total - $used, 0);

            $dealer->total_addresses = $total;
            $dealer->used_addresses = $used;
            $dealer->left_addresses = $left;
            return $dealer;
        });

        return $dealers;
    }

    private function loadDealFormData($type = 0, $formMode = 'create', $deal = null)
    {
        $stores = Store::where('status', 1)->get();
        $dealers = $this->dealersWithAddressStats();
        $bankCards = BankCard::where('status', 1)->get();

        return compact('stores', 'dealers', 'bankCards', 'type', 'formMode', 'deal');
    }

    public function dealCreate($type = 0)
    {
        try {
            $formMode = 'create';
            $deal = null;
            return view(
                'admin.masters.deals.create',
                $this->loadDealFormData($type, $formMode, $deal)
            );
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }
    public function store(Request $request)
    {
        $validator = $this->validateDeal($request);
        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator)->withInput();
        }


        DB::beginTransaction();
        try {
            $isNew = is_null($request->ddlDealID);
            $existingDeal = null;
            $existingImage = null;
            $dealIdForHandle = null;
            if (!$isNew) {
                $existingDeal = Deal::findOrFail($request->ddlDealID);
                $existingImage = $existingDeal->image;
                $dealIdForHandle = $request->ddlDealID;
            }
            $imagesData = $this->handleDealImages($request, $dealIdForHandle, $existingImage);

            if ($isNew && $request->input('is_copy') != 1) {
                // V2 topic/multicast deal FCM silenced — Flutter uses V3DealLiveService only
                // (avoids double tray buzz on mintzer-e45d6). Old Play holders still get
                // V3 fallback via users.fcm_token inside V3PushGateway when registered.
                // $this->sendFcmNotifications($request, $imagesData['main']);
            }

            $createdDealIds = [];
            if ($isNew) {
                $dealIds = $this->createDeals($request, $imagesData['main']);
                $createdDealIds = $dealIds;
                if (!empty($imagesData['all_paths'])) {
                    foreach ($dealIds as $dealId) {
                        foreach ($imagesData['all_paths'] as $path) {
                            DealImage::create([
                                'deal_id' => $dealId,
                                'image' => $path
                            ]);
                        }
                    }
                }

                $notificationMessage = 'Deal Created Successfully';
            } else {
                $this->updateDeal($request, $imagesData['main'], $existingDeal);

                DB::table('deal_images')->where('deal_id', $existingDeal->id)->delete();

                foreach ($imagesData['all_paths'] as $path) {
                    DB::table('deal_images')->insert([
                        'deal_id'    => $existingDeal->id,
                        'image'      => $path,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                $notificationMessage = 'Deal Updated Successfully';

                // V3 Home — refresh catalog after edit (qty / image / off stock).
                try {
                    \App\Services\V3Push\V3DealLiveService::notifyCatalogChanged(
                        (int) $existingDeal->id,
                        'updated'
                    );
                } catch (\Throwable $e) {
                    $this->Log(__FUNCTION__, request()->method(), 'V3 catalog push: ' . $e->getMessage(), Auth::user()->id ?? 0, request()->ip(), gethostname(), 0, LogType::Error);
                }
            }

            DB::commit();

            // V3 deal.live after the browser gets the redirect — do not block create.
            if ($isNew && !empty($createdDealIds)) {
                $pushDealIds = array_values(array_map('intval', $createdDealIds));
                $logUserId = Auth::user()->id ?? 0;
                $logIp = request()->ip();
                dispatch(function () use ($pushDealIds, $logUserId, $logIp) {
                    foreach ($pushDealIds as $dealId) {
                        try {
                            \App\Services\V3Push\V3DealLiveService::notifyDealLive($dealId);
                        } catch (\Throwable $e) {
                            \Illuminate\Support\Facades\Log::error('V3 auto deal push: ' . $e->getMessage(), [
                                'deal_id' => $dealId,
                                'user_id' => $logUserId,
                                'ip' => $logIp,
                            ]);
                        }
                    }
                })->afterResponse();
            }

            return redirect()->route('deals')->with([
                'message' => $notificationMessage,
                'alert-type' => 'success'
            ]);
        } catch (Exception $e) {
            DB::rollBack();
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            return redirect()->back()->with([
                'message' => 'Something went wrong. Please try again.',
                'alert-type' => 'error'
            ]);
        }
    }
    protected function validateDeal($request)
    {
        $isPineLabLink = (int) $request->input('deal_type') === 1
            || !empty(trim((string) $request->input('txtPineLabLink', '')));

        $rules = [
            'ddlStoreID'         => $isPineLabLink ? 'nullable|integer' : 'required|integer',
            'ddlDealerId'        => $request->ddlDealID ? 'required|integer' : 'required|array|min:1',
            'ddlDealerId.*'      => $isPineLabLink ? 'nullable|integer' : 'integer',
            'ddlBankCardId'      => $isPineLabLink ? 'nullable|integer' : 'required|integer',
            'txtDealName'        => 'required|string|max:255',
            'txtcolor'           => $isPineLabLink ? 'nullable|string|max:255' : 'required|string|max:255',
            'deal_images.*'      => 'image|mimes:jpeg,png,jpg,gif,webp|max:2048',
            'txtOrderQty'        => $isPineLabLink ? 'nullable|integer' : 'required|integer',
            'txtOfferText'       => $isPineLabLink ? 'nullable|string' : 'required|string',
            'txtOfferLink1'      => $isPineLabLink ? 'nullable|url' : 'required|url',
            'txtOfferLink2'      => 'nullable|url',
            'txtOfferLink3'      => 'nullable|url',
            'txtPineLabLink'     => $isPineLabLink ? 'required|url' : 'nullable|url',
            'txtCashReward'      => $isPineLabLink ? 'nullable|numeric' : 'required|numeric',
            'txtDealerPrice'     => $isPineLabLink ? 'nullable|numeric' : 'required|numeric',
            'txtCashback'        => $isPineLabLink ? 'nullable|numeric' : 'required|numeric',
            'txtDiscount'        => $isPineLabLink ? 'nullable|numeric' : 'required|numeric',
            'txtCardHolderEarn'  => 'required|numeric',
            'txtCardHolderSpend' => 'required|numeric',
            'txtTotalReceive'    => 'required|numeric',
            'txtInstruction'     => 'required|string',
            'txtExtraNotes'      => 'required|string',
            'txtGSTContent'      => 'nullable|string',
        ];
        $validator = Validator::make($request->all(), $rules);


        $validator->after(function ($validator) use ($request) {
            $isEdit = !is_null($request->ddlDealID);
            $isCopy = $request->input('is_copy') == 1;

            $hasNewImages  = $request->hasFile('deal_images')
                && count($request->file('deal_images', [])) > 0;

            $hasKeepImages = is_array($request->input('keep_images'))
                && count($request->input('keep_images')) > 0;

            if (!$isEdit && !$isCopy && !$hasNewImages) {
                $validator->errors()->add(
                    'deal_images',
                    'At least one image is required.'
                );
            }

            if (($isEdit || $isCopy) && !$hasNewImages && !$hasKeepImages) {
                $validator->errors()->add(
                    'deal_images',
                    'At least one image is required for the deal.'
                );
            }
        });
        $validator->validate();
        return $validator;
    }

    protected function handleDealImages($request, $dealId = null, $existingMain = null)
    {
        $isCopy = $request->input('is_copy') == 1;
        $mainPath = $existingMain;
        $allPaths = [];
        if ($isCopy) {
            $keepPaths = $request->input('keep_images', []);
            $allPaths = array_values($keepPaths);
        }
        if ($dealId && !$isCopy) {
            $keepPaths = $request->input('keep_images', []);

            $existingDeal = Deal::find($dealId);
            $currentMain = $existingDeal->image ?? null;

            $additionalImages = DealImage::withoutGlobalScopes()
                ->where('deal_id', $dealId)
                ->pluck('image')
                ->toArray();

            $allCurrentPaths = array_filter(array_merge([$currentMain], $additionalImages));

            foreach ($allCurrentPaths as $path) {
                if ($path && !in_array($path, $keepPaths)) {
                    $fullPath = public_path($path);
                    if (file_exists($fullPath)) {
                        unlink($fullPath);
                    }
                }
            }

            DB::table('deal_images')
                ->where('deal_id', $dealId)
                ->whereNotIn('image', $keepPaths)
                ->delete();

            if ($currentMain && !in_array($currentMain, $keepPaths)) {
                $mainPath = null;
            }

            $allPaths = array_values($keepPaths);
        }

        $directory = public_path('upload/deals');
        if (!file_exists($directory)) {
            mkdir($directory, 0777, true);
        }

        $files = $request->file('deal_images') ?? [];
        foreach ($files as $file) {
            $fileName = hexdec(uniqid()) . '.webp';
            $filePath = $directory . '/' . $fileName;

            $originalPath = $file->getRealPath();
            $imageInfo = getimagesize($originalPath);

            if ($imageInfo !== false) {
                $mimeType = $imageInfo['mime'];

                switch ($mimeType) {
                    case 'image/jpeg':
                    case 'image/jpg':
                        $image = imagecreatefromjpeg($originalPath);
                        break;
                    case 'image/png':
                        $image = imagecreatefrompng($originalPath);
                        break;
                    case 'image/gif':
                        $image = imagecreatefromgif($originalPath);
                        break;
                    case 'image/webp':
                        $image = imagecreatefromwebp($originalPath);
                        break;
                    default:
                        continue 2; // skip unsupported formats
                }

                if ($image !== false) {
                    if (!imageistruecolor($image)) {
                        $width = imagesx($image);
                        $height = imagesy($image);
                        $trueColorImage = imagecreatetruecolor($width, $height);
                        imagealphablending($trueColorImage, false);
                        imagesavealpha($trueColorImage, true);
                        imagecopy($trueColorImage, $image, 0, 0, 0, 0, $width, $height);
                        imagedestroy($image);
                        $image = $trueColorImage;
                    }

                    imagewebp($image, $filePath, 90);
                    imagedestroy($image);

                    $allPaths[] = 'upload/deals/' . $fileName;
                }
            }
        }
        $mainPath = $allPaths[0] ?? $existingMain ?? null;

        return [
            'main'      => $mainPath,
            'all_paths' => $allPaths
        ];
    }


    protected function dealPopupPayload($request, $existingImage = null)
    {
        if (!Schema::hasColumn('deals', 'popup_on')) {
            return [];
        }
        $image = $existingImage;
        $posted = trim((string) $request->input('existingPopupImage', ''));
        if ($posted !== '' && strpos($posted, 'upload/deals/') === 0) {
            $image = $posted;
        }
        if ($request->hasFile('dealPopupImage')) {
            $saved = $this->storeDealPopupImage($request->file('dealPopupImage'));
            if ($saved) {
                $image = $saved;
            }
        }
        $link = trim((string) $request->input('txtDealPopupLink', ''));
        return [
            'popup_on' => $request->has('chkDealPopup') ? 1 : 0,
            'popup_image' => $image ?: null,
            'popup_link' => $link !== '' ? $link : null,
        ];
    }

    protected function storeDealPopupImage($file)
    {
        $ext = strtolower($file->getClientOriginalExtension() ?: 'jpg');
        if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
            return null;
        }
        $directory = public_path('upload/deals');
        if (!file_exists($directory)) {
            mkdir($directory, 0777, true);
        }
        $name = 'popup-' . hexdec(uniqid()) . '.' . $ext;
        $file->move($directory, $name);
        return 'upload/deals/' . $name;
    }

    protected function createDeals($request, $mainImagePath)
    {
        $commonData = [
            'name' => $request->txtDealName,
            'image' => $mainImagePath,
            'color' => $request->txtcolor ?? null,
            // 'description' => $request->txtDiscription ?? null,
            'store_id' => $request->ddlStoreID ?? null,
            'bank_card_id' => $request->ddlBankCardId ?? null,
            'order_qty' => $request->txtOrderQty ?? 0,
            // 'offer_tittle' => $request->txtOfferTitle ?? null,
            'offer_text' => $request->txtOfferText ?? null,
            'offer_link1' => $request->txtOfferLink1 ?? null,
            'offer_link2' => $request->txtOfferLink2 ?? null,
            'offer_link3' => $request->txtOfferLink3 ?? null,
            'cash_reward' => $request->txtCashReward ?? 0,
            'product_price' => $request->txtDealerPrice ?? 0,
            'cashback' => $request->txtCashback ?? 0,
            'discount' => $request->txtDiscount ?? 0,
            'platform_fee' => $request->txtPlatformFee ?? 0,
            'card_fee' => $request->txtCardFee ?? 0,
            'card_holder_spend' => $request->txtCardHolderSpend,
            'card_holder_recieve' => $request->txtTotalReceive ?? 0,
            'card_holder_earn' => $request->txtCardHolderEarn,
            'maximum_discount' => $request->txtMaximumCount ?? null,
            'company_name' => $request->txtCompanyName ?? null,
            'gst_number' => $request->txtGSTNumber ?? null,
            'gst_message' => $request->txtGSTMessage ?? null,
            'gst_content' => $request->txtGSTContent ?? null,
            'instruction' => $request->txtInstruction,
            'extra_note' => $request->txtExtraNotes,
            'is_pine_lab' => $request->txtPineLabLink ? 1 : 0,
            'pine_lab_url' => $request->txtPineLabLink ?? null,
            'created_by' => Auth::user()->id,
            'updated_at' => now(),
            'created_at' => now(),
        ];
        $commonData = array_merge($commonData, $this->dealPopupPayload($request));

        $dealIds = [];

        // Handle single dealer or multiple dealers
        $dealerIds = is_array($request->ddlDealerId)
            ? $request->ddlDealerId
            : [$request->ddlDealerId];


        foreach ($dealerIds as $dealerId) {
            if ($dealerId) { // Only process if dealerId is not null
                $data = array_merge($commonData, ['dealer_id' => $dealerId]);
                $deal = Deal::create($data);
                $dealIds[] = $deal->id;
            }
        }

        return $dealIds;
    }

    protected function updateDeal($request, $imagePath, $deal)
    {
        $deal->update([
            'name'               => $request->txtDealName,
            'image'              => $imagePath, // Fixed syntax error - removed concatenation
            'color'              => $request->txtcolor ?? null,
            // 'description'        => $request->txtDiscription,
            'store_id'           => $request->ddlStoreID ?? null,
            'dealer_id'          => $request->ddlDealerId,
            'bank_card_id'       => $request->ddlBankCardId ?? null,
            'order_qty'          => $request->txtOrderQty ?? 0,
            // 'offer_tittle'       => $request->txtOfferTitle,
            'offer_text'         => $request->txtOfferText ?? null,
            'offer_link1'        => $request->txtOfferLink1 ?? null,
            'offer_link2'        => $request->txtOfferLink2 ?? null,
            'offer_link3'        => $request->txtOfferLink3 ?? null,
            'cash_reward'        => $request->txtCashReward ?? 0,
            'product_price'      => $request->txtDealerPrice ?? 0,
            'cashback'           => $request->txtCashback ?? 0,
            'discount'           => $request->txtDiscount ?? 0,
            'platform_fee'       => $request->txtPlatformFee ?? 0,
            'card_fee'           => $request->txtCardFee ?? 0,
            'card_holder_spend'  => $request->txtCardHolderSpend ?? 0,
            'card_holder_recieve' => $request->txtTotalReceive ?? 0,
            'card_holder_earn'   => $request->txtCardHolderEarn ?? 0,
            'maximum_discount'   => $request->txtMaximumCount ?? null,
            'company_name'       => $request->txtCompanyName ?? null,
            'gst_number'         => $request->txtGSTNumber ?? null,
            'gst_message'        => $request->txtGSTMessage ?? null,
            'gst_content'        => $request->txtGSTContent ?? null,
            'instruction'        => $request->txtInstruction ?? null,
            'extra_note'         => $request->txtExtraNotes ?? null,
            'is_pine_lab'         => $request->txtPineLabLink ? 1 : 0,
            'pine_lab_url'         => $request->txtPineLabLink ?? null,
            'updated_by'         => Auth::user()->id,
        ]);
        $popup = $this->dealPopupPayload($request, $deal->popup_image ?? null);
        if (!empty($popup)) {
            $deal->update($popup);
        }
    }
    protected function sendFcmNotifications(Request $request, $imagePath)
    {
        $users = User::whereNotNull('fcm_token')->pluck('fcm_token', 'id');

        if ($users->isEmpty()) {
            return;
        }

        $accessToken = $this->getAccessToken();
        $url = "https://fcm.googleapis.com/v1/projects/" . $this->fcmProjectId() . "/messages:send";
        $headers = [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ];

        $chunks = $users->chunk(500);
        $messagePayload = $this->buildAutoDealNotificationMessage($request);
        $title = $messagePayload['title'];
        $body = $messagePayload['body'];

        foreach ($chunks as $chunk) {
            $tokens = $chunk->values()->toArray(); // Extract tokens for this chunk

            // Multicast payload
            $payload = [
                "message" => [
                    "tokens" => $tokens, // Multicast to multiple tokens
                    "notification" => [
                        "title" => $title,
                        "body" => $body,
                    ],
                ],
            ];

            // Send HTTP request
            $ch = curl_init();
            curl_setopt_array($ch, [
                CURLOPT_URL => $url,
                CURLOPT_POST => true,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POSTFIELDS => json_encode($payload),
                CURLOPT_HTTPHEADER => $headers,
            ]);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            // Optionally save notifications to database
            foreach ($chunk as $userId => $fcmToken) {
                Notification::create([
                    'user_id' => $userId,
                    'title' => $title,
                    'content' => $body,
                    'image_url' => $imagePath,
                    'status' => $httpCode == 200 ? 1 : 0,
                ]);
            }
        }
    }

    private function buildAutoDealNotificationMessage(Request $request): array
    {
        $dealName = trim((string) $request->txtDealName) ?: 'New Deal';
        $cardName = null;

        if (!empty($request->ddlBankCardId)) {
            $bankCard = BankCard::find($request->ddlBankCardId);
            if ($bankCard && !empty($bankCard->name)) {
                $cardName = trim((string) $bankCard->name);
            }
        }

        $cardLabel = $cardName ?: 'Credit Card';
        $hasSpecificCard = !empty($cardName);
        $rewardAmount = is_numeric($request->txtCardHolderEarn)
            ? number_format((float) $request->txtCardHolderEarn, 0)
            : null;

        $titles = $hasSpecificCard ? [
            "{$cardLabel} Offer Is Live 🔥",
            "{$cardLabel} Deal Just Dropped 🚀",
            "{$cardLabel} Users, Tap Fast 🎯",
            "Limited {$cardLabel} Deal ⏳",
            "{$cardLabel} Reward Alert 💸",
            "{$cardLabel} Offer Ending Soon ⚡",
            "Hot {$cardLabel} Deal 🎉",
            "{$cardLabel} Special On Mintzer ✨",
        ] : [
            "New Card Offer Is Live 🔥",
            "Tap Fast, New Deal Dropped 🚀",
            "Limited Deal Alert ⏳",
            "Reward Deal Is Here 💸",
            "Hot Offer On Mintzer 🎉",
            "Card Users, Grab This Now ⚡",
            "New Deal Just Landed ✨",
            "Offer Live, Don't Miss Out 👀",
        ];

        $bodies = $hasSpecificCard ? [
            "{$dealName} with {$cardLabel} is live now. Order fast before out of stock ⏳",
            "Use {$cardLabel} on {$dealName}. Tap now and lock this offer 🔥",
            "{$dealName} + {$cardLabel} offer is active. Grab it now 🚀",
            "Best time to use your {$cardLabel} card on {$dealName}. Tap fast ⚡",
            "{$dealName} card offer is open for {$cardLabel}. Don't miss it 👀",
            "Order {$dealName} with {$cardLabel} card now. Limited stock 🎯",
            "{$cardLabel} users: {$dealName} deal is open now. Claim quickly 🎉",
            "Use {$cardLabel} card today on {$dealName}. Offer may close soon ⏰",
        ] : [
            "{$dealName} card offer is live. Order fast before out of stock ⏳",
            "Use your credit card on {$dealName}. Tap now and claim 🔥",
            "{$dealName} offer is active now. Grab it fast 🚀",
            "Best time to order {$dealName}. Tap and check benefits ⚡",
            "{$dealName} deal is live now. Don't miss this chance 👀",
            "Limited stock on {$dealName}. Open app and order now 🎯",
            "{$dealName} reward offer is open. Tap fast 🎉",
            "Card users: {$dealName} is available now. Claim quickly 💥",
        ];

        if ($rewardAmount) {
            $bodies[] = $hasSpecificCard
                ? "{$dealName} with {$cardLabel} can earn you ₹{$rewardAmount}. Tap now 💰"
                : "{$dealName} can earn you ₹{$rewardAmount}. Tap now 💰";
            $bodies[] = $hasSpecificCard
                ? "Use {$cardLabel} on {$dealName} and earn ₹{$rewardAmount} today 🎁"
                : "Use your card on {$dealName} and earn ₹{$rewardAmount} today 🎁";
            $bodies[] = $hasSpecificCard
                ? "Order {$dealName} via {$cardLabel} and get extra ₹{$rewardAmount} reward ✨"
                : "Order {$dealName} and get extra ₹{$rewardAmount} reward ✨";
        }

        return [
            'title' => $titles[array_rand($titles)],
            'body' => $bodies[array_rand($bodies)],
        ];
    }

    private function findDealWithImages($id)
    {
        $deal = Deal::with(['dealImages' => function ($query) {
            $query->withoutGlobalScopes();
        }])->findOrFail($id);

        $deal->unsetRelation('dealImages');
        $deal->load(['dealImages' => function ($query) {
            $query->withoutGlobalScopes()
                ->select('id', 'deal_id', 'image');
        }]);

        return $deal;
    }

    public function dealEdit($id, $is_pine_lab)
    {
        try {
            $deal = $this->findDealWithImages($id);
            $formMode = 'edit';
            $type = (int) $is_pine_lab;

            return view(
                'admin.masters.deals.create',
                $this->loadDealFormData($type, $formMode, $deal)
            );
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            return redirect()->back()->with('error', 'Something went wrong.');
        }
    }

    public function dealCopy($id)
    {
        try {
            $deal = $this->findDealWithImages($id);
            $formMode = 'copy';
            $type = (int) ($deal->is_pine_lab ?? 0);

            return view(
                'admin.masters.deals.create',
                $this->loadDealFormData($type, $formMode, $deal)
            );
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    public function dealChangeStatus($id, $status)
    {
        try {
            $deal = Deal::findorfail($id);
            $deal->update([
                'status' => $status
            ]);
        } catch (Exception $e) {
            $this->Log(__FUNCTION__, "POST", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    function deleteDeal($id)
    {
        DB::beginTransaction();
        try {
            $deal = Deal::findOrFail($id);

            // Delete all associated images from storage + DB
            // $this->deleteDealImages($id);

            // Soft delete the deal (or hard delete if you prefer)
            $deal->delete();

            DB::commit();

            return response()->json([
                'responseData' => [
                    'message' => 'Deal Deleted Successfully',
                    'alert' => 'success'
                ]
            ]);
        } catch (Exception $e) {
            DB::rollback();
            $this->Log(__FUNCTION__, "POST", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);

            return response()->json([
                'responseData' => [
                    'message' => 'Deal could not be deleted',
                    'alert' => 'error'
                ]
            ]);
        }
    }

    private function deleteDealImages($dealId)
    {
        $deal = Deal::withTrashed()->find($dealId);

        if (!$deal) return;

        // 1. Delete main image
        if ($deal->image && file_exists(public_path($deal->image))) {
            @unlink(public_path($deal->image));
        }

        // 2. Delete all additional images from deal_images table + storage
        $additionalImages = DB::table('deal_images')
            ->where('deal_id', $dealId)
            ->pluck('image')
            ->toArray();

        foreach ($additionalImages as $path) {
            if ($path && file_exists(public_path($path))) {
                @unlink(public_path($path));
            }
        }

        // 3. Remove records from deal_images table (hard delete)
        DB::table('deal_images')->where('deal_id', $dealId)->delete();
    }
    public function dealerAddresses(Request $request)
    {
        try {
            $dealer_id = $request->id;
            return view('admin.masters.deals.import-addresses', compact('dealer_id'));
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "GET", $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
        }
    }

    public function bulkImportAddresses(Request $request)
    {
        try {
            $collections = (new FastExcel)->import($request->file('address_file'));
        } catch (\Exception $e) {
            $this->Log(__FUNCTION__, "POST", "File import error: " . $e->getMessage(), Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            return back()->with([
                'message' => 'Invalid file format. Please upload a valid Excel file.',
                'alert-type' => 'error'
            ]);
        }

        $dealer_id = $request->dealer_id;
        $user = User::find($dealer_id);

        if (!$user) {
            $this->Log(__FUNCTION__, "POST", "Dealer with ID $dealer_id not found.", Auth::user()->id, request()->ip(), gethostname(), 0, LogType::Error);
            return back()->with([
                'message' => 'Dealer ID not found.',
                'alert-type' => 'error'
            ]);
        }

        $data = [];

        foreach ($collections as $index => $collection) {
            // Validate required keys
            $requiredKeys = ['display_name', 'address', 'address2', 'landmark', 'city', 'state', 'country', 'pincode'];
            foreach ($requiredKeys as $key) {
                if (!array_key_exists($key, $collection)) {
                    return back()->with([
                        'message' => "Missing column '$key' in row " . ($index + 1),
                        'alert-type' => 'error'
                    ]);
                }
            }

            $data[] = [
                'dealer_id' => $dealer_id,
                'display_name' => $collection['display_name'],
                'address' => $collection['address'],
                'address2' => $collection['address2'],
                'landmark' => $collection['landmark'],
                'city' => $collection['city'],
                'state' => $collection['state'],
                'country' => $collection['country'],
                'pincode' => $collection['pincode'],
                'created_at' => now(),
                'updated_at' => now()
            ];
        }

        // Bulk insert
        DB::table('dealer_addresses')->insert($data);

        return back()->with([
            'message' => 'Addresses Imported Successfully',
            'alert-type' => 'success'
        ]);
    }

    public function sendDealNotification(Request $request)
    {
        $deal = Deal::findOrFail($request->deal_id);
        $isStock = (string) $request->input('kind') === 'stock';

        return $this->pushDealBlast(
            (int) $deal->id,
            (string) ($deal->name ?: 'this deal'),
            !$isStock
        );
    }

    public function sendDealStockAlert(Request $request)
    {
        $deal = Deal::findOrFail($request->deal_id);

        return $this->pushDealBlast(
            (int) $deal->id,
            (string) ($deal->name ?: 'this deal'),
            false
        );
    }

    private function pushDealBlast(int $dealId, string $dealName, bool $isLiveBell)
    {
        try {
            $result = $isLiveBell
                ? \App\Services\V3Push\V3DealLiveService::notifyManualDeal($dealId)
                : \App\Services\V3Push\V3DealLiveService::notifyDealStock($dealId);
        } catch (\Throwable $e) {
            $this->Log(__FUNCTION__, 'POST', $e->getMessage(), Auth::user()->id ?? 0, request()->ip(), gethostname(), 0, LogType::Error);
            return response()->json([
                'success' => false,
                'message' => 'Push failed. Please try again.',
            ], 500);
        }

        $sent = (int) ($result['sent'] ?? 0);
        $targeted = (int) ($result['targeted'] ?? 0);
        $kind = $isLiveBell ? 'Notification' : 'Stock alert';

        if ($sent < 1) {
            $message = $targeted < 1
                ? 'No phones are registered for push yet.'
                : 'Phones are registered, but none accepted this push. Ask them to open the app once with notifications on.';
            return response()->json([
                'success' => false,
                'message' => $message,
                'targeted' => $targeted,
                'sent' => $sent,
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => $kind . ' sent to ' . $sent . ' phone' . ($sent === 1 ? '' : 's') . ' about ' . $dealName . '.',
            'targeted' => $targeted,
            'sent' => $sent,
        ]);
    }

    private function buildDealNotificationMessage(Deal $deal): array
    {
        $dealName = trim((string) $deal->name) ?: 'this deal';
        $cardName = optional($deal->bankCard)->name
            ? trim((string) $deal->bankCard->name)
            : null;
        $cardLabel = $cardName ?: 'Credit Card';
        $hasSpecificCard = !empty($cardName);

        $rewardAmount = is_numeric($deal->card_holder_earn)
            ? number_format((float) $deal->card_holder_earn, 0)
            : null;

        $titles = $hasSpecificCard ? [
            "{$cardLabel} Offer Live 🔥",
            "{$cardLabel} Deal Alert 🚀",
            "{$cardLabel} Users Tap Now 🎯",
            "{$cardLabel} Special Drop ✨",
            "Limited {$cardLabel} Offer ⏳",
            "{$cardLabel} Reward Deal 💸",
            "{$cardLabel} Offer Ending Soon ⚡",
            "{$cardLabel} Card Deal Is Live 🎉",
        ] : [
            'Credit Card Deal Live 🔥',
            'Tap Fast For Card Offer 🚀',
            'New Card Offer 🎉',
            'Mintzer Deal Drop ✨',
            'Limited Card Deal ⏳',
            'Reward Deal Is Live 💸',
            'Offer Ending Soon ⚡',
            'Card Users Tap Now 🎯',
        ];

        $bodies = $hasSpecificCard ? [
            "{$dealName} with {$cardLabel} is live. Order fast before out of stock ⏳",
            "Use {$cardLabel} on {$dealName}. Tap now and lock this offer 🔥",
            "{$dealName} + {$cardLabel} offer is active. Grab it now 🚀",
            "Best time to use your {$cardLabel} card on {$dealName}. Tap fast ⚡",
            "{$dealName} card offer is live for {$cardLabel}. Don't miss it 👀",
            "Order {$dealName} with {$cardLabel} card now. Limited stock 🎯",
            "{$cardLabel} users: {$dealName} deal is open now. Tap to claim 🎉",
            "{$dealName} is trending with {$cardLabel} offer. Open app now 💥",
            "Use {$cardLabel} card today on {$dealName}. Deal may close soon ⏰",
            "{$dealName} + {$cardLabel} benefit is live now. Tap and order 🛍️",
        ] : [
            "{$dealName} card offer is live. Order fast before out of stock ⏳",
            "Use your credit card on {$dealName}. Tap now and claim 🔥",
            "{$dealName} offer is active now. Grab it fast 🚀",
            "Best time to order {$dealName}. Tap and check card benefits ⚡",
            "{$dealName} deal is live now. Don't miss this chance 👀",
            "Limited stock on {$dealName}. Open app and order now 🎯",
            "{$dealName} reward offer is open. Tap fast 🎉",
            "Card users: {$dealName} is now available. Claim now 💥",
        ];

        if ($rewardAmount) {
            $bodies[] = $hasSpecificCard
                ? "{$dealName} with {$cardLabel} can earn you ₹{$rewardAmount}. Tap now 💰"
                : "{$dealName} can earn you ₹{$rewardAmount}. Tap now 💰";
            $bodies[] = $hasSpecificCard
                ? "Use {$cardLabel} on {$dealName} and earn ₹{$rewardAmount} today 🎁"
                : "Use your card on {$dealName} and earn ₹{$rewardAmount} today 🎁";
            $bodies[] = $hasSpecificCard
                ? "Order {$dealName} via {$cardLabel} and get extra ₹{$rewardAmount} reward ✨"
                : "Order {$dealName} and get extra ₹{$rewardAmount} reward ✨";
        }

        return [
            'title' => $titles[array_rand($titles)],
            'body' => $bodies[array_rand($bodies)],
        ];
    }

    public function searchDeals(Request $request)
    {
        $term = $request->query('term', '');
        $perPage = $request->query('per_page', 5);

        $deals = Deal::with(['dealer', 'store'])
            ->whereNull('deleted_at')
            ->where('name', 'like', '%' . $term . '%')
            ->orderBy('id', 'DESC')
            ->paginate($perPage);

        $result = [];

        foreach ($deals as $deal) {
            $additional = DB::table('deal_images')
                ->where('deal_id', $deal->id)
                ->pluck('image')
                ->toArray();

            $additional_images = [];
            foreach ($additional as $path) {
                $additional_images[] = [
                    'url'  => $path ? asset($path) : null,
                    'path' => $path,
                ];
            }

            $result[] = [
                'id' => $deal->id,
                'name' => $deal->name,
                'store_id' => $deal->store_id,
                'store_name' => $deal->store->name ?? null,
                'dealer_id' => $deal->dealer_id,
                'dealer_name' => $deal->dealer->name ?? $deal->dealer->display_name ?? null,
                'bank_card_id' => $deal->bank_card_id,
                'image_url' => $deal->image ? asset($deal->image) : null,
                'image_path' => $deal->image,
                'additional_images' => $additional_images,
                'color' => $deal->color,
                'order_qty' => $deal->order_qty,
                'offer_tittle' => $deal->offer_tittle,
                'offer_text' => $deal->offer_text,
                'offer_link1' => $deal->offer_link1,
                'offer_link2' => $deal->offer_link2,
                'offer_link3' => $deal->offer_link3,
                'cash_reward' => $deal->cash_reward,
                'product_price' => $deal->product_price,
                'cashback' => $deal->cashback,
                'discount' => $deal->discount,
                'card_holder_spend' => $deal->card_holder_spend,
                'card_holder_recieve' => $deal->card_holder_recieve,
                'card_holder_earn' => $deal->card_holder_earn,
                'maximum_discount' => $deal->maximum_discount,
                'company_name' => $deal->company_name,
                'gst_number' => $deal->gst_number,
                'gst_content' => $deal->gst_content,
                'gst_message' => $deal->gst_message,
                'instruction' => $deal->instruction,
                'extra_note' => $deal->extra_note,
                'is_pine_lab' => $deal->is_pine_lab,
                'pine_lab_url' => $deal->pine_lab_url,
            ];
        }

        return response()->json($result);
    }
}
