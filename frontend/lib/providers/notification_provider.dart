import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/api_client.dart';

/// Mengambil notifikasi dari API secara berkala (polling).
/// Dibuat saat pengguna masuk ke layar utama, dan dibuang saat keluar.
class NotificationProvider extends ChangeNotifier {
  final ApiClient _api;
  Timer? _timer;
  bool _polling = false;
  bool _disposed = false;
  bool _firstLoadDone = false;

  /// Notifikasi, terbaru di atas.
  List<AppNotification> items = [];
  int unread = 0;

  /// Bertambah setiap ada notifikasi baru. Tab memakainya untuk memuat ulang.
  int version = 0;

  /// Dipanggil untuk notifikasi terbaru yang baru masuk (bukan saat muat awal).
  void Function(AppNotification notification)? onNew;

  NotificationProvider(this._api);

  int get _lastId => items.isEmpty ? 0 : items.first.id;

  void start({Duration interval = const Duration(seconds: 15)}) {
    refresh();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  Future<void> refresh() async {
    if (_polling || _disposed) return;
    _polling = true;
    try {
      final data =
          await _api.get('/notifications?after_id=$_lastId') as Map<String, dynamic>;
      if (_disposed) return;
      final fresh = (data['items'] as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      final serverUnread = (data['unread'] as num).toInt();

      final changed = fresh.isNotEmpty || serverUnread != unread;
      if (fresh.isNotEmpty) items = [...fresh, ...items];
      unread = serverUnread;

      final hadFirstLoad = _firstLoadDone;
      _firstLoadDone = true;
      if (fresh.isNotEmpty && hadFirstLoad) {
        version++;
        onNew?.call(fresh.first);
      }
      if (changed) notifyListeners();
    } on ApiException {
      // Gagal sesaat (jaringan atau server): coba lagi pada putaran berikutnya.
    } finally {
      _polling = false;
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    items = [for (final i in items) i.id == n.id ? i.copyWith(isRead: true) : i];
    unread = unread > 0 ? unread - 1 : 0;
    notifyListeners();
    try {
      await _api.patch('/notifications/${n.id}/read');
    } on ApiException {
      // Biarkan; hitungan akan disinkronkan lagi pada polling berikutnya.
    }
  }

  Future<void> markAllRead() async {
    items = [for (final i in items) i.copyWith(isRead: true)];
    unread = 0;
    notifyListeners();
    try {
      await _api.patch('/notifications/read-all');
    } on ApiException {
      // Sama seperti di atas.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
