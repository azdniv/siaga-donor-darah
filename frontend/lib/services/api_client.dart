import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Error dari API atau jaringan, dengan pesan yang siap ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  final int? status;

  ApiException(this.message, {this.status});

  @override
  String toString() => message;
}

/// Klien HTTP tunggal untuk semua panggilan ke API.
/// Token JWT diisi lewat [token] dan otomatis dikirim di setiap permintaan.
class ApiClient {
  final http.Client _client = http.Client();

  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _send('PUT', path, body);

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', path, body);

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 15));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
          'Server tidak merespons. Pastikan API sudah dijalankan.');
    } catch (_) {
      throw ApiException(
          'Tidak bisa terhubung ke server. Cek alamat API dan koneksimu.');
    }

    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = (data is Map && data['error'] is String)
        ? data['error'] as String
        : 'Terjadi kesalahan (${response.statusCode}).';
    throw ApiException(message, status: response.statusCode);
  }
}
