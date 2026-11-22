/// Pengaturan aplikasi.
///
/// Alamat API bisa diganti saat menjalankan tanpa mengubah kode:
///   flutter run --dart-define=API_URL=http://192.168.1.10:3000
class AppConfig {
  /// Emulator Android memakai 10.0.2.2 untuk menjangkau komputer (bukan localhost).
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Masa jeda antar donor (hari). Harus sama dengan DONOR_INTERVAL_DAYS di API.
  static const int donorIntervalDays = 90;

  /// Tahap radius pencarian pendonor (km). Harus sama dengan RADIUS_STAGES_KM di API.
  static const List<int> radiusStagesKm = [3, 5, 10, 25, 50];
}
