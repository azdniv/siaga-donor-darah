import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/blood_request.dart';
import '../services/api_client.dart';
import '../services/request_service.dart';
import '../utils/formatters.dart';
import '../widgets/status_chip.dart';
import 'create_request_screen.dart';
import 'request_detail_screen.dart';

/// Daftar permintaan darah milik pengguna yang sedang login.
class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  late final RequestService _service;
  List<BloodRequest> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = RequestService(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final data = await _service.mine();
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

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _open(BloodRequest r) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: r.id)),
    );
    _load();
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
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
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.bloodtype_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Belum ada permintaan.\nKetuk tombol di bawah untuk membuat permintaan darah.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RequestCard(
        request: _items[i],
        onTap: () => _open(_items[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(onRefresh: _load, child: _body()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Buat permintaan'),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final BloodRequest request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.errorContainer,
                child: Text(
                  r.bloodLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.patientName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${r.hospitalName} • ${r.unitsNeeded} kantong',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      formatDateTime(r.createdAt),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (r.isActive) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Diundang ${r.invited} • Menyanggupi ${r.committed} • Donor ${r.donated}/${r.unitsNeeded}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(r.status),
            ],
          ),
        ),
      ),
    );
  }
}
