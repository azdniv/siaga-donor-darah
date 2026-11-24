import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/admin_stats.dart';
import '../models/blood_request.dart';
import '../services/api_client.dart';

/// Statistik ringkas untuk admin.
class AdminStatsTab extends StatefulWidget {
  const AdminStatsTab({super.key});

  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  late final ApiClient _api;
  AdminStats? _stats;
  bool _loading = true;
  String? _error;

  static const _statusOrder = [
    'pending_verification',
    'active',
    'fulfilled',
    'rejected',
    'expired',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiClient>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _stats == null;
      _error = null;
    });
    try {
      final data = await _api.get('/admin/stats') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _stats = AdminStats.fromJson(data);
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

  Widget _numberCard(String label, int value, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 6),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barRow(String label, int value, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('$value', textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );

  Widget _content(AdminStats s) {
    final statusMax = s.requestsByStatus.values.fold(0, (a, b) => a > b ? a : b);
    final typeEntries = s.donorsByBloodType.entries.toList();
    final typeMax = s.donorsByBloodType.values.fold(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _numberCard('Pengguna', s.users, Icons.people_outline),
            _numberCard('Pendonor tersedia', s.donorsAvailable,
                Icons.volunteer_activism),
            _numberCard('Donor terkonfirmasi', s.donations,
                Icons.bloodtype_outlined),
          ],
        ),
        const SizedBox(height: 8),
        _section('Permintaan menurut status (${s.totalRequests})', [
          if (s.requestsByStatus.isEmpty) const Text('Belum ada permintaan.'),
          for (final status in _statusOrder)
            if (s.requestsByStatus.containsKey(status))
              _barRow(requestStatusLabel(status), s.requestsByStatus[status]!,
                  statusMax),
        ]),
        const SizedBox(height: 8),
        _section('Pendonor menurut golongan darah (${s.totalDonors})', [
          if (typeEntries.isEmpty) const Text('Belum ada pendonor.'),
          for (final e in typeEntries) _barRow(e.key, e.value, typeMax),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _stats == null) {
      body = ListView(
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
    } else {
      body = _content(_stats!);
    }
    return RefreshIndicator(onRefresh: _load, child: body);
  }
}
