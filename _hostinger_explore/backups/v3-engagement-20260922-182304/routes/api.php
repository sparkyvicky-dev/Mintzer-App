<?php

use App\Http\Controllers\API\Auth\AuthController;
use App\Http\Controllers\API\Auth\SocialAuthController;
use App\Http\Controllers\API\BannerController;
use App\Http\Controllers\API\ConfigController;
use App\Http\Controllers\API\Deal\bankController;
use App\Http\Controllers\API\Deal\dealController;
use App\Http\Controllers\API\Deal\storeController;
use App\Http\Controllers\API\FeedbackController;
use App\Http\Controllers\API\Order\OrderController;
use App\Http\Controllers\API\ProfileController;
use App\Http\Controllers\API\ReferralController;
use App\Http\Controllers\API\TicketController;
use App\Http\Controllers\API\WalletController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;


/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/
//Configuration
Route::get('business-configuration', [ConfigController::class, 'business_confiuration']);
Route::get('get-languages', [ConfigController::class, 'getLanguages']);

// Register & Login
Route::post('sendotp', [AuthController::class, 'sendOTP']);
Route::post('verify-otp', [AuthController::class, 'verifyOTP']);

// Social - Register & Login
Route::post('social-register', [SocialAuthController::class, 'social_register']);
Route::post('social-update', [SocialAuthController::class, 'social_update']);
Route::post('social-login', [SocialAuthController::class, 'social_login']);

// Deals
// Route::get('getDealdata/{store_id?}/{search?}', [dealController::class, 'getDealdata']);
Route::get('getDealdata', [dealController::class, 'getDealdata']);
Route::get('getDealDetail', [dealController::class, 'getDealDetail']);

//Logistics
Route::get('getLogistics', [dealController::class, 'getlogistics']);

// Store & BankCards
Route::get('getStoreAndCardData', [storeController::class, 'getStoreAndCardData']);

Route::get('getBanks', [bankController::class, 'getBanks']);
// Route::get('getBankCards/{id?}', [bankController::class, 'getBankCards']);
Route::get('getbanners', [BannerController::class, 'getbanners']);


Route::group(['middleware' => ['auth:sanctum', 'check.user.status']], function () {
    Route::post('logout', [AuthController::class, 'logout']);
    Route::post('deleteAccount', [AuthController::class, 'deleteAccount']);
    // Route::post('register', [ProfileController::class, 'register']);
    Route::post('pan-verify', [ProfileController::class, 'panVerify']);
    Route::post('fcm-update', [AuthController::class, 'fcmTokenUpdate']);
    Route::get('getuserprofile', [ProfileController::class, 'getUserProfile']);
    Route::post('updateProfile', [ProfileController::class, 'updateProfile']);
    Route::post('updateProfileImage', [ProfileController::class, 'updateProfileImage']);
    Route::post('updateBankDetail', [ProfileController::class, 'updateBankDetail']);
    Route::get('getBankDetail', [ProfileController::class, 'getBankDetail']);
    Route::post('updateAddress', [ProfileController::class, 'updateAddress']);
    Route::get('getAddress', [ProfileController::class, 'getAddress']);

    //User Setting
    Route::post('update-settings', [ProfileController::class, 'updateSettings']);

    //Refferal Settings
    Route::get('/getReferralSettings', [ReferralController::class, 'getReferralSettings']);
    Route::get('/getReferralHistories', [ReferralController::class, 'getReferralHistories']);

    //Notification
    Route::get('getnotifications', [ProfileController::class, 'getnotifications']);
    Route::post('updatenotifications', [ProfileController::class, 'updatenotifications']);
    
    //Tickets
    Route::post('addnewticket', [TicketController::class, 'addnewtickets']);
    Route::post('addticketreply', [TicketController::class, 'addTicketReply']);
    Route::post('closeticket', [TicketController::class, 'closeTicket']);
    Route::get('getticket', [TicketController::class, 'getTicket']);
    Route::get('getsubjects', [TicketController::class, 'getSubjects']);
    //Orders
    Route::post('accept-order', [OrderController::class, 'acceptOrder']);
    Route::post('cancel-order', [OrderController::class, 'cancelOrder']);
    Route::get('cancel-reasons', [OrderController::class, 'cancelReasons']);
    Route::post('auto-delete-order', [OrderController::class, 'autoDeleteOrder']);
    Route::post('update-order-id', [OrderController::class, 'updateOrderId']);
    Route::post('update-tracking-id', [OrderController::class, 'updateTrackingId']);
    Route::post('update-outfordelivery', [OrderController::class, 'updateOutForDelivery']);
    Route::post('update-invoice-delivery', [OrderController::class, 'updateInvoiceDelivery']);

    //Payout
    Route::post('payout-request', [OrderController::class, 'payoutRequest']);
    Route::get('payout-history', [OrderController::class, 'payoutHistory']);
    
    //My Orders
    Route::post('getOrderList', [OrderController::class, 'getOrderList']);
    Route::post('getPinelabOrderList', [OrderController::class, 'getPinelabOrderList']);
    Route::get('getPayoutStage', [OrderController::class, 'getPayoutStage']);

    //Wallet
    Route::post('withdraw-request', [WalletController::class, 'withdrawRequest']);

    //Feedback
    Route::post('submit-feedback', [FeedbackController::class, 'submitFeedback']);

    // Route::get('/deleteAccount', [AuthController::class, 'deleteAccount']);
});

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
require base_path('routes/admin-app.php');