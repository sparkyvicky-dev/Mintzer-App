import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../mock/session.dart';
import '../mock/session_store.dart';
import '../util/format.dart';
import 'api_config.dart';
import 'auth_api.dart';

/// Live profile — Sanctum `getuserprofile` · bank · logout · delete · photo.
class ProfileApi {
  ProfileApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = ProfileApi();

  Map<String, String> _jsonHeaders(String authToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  /// `GET /getuserprofile` — name · PAN · photo · phone into [MockSession].
  Future<bool> refreshProfileIntoSession({required String authToken}) async {
    if (authToken.isEmpty) return false;
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUserProfilePath}'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      final decoded = _decode(res.body);
      final data = decoded['data'];
      if (data is! Map) return false;
      final map = Map<String, dynamic>.from(data);

      final mobile = _str(map['mobile'])?.replaceAll(RegExp(r'\D'), '');
      if (mobile != null && mobile.length >= 10) {
        MockSession.phoneDigits = mobile.substring(mobile.length - 10);
      }

      final name = _str(map['User_name']) ?? _str(map['user_name']) ?? _str(map['display_name']);
      if (name != null && name.isNotEmpty) MockSession.displayName = name;

      final ref =
          _str(map['referral_code']) ?? _str(map['reffereal_code']) ?? _str(map['invite_code']);
      if (ref != null && ref.isNotEmpty) MockSession.referralCode = ref;

      final pic = _str(map['profile_picture']);
      if (pic != null && pic.isNotEmpty) {
        MockSession.profilePictureUrl = pic.startsWith('http')
            ? pic
            : 'https://app.mintzer.in/${pic.replaceFirst(RegExp(r'^/'), '')}';
        MockSession.useLetterAvatar = false;
      }

      final pan = map['pan_details'];
      if (pan is Map) {
        final pm = Map<String, dynamic>.from(pan);
        final verified = pm['pan_verified'] == true;
        final panName = _str(pm['pan_name']);
        final panNum = _str(pm['pan']);
        if (verified && panName != null && panNum != null) {
          MockSession.kycDone = true;
          MockSession.panName = personName(panName);
          MockSession.panNumber = panNum;
        } else {
          MockSession.kycDone = false;
          MockSession.panName = '';
          MockSession.panNumber = '';
        }
      }

      if (map['is_bank_account_added'] == true) {
        MockSession.payoutDone = true;
      }

      final uid = map['user_id'];
      if (uid is int) {
        MockSession.userId = uid;
      } else if (uid != null) {
        MockSession.userId = int.tryParse(uid.toString());
      }

      await SessionStore.save();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// `GET /getBankDetail` — fills [MockSession] payout bank when present.
  Future<bool> refreshBankIntoSession({required String authToken}) async {
    if (authToken.isEmpty) return false;
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBankDetailPath}'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      final decoded = _decode(res.body);
      final data = decoded['data'];
      if (data is! Map) return false;
      final map = Map<String, dynamic>.from(data);

      final bank = _str(map['bank_name']);
      final acct = _str(map['account_number'])?.replaceAll(RegExp(r'\s'), '');
      final ifsc = _str(map['ifsc_code']) ?? _str(map['bank_ifsc']) ?? _str(map['ifsc']);
      final upi = _str(map['upi_address']);

      final savedUpi = (upi != null && upi.isNotEmpty) ? upi : '';
      final savedBank = (bank != null && bank.isNotEmpty) ? bank : '';
      final savedAcct = (acct != null && acct.isNotEmpty) ? acct : '';
      if (savedBank.isEmpty && savedAcct.isEmpty && savedUpi.isEmpty) return false;

      MockSession.bankName = savedBank;
      MockSession.bankAccount = savedAcct;
      MockSession.bankIfsc = (ifsc != null && ifsc.isNotEmpty) ? ifsc.trim().toUpperCase() : '';
      MockSession.upiId = savedUpi;
      MockSession.payoutDone = (savedBank.isNotEmpty && savedAcct.isNotEmpty) || savedUpi.isNotEmpty;
      await SessionStore.save();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateDisplayName({
    required String authToken,
    required String name,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw AuthApiException('Enter your name');

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfilePath}'),
          headers: _jsonHeaders(authToken),
          body: jsonEncode({'name': trimmed}),
        )
        .timeout(const Duration(seconds: 25));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t update name'),
        statusCode: res.statusCode,
      );
    }
    MockSession.displayName = trimmed;
    await SessionStore.save();
  }

  /// `POST /updateBankDetail` — payout account for Mintzer → user.
  Future<void> updateBankDetail({
    required String authToken,
    required String fullName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
    String upi = '',
    String payoutMethod = 'bank',
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final holder = fullName.trim();
    final bank = bankName.trim();
    final acct = accountNumber.replaceAll(RegExp(r'\s'), '');
    final code = ifsc.trim().toUpperCase().replaceAll(' ', '');
    final upiId = upi.trim();
    final method = payoutMethod == 'upi' ? 'upi' : 'bank';
    if (holder.isEmpty) throw AuthApiException('PAN name is required for payout');
    if (method == 'upi') {
      if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$').hasMatch(upiId)) {
        throw AuthApiException('Enter a valid UPI ID');
      }
    } else {
      if (bank.isEmpty) throw AuthApiException('Bank name is required');
      if (acct.isEmpty) throw AuthApiException('Account number is required');
      if (code.isEmpty) throw AuthApiException('IFSC is required');
    }

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateBankDetailPath}'),
          headers: _jsonHeaders(authToken),
          body: jsonEncode({
            'full_name': holder,
            'bank_name': method == 'upi' ? '' : bank,
            'bank_account_number': method == 'upi' ? '' : acct,
            'bank_ifsc': method == 'upi' ? '' : code,
            'upi_address': method == 'upi' ? upiId : '',
            'payout_method': method,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t save payout account'),
        statusCode: res.statusCode,
      );
    }

    MockSession.savePayout(
      bankName: method == 'upi' ? '' : bank,
      account: method == 'upi' ? '' : acct,
      ifsc: method == 'upi' ? '' : code,
      upi: method == 'upi' ? upiId : '',
    );
  }

  /// `POST /pan-verify` — typed PAN; server resolves the name via Cashfree.
  /// Returns verified name on success.
  Future<String> panVerify({
    required String authToken,
    required String pan,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final cleaned = pan.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(cleaned)) {
      throw AuthApiException('PAN format is invalid');
    }

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.panVerifyPath}'),
          headers: _jsonHeaders(authToken),
          body: jsonEncode({'pan': cleaned}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'PAN could not be verified'),
        statusCode: res.statusCode,
      );
    }

    final name = _str(decoded['pan_name']);
    if (name == null) {
      throw AuthApiException('PAN verified, but name was missing');
    }
    return name;
  }

  /// `POST /ifsc-lookup` — bank and branch from API Sathi. Cached on the server.
  Future<({String bank, String? branch})> lookupIfsc({
    required String authToken,
    required String ifsc,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final code = ifsc.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(code)) {
      throw AuthApiException('Enter a valid IFSC code');
    }
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ifscLookupPath}'),
          headers: _jsonHeaders(authToken),
          body: jsonEncode({'ifsc': code}),
        )
        .timeout(const Duration(seconds: 15));
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t find this IFSC. Check and try again.'),
        statusCode: res.statusCode,
      );
    }
    final bank = _str(decoded['bank']);
    if (bank == null) {
      throw AuthApiException('Couldn’t find this IFSC. Check and try again.');
    }
    return (bank: bank, branch: _str(decoded['branch']));
  }

  /// `GET /getReferralSettings` — invite code (+ share copy fields unused for now).
  Future<String?> refreshReferralIntoSession({required String authToken}) async {
    if (authToken.isEmpty) return null;
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getReferralSettingsPath}'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final decoded = _decode(res.body);
      final data = decoded['data'];
      if (data is! Map) return null;
      final map = Map<String, dynamic>.from(data);
      final code = _str(map['reffereal_code']) ?? _str(map['referral_code']);
      if (code == null) return null;
      MockSession.referralCode = code;
      await SessionStore.save();
      return code;
    } catch (_) {
      return null;
    }
  }

  /// `POST /change-phone` — OTP to the new number (does not create a second account).
  Future<void> changePhoneSendOtp({
    required String authToken,
    required String mobile,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final d = mobile.replaceAll(RegExp(r'\D'), '');
    if (d.length != 10) throw AuthApiException('Enter a valid 10-digit number');

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePhonePath}'),
          headers: _jsonHeaders(authToken),
          body: jsonEncode({'mobile': d}),
        )
        .timeout(const Duration(seconds: 30));
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t send OTP'),
        statusCode: res.statusCode,
      );
    }
  }

  /// `POST /verify-change-phone` — confirms OTP and updates account mobile.
  Future<void> changePhoneVerify({
    required String authToken,
    required String mobile,
    required String otp,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final d = mobile.replaceAll(RegExp(r'\D'), '');
    final code = otp.trim();
    if (d.length != 10) throw AuthApiException('Enter a valid 10-digit number');
    if (code.length < 4) throw AuthApiException('Enter the OTP');

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyChangePhonePath}'),
          headers: _jsonHeaders(authToken),
          body: jsonEncode({'mobile': d, 'otp': code}),
        )
        .timeout(const Duration(seconds: 30));
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t update phone'),
        statusCode: res.statusCode,
      );
    }
    MockSession.phoneDigits = d;
    await SessionStore.save();
  }

  Future<String?> updateProfileImage({
    required String authToken,
    required File file,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfileImagePath}');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $authToken';
    req.headers['Accept'] = 'application/json';
    req.files.add(await http.MultipartFile.fromPath('profile_image', file.path));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t upload photo'),
        statusCode: res.statusCode,
      );
    }

    final path = _str(decoded['profile_picture']);
    if (path == null) return null;
    final url = path.startsWith('http')
        ? path
        : 'https://app.mintzer.in/${path.replaceFirst(RegExp(r'^/'), '')}';
    MockSession.profilePictureUrl = url;
    MockSession.useLetterAvatar = false;
    await SessionStore.save();
    return url;
  }

  Future<void> logout({required String authToken}) async {
    if (authToken.isEmpty) return;
    try {
      await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutPath}'),
            headers: _jsonHeaders(authToken),
            body: '{}',
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Local clear still happens.
    }
  }

  /// Returns null on success. Returns server message when blocked / failed.
  Future<String?> deleteAccount({required String authToken}) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deleteAccountPath}'),
          headers: _jsonHeaders(authToken),
          body: '{}',
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decode(res.body);
    if (decoded['status'] == false) {
      return _message(decoded, 'Couldn’t delete account');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return _message(decoded, 'Couldn’t delete account');
    }
    return null;
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

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static String _message(Map<String, dynamic> body, String fallback) {
    final m = body['message'];
    if (m is String && m.trim().isNotEmpty) return m.trim();
    return fallback;
  }
}
