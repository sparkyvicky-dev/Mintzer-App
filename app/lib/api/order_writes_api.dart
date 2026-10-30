import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_api.dart';
import '../util/couriers.dart';

/// Live order progress writes — Sanctum (`update-tracking-id`, OFD/OTP, …).
class OrderWritesApi {
  OrderWritesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = OrderWritesApi();

  /// Maps UI courier → `delivery_partner_id` (+ `logistic_name` when Others path).
  static ({String partnerId, String? logisticName}) partnerForCourier(String courier) {
    return MintzerCouriers.partnerForApi(courier);
  }

  /// `POST /update-tracking-id`
  Future<void> updateTrackingId({
    required String authToken,
    required int acceptOrderId,
    required String trackingId,
    required String courier,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final partner = partnerForCourier(courier);
    final body = <String, dynamic>{
      'accept_order_id': '$acceptOrderId',
      'order_tracking_id': trackingId.trim(),
      'delivery_partner_id': partner.partnerId,
      if (partner.logisticName != null) 'logistic_name': partner.logisticName,
    };
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateTrackingIdPath}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(_message(decoded, 'Couldn’t save tracking'), statusCode: res.statusCode);
    }
  }

  /// `POST /update-outfordelivery` — OTP + last-4 of delivery mobile.
  Future<void> updateOutForDelivery({
    required String authToken,
    required int acceptOrderId,
    required String deliveryOtp,
    required String mobileLast4,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateOutForDeliveryPath}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'accept_order_id': '$acceptOrderId',
            'order_delivery_otp': deliveryOtp.trim(),
            'mobile_number': mobileLast4.trim(),
          }),
        )
        .timeout(const Duration(seconds: 30));
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(_message(decoded, 'Couldn’t save delivery OTP'), statusCode: res.statusCode);
    }
  }

  /// `POST /update-invoice-delivery` — multipart `account_order_pdf` (image or PDF).
  Future<void> updateInvoiceDelivery({
    required String authToken,
    required int acceptOrderId,
    required File file,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final name = file.path.split(RegExp(r'[\\/]')).last;
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateInvoiceDeliveryPath}'),
    );
    req.headers['Accept'] = 'application/json';
    req.headers['Authorization'] = 'Bearer $authToken';
    req.fields['accept_order_id'] = '$acceptOrderId';
    req.files.add(await http.MultipartFile.fromPath(
      'account_order_pdf',
      file.path,
      filename: name.isEmpty ? 'invoice.jpg' : name,
    ));
    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(_message(decoded, 'Couldn’t upload invoice'), statusCode: res.statusCode);
    }
  }

  /// `GET /cancel-reasons`
  Future<List<String>> fetchCancelReasons({required String authToken}) async {
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cancelReasonsPath}'),
            headers: {
              'Accept': 'application/json',
              if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(const Duration(seconds: 15));
      final decoded = _decode(res.body);
      final data = decoded['data'];
      if (data is! List) return const [];
      final out = <String>[];
      for (final item in data) {
        if (item is Map) {
          final r = item['reason'] ?? item['content'];
          if (r != null && '$r'.trim().isNotEmpty) out.add('$r'.trim());
        } else if (item is String && item.trim().isNotEmpty) {
          out.add(item.trim());
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// `POST /cancel-order` — reason required so admin gets Cancelled (not soft-delete).
  Future<void> cancelOrder({
    required String authToken,
    required int acceptOrderId,
    required String reason,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cancelOrderPath}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'accept_order_id': '$acceptOrderId',
            'reason': reason.trim(),
          }),
        )
        .timeout(const Duration(seconds: 25));
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(_message(decoded, 'Couldn’t cancel'), statusCode: res.statusCode);
    }
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

  static String _message(Map<String, dynamic> body, String fallback) {
    final m = body['message'];
    if (m is String && m.trim().isNotEmpty) return m.trim();
    return fallback;
  }
}
