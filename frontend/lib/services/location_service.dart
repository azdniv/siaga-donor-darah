import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;

  LocationException(this.message);

  @override
  String toString() => message;
}

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

/// Mengambil lokasi perangkat saat ini lewat GPS.
class LocationService {
  static Future<GeoPoint> current() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw LocationException(
            'Layanan lokasi di perangkat sedang mati. Aktifkan dulu.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw LocationException(
            'Izin lokasi ditolak. Izinkan lewat pengaturan aplikasi, '
            'atau isi koordinat secara manual.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } on LocationException {
      rethrow;
    } catch (_) {
      throw LocationException(
          'Gagal mendapatkan lokasi. Coba lagi, atau isi koordinat manual.');
    }
  }
}
