import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path').replace(queryParameters: query);
    final res = await _client.get(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getJsonList(String path) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final res = await _client.get(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    if (data is List) return data;
    throw Exception('Expected List but got ${data.runtimeType}');
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final res = await _client.delete(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body);
  }
}
