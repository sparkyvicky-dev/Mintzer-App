import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_api.dart';

class TicketSubject {
  const TicketSubject({required this.id, required this.name});

  final int id;
  final String name;
}

/// Live support tickets — Sanctum `getticket` · `getsubjects` · `addnewticket`.
class TicketsApi {
  TicketsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final instance = TicketsApi();

  Map<String, String> _headers(String authToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  Future<List<TicketSubject>> fetchSubjects({required String authToken}) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');

    final res = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getSubjectsPath}'),
          headers: _headers(authToken),
        )
        .timeout(const Duration(seconds: 25));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t load ticket topics'),
        statusCode: res.statusCode,
      );
    }

    final data = decoded['data'];
    if (data is! List) return [];

    final out = <TicketSubject>[];
    for (final item in data) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = _asInt(m['id']);
      final name = (m['name'] ?? '').toString().trim();
      if (id == null || name.isEmpty) continue;
      out.add(TicketSubject(id: id, name: name));
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> fetchTickets({
    required String authToken,
    int pageSize = 100,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getTicketPath}').replace(
      queryParameters: {'pageSize': '$pageSize'},
    );

    final res = await _client
        .get(uri, headers: _headers(authToken))
        .timeout(const Duration(seconds: 30));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t load tickets'),
        statusCode: res.statusCode,
      );
    }

    final data = decoded['data'];
    if (data is! List) return [];

    final out = <Map<String, dynamic>>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        out.add(item);
      } else if (item is Map) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }

  Future<void> addTicket({
    required String authToken,
    required int subjectId,
    required String message,
    String? orderRef,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final msg = message.trim();
    if (msg.isEmpty) throw AuthApiException('Message is required');

    final body = <String, dynamic>{
      'subject_id': subjectId,
      'message': msg,
    };
    final ref = orderRef?.trim();
    if (ref != null && ref.isNotEmpty && ref != '—') {
      body['order_ref'] = ref;
    }

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addNewTicketPath}'),
          headers: _headers(authToken),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t send ticket'),
        statusCode: res.statusCode,
      );
    }
  }

  Future<void> addReply({
    required String authToken,
    required int ticketId,
    required String message,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');
    final msg = message.trim();
    if (msg.isEmpty) throw AuthApiException('Message is required');

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.addTicketReplyPath}'),
          headers: _headers(authToken),
          body: jsonEncode({
            'ticket_id': ticketId,
            'message': msg,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t send reply'),
        statusCode: res.statusCode,
      );
    }
  }

  Future<void> closeTicket({
    required String authToken,
    required int ticketId,
  }) async {
    if (authToken.isEmpty) throw AuthApiException('Not signed in');

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.closeTicketPath}'),
          headers: _headers(authToken),
          body: jsonEncode({'ticket_id': ticketId}),
        )
        .timeout(const Duration(seconds: 25));

    final decoded = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300 || decoded['status'] == false) {
      throw AuthApiException(
        _message(decoded, 'Couldn’t close ticket'),
        statusCode: res.statusCode,
      );
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString().trim());
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
