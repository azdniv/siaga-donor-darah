import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../models/invitation.dart';
import '../services/api_client.dart';
import '../services/invitation_service.dart';
import '../utils/formatters.dart';

/// Tab Undangan: undangan donor yang masuk, dan riwayat donor.
class InvitationsTab extends StatefulWidget {
  const InvitationsTab({super.key});

  @override
  State<InvitationsTab> createState() => _InvitationsTabState();
}

class _InvitationsTabState extends State<InvitationsTab> {
  late final InvitationService _service;
  List<Invitation> _invitations = [];
  List<DonationRecord> _history = [];
  final Set<int> _busy = {};
  bool _showHistory = false;
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
    _service = InvitationService(context.read<ApiClient>());
    _load();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    setState(() {
      _loading = _invitations.isEmpty && _history.isEmpty;
      _error = null;
    });
    try {
      final results =
          await Future.wait([_service.invitations(), _service.history()]);
      if (!mounted) return;
      setState(() {
        _invitations = results[0] as List<Invitation>;
        _history = results[1] as List<DonationRecord>;
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

  Future<void> _respond(Invitation inv, bool accept) async {
    setState(() => _busy.add(inv.requestId));
    try {
      await _service.respond(inv.requestId, accept: accept);
      if (!mounted) return;
      _snack(accept
          ? 'Terima kasih! Pemohon akan melihat kesediaanmu.'
          : 'Undangan ditolak.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
      await _load();
    } finally {
      if (mounted) setState(() => _busy.remove(inv.requestId));
    }
  }

  Color _statusColor(Invitation inv) {
    if (inv.requestClosed && inv.status == 'notified') {
      return Colors.grey.shade700;
    }
    switch (inv.status) {
      case 'notified':
        return Colors.orange.shade800;
      case 'accepted':
        return Colors.blue.shade700;
      case 'donated':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _invitationCard(Invitation inv) {
    final scheme = Theme.of(context).colorScheme;
    final busy = _busy.contains(inv.requestId);
    final color = _statusColor(inv);
    final label = (inv.requestClosed && inv.status == 'notified')
        ? 'Permintaan sudah ditutup'
        : inv.statusLabel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.errorContainer,
                  child: Text(inv.bloodLabel,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.onErrorContainer)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv.hospitalName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                          '${inv.distanceKm.toStringAsFixed(1)} km dari lokasimu • ${inv.unitsNeeded} kantong'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Pasien: ${inv.patientName}',
                style: const TextStyle(fontSize: 13)),
            if (inv.note != null && inv.note!.isNotEmpty)
              Text('Catatan: ${inv.note}',
                  style: const TextStyle(fontSize: 13)),
            Text(
              'Diundang ${formatDateTime(inv.notifiedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            if (inv.canRespond)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : () => _respond(inv, false),
                    child: const Text('Tolak'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: busy ? null : () => _respond(inv, true),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Saya bersedia'),
                  ),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            if (inv.status == 'accepted' && !inv.requestClosed) ...[
              const SizedBox(height: 8),
              const Text(
                'Datangi lokasi dan hubungi pemohon. Pemohon akan mengonfirmasi setelah kamu donor.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _historyCard(DonationRecord d) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.errorContainer,
          child: Text(d.bloodLabel,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: scheme.onErrorContainer)),
        ),
        title: Text(d.hospitalName),
        subtitle: Text(formatDate(d.donatedAt)),
      ),
    );
  }

  Widget _list() {
    final isHistory = _showHistory;
    final count = isHistory ? _history.length : _invitations.length;

    if (count == 0) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(isHistory ? Icons.history : Icons.mail_outline,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            isHistory
                ? 'Belum ada riwayat donor.'
                : 'Belum ada undangan.\nPastikan profil donor sudah lengkap dan statusmu tersedia.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => isHistory
          ? _historyCard(_history[i])
          : _invitationCard(_invitations[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null &&
        _invitations.isEmpty &&
        _history.isEmpty) {
      content = ListView(
        children: [
          const SizedBox(height: 100),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
                onPressed: _load, child: const Text('Coba lagi')),
          ),
        ],
      );
    } else {
      content = _list();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text('Undangan (${_invitations.length})'),
                  icon: const Icon(Icons.mail_outline),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Riwayat (${_history.length})'),
                  icon: const Icon(Icons.history),
                ),
              ],
              selected: {_showHistory},
              onSelectionChanged: (s) =>
                  setState(() => _showHistory = s.first),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(onRefresh: _load, child: content),
        ),
      ],
    );
  }
}
