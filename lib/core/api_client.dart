import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(Map<String, dynamic> payload) async {
    try {
      final response = await _client
          .post(
            Uri.parse(AppConfig.apiUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException();
        }
        data = decoded;
      } catch (_) {
        throw ApiException('Server returned an invalid response.', response.statusCode);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException((data['error'] ?? 'Request failed.').toString(), response.statusCode);
      }
      if (data['ok'] == false) {
        throw ApiException((data['error'] ?? 'Request failed.').toString(), response.statusCode);
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Unable to connect to Khalid Networks server. Check internet and retry.');
    }
  }
}
