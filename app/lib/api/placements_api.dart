import 'dart:convert';

import 'package:http/http.dart' as http;

import '../live/live_deal_adapter.dart';
import '../models/deal.dart';
import '../models/delivery_address.dart';
import 'api_config.dart';
import 'auth_api.dart';

/// Live Accept + Order ID writes — Sanctum.
class PlacementsApi {
  PlacementsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = PlacementsApi();

  /// `GET /getDealDetail` — includes dealer `address` for Accept.
  Future<DealDetailLive> fetchDealDetail({
    required int dealId,
    int? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getDealDetailPath}').replace(
      queryParameters: {
        'deal_id': '$dealId',
        if (userId != null) 'user_id': '$userId',
      },
    );
    final res = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 25));
    final body = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(_message(body, 'Couldn’t load deal'), statusCode: res.statusCode);
    }
    final data = body['data'];
    if (data is! Map) {
      throw AuthApiException('Deal detail missing');
    }
    final map = Map<String, dynamic>.from(data);
    DeliveryAddress? address;
    final addr = map['address'];
    if (addr is Map) {
      try {
        address = DeliveryAddress.fromJson(Map<String, dynamic>.from(addr));
        if (address.addressId <= 0) address = null;
      } catch (_) {
        address = null;
      }
    }
    final selling = _asInt(map['selling_price']) ?? 0;
    final productUrl = _str(map['offer_link1']) ?? _str(map['pine_lab_url']);
    final offerText = _str(map['instruction']) ?? _str(map['extra_note']) ?? _str(map['offer_content']);
    // Same panel money fields as list — maps Product price / You pay / cashback / TDS / earn.
    final priced = liveDealFromJson(map);
    return DealDetailLive(
      dealId: _asInt(map['id']) ?? dealId,
      sellingPrice: selling,
      address: address,
      productUrl: productUrl,
      offerText: offerText,
      acceptOrderId: _asInt(map['accept_order_id']),
      gstNumber: _str(map['gst_number']),
      isPineLab: _asInt(map['is_pine_lab']) == 1 || (_str(map['pine_lab_url']) ?? '').isNotEmpty,
      pricedDeal: priced,
    );
  }

  /// `POST /accept-order`
  Future<AcceptOrderResult> acceptOrder({
    required String authToken,
    required int dealId,
    required int orderAmount,
    int? addressId,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final body = <String, dynamic>{
      'deal_id': '$dealId',
      'order_amount': '$orderAmount',
      if (addressId != null) 'address_id': '$addressId',
    };
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.acceptOrderPath}'),
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
      throw AuthApiException(_message(decoded, 'Couldn’t accept deal'), statusCode: res.statusCode);
    }
    final acceptId = _asInt(decoded['accept_order_id']);
    if (acceptId == null) {
      throw AuthApiException('Accept succeeded but no order id returned');
    }
    DateTime? endsAt;
    final rawEnd = _str(decoded['reserved_date_time']);
    if (rawEnd != null) {
      endsAt = DateTime.tryParse(rawEnd.replaceFirst(' ', 'T'));
    }
    return AcceptOrderResult(
      acceptOrderId: acceptId,
      reservedEndsAt: endsAt,
      message: _str(decoded['message']),
    );
  }

  /// `POST /update-order-id`
  Future<void> updateOrderId({
    required String authToken,
    required int acceptOrderId,
    required String storeOrderId,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateOrderIdPath}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'accept_order_id': '$acceptOrderId',
            'store_order_id': storeOrderId.trim(),
          }),
        )
        .timeout(const Duration(seconds: 30));
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(_message(decoded, 'Couldn’t save Order ID'), statusCode: res.statusCode);
    }
  }

  /// `POST /cancel-order`
  Future<void> cancelOrder({
    required String authToken,
    required int acceptOrderId,
    String? reason,
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
            if (reason != null && reason.isNotEmpty) 'reason': reason,
          }),
        )
        .timeout(const Duration(seconds: 25));
    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(_message(decoded, 'Couldn’t cancel'), statusCode: res.statusCode);
    }
  }

  /// `POST /auto-delete-order` — timer expiry with no store Order ID.
  Future<void> autoDeleteOrder({
    required String authToken,
    required int acceptOrderId,
  }) async {
    if (authToken.isEmpty) return;
    try {
      await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.autoDeleteOrderPath}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'accept_order_id': '$acceptOrderId'}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
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

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString().trim());
  }
}

class DealDetailLive {
  const DealDetailLive({
    required this.dealId,
    required this.sellingPrice,
    this.address,
    this.productUrl,
    this.offerText,
    this.acceptOrderId,
    this.gstNumber,
    this.isPineLab = false,
    this.pricedDeal,
  });

  final int dealId;
  final int sellingPrice;
  final DeliveryAddress? address;
  final String? productUrl;
  final String? offerText;
  final int? acceptOrderId;
  final String? gstNumber;
  final bool isPineLab;
  /// Money breakdown from panel fields (for Payment summary).
  final MockDeal? pricedDeal;
}

class AcceptOrderResult {
  const AcceptOrderResult({
    required this.acceptOrderId,
    this.reservedEndsAt,
    this.message,
  });

  final int acceptOrderId;
  final DateTime? reservedEndsAt;
  final String? message;
}
