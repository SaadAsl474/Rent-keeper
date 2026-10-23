import 'dart:convert';
import 'dart:io';

class RentKeeperApiClient {
  final String baseUrl;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  RentKeeperApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://10.0.2.2:8080/api/v1'; // Default 10.0.2.2 for Android emulator

  Future<Map<String, dynamic>> getDashboard() async {
    return _get('/dashboard');
  }

  Future<List<dynamic>> getItems({String? category, String? status, String? query}) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (status != null) params['status'] = status;
    if (query != null) params['query'] = query;

    final queryString = params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    final res = await _get('/items$queryString');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> createChallan(Map<String, dynamic> data) async {
    final res = await _post('/challans', data);
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> returnChallan(String id, {String? notes, double? damageFee}) async {
    final res = await _post('/challans/$id/return', {
      if (notes != null) 'notes': notes,
      if (damageFee != null) 'damageFee': damageFee,
    });
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> triggerWhatsAppAlert(String challanId) async {
    final res = await _post('/challans/$challanId/whatsapp-alert', {});
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> pushSyncQueue(List<Map<String, dynamic>> mutations) async {
    final res = await _post('/sync/push', {'mutations': mutations});
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  Future<Map<String, dynamic>> pullDeltaChanges({String? since}) async {
    final qs = since != null ? '?since=${Uri.encodeComponent(since)}' : '';
    final res = await _get('/sync/pull$qs');
    return Map<String, dynamic>.from(res['data'] as Map? ?? {});
  }

  // HTTP Helper Methods
  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = await _client.getUrl(uri);
    req.headers.set('Accept', 'application/json');

    final res = await req.close();
    final body = await utf8.decoder.bind(res).join();
    if (res.statusCode >= 400) {
      throw HttpException('API Error ${res.statusCode}: $body', uri: uri);
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = await _client.postUrl(uri);
    req.headers.set('Content-Type', 'application/json');
    req.headers.set('Accept', 'application/json');
    req.write(jsonEncode(payload));

    final res = await req.close();
    final body = await utf8.decoder.bind(res).join();
    if (res.statusCode >= 400) {
      throw HttpException('API Error ${res.statusCode}: $body', uri: uri);
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
