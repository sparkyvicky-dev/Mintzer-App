<?php

namespace App\Services\AdminApp;

use App\Models\Deal;
use App\Models\DealImage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class DealStoreService
{
    public function validatePayload(Request $request, bool $isEdit = false): array
    {
        $pine = $request->boolean('pineLab') || filled($request->input('pineLabLink'));

        $rules = [
            'name' => 'required|string|max:255',
            'color' => $pine ? 'nullable|string|max:255' : 'required|string|max:255',
            'store_id' => $pine ? 'nullable|integer' : 'required|integer',
            'dealer_id' => 'required|integer',
            'card_id' => $pine ? 'nullable|integer' : 'required|integer',
            'orderQty' => $pine ? 'nullable|integer' : 'required|integer',
            'spend' => 'required|numeric',
            'earn' => 'required|numeric',
            'receive' => 'required|numeric',
            'offerLink' => $pine ? 'nullable|url' : 'required|url',
            'productPrice' => $pine ? 'nullable|numeric' : 'required|numeric',
            'offerText' => $pine ? 'nullable|string' : 'required|string',
            'discount' => $pine ? 'nullable|numeric' : 'required|numeric',
            'cashback' => $pine ? 'nullable|numeric' : 'required|numeric',
            'cashReward' => $pine ? 'nullable|numeric' : 'required|numeric',
            'instruction' => 'required|string',
            'extraNotes' => 'required|string',
            'gstNumber' => 'nullable|string|max:255',
            'companyName' => 'nullable|string|max:255',
            'gstContent' => 'nullable|string',
            'pineLabLink' => $pine ? 'required|url' : 'nullable|url',
            'goLive' => 'nullable|boolean',
            'is_copy' => 'nullable|boolean',
            'reuse_image_paths' => 'nullable|array',
            'reuse_image_paths.*' => 'string',
            'deal_images' => 'nullable|array',
            'deal_images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:4096',
        ];

        $validator = Validator::make($request->all(), $rules);

        $validator->after(function ($v) use ($request, $isEdit, $pine) {
            $hasUpload = $request->hasFile('deal_images') && count($request->file('deal_images', [])) > 0;
            $hasReuse = is_array($request->input('reuse_image_paths')) && count($request->input('reuse_image_paths')) > 0;

            if (!$isEdit && !$request->boolean('is_copy') && !$hasUpload && !$hasReuse && !$pine) {
                $v->errors()->add('deal_images', 'At least one image is required (upload or reuse_image_paths).');
            }
        });

        if ($validator->fails()) {
            throw new ValidationException($validator);
        }

        return $validator->validated();
    }

    public function create(Request $request): Deal
    {
        $this->validatePayload($request, false);
        $images = $this->resolveImages($request);

        return DB::transaction(function () use ($request, $images) {
            $deal = Deal::create($this->mapAttributes($request, $images['main']));
            $this->syncExtraImages($deal->id, $images['all']);

            return $deal->fresh(['store', 'dealer', 'bankCard']);
        });
    }

    public function update(Deal $deal, Request $request): Deal
    {
        $this->validatePayload($request, true);
        $images = $this->resolveImages($request, $deal);

        return DB::transaction(function () use ($deal, $request, $images) {
            $deal->update($this->mapAttributes($request, $images['main'], $deal));
            DB::table('deal_images')->where('deal_id', $deal->id)->delete();
            $this->syncExtraImages($deal->id, array_values(array_filter($images['all'], fn ($p) => $p !== $images['main'])));

            return $deal->fresh(['store', 'dealer', 'bankCard']);
        });
    }

    public function copyFrom(Deal $source, Request $request): Deal
    {
        $payload = $request->merge([
            'is_copy' => true,
            'reuse_image_paths' => $this->imagePathsForDeal($source),
            'goLive' => $request->boolean('goLive', false),
        ]);

        return $this->create($payload);
    }

    private function mapAttributes(Request $request, ?string $mainImage, ?Deal $existing = null): array
    {
        $pine = $request->boolean('pineLab') || filled($request->input('pineLabLink'));

        return [
            'name' => $request->input('name'),
            'image' => $mainImage ?? $existing?->image,
            'color' => $request->input('color'),
            'store_id' => $pine ? null : $request->input('store_id'),
            'dealer_id' => $request->input('dealer_id'),
            'bank_card_id' => $pine ? null : $request->input('card_id'),
            'order_qty' => $request->input('orderQty', 0),
            'offer_text' => $request->input('offerText'),
            'offer_link1' => $request->input('offerLink'),
            'cash_reward' => $request->input('cashReward', 0),
            'product_price' => $request->input('productPrice', 0),
            'cashback' => $request->input('cashback', 0),
            'discount' => $request->input('discount', 0),
            'card_holder_spend' => $request->input('spend'),
            'card_holder_recieve' => $request->input('receive'),
            'card_holder_earn' => $request->input('earn'),
            'company_name' => $request->input('companyName'),
            'gst_number' => $request->input('gstNumber'),
            'gst_content' => $request->input('gstContent'),
            'instruction' => $request->input('instruction'),
            'extra_note' => $request->input('extraNotes'),
            'is_pine_lab' => $pine ? 1 : 0,
            'pine_lab_url' => $request->input('pineLabLink'),
            'status' => $request->boolean('goLive', true) ? 1 : 0,
            'created_by' => $existing?->created_by ?? Auth::id(),
            'updated_by' => Auth::id(),
        ];
    }

    private function resolveImages(Request $request, ?Deal $existing = null): array
    {
        $paths = array_values(array_filter((array) $request->input('reuse_image_paths', [])));
        $main = $paths[0] ?? $existing?->image;

        foreach ($request->file('deal_images', []) as $file) {
            $directory = public_path('upload/deals');
            if (!is_dir($directory)) {
                mkdir($directory, 0777, true);
            }
            $fileName = dechex(random_int(0, PHP_INT_MAX)) . '.webp';
            $relative = 'upload/deals/' . $fileName;
            $file->move($directory, $fileName);
            $paths[] = $relative;
            if (!$main) {
                $main = $relative;
            }
        }

        if (!$main && $existing?->image) {
            $main = $existing->image;
            $paths = array_merge([$main], $paths);
        }

        $paths = array_values(array_unique(array_filter($paths)));

        return [
            'main' => $main,
            'all' => $paths,
        ];
    }

    private function syncExtraImages(int $dealId, array $paths): void
    {
        foreach ($paths as $path) {
            DealImage::create([
                'deal_id' => $dealId,
                'image' => $path,
            ]);
        }
    }

    public function imagePathsForDeal(Deal $deal): array
    {
        $extra = DB::table('deal_images')->where('deal_id', $deal->id)->pluck('image')->toArray();
        $all = array_filter(array_merge([$deal->image], $extra));

        return array_values(array_unique($all));
    }
}
