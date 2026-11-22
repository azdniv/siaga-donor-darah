import '../models/blood_request.dart';
import 'api_client.dart';

/// Semua panggilan API yang berkaitan dengan permintaan darah
/// (sisi pemohon dan sisi admin).
class RequestService {
  final ApiClient _api;

  RequestService(this._api);

  List<BloodRequest> _parseList(dynamic data) => (data as List<dynamic>)
      .map((e) => BloodRequest.fromJson(e as Map<String, dynamic>))
      .toList();

  /// Permintaan milik saya.
  Future<List<BloodRequest>> mine() async =>
      _parseList(await _api.get('/requests/mine'));

  Future<BloodRequest> detail(int id) async => BloodRequest.fromJson(
      (await _api.get('/requests/$id')) as Map<String, dynamic>);

  Future<void> create({
    required String patientName,
    required String bloodType,
    required String rhesus,
    required int unitsNeeded,
    required String hospitalName,
    required double latitude,
    required double longitude,
    String? note,
  }) async {
    await _api.post('/requests', {
      'patient_name': patientName,
      'blood_type': bloodType,
      'rhesus': rhesus,
      'units_needed': unitsNeeded,
      'hospital_name': hospitalName,
      'latitude': latitude,
      'longitude': longitude,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  Future<void> cancel(int id) async {
    await _api.patch('/requests/$id/cancel');
  }

  /// Mengembalikan true bila permintaan menjadi terpenuhi setelah konfirmasi ini.
  Future<bool> confirmDonation(int requestId, int donorId) async {
    final data = await _api
        .post('/requests/$requestId/confirm-donation', {'donor_id': donorId});
    return data is Map && data['request_fulfilled'] == true;
  }

  // ---- Admin ----

  Future<List<BloodRequest>> pendingForAdmin() async => _parseList(
      await _api.get('/admin/requests?status=pending_verification'));

  /// Mengembalikan jumlah pendonor yang diundang (0 bila ditolak).
  Future<int> verify(int id, {required bool approve, String? reason}) async {
    final data = await _api.patch('/admin/requests/$id/verify', {
      'approve': approve,
      if (!approve) 'reason': reason,
    });
    if (data is Map && data['invited'] is num) {
      return (data['invited'] as num).toInt();
    }
    return 0;
  }
}
