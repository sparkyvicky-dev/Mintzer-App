import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SendOtpResult {
  const SendOtpResult({required this.isNewUser, this.message});

  final bool isNewUser;
  final String? message;
}

class VerifyOtpResult {
  const VerifyOtpResult({
    required this.token,
    required this.userId,
    required this.isNewUser,
    this.message,
  });

  final String token;
  final int userId;
  final bool isNewUser;
  final String? message;
}

/// Mintzer OTP against live `newapp` only (`app.mintzer.in`).
class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final instance = AuthApi();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<SendOtpResult> sendOtp(String mobile10) async {
    final phone = _digits10(mobile10);
    final res = await _client
        .post(
          _uri(ApiConfig.sendOtpPath),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'mobile': phone}),
        )
        .timeout(const Duration(seconds: 25));

    final body = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['status'] != false) {
      // Live API may echo OTP in JSON — never surface it in UI.
      return SendOtpResult(
        isNewUser: body['is_new_user'] == true,
        message: body['message']?.toString(),
      );
    }
    throw AuthApiException(
      _errorMessage(body, fallback: 'Couldn’t send OTP. Try again.'),
      statusCode: res.statusCode,
    );
  }

  Future<VerifyOtpResult> verifyOtp({required String mobile10, required String otp}) async {
    final phone = _digits10(mobile10);
    final code = otp.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      throw AuthApiException('Enter the 6-digit OTP');
    }

    final res = await _client
        .post(
          _uri(ApiConfig.verifyOtpPath),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'mobile': phone, 'otp': code}),
        )
        .timeout(const Duration(seconds: 25));

    final body = _decode(res.body);
    final token = body['token']?.toString();
    final userIdRaw = body['user_id'];
    final userId = userIdRaw is int
        ? userIdRaw
        : int.tryParse(userIdRaw?.toString() ?? '') ?? 0;

    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        body['status'] != false &&
        token != null &&
        token.isNotEmpty &&
        userId > 0) {
      return VerifyOtpResult(
        token: token,
        userId: userId,
        isNewUser: body['is_new_user'] == true,
        message: body['message']?.toString(),
      );
    }
    throw AuthApiException(
      _errorMessage(body, fallback: 'Incorrect OTP. Try again.'),
      statusCode: res.statusCode,
    );
  }

  /// POST /fcm-update — stores token on `users.fcm_token` for this Sanctum user.
  Future<void> updateFcmToken({required String authToken, required String fcmToken}) async {
    if (authToken.isEmpty || fcmToken.isEmpty) return;

    final res = await _client
        .post(
          _uri(ApiConfig.fcmUpdatePath),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'fcm_token': fcmToken}),
        )
        .timeout(const Duration(seconds: 20));

    final body = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['status'] != false) {
      return;
    }
    throw AuthApiException(
      _errorMessage(body, fallback: 'Couldn’t register push token.'),
      statusCode: res.statusCode,
    );
  }

  /// POST /v3/push/register — Flutter V3 device table (parallel to V2).
  Future<void> registerV3PushDevice({required String authToken, required String fcmToken}) async {
    if (authToken.isEmpty || fcmToken.isEmpty) return;

    final res = await _client
        .post(
          _uri(ApiConfig.v3PushRegisterPath),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'fcm_token': fcmToken, 'platform': 'android'}),
        )
        .timeout(const Duration(seconds: 20));

    final body = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['status'] != false) {
      return;
    }
    throw AuthApiException(
      _errorMessage(body, fallback: 'Couldn’t register V3 push device.'),
      statusCode: res.statusCode,
    );
  }

  /// POST /v3/push/prefs — master + deal/order/payment tiers.
  Future<void> saveV3PushPrefs({
    required String authToken,
    required bool master,
    required bool deals,
    required bool orders,
    required bool payments,
  }) async {
    if (authToken.isEmpty) return;

    final res = await _client
        .post(
          _uri(ApiConfig.v3PushPrefsPath),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'master': master,
            'deals': deals,
            'orders': orders,
            'payments': payments,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['status'] != false) {
      return;
    }
    throw AuthApiException(
      _errorMessage(body, fallback: 'Couldn’t save notification prefs.'),
      statusCode: res.statusCode,
    );
  }

  /// POST /v3/push/deal-view — schedule tight follow-ups after qualifying dwell.
  Future<void> reportDealView({
    required String authToken,
    required int dealId,
    required int dwellSeconds,
  }) async {
    if (authToken.isEmpty || dealId < 1 || dwellSeconds < 1) return;
    try {
      await _client
          .post(
            _uri(ApiConfig.v3PushDealViewPath),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'deal_id': dealId,
              'dwell_seconds': dwellSeconds,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // best-effort — never block UI
    }
  }

  /// POST /v3/push/cancel-view-followups — after Accept.
  Future<void> cancelDealViewFollowups({
    required String authToken,
    int? dealId,
  }) async {
    if (authToken.isEmpty) return;
    try {
      await _client
          .post(
            _uri(ApiConfig.v3PushCancelViewFollowupsPath),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              if (dealId != null) 'deal_id': dealId,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  static String _digits10(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12 && d.startsWith('91')) return d.substring(2);
    if (d.length != 10) {
      throw AuthApiException('Enter a valid 10-digit mobile number');
    }
    return d;
  }

  static Map<String, dynamic> _decode(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      final v = jsonDecode(raw);
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
    } catch (_) {}
    return {};
  }

  static String _errorMessage(Map<String, dynamic> body, {required String fallback}) {
    final m = body['message'];
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m != null && m.toString().trim().isNotEmpty) return m.toString().trim();
    return fallback;
  }
}
