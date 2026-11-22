/// Profil pendonor milik pengguna (sesuai tabel donor_profiles).
class DonorProfile {
  final String bloodType; // A, B, AB, O
  final String rhesus; // + atau -
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final DateTime? lastDonationDate;

  const DonorProfile({
    required this.bloodType,
    required this.rhesus,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    this.lastDonationDate,
  });

  String get bloodLabel => '$bloodType$rhesus';

  /// Tanggal paling cepat bisa donor lagi. Null bila belum pernah donor.
  DateTime? nextEligibleDate(int intervalDays) =>
      lastDonationDate?.add(Duration(days: intervalDays));

  /// Apakah masa jeda donor sudah terpenuhi hari ini.
  bool canDonateNow(int intervalDays, {DateTime? now}) {
    final next = nextEligibleDate(intervalDays);
    if (next == null) return true;
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    return !today.isBefore(next);
  }

  factory DonorProfile.fromJson(Map<String, dynamic> json) {
    final last = json['last_donation_date'];
    return DonorProfile(
      bloodType: json['blood_type'] as String,
      rhesus: json['rhesus'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isAvailable: json['is_available'] == true,
      lastDonationDate: last is String ? DateTime.parse(last) : null,
    );
  }
}
