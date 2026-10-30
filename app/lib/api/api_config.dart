/// Live Mintzer Laravel `newapp` — never Pakka Bill / sparkymobiles.
class ApiConfig {
  ApiConfig._();

  static const baseUrl = 'https://app.mintzer.in/api';
  static const sendOtpPath = '/sendotp';
  static const verifyOtpPath = '/verify-otp';
  /// Register device FCM token (Sanctum). Existing live endpoint — additive use only.
  static const fcmUpdatePath = '/fcm-update';
  static const v3PushRegisterPath = '/v3/push/register';
  static const v3PushPrefsPath = '/v3/push/prefs';
  static const v3PushTestSelfPath = '/v3/push/test-self';
  static const v3PushDealViewPath = '/v3/push/deal-view';
  static const v3PushCancelViewFollowupsPath = '/v3/push/cancel-view-followups';
  static const getOrderListPath = '/getOrderList';
  static const getBankDetailPath = '/getBankDetail';
  static const updateBankDetailPath = '/updateBankDetail';
  static const getUserProfilePath = '/getuserprofile';
  static const updateProfilePath = '/updateProfile';
  static const updateProfileImagePath = '/updateProfileImage';
  static const logoutPath = '/logout';
  static const deleteAccountPath = '/deleteAccount';
  static const getDealdataPath = '/getDealdata';
  static const getDealDetailPath = '/getDealDetail';
  static const getBannersPath = '/getbanners';
  static const homePopupSeenPath = '/home-popup-seen';
  static const getBanksPath = '/getBanks';
  static const partnerCardClickPath = '/partner-card-click';
  static const getReferralSettingsPath = '/getReferralSettings';
  static const changePhonePath = '/change-phone';
  static const verifyChangePhonePath = '/verify-change-phone';
  static const acceptOrderPath = '/accept-order';
  static const updateOrderIdPath = '/update-order-id';
  static const updateTrackingIdPath = '/update-tracking-id';
  static const updateOutForDeliveryPath = '/update-outfordelivery';
  static const updateInvoiceDeliveryPath = '/update-invoice-delivery';
  static const cancelOrderPath = '/cancel-order';
  static const cancelReasonsPath = '/cancel-reasons';
  static const autoDeleteOrderPath = '/auto-delete-order';
  static const getLogisticsPath = '/getLogistics';
  static const addNewTicketPath = '/addnewticket';
  static const addTicketReplyPath = '/addticketreply';
  static const closeTicketPath = '/closeticket';
  static const getTicketPath = '/getticket';
  static const getSubjectsPath = '/getsubjects';
  static const getNotificationsPath = '/getnotifications';
  static const updateNotificationsPath = '/updatenotifications';
  static const panVerifyPath = '/pan-verify';
  static const ifscLookupPath = '/ifsc-lookup';
  static const businessConfigurationPath = '/business-configuration';
}
