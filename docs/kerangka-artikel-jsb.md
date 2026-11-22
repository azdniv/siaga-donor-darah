# Kerangka Draft Artikel Ilmiah

Urutan bagian ini umum untuk artikel rancang bangun sistem. **Sesuaikan dengan template resmi JSB** (judul bagian, jumlah kolom, gaya sitasi, panjang abstrak) setelah kamu mengunduhnya. Saya tidak memeriksa template JSB-nya, jadi anggap ini kerangka awal, bukan format final.

**Judul:** Rancang Bangun Aplikasi Siaga Donor Darah Berbasis Mobile dengan Pencocokan Pendonor Berdasarkan Kompatibilitas Golongan Darah, Masa Jeda Donor, dan Jarak

1. **Abstrak** (bahasa Indonesia, dan Inggris bila diminta template) + kata kunci
2. **Pendahuluan**: masalah penyebaran permintaan darah lewat grup chat, kebutuhan pencocokan terarah, tujuan, kontribusi
3. **Tinjauan pustaka / penelitian terkait**: aplikasi donor darah yang sudah ada dan perbedaannya, sistem golongan darah ABO dan rhesus, rumus Haversine, REST API
   *(isi dengan sumber yang benar-benar kamu baca; jangan mengarang referensi)*
4. **Metode**
   - Model pengembangan (misalnya prototyping atau waterfall) dan tahapannya
   - Analisis kebutuhan: aktor (pemohon, pendonor, admin), use case
   - Perancangan: arsitektur 3 lapis (Flutter → REST API → PostgreSQL), ERD, aturan pencocokan
   - Algoritma: kompatibilitas ABO/rhesus, masa jeda 90 hari, jarak Haversine, penyebaran bertahap (3, 5, 10, 25, 50 km)
5. **Hasil dan pembahasan**
   - Implementasi: tangkapan layar tiap fitur
   - Pengujian fungsional (black box): tabel kasus uji dan hasil (data bisa diambil dari `api/test`)
   - Pengujian logika pencocokan: matriks kompatibilitas (27 dari 64 pasangan donor-penerima yang kompatibel), skenario radius bertahap dengan data contoh
   - Keterbatasan: tidak terhubung ke data stok PMI, verifikasi permintaan masih manual oleh admin, data kesehatan pendonor (misalnya penyakit) belum diverifikasi sistem
6. **Kesimpulan dan saran**
7. **Daftar pustaka**

## Catatan
- Pengujian yang kamu klaim harus benar-benar kamu jalankan. Jangan menulis hasil yang belum ada.
- Aturan donor (masa jeda, syarat kesehatan) sebaiknya dirujuk ke sumber resmi seperti PMI atau Kemenkes. Nilai 90 hari di aplikasi ini bisa diubah lewat `DONOR_INTERVAL_DAYS`, silakan cocokkan dengan sumber yang kamu pakai.
