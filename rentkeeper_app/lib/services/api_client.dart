import 'dart:convert';
import 'package:http/http.dart' as http;

/// REST API client for the RentKeeper backend server.
///
/// All methods return parsed JSON. Throws on network errors or non-2xx
/// responses so callers can fall back to offline storage.
class ApiClient {
  String baseUrl;

  ApiClient({required this.baseUrl});

  // --- Dashboard ---
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(Uri.parse('$baseUrl/dashboard'));
    _checkStatus(res);
    return _data(res);
  }

  // --- Shop ---
  Future<Map<String, dynamic>> getShop() async {
    final res = await http.get(Uri.parse('$baseUrl/shop'));
    _checkStatus(res);
    return _data(res);
  }

  Future<void> updateShop(Map<String, dynamic> shop) async {
    final res = await http.put(
      Uri.parse('$baseUrl/shop'),
      headers: _headers,
      body: jsonEncode(shop),
    );
    _checkStatus(res);
  }

  // --- Items ---
  Future<List<Map<String, dynamic>>> getItems({String? category, String? status, String? query}) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (status != null) params['status'] = status;
    if (query != null && query.isNotEmpty) params['query'] = query;

    final qs = params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    final res = await http.get(Uri.parse('$baseUrl/items$qs'));
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> item) async {
    final res = await http.post(
      Uri.parse('$baseUrl/items'),
      headers: _headers,
      body: jsonEncode(item),
    );
    _checkStatus(res);
    return _data(res);
  }

  Future<Map<String, dynamic>> updateItem(String id, Map<String, dynamic> item) async {
    final res = await http.put(
      Uri.parse('$baseUrl/items/$id'),
      headers: _headers,
      body: jsonEncode(item),
    );
    _checkStatus(res);
    return _data(res);
  }

  Future<void> deleteItem(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/items/$id'));
    _checkStatus(res);
  }

  // --- Customers ---
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final res = await http.get(Uri.parse('$baseUrl/customers'));
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customer) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: _headers,
      body: jsonEncode(customer),
    );
    _checkStatus(res);
    return _data(res);
  }

  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> customer) async {
    final res = await http.put(
      Uri.parse('$baseUrl/customers/$id'),
      headers: _headers,
      body: jsonEncode(customer),
    );
    _checkStatus(res);
    return _data(res);
  }

  Future<void> deleteCustomer(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/customers/$id'));
    _checkStatus(res);
  }

  // --- Challans ---
  Future<List<Map<String, dynamic>>> getChallans() async {
    final res = await http.get(Uri.parse('$baseUrl/challans'));
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createChallan(Map<String, dynamic> challan) async {
    final res = await http.post(
      Uri.parse('$baseUrl/challans'),
      headers: _headers,
      body: jsonEncode(challan),
    );
    _checkStatus(res);
    return _data(res);
  }

  Future<Map<String, dynamic>> returnChallan(String id, {double lateFee = 0.0, double damageFee = 0.0, String notes = ''}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/challans/$id/return'),
      headers: _headers,
      body: jsonEncode({'lateFee': lateFee, 'damageFee': damageFee, 'notes': notes}),
    );
    _checkStatus(res);
    return _data(res);
  }

  Future<Map<String, dynamic>> recordPayment(String id, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/challans/$id/payment'),
      headers: _headers,
      body: jsonEncode({'amount': amount}),
    );
    _checkStatus(res);
    return _data(res);
  }

  // --- Sync ---
  Future<Map<String, dynamic>> syncPull() async {
    final res = await http.get(Uri.parse('$baseUrl/sync/pull'));
    _checkStatus(res);
    return _data(res);
  }

  Future<Map<String, dynamic>> syncPush(List<Map<String, dynamic>> mutations) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sync/push'),
      headers: _headers,
      body: jsonEncode({'mutations': mutations}),
    );
    _checkStatus(res);
    return _data(res);
  }

  // --- Helpers ---
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception('API Error ${res.statusCode}: ${res.body}');
    }
  }

  Map<String, dynamic> _data(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['data'] as Map? ?? {});
  }
}
