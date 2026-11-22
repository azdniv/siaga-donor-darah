import '../models/invitation.dart';
import 'api_client.dart';

/// Panggilan API untuk sisi pendonor: undangan, jawaban, dan riwayat.
class InvitationService {
  final ApiClient _api;

  InvitationService(this._api);

  Future<List<Invitation>> invitations() async {
    final data = await _api.get('/donors/me/invitations') as List<dynamic>;
    return data
        .map((e) => Invitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DonationRecord>> history() async {
    final data = await _api.get('/donors/me/history') as List<dynamic>;
    return data
        .map((e) => DonationRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Menyanggupi (true) atau menolak (false) sebuah undangan.
  Future<void> respond(int requestId, {required bool accept}) async {
    await _api.post('/requests/$requestId/respond',
        {'response': accept ? 'accepted' : 'declined'});
  }
}
