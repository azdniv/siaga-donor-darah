int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// Ringkasan angka untuk dasbor admin.
class AdminStats {
  final Map<String, int> requestsByStatus;
  final Map<String, int> donorsByBloodType;
  final int users;
  final int donorsAvailable;
  final int donations;

  const AdminStats({
    required this.requestsByStatus,
    required this.donorsByBloodType,
    required this.users,
    required this.donorsAvailable,
    required this.donations,
  });

  int get totalRequests =>
      requestsByStatus.values.fold(0, (sum, v) => sum + v);

  int get totalDonors =>
      donorsByBloodType.values.fold(0, (sum, v) => sum + v);

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final byStatus = <String, int>{};
    for (final row in json['requests_by_status'] as List<dynamic>) {
      final m = row as Map<String, dynamic>;
      byStatus[m['status'] as String] = _toInt(m['total']);
    }
    final byType = <String, int>{};
    for (final row in json['donors_by_blood_type'] as List<dynamic>) {
      final m = row as Map<String, dynamic>;
      byType[m['golongan'] as String] = _toInt(m['total']);
    }
    final totals = json['totals'] as Map<String, dynamic>;
    return AdminStats(
      requestsByStatus: byStatus,
      donorsByBloodType: byType,
      users: _toInt(totals['users']),
      donorsAvailable: _toInt(totals['donors_available']),
      donations: _toInt(totals['donations']),
    );
  }
}
