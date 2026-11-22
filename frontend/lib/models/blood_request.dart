int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// Label status permintaan untuk ditampilkan ke pengguna.
String requestStatusLabel(String status) {
  switch (status) {
    case 'pending_verification':
      return 'Menunggu verifikasi';
    case 'active':
      return 'Aktif';
    case 'fulfilled':
      return 'Terpenuhi';
    case 'rejected':
      return 'Ditolak';
    case 'expired':
      return 'Kedaluwarsa';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return status;
  }
}

/// Pendonor yang sudah menyanggupi (atau sudah mendonor) untuk sebuah permintaan.
class CommittedDonor {
  final int donorId;
  final String name;
  final String? phone;
  final double distanceKm;
  final String status; // accepted atau donated

  const CommittedDonor({
    required this.donorId,
    required this.name,
    required this.distanceKm,
    required this.status,
    this.phone,
  });

  bool get hasDonated => status == 'donated';

  factory CommittedDonor.fromJson(Map<String, dynamic> json) {
    return CommittedDonor(
      donorId: _toInt(json['donor_id']),
      name: json['name'] as String,
      phone: json['phone'] as String?,
      distanceKm: (json['distance_km'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}

/// Permintaan darah.
class BloodRequest {
  final int id;
  final int requesterId;
  final String patientName;
  final String bloodType;
  final String rhesus;
  final int unitsNeeded;
  final String hospitalName;
  final double latitude;
  final double longitude;
  final String? note;
  final String status;
  final String? rejectReason;
  final int stageIndex;
  final DateTime createdAt;

  /// Jumlah pendonor yang diundang, menyanggupi, dan sudah donor.
  /// Terisi dari daftar "permintaan saya" dan detail.
  final int invited;
  final int committed;
  final int donated;

  /// Hanya terisi pada daftar admin.
  final String? requesterName;
  final String? requesterPhone;

  /// Hanya terisi pada detail.
  final List<CommittedDonor> committedDonors;

  const BloodRequest({
    required this.id,
    required this.requesterId,
    required this.patientName,
    required this.bloodType,
    required this.rhesus,
    required this.unitsNeeded,
    required this.hospitalName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.stageIndex,
    required this.createdAt,
    this.note,
    this.rejectReason,
    this.invited = 0,
    this.committed = 0,
    this.donated = 0,
    this.requesterName,
    this.requesterPhone,
    this.committedDonors = const [],
  });

  String get bloodLabel => '$bloodType$rhesus';

  String get statusLabel => requestStatusLabel(status);

  bool get isPending => status == 'pending_verification';

  bool get isActive => status == 'active';

  /// Masih bisa dibatalkan pemohon.
  bool get isOpen => isPending || isActive;

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    final donorsJson = json['committed_donors'];
    final donors = donorsJson is List
        ? donorsJson
            .map((e) => CommittedDonor.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CommittedDonor>[];

    // Pada detail, jumlah penyanggup dan donor dihitung dari daftar pendonor.
    final committed = donorsJson is List
        ? donors.length
        : _toInt(json['committed']);
    final donated = donorsJson is List
        ? donors.where((d) => d.hasDonated).length
        : _toInt(json['donated']);

    return BloodRequest(
      id: _toInt(json['id']),
      requesterId: _toInt(json['requester_id']),
      patientName: json['patient_name'] as String,
      bloodType: json['blood_type'] as String,
      rhesus: json['rhesus'] as String,
      unitsNeeded: _toInt(json['units_needed']),
      hospitalName: json['hospital_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      note: json['note'] as String?,
      status: json['status'] as String,
      rejectReason: json['reject_reason'] as String?,
      stageIndex: _toInt(json['stage_index']),
      createdAt: DateTime.parse(json['created_at'] as String),
      invited: _toInt(json['invited']),
      committed: committed,
      donated: donated,
      requesterName: json['requester_name'] as String?,
      requesterPhone: json['requester_phone'] as String?,
      committedDonors: donors,
    );
  }
}
