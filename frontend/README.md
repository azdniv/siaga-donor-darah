# Frontend (Flutter)

Folder ini untuk aplikasi Flutter. Belum dibuat. Buat dari dalam folder ini:

```bash
flutter create --org id.ac.unesa --project-name siaga_donor_darah .
```

Paket yang direncanakan: `http` (panggil API), `provider` atau `riverpod` (state), `flutter_secure_storage` (simpan JWT), `geolocator` (lokasi), `flutter_map` + `latlong2` (peta OpenStreetMap, tanpa kunci API), `flutter_local_notifications` (notifikasi lokal dari hasil polling).

## Layar

**Umum:** Login, Register.
**Pemohon:** Buat Permintaan Darah (pilih lokasi di peta), Daftar Permintaan Saya, Detail Permintaan (jumlah penyanggup, kontak pendonor yang menyanggupi, tombol konfirmasi donor).
**Pendonor:** Profil Pendonor (golongan, lokasi, ketersediaan, donor terakhir), Undangan Masuk (terima/tolak), Riwayat Donor.
**Admin:** Verifikasi Permintaan, Dashboard Statistik.
**Bersama:** Notifikasi.

## Menyambung ke API
- Emulator Android: `http://10.0.2.2:3000` (bukan `localhost`).
- HP asli: pakai IP komputer (misalnya `http://192.168.1.10:3000`), HP dan komputer satu Wi-Fi, dan izinkan port 3000 di firewall.
- Android memblokir HTTP biasa pada rilis. Untuk pengembangan, tambahkan `android:usesCleartextTraffic="true"` di `AndroidManifest.xml`.
- Respons API: `is_available` dan `is_read` berupa `true/false`, tanggal berformat `YYYY-MM-DD`, waktu berformat ISO 8601 UTC.
