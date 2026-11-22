import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/request_service.dart';
import '../utils/coordinates.dart';

/// Form membuat permintaan darah. Menutup dengan `true` bila berhasil.
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _hospital = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _note = TextEditingController();

  String _bloodType = 'A';
  String _rhesus = '+';
  int _units = 1;
  bool _locating = false;
  bool _saving = false;

  @override
  void dispose() {
    _patient.dispose();
    _hospital.dispose();
    _lat.dispose();
    _lng.dispose();
    _note.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final p = await LocationService.current();
      if (!mounted) return;
      _lat.text = p.latitude.toStringAsFixed(6);
      _lng.text = p.longitude.toStringAsFixed(6);
    } on LocationException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await RequestService(context.read<ApiClient>()).create(
        patientName: _patient.text.trim(),
        bloodType: _bloodType,
        rhesus: _rhesus,
        unitsNeeded: _units,
        hospitalName: _hospital.text.trim(),
        latitude: parseCoordinate(_lat.text)!,
        longitude: parseCoordinate(_lng.text)!,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat permintaan darah')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Permintaan akan diperiksa admin terlebih dahulu. '
                  'Setelah disetujui, pendonor yang cocok di sekitar rumah sakit '
                  'akan diundang otomatis.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patient,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama pasien',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _required(v, 'Nama pasien'),
            ),
            const SizedBox(height: 16),
            const Text('Golongan darah'),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'A', label: Text('A')),
                ButtonSegment(value: 'B', label: Text('B')),
                ButtonSegment(value: 'AB', label: Text('AB')),
                ButtonSegment(value: 'O', label: Text('O')),
              ],
              selected: {_bloodType},
              onSelectionChanged: (s) => setState(() => _bloodType = s.first),
            ),
            const SizedBox(height: 12),
            const Text('Rhesus'),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '+', label: Text('Positif (+)')),
                ButtonSegment(value: '-', label: Text('Negatif (−)')),
              ],
              selected: {_rhesus},
              onSelectionChanged: (s) => setState(() => _rhesus = s.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Jumlah kantong dibutuhkan')),
                IconButton.filledTonal(
                  onPressed:
                      _units > 1 ? () => setState(() => _units--) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$_units',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed:
                      _units < 20 ? () => setState(() => _units++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hospital,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama rumah sakit / tempat donor',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _required(v, 'Nama rumah sakit'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('Lokasi rumah sakit',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                TextButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: const Text('Gunakan lokasi saya'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => validateCoordinate(v, -90, 90, 'Latitude'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        validateCoordinate(v, -180, 180, 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Contoh Surabaya: -7.2575, 112.7521',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Misalnya: ruang, nomor kontak, kebutuhan khusus',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kirim permintaan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
