import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trankhoi/config/config_url.dart';

class ApiClient {
  String get baseUrl => ConfigUrl.baseUrl;

  Future<Map<String, String>> _buildHeaders(Map<String, String>? customHeaders) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    String fullUrl = '$baseUrl$cleanEndpoint';
    Uri uri = Uri.parse(fullUrl);

    if (queryParams != null && queryParams.isNotEmpty) {
      Map<String, String> stringParams = {};
      queryParams.forEach((key, value) {
        if (value != null) {
          stringParams[key] = value.toString();
        }
      });
      uri = uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  Future<http.Response> get(String endpoint, {Map<String, dynamic>? queryParams, Map<String, String>? headers}) async {
    final h = await _buildHeaders(headers);
    final uri = _buildUri(endpoint, queryParams);
    return http.get(uri, headers: h);
  }

  Future<http.Response> post(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final h = await _buildHeaders(headers);
    final uri = _buildUri(endpoint);
    return http.post(
      uri,
      headers: h,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final h = await _buildHeaders(headers);
    final uri = _buildUri(endpoint);
    return http.put(
      uri,
      headers: h,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    final h = await _buildHeaders(headers);
    final uri = _buildUri(endpoint);
    return http.delete(uri, headers: h);
  }
}
