<?php


use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('cron-jobs', [App\Http\Controllers\CronjobController::class, 'cronJobs']);

Route::fallback(function () {
    return view('404');
});

/*==================================================ADMIN ROUTES==============================================================*/
//Login
Route::get('/', [App\Http\Controllers\Login\LoginController::class, 'loginForm'])->name('login');
Route::get('forgot-password', [App\Http\Controllers\Login\LoginController::class, 'forgotPassword'])->name('forgot-password');
Route::get('reset-password', [App\Http\Controllers\Login\LoginController::class, 'resetPassword'])->name('reset-password');
Route::post('change-password', [App\Http\Controllers\Login\LoginController::class, 'changePassword'])->name('change-password');
Route::post('admin/login', [App\Http\Controllers\Login\LoginController::class, 'login'])->name('admin.login');

// Route::post('razorpay/webhook', [App\Http\Controllers\Login\LoginController::class, 'handleWebhook'])->name('admin.login');

Route::group(['middleware' => ['auth', 'prevent-back-history']], function () {
    //Logout
    Route::get('admin/logout', [App\Http\Controllers\Login\LoginController::class, 'logout'])->name('admin.logout');

    //Business Configuration
    Route::get('configuration', [App\Http\Controllers\Admin\Settings\SettingsController::class, 'configuration'])->name('configuration');
    Route::post('updatesettings', [App\Http\Controllers\Admin\Settings\SettingsController::class, 'updatesettings'])->name('update-bussiness-settings');

    //Referral settings
    Route::get('/referralsettings', [App\Http\Controllers\Admin\Settings\RefferalSettingsController::class, 'referralSettings'])->name('referral-points');
    Route::post('/add/referralpoints', [App\Http\Controllers\Admin\Settings\RefferalSettingsController::class, 'addReferralPoints'])->name('add.referralsettings');

    //Dashboard
    Route::get('/dashboard', [App\Http\Controllers\Admin\Dashboard\DashboardController::class, 'dashboard'])->name('dashboard');
    Route::get('api-dashboard', [App\Http\Controllers\Admin\Dashboard\ApiDashboardController::class, 'index'])->name('api.dashboard');
    Route::get('logs', [App\Http\Controllers\Admin\Dashboard\DashboardController::class, 'activityLog'])->name('activityLog');
    Route::get('log-data', [App\Http\Controllers\Admin\Dashboard\DashboardController::class, 'logData'])->name('logData');

    //Profile
    Route::get('/profile', [App\Http\Controllers\Admin\Dashboard\DashboardController::class, 'Profile'])->name('profile');
    Route::post('/profile/update', [App\Http\Controllers\Admin\Dashboard\DashboardController::class, 'ProfileUpdate'])->name('profile.update');
    Route::get('/unauthorized', [App\Http\Controllers\Admin\Dashboard\DashboardController::class, 'unauthorized'])->name('unauthorized');
    Route::get('/404', [App\Http\Controllers\Admin\Dashboard\DashboardController::class, 'pageNotFound'])->name('404');

    //TDS Report
    Route::get('/tds-report', [App\Http\Controllers\Admin\Report\TDSReportController::class, 'tdsReport'])->name('tds.report');
    Route::get('/tds-report-data', [App\Http\Controllers\Admin\Report\TDSReportController::class, 'getTDSReportData'])->name('tds.data');
    
    //customer
    Route::get('customers', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'customers'])->name('customers');
    Route::get('user-funnel', [App\Http\Controllers\Admin\Customer\UserFunnelController::class, 'index'])->name('user.funnel');
    Route::get('top-orderers', [App\Http\Controllers\Admin\Customer\UserFunnelController::class, 'topOrderers'])->name('top.orderers');
    Route::get('customer/info/{id}', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'customerInfo'])->name('customer.info');
    Route::get('customer/order-data', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'getCustomerDeliveredOrders'])->name('customer.delivered-orders-data');
    Route::get('customers-data', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'get_customers_data'])->name('get-customers-data');
    Route::get('get-user-data', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'get_customers_detail'])->name('get-customers-detail');
    Route::post('customer-status-change/{id}/{status}', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'customerChangeStatus'])->name('customer.status.update');
    Route::get('wallet', [App\Http\Controllers\Admin\Customer\WalletController::class, 'wallet'])->name('wallet');

    //Master
    //Subjects
    Route::get('subjects', [App\Http\Controllers\Admin\Masters\SubjectController::class, 'subjects'])->name('subjects');
    Route::get('subjects-data', [App\Http\Controllers\Admin\Masters\SubjectController::class, 'subjectsData'])->name('subjects.data');
    Route::get('subjects/toggle-status/{id}', [App\Http\Controllers\Admin\Masters\SubjectController::class, 'toggleStatus'])->name('subjects.toggle');
    Route::post('subjects/store', [App\Http\Controllers\Admin\Masters\SubjectController::class, 'store'])->name('subjects.store');
    Route::get('subjects/delete/{id}', [App\Http\Controllers\Admin\Masters\SubjectController::class, 'destroy'])->name('subjects.destroy');

    //tickets
    Route::get('tickets', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'tickets'])->name('tickets');
    Route::get('tickets-data', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'getTicketsdata'])->name('get.ticket.data');
    Route::get('tickets/notifications', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'notifications'])->name('tickets.notifications');
    Route::post('tickets/mark-notified', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'markNotified'])->name('tickets.mark-notified');
    Route::get('ticket-status-update/{id}', [App\Http\Controllers\Admin\Customer\CustomerController::class, 'statusUpdate'])->name('update.ticket.status');

    //Orders
    Route::get('orders/{status?}', [App\Http\Controllers\Admin\Order\OrderController::class, 'orderList'])->name('order.list');
    Route::get('order-data', [App\Http\Controllers\Admin\Order\OrderController::class, 'getOrderData'])->name('order.data');
    Route::get('pinelab-orders', [App\Http\Controllers\Admin\Order\OrderController::class, 'pinelabeOrderList'])->name('pinelab.order.list');
    Route::get('pinelab-order-data', [App\Http\Controllers\Admin\Order\OrderController::class, 'getPinelabeOrderData'])->name('pinelab.order.data');
    Route::get('get-bank-data', [App\Http\Controllers\Admin\Order\OrderController::class, 'getBankData'])->name('get.bank.data');
    Route::get('tracking-send-notify/{orderId}', [App\Http\Controllers\Admin\Order\OrderController::class, 'trackingSendNotify'])->name('tracking.send.notify');
    Route::get('otp-send-notify/{orderId}', [App\Http\Controllers\Admin\Order\OrderController::class, 'otpSendNotify'])->name('otp.send.notify');
    Route::get('verification-status-update/{id}', [App\Http\Controllers\Admin\Order\OrderController::class, 'verificationStatusUpdate'])->name('verification.status.update');
    Route::get('order-status-update/{id}', [App\Http\Controllers\Admin\Order\OrderController::class, 'orderStatusUpdate'])->name('order.status.update');
    Route::post('order-cancel', [App\Http\Controllers\Admin\Order\OrderController::class, 'orderCancel'])->name('order.cancel');
    Route::get('payment-status-update/{id}', [App\Http\Controllers\Admin\Order\OrderController::class, 'paymentStatusUpdate'])->name('payment.status.update');
    Route::post('update-order-field', [App\Http\Controllers\Admin\Order\OrderController::class, 'updateOrderField'])->name('update.order.field');
    //Payout
    Route::post('approve-payout', [App\Http\Controllers\Admin\Order\OrderController::class, 'approvePayout'])->name('approve.payout');

    //invoice
    Route::get('invoices', [App\Http\Controllers\Admin\Order\InvoiceController::class, 'invoices'])->name('invoices');
    Route::get('invoice-data', [App\Http\Controllers\Admin\Order\InvoiceController::class, 'getInvoiceData'])->name('invoice.data');

    //Store
    Route::get('stores', [App\Http\Controllers\Admin\Masters\StoreController::class, 'store'])->name('store');
    Route::get('store-data', [App\Http\Controllers\Admin\Masters\StoreController::class, 'getStoreData'])->name('store.data');
    Route::post('create/store', [App\Http\Controllers\Admin\Masters\StoreController::class, 'createStore'])->name('create.store');
    Route::get('store/delete/{id}', [App\Http\Controllers\Admin\Masters\StoreController::class, 'deleteStore'])->name('store.delete');

    //Banks
    Route::get('banks', [App\Http\Controllers\Admin\Masters\BankController::class, 'banks'])->name('banks');
    Route::post('create/bank', [App\Http\Controllers\Admin\Masters\BankController::class, 'createBank'])->name('create.bank');
    Route::get('bank-data', [App\Http\Controllers\Admin\Masters\BankController::class, 'getBankData'])->name('bank.data');
    Route::get('bank/delete/{id}', [App\Http\Controllers\Admin\Masters\BankController::class, 'deleteBank'])->name('bank.delete');

    //Bank cards 
    Route::get('cards', [App\Http\Controllers\Admin\Masters\BankCardController::class, 'cards'])->name('card.list');
    Route::post('create/card', [App\Http\Controllers\Admin\Masters\BankCardController::class, 'createBankCard'])->name('create.card');
    Route::get('card-data', [App\Http\Controllers\Admin\Masters\BankCardController::class, 'getCardData'])->name('card.data');
    Route::get('card/delete/{id}', [App\Http\Controllers\Admin\Masters\BankCardController::class, 'deleteCard'])->name('card.delete');

    //banners
    Route::get('banners', [App\Http\Controllers\Admin\Settings\BannerController::class, 'banners'])->name('banners');
    Route::get('banner-data', [App\Http\Controllers\Admin\Settings\BannerController::class, 'getBannerData'])->name('banner.data');
    Route::post('banner-store', [App\Http\Controllers\Admin\Settings\BannerController::class, 'store'])->name('banner-store');
    Route::get('banner/delete/{id}', [App\Http\Controllers\Admin\Settings\BannerController::class, 'deletebanner'])->name('banner.delete');
    Route::post('banner-status-update/{id}/{status}', [App\Http\Controllers\Admin\Settings\BannerController::class, 'changestatus'])->name('banner.status.update');

    //Master
    //Mode
    Route::get('mode', [App\Http\Controllers\Admin\Masters\GeneralSettingsController::class, 'modeSettings'])->name('mode.settings');

    //Notification
    Route::get('notification', [App\Http\Controllers\Admin\Masters\GeneralSettingsController::class, 'notification'])->name('notification');
    Route::post('send-notification', [App\Http\Controllers\Admin\Masters\GeneralSettingsController::class, 'send_notification'])->name('send-notification');
    Route::post('notification-estimate', [App\Http\Controllers\Admin\Masters\GeneralSettingsController::class, 'notificationEstimate'])->name('notification.estimate');
    Route::post('notification-send-test', [App\Http\Controllers\Admin\Masters\GeneralSettingsController::class, 'sendTestNotification'])->name('notification.send-test');

    //deals
    Route::get('deals', [App\Http\Controllers\Admin\Masters\DealsController::class, 'deals'])->name('deals');
    Route::get('deals-data/{type?}', [App\Http\Controllers\Admin\Masters\DealsController::class, 'getDealData'])->name('getDealData');
    Route::get('deals/search', [App\Http\Controllers\Admin\Masters\DealsController::class, 'searchDeals'])->name('deals.search');
    Route::get('deal-create/{type?}', [App\Http\Controllers\Admin\Masters\DealsController::class, 'dealCreate'])->name('deal-create');
    Route::get('get/dealers', [App\Http\Controllers\Admin\Masters\DealsController::class, 'getDealers']);
    Route::post('deal-store', [App\Http\Controllers\Admin\Masters\DealsController::class, 'store'])->name('deal-store');
    Route::get('deal-edit/{id}/{is_pine_lab}', [App\Http\Controllers\Admin\Masters\DealsController::class, 'dealEdit'])->name('deal-edit');
    Route::post('deal-status-change/{id}/{status}', [App\Http\Controllers\Admin\Masters\DealsController::class, 'dealChangeStatus'])->name('banner.status.update');
    Route::get('delete-deal/{id}', [App\Http\Controllers\Admin\Masters\DealsController::class, 'deleteDeal'])->name('delete-deal');
    Route::get('deal-copy/{id}', [App\Http\Controllers\Admin\Masters\DealsController::class, 'dealCopy'])->name('deal-copy');
    Route::post('/send-deal-notification', [App\Http\Controllers\Admin\Masters\DealsController::class, 'sendDealNotification'])->name('sendDealNotification');
    Route::post('/send-deal-stock-alert', [App\Http\Controllers\Admin\Masters\DealsController::class, 'sendDealStockAlert'])->name('sendDealStockAlert');



    //dealer-addresses
    // Route::get('dealer-addresses', [App\Http\Controllers\Admin\Masters\DealsController::class, 'dealerAddresses'])->name('dealer-addresses');
    Route::post('bulk-import', [App\Http\Controllers\Admin\Masters\DealsController::class, 'bulkImportAddresses'])->name('bulk-import');

    //Role
    Route::get('roles', [App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'rolesList'])->name('roles.list');
    Route::post('createroles', [App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'createRoles'])->name('createroles');
    Route::get('getrolesdata', [App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'getRolesData'])->name('getrolesdata');


    //permission
    Route::get('user-role-permission', [App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'rolePermission'])->name('role.permission');
    Route::get('permission/data', [App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'getPermissionData'])->name('getPermissionData');
    Route::get('getpermission/{id}', [App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'getPermissionById'])->name('getPermissionData');
    Route::get('/get-menu', [App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'getMenu'])->name('get.menu');
    Route::post('createpermission', [App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'createPermission'])->name('createPermission');

    //users
    Route::get('/users', [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'users'])->name('users');
    Route::post('create-user', [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'createsUser'])->name('create-user');
    Route::get('/listmenus/{id}', [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'listMenus'])->name('listmenus');
    Route::get('/userpermission/data', [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'getUserPermissionData'])->name('userpermission-data');
    Route::get('/getuserpermission/{id}', [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'getUserPermissionById'])->name('getUserPermission');
    Route::get('delete-user/{id}', [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'deleteUser'])->name('delete-user');
    Route::get('dealer/address/{id}', [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'dealerAdress'])->name('dealerAdress');
    Route::get(
        'dealer/address/data/{id}',
        [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'getDealerAdress']
    )->name('getDealerAdress');
    Route::post('/dealer/address/delete-bulk', [\App\Http\Controllers\Admin\Masters\RolePermissionController::class, 'deleteBulk'])->name('deleteBulk');
    
    require base_path('routes/staff-admin-web.php');

    //Users Feedback
    Route::get('feedback', [\App\Http\Controllers\Admin\Masters\FeedbackController::class, 'feedback'])->name('feedback');
    Route::get('getFeedbackData', [\App\Http\Controllers\Admin\Masters\FeedbackController::class, 'getFeedbackData'])->name('getFeedbackData');

    //Withdraw Requests
    Route::get('withdraw-request', [\App\Http\Controllers\Admin\Masters\WithdrawRequestController::class, 'withdrawRequest'])->name('withdraw-request');
    Route::get('withdrawRequestData', [\App\Http\Controllers\Admin\Masters\WithdrawRequestController::class, 'withdrawRequestData'])->name('withdrawRequestData');
    Route::get('get-bank-info', [\App\Http\Controllers\Admin\Masters\WithdrawRequestController::class, 'getBankInfo'])->name('get.bank.info');
    Route::post('approve-request', [\App\Http\Controllers\Admin\Masters\WithdrawRequestController::class, 'approveRequest'])->name('approve.request');
});
