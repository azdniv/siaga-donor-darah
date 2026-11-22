int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// Label status undangan dari sisi pendonor.
String invitationStatusLabel(String status) {
  switch (status) {
    case 'notified':
      return 'Menunggu jawabanmu';
    case 'accepted':
      return 'Kamu menyanggupi';
    case 'declined':
      return 'Kamu menolak';
    case 'donated':
      return 'Sudah donor';
    default:
      return status;
  }
}

/// Undangan donor yang masuk ke pendonor untuk satu permintaan darah.
class Invitation {
  final int matchId;
  final int requestId;
  final String status; // notified, accepted, declined, donated
  final double distanceKm;
  final DateTime notifiedAt;
  final String patientName;
  final String bloodType;
  final String rhesus;
  final int unitsNeeded;
  final String hospitalName;
  final double latitude;
  final double longitude;
  final String? note;
  final String requestStatus;

  const Invitation({
    required this.matchId,
    required this.requestId,
    required this.status,
    required this.distanceKm,
    required this.notifiedAt,
    required this.patientName,
    required this.bloodType,
    required this.rhesus,
    required this.unitsNeeded,
    required this.hospitalName,
    required this.latitude,
    required this.longitude,
    required this.requestStatus,
    this.note,
  });

  String get bloodLabel => '$bloodType$rhesus';

  String get statusLabel => invitationStatusLabel(status);

  /// Undangan masih menunggu jawaban dan permintaannya masih aktif.
  bool get canRespond => status == 'notified' && requestStatus == 'active';

  /// Permintaan sudah tidak aktif (selesai, kedaluwarsa, atau dibatalkan).
  bool get requestClosed => requestStatus != 'active';

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      matchId: _toInt(json['match_id']),
      requestId: _toInt(json['request_id']),
      status: json['status'] as String,
      distanceKm: _toDouble(json['distance_km']),
      notifiedAt: DateTime.parse(json['notified_at'] as String),
      patientName: json['patient_name'] as String,
      bloodType: json['blood_type'] as String,
      rhesus: json['rhesus'] as String,
      unitsNeeded: _toInt(json['units_needed']),
      hospitalName: json['hospital_name'] as String,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      note: json['note'] as String?,
      requestStatus: json['request_status'] as String,
    );
  }
}

/// Satu catatan donor yang sudah dikonfirmasi.
class DonationRecord {
  final int id;
  final DateTime donatedAt;
  final String hospitalName;
  final String bloodType;
  final String rhesus;

  const DonationRecord({
    required this.id,
    required this.donatedAt,
    required this.hospitalName,
    required this.bloodType,
    required this.rhesus,
  });

  String get bloodLabel => '$bloodType$rhesus';

  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    return DonationRecord(
      id: _toInt(json['id']),
      donatedAt: DateTime.parse(json['donated_at'] as String),
      hospitalName: json['hospital_name'] as String,
      bloodType: json['blood_type'] as String,
      rhesus: json['rhesus'] as String,
    );
  }
}
