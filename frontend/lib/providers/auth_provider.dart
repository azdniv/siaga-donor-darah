import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';

enum AuthStatus { loading, loggedOut, loggedIn }

/// Mengelola login, register, logout, dan penyimpanan token JWT.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  static const _tokenKey = 'jwt_token';

  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus status = AuthStatus.loading;
  AppUser? user;

  /// Dipanggil sekali saat aplikasi dibuka: pulihkan sesi dari token tersimpan.
  Future<void> init() async {
    try {
      final saved = await _storage.read(key: _tokenKey);
      if (saved == null) {
        _setLoggedOut();
        return;
      }
      _api.token = saved;
      final data = await _api.get('/auth/me');
      user = AppUser.fromJson(data as Map<String, dynamic>);
      status = AuthStatus.loggedIn;
      notifyListeners();
    } on ApiException catch (e) {
      // Token ditolak server = sesi habis. Masalah jaringan: tetap ke layar login.
      if (e.status == 401) await _clearToken();
      _setLoggedOut();
    } catch (_) {
      _setLoggedOut();
    }
  }

  Future<void> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    }) as Map<String, dynamic>;
    await _startSession(data);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _api.post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    }) as Map<String, dynamic>;
    await _startSession(data);
  }

  Future<void> logout() async {
    await _clearToken();
    user = null;
    _setLoggedOut();
  }

  /// Muat ulang data pengguna (misalnya setelah profil pendonor diubah).
  Future<void> refreshUser() async {
    final data = await _api.get('/auth/me');
    user = AppUser.fromJson(data as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> _startSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    _api.token = token;
    await _storage.write(key: _tokenKey, value: token);
    // /auth/me mengembalikan data lengkap termasuk profil pendonor.
    final me = await _api.get('/auth/me');
    user = AppUser.fromJson(me as Map<String, dynamic>);
    status = AuthStatus.loggedIn;
    notifyListeners();
  }

  Future<void> _clearToken() async {
    _api.token = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  void _setLoggedOut() {
    status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
