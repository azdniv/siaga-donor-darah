/// Tanggal untuk ditampilkan ke pengguna: 05/11/2026.
String formatDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}

/// Tanggal dan jam (waktu lokal perangkat): 05/11/2026 14:30.
String formatDateTime(DateTime d) {
  final l = d.toLocal();
  final hour = l.hour.toString().padLeft(2, '0');
  final minute = l.minute.toString().padLeft(2, '0');
  return '${formatDate(l)} $hour:$minute';
}

/// Tanggal untuk dikirim ke API: 2026-11-05.
String toApiDate(DateTime d) {
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}
