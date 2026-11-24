import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../models/blood_request.dart';
import '../services/api_client.dart';
import '../services/request_service.dart';
import '../utils/formatters.dart';

/// Daftar permintaan yang menunggu verifikasi admin.
class AdminVerifyTab extends StatefulWidget {
  const AdminVerifyTab({super.key});

  @override
  State<AdminVerifyTab> createState() => _AdminVerifyTabState();
}

class _AdminVerifyTabState extends State<AdminVerifyTab> {
  late final RequestService _service;
  List<BloodRequest> _items = [];
  final Set<int> _busy = {};
  bool _loading = true;
  String? _error;

  late final NotificationProvider _notif;
  int _notifVersion = 0;

  void _onNotif() {
    if (_notif.version != _notifVersion) {
      _notifVersion = _notif.version;
      _load();
    }
  }

  @override
  void dispose() {
    _notif.removeListener(_onNotif);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _notif = context.read<NotificationProvider>();
    _notifVersion = _notif.version;
    _notif.addListener(_onNotif);
    _service = RequestService(context.read<ApiClient>());
    _load();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final data = await _service.pendingForAdmin();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _approve(BloodRequest r) async {
    setState(() => _busy.add(r.id));
    try {
      final invited = await _service.verify(r.id, approve: true);
      if (!mounted) return;
      _snack(invited > 0
          ? 'Disetujui. $invited pendonor diundang.'
          : 'Disetujui, tetapi belum ada pendonor yang cocok di radius awal.');
      await _load();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  Future<void> _reject(BloodRequest r) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak permintaan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Alasan penolakan',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    setState(() => _busy.add(r.id));
    try {
      await _service.verify(r.id, approve: false, reason: reason);
      if (!mounted) return;
      _snack('Permintaan ditolak.');
      await _load();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  Widget _card(BloodRequest r) {
    final busy = _busy.contains(r.id);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.errorContainer,
                  child: Text(r.bloodLabel,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.onErrorContainer)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.patientName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${r.unitsNeeded} kantong • ${r.hospitalName}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Pemohon: ${r.requesterName ?? '-'}'
              '${r.requesterPhone != null ? ' (${r.requesterPhone})' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Koordinat: ${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 13),
            ),
            if (r.note != null && r.note!.isNotEmpty)
              Text('Catatan: ${r.note}', style: const TextStyle(fontSize: 13)),
            Text(
              'Dibuat ${formatDateTime(r.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : () => _reject(r),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error),
                  child: const Text('Tolak'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy ? null : () => _approve(r),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Setujui'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
                onPressed: _load, child: const Text('Coba lagi')),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.task_alt, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('Tidak ada permintaan yang menunggu verifikasi.',
              textAlign: TextAlign.center),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _card(_items[i]),
    );
  }

  @override
  Widget build(BuildContext context) =>
      RefreshIndicator(onRefresh: _load, child: _body());
}
