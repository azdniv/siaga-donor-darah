# Aplikasi Siaga Donor Darah

Tugas akhir individu, mata kuliah Pemrograman Aplikasi Bergerak.

## Abstrak

Permintaan darah mendesak masih sering disebarkan lewat grup WhatsApp atau media sosial, sehingga balasannya lambat dan belum tentu sampai ke orang yang golongan darahnya cocok. Aplikasi mobile ini dibuat untuk mempertemukan pemohon darah dengan pendonor sukarela dengan lebih cepat. Dengan memanfaatkan lokasi perangkat, sistem memilih pendonor yang golongan darahnya kompatibel, sudah melewati masa jeda donor, dan berada paling dekat dengan pemohon, lalu mengirimkan notifikasi kepada mereka. Jika jumlah kantong darah yang dibutuhkan belum terpenuhi, pencarian diperluas ke radius berikutnya. Pemohon dapat memantau jumlah pendonor yang sudah menyanggupi, sedangkan admin memverifikasi permintaan agar tidak disalahgunakan.

## Struktur repo (1 repo, 3 folder)

| Folder | Isi | Teknologi |
|---|---|---|
| `frontend/` | Aplikasi mobile | Flutter |
| `api/` | REST API (berdiri sendiri) | Node.js + Express, JWT |
| `database/` | Skema dan data contoh | MySQL / MariaDB (Laragon) |

Frontend tidak mengakses database langsung. Semua lewat API. Tidak memakai Firebase/Supabase maupun database NoSQL.

## Alur inti

1. Pemohon membuat permintaan darah (golongan, rhesus, jumlah kantong, rumah sakit, lokasi). Status: `pending_verification`.
2. Admin memverifikasi. Jika disetujui, status `active` dan penyebaran tahap pertama dimulai (radius 3 km).
3. Sistem memilih pendonor yang memenuhi **tiga syarat**: golongan kompatibel, masa jeda donor (90 hari) terpenuhi, dan berada dalam radius, diurutkan dari yang terdekat. Mereka diberi notifikasi.
4. Pendonor menyanggupi atau menolak. Pemohon melihat jumlah penyanggup.
5. Bila kantong belum terpenuhi setelah batas waktu tahap (default 10 menit), radius diperluas: 3 → 5 → 10 → 25 → 50 km. Setelah radius terakhir habis, permintaan kedaluwarsa.
6. Pemohon/admin mengonfirmasi donor yang sudah terjadi. Masa jeda pendonor dihitung ulang dan permintaan ditandai `fulfilled` bila cukup.

Logika pencocokan ada di `api/src/services/matching.js` (fungsi murni, diuji), dan penyebaran/perluasan di `api/src/services/dispatch.js`.

Notifikasi memakai tabel `notifications` yang diambil klien lewat polling (`GET /notifications?after_id=`), jadi tidak butuh Firebase/FCM. Di Flutter, hasil polling ditampilkan sebagai notifikasi lokal.

## Menjalankan

### 1. Database (Laragon)
1. Buka Laragon, klik **Start All** (MySQL/MariaDB menyala di port 3306, user `root`, password kosong).
2. Klik **Database** di Laragon untuk membuka HeidiSQL, lalu **File → Run SQL file**: jalankan `database/schema.sql`, kemudian `database/seed.sql` (data contoh, opsional).

Atau lewat terminal Laragon:
```bash
mysql -u root < database/schema.sql
mysql -u root < database/seed.sql
```
`schema.sql` membuat database `siaga_donor` sendiri, dan menghapus tabel lama dengan nama yang sama. Jangan dijalankan ulang kalau datanya sudah penting.

Akun contoh: `admin@siaga.test` / `admin123`, `budi@siaga.test` (pemohon) dan `sari@siaga.test` (pendonor), password `password123`.

### 2. API
```bash
cd api
cp .env.example .env        # sesuaikan DATABASE_URL (kalau root punya password) dan JWT_SECRET
npm install
npm start                   # http://localhost:3000
npm test                    # tes logika pencocokan
npm run test:e2e            # uji alur lengkap (butuh database terisi)
```

## Endpoint API

| Metode | Path | Akses | Fungsi |
|---|---|---|---|
| POST | `/auth/register`, `/auth/login` | publik | daftar, masuk (JWT) |
| GET | `/auth/me` | login | profil + profil pendonor |
| PUT / GET | `/donors/me` | login | buat/ubah, lihat profil pendonor |
| PATCH | `/donors/me/availability` | login | aktif/nonaktif ketersediaan |
| GET | `/donors/me/invitations` | login | undangan donor yang masuk |
| GET | `/donors/me/history` | login | riwayat donor |
| POST | `/requests` | login | buat permintaan darah |
| GET | `/requests/mine` | login | permintaan saya + jumlah penyanggup |
| GET | `/requests/:id` | pemilik/admin | detail + kontak pendonor yang menyanggupi |
| PATCH | `/requests/:id/cancel` | pemilik | batalkan |
| POST | `/requests/:id/respond` | pendonor | `accepted` / `declined` |
| POST | `/requests/:id/confirm-donation` | pemilik/admin | konfirmasi donor terjadi |
| GET | `/notifications` | login | polling notifikasi |
| PATCH | `/notifications/:id/read`, `/notifications/read-all` | login | tandai dibaca |
| GET | `/admin/requests` | admin | daftar permintaan (`?status=`) |
| PATCH | `/admin/requests/:id/verify` | admin | setujui / tolak |
| GET | `/admin/stats` | admin | statistik dashboard |

## Pengumpulan tugas

Lihat `docs/checklist-pengumpulan.md`. Rencana commit ada di `docs/rencana-pengerjaan.md`.
