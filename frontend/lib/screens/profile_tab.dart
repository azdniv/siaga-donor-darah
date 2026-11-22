import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../utils/formatters.dart';

/// Tab Profil. Untuk pengguna biasa berisi form profil pendonor,
/// untuk admin hanya info akun dan tombol keluar.
class ProfileTab extends StatefulWidget {
  final bool showDonorForm;

  const ProfileTab({super.key, required this.showDonorForm});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  String? _bloodType;
  String? _rhesus;
  bool _available = true;
  DateTime? _lastDonation;

  bool _saving = false;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().user?.donor;
    if (profile != null) {
      _bloodType = profile.bloodType;
      _rhesus = profile.rhesus;
      _available = profile.isAvailable;
      _lastDonation = profile.lastDonationDate;
      _latCtrl.text = profile.latitude.toString();
      _lngCtrl.text = profile.longitude.toString();
    }
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  double? _parse(String? v) =>
      double.tryParse((v ?? '').trim().replaceAll(',', '.'));

  String? _validateCoord(String? v, double min, double max, String label) {
    final value = _parse(v);
    if (value == null) return '$label harus berupa angka';
    if (value < min || value > max) return '$label harus antara $min dan $max';
    return null;
  }

  /// Mengisi lokasi dari GPS. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> _fetchLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return 'Layanan lokasi di perangkat sedang mati. Aktifkan dulu.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return 'Izin lokasi ditolak. Izinkan lewat pengaturan aplikasi, '
            'atau isi koordinat secara manual.';
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _latCtrl.text = position.latitude.toStringAsFixed(6);
      _lngCtrl.text = position.longitude.toStringAsFixed(6);
      return null;
    } catch (_) {
      return 'Gagal mendapatkan lokasi. Coba lagi, atau isi koordinat manual.';
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    final problem = await _fetchLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _error = problem;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonation ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Tanggal donor terakhir',
    );
    if (picked != null && mounted) setState(() => _lastDonation = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bloodType == null || _rhesus == null) {
      setState(() => _error = 'Pilih golongan darah dan rhesus dulu.');
      return;
    }

    final api = context.read<ApiClient>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await api.put('/donors/me', {
        'blood_type': _bloodType,
        'rhesus': _rhesus,
        'latitude': _parse(_latCtrl.text),
        'longitude': _parse(_lngCtrl.text),
        'is_available': _available,
        'last_donation_date':
            _lastDonation == null ? null : toApiDate(_lastDonation!),
      });
      await auth.refreshUser();
      messenger.showSnackBar(
        const SnackBar(content: Text('Profil pendonor disimpan')),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Chip(label: Text(user.isAdmin ? 'Admin' : 'Pengguna')),
          ),
        ),
        if (widget.showDonorForm) ...[
          const SizedBox(height: 16),
          Text('Profil pendonor', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Lokasi dan golongan darahmu dipakai untuk mencocokkan kamu dengan '
            'permintaan darah di sekitarmu.',
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Golongan darah', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'A', label: Text('A')),
                    ButtonSegment(value: 'B', label: Text('B')),
                    ButtonSegment(value: 'AB', label: Text('AB')),
                    ButtonSegment(value: 'O', label: Text('O')),
                  ],
                  selected: _bloodType == null ? <String>{} : {_bloodType!},
                  onSelectionChanged: (s) => setState(
                    () => _bloodType = s.isEmpty ? null : s.first,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Rhesus', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: '+', label: Text('Positif (+)')),
                    ButtonSegment(value: '-', label: Text('Negatif (-)')),
                  ],
                  selected: _rhesus == null ? <String>{} : {_rhesus!},
                  onSelectionChanged: (s) => setState(
                    () => _rhesus = s.isEmpty ? null : s.first,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Lokasi', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Latitude'),
                        validator: (v) =>
                            _validateCoord(v, -90, 90, 'Latitude'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                        validator: (v) =>
                            _validateCoord(v, -180, 180, 'Longitude'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Gunakan lokasi saya'),
                ),
                const SizedBox(height: 24),
                Text('Donor terakhir', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _lastDonation == null
                        ? 'Belum pernah / pilih tanggal'
                        : formatDate(_lastDonation!),
                  ),
                ),
                if (_lastDonation != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _lastDonation = null),
                      child: const Text('Hapus tanggal'),
                    ),
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bersedia menerima undangan donor'),
                  subtitle: const Text(
                    'Matikan bila kamu sedang tidak bisa mendonor.',
                  ),
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan profil'),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
        ),
      ],
    );
  }
}
