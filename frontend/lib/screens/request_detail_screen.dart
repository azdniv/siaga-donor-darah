import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/blood_request.dart';
import '../services/api_client.dart';
import '../services/request_service.dart';
import '../utils/formatters.dart';
import '../widgets/status_chip.dart';

/// Detail permintaan: status, progres pendonor, konfirmasi donor, dan pembatalan.
class RequestDetailScreen extends StatefulWidget {
  final int requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late final RequestService _service;
  BloodRequest? _request;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = RequestService(context.read<ApiClient>());
    _load();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await _service.detail(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = r;
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

  Future<void> _confirm(CommittedDonor donor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi donor'),
        content: Text('Konfirmasi bahwa ${donor.name} sudah mendonorkan darah?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, sudah')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final fulfilled =
          await _service.confirmDonation(widget.requestId, donor.donorId);
      if (!mounted) return;
      _snack(fulfilled
          ? 'Semua kantong terpenuhi. Permintaan selesai.'
          : 'Donor dikonfirmasi.');
      await _load();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan permintaan?'),
        content: const Text(
            'Pendonor yang sudah diundang tidak akan diminta lagi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, batalkan')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _service.cancel(widget.requestId);
      if (!mounted) return;
      _snack('Permintaan dibatalkan.');
      await _load();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) _snack('Nomor $phone disalin.');
  }

  Widget _info(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            SizedBox(
              width: 86,
              child: Text(label,
                  style: TextStyle(color: Colors.grey.shade700)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _progress(BloodRequest r) {
    final radiusIdx = r.stageIndex.clamp(0, AppConfig.radiusStagesKm.length - 1);
    final fraction =
        r.unitsNeeded == 0 ? 0.0 : (r.donated / r.unitsNeeded).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progres pendonor',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: fraction, minHeight: 8),
            const SizedBox(height: 8),
            Text('${r.donated} dari ${r.unitsNeeded} kantong sudah didonorkan'),
            const SizedBox(height: 8),
            Text('Radius pencarian saat ini: ${AppConfig.radiusStagesKm[radiusIdx]} km'),
            Text('Pendonor diundang: ${r.invited}'),
            Text('Pendonor menyanggupi: ${r.committed}'),
          ],
        ),
      ),
    );
  }

  Widget _donorList(BloodRequest r) {
    if (r.committedDonors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Belum ada pendonor yang menyanggupi.'),
      );
    }
    return Column(
      children: [
        for (final d in r.committedDonors)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(d.hasDonated ? Icons.check : Icons.person),
              ),
              title: Text(d.name),
              subtitle: Text(
                '${d.distanceKm.toStringAsFixed(1)} km'
                '${d.phone != null ? ' • ${d.phone}' : ''}'
                '${d.hasDonated ? ' • Sudah donor' : ''}',
              ),
              trailing: d.hasDonated
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (d.phone != null)
                          IconButton(
                            tooltip: 'Salin nomor',
                            onPressed: () => _copyPhone(d.phone!),
                            icon: const Icon(Icons.copy, size: 20),
                          ),
                        if (r.isActive)
                          TextButton(
                            onPressed: _busy ? null : () => _confirm(d),
                            child: const Text('Sudah donor'),
                          ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _content(BloodRequest r) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(r.bloodLabel,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              StatusChip(r.status),
            ],
          ),
          const SizedBox(height: 12),
          _info(Icons.person_outline, 'Pasien', r.patientName),
          _info(Icons.local_hospital_outlined, 'Lokasi', r.hospitalName),
          _info(Icons.bloodtype_outlined, 'Kebutuhan', '${r.unitsNeeded} kantong'),
          _info(Icons.place_outlined, 'Koordinat',
              '${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}'),
          _info(Icons.schedule, 'Dibuat', formatDateTime(r.createdAt)),
          if (r.note != null && r.note!.isNotEmpty)
            _info(Icons.notes, 'Catatan', r.note!),
          if (r.status == 'rejected') ...[
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                    'Ditolak admin: ${r.rejectReason ?? 'tanpa alasan'}'),
              ),
            ),
          ],
          if (r.isPending) ...[
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                    'Menunggu verifikasi admin. Pendonor akan diundang setelah disetujui.'),
              ),
            ),
          ],
          if (!r.isPending && r.status != 'rejected') ...[
            const SizedBox(height: 12),
            _progress(r),
            const SizedBox(height: 16),
            const Text('Pendonor yang menyanggupi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            _donorList(r),
          ],
          if (r.isOpen) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _busy ? null : _cancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Batalkan permintaan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _request == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      );
    } else {
      body = _content(_request!);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detail permintaan')),
      body: body,
    );
  }
}
