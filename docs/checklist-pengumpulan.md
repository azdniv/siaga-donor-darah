# Checklist Pengumpulan (sesuai arahan dosen)

Dikumpulkan di LMS pada minggu UAS. Tanggal dan jam pastinya akan diumumkan dosen.

## 1. Repo GitHub
- [ ] Satu repo, tiga folder: `frontend`, `api`, `database`
- [ ] Riwayat commit dari awal, sering di-push (konsistensi yang dinilai)
- [ ] Frontend Flutter
- [ ] API berdiri sendiri (Express), frontend tidak langsung ke database
- [ ] Database SQL (MySQL/MariaDB), bukan NoSQL
- [ ] Tidak memakai Firebase / Supabase / database-as-a-service
- [ ] Bukan hasil menyalin atau clone proyek orang lain (red flag, nilai minimal)

## 2. Video presentasi (unggah ke YouTube, kumpulkan linknya)
- [ ] Minimal 10 menit
- [ ] Jelaskan sedetail mungkin, kecuali kode (kode tidak perlu dijelaskan)
- [ ] Format seperti presentasi UTS, boleh ditambah
- [ ] Usulan isi: masalah dan latar belakang, titik inovasi dibanding aplikasi donor darah lain, peran pengguna, arsitektur (Flutter → API → MySQL), ERD, demo semua alur, penjelasan algoritma pencocokan (3 syarat + radius bertahap), pengujian

## 3. Draft artikel ilmiah
- [ ] Mengikuti template jurnal JSB (cari "JSB jurnal SE" lalu unduh template-nya)
- [ ] Hanya draft, tidak perlu dipublikasikan
- [ ] Kerangka ada di `docs/kerangka-artikel-jsb.md`

## 4. Spreadsheet judul
- [ ] Judul: Aplikasi Siaga Donor Darah (sudah di-ACC)
- [ ] Abstrak sudah diisi (teks ada di README)

## Sebelum mengumpulkan
- [ ] README terisi dan cara menjalankan teruji di komputer lain
- [ ] `npm test` dan `npm run test:e2e` lulus
- [ ] Aplikasi bisa didemokan dari awal sampai akhir dengan data contoh
