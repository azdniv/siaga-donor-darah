# Rencana Pengerjaan dan Commit

Dosen menilai **konsistensi commit sejak awal**, bukan kualitas kode. Commit kecil dan sering, jangan satu commit besar di akhir. Tulis pesan commit yang jelas, misalnya `feat(api): endpoint verifikasi admin`.

Deadline di minggu UAS (tanggal pastinya menyusul dari dosen). Rencana di bawah dihitung mundur dari minggu pengumpulan.

## Status saat ini
- [x] Skema database MySQL + data contoh
- [x] API: auth, profil pendonor, permintaan, respons, konfirmasi donor, admin, notifikasi
- [x] Logika pencocokan + perluasan radius, dengan tes
- [ ] Frontend Flutter
- [ ] Video presentasi
- [ ] Draft artikel ilmiah

## Urutan kerja yang disarankan

| Tahap | Pekerjaan | Contoh commit |
|---|---|---|
| 1 | Buat repo, push struktur 3 folder + README | `chore: struktur awal repo` |
| 2 | Push database, lalu API (per modul, bukan sekaligus) | `feat(db): skema tabel`, `feat(api): auth JWT`, `feat(api): pencocokan donor` |
| 3 | Flutter: setup, login/register, simpan token | `feat(app): halaman login` |
| 4 | Flutter pendonor: profil + lokasi, undangan, riwayat | `feat(app): profil pendonor` |
| 5 | Flutter pemohon: buat permintaan, daftar, detail | `feat(app): buat permintaan darah` |
| 6 | Flutter admin: verifikasi + dashboard statistik | `feat(app): verifikasi admin` |
| 7 | Notifikasi lokal dari polling, peta | `feat(app): notifikasi polling` |
| 8 | Perapian UI, penanganan error, uji manual semua alur | `fix(app): ...` |
| 9 | Rekam video, tulis artikel | `docs: draft artikel` |

Catatan: karena kode di repo ini sudah selesai sebagian, jangan push semuanya sekaligus. Masukkan bertahap per modul sambil kamu membaca dan memahaminya. Kamu perlu bisa menjelaskan semuanya di video dan kalau ditanya.

## Fitur yang wajib jalan (janji di abstrak)
1. Pencocokan golongan darah + rhesus
2. Masa jeda donor
3. Jarak terdekat + perluasan radius
4. Notifikasi ke pendonor
5. Pemohon memantau jumlah penyanggup
6. Verifikasi admin

## Alat yang dipakai
Laragon (MySQL/MariaDB, Node.js, Git), HeidiSQL atau phpMyAdmin untuk melihat tabel, VS Code, Flutter SDK + Android Studio (emulator), Postman. Di emulator Android, alamat API adalah `http://10.0.2.2:3000`. Di HP asli pakai IP komputer di Wi-Fi yang sama, dan izinkan port 3000 di firewall.
