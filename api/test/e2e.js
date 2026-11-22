'use strict';
/**
 * Uji ujung ke ujung (butuh MySQL/MariaDB yang sudah diisi schema.sql + seed.sql).
 * PERINGATAN: tes ini menambah data di database yang dipakai. Jalankan ulang schema.sql + seed.sql
 * sebelum dan sesudahnya, dan jangan arahkan ke database yang datanya penting.
 *   DATABASE_URL=mysql://root@localhost:3306/siaga_donor STAGE_TIMEOUT_MIN=0 node test/e2e.js
 * Memanggil API lewat HTTP dan menjalankan perluasan radius (isi cron) secara langsung.
 */
const assert = require('node:assert/strict');
const app = require('../src/app');
const db = require('../src/db');
const { escalateRequests } = require('../src/services/dispatch');

let passed = 0;
const ok = (name) => { passed++; console.log('  ok -', name); };

async function main() {
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (method, path, token, body) => {
    const res = await fetch(base + path, {
      method,
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    return { status: res.status, body: await res.json() };
  };
  const login = async (email, password = 'password123') => {
    const r = await call('POST', '/auth/login', null, { email, password });
    assert.equal(r.status, 200, `login ${email}`);
    return r.body.token;
  };

  const admin = await login('admin@siaga.test', 'admin123');
  const budi = await login('budi@siaga.test');
  const sari = await login('sari@siaga.test');   // O+, ~1 km
  const dimas = await login('dimas@siaga.test'); // A+, masih masa jeda
  const lina = await login('lina@siaga.test');   // O-, ~5.3 km

  // --- Autentikasi & validasi ---
  assert.equal((await call('POST', '/auth/login', null, { email: 'budi@siaga.test', password: 'salah' })).status, 401);
  assert.equal((await call('GET', '/auth/me')).status, 401);
  assert.equal((await call('POST', '/auth/register', null, { email: 'x@y.z' })).status, 400);
  assert.equal((await call('POST', '/auth/register', null, { name: 'Dup', email: 'budi@siaga.test', password: 'abcdef' })).status, 409);
  ok('login salah / tanpa token / validasi register / email ganda ditolak');

  const reg = await call('POST', '/auth/register', null, { name: 'Baru', email: 'baru@siaga.test', password: 'abcdef' });
  assert.equal(reg.status, 201);
  const baru = reg.body.token;
  const prof = await call('PUT', '/donors/me', baru, { blood_type: 'A', rhesus: '+', latitude: -7.26, longitude: 112.75 });
  assert.equal(prof.status, 200);
  assert.equal((await call('PUT', '/donors/me', baru, { blood_type: 'Z', rhesus: '+', latitude: 0, longitude: 0 })).status, 400);
  assert.equal((await call('PUT', '/donors/me', baru, { blood_type: 'A', rhesus: '+', latitude: 0, longitude: 0, last_donation_date: '21/11/2026' })).status, 400);
  // Ubah profil (upsert) dan ketersediaan tetap terjaga bila is_available tidak dikirim
  const again = await call('PUT', '/donors/me', baru, { blood_type: 'A', rhesus: '+', latitude: -7.26, longitude: 112.75, last_donation_date: null });
  assert.equal(again.status, 200);
  assert.equal(Number(again.body.is_available), 1);
  const off = await call('PATCH', '/donors/me/availability', baru, { is_available: false });
  assert.equal(Number(off.body.is_available), 0);
  const kept = await call('PUT', '/donors/me', baru, { blood_type: 'A', rhesus: '+', latitude: -7.26, longitude: 112.75 });
  assert.equal(Number(kept.body.is_available), 0, 'PUT tanpa is_available tidak mengubah ketersediaan');
  await call('PATCH', '/donors/me/availability', baru, { is_available: true });
  assert.equal((await call('PATCH', '/donors/me/availability', budi, { is_available: true })).status, 404);
  ok('register + profil pendonor (upsert), ketersediaan, golongan/tanggal tidak valid ditolak');

  // --- Permintaan darah: A+, 2 kantong ---
  const bad = await call('POST', '/requests', budi, { patient_name: 'P', blood_type: 'A', rhesus: '+', units_needed: 0, hospital_name: 'RS', latitude: 1, longitude: 1 });
  assert.equal(bad.status, 400);
  const created = await call('POST', '/requests', budi, {
    patient_name: 'Ibu Ani', blood_type: 'A', rhesus: '+', units_needed: 2,
    hospital_name: 'RS Pusat Surabaya', latitude: -7.2575, longitude: 112.7521,
  });
  assert.equal(created.status, 201);
  assert.equal(created.body.status, 'pending_verification');
  const rid = created.body.id;
  ok('permintaan dibuat dengan status menunggu verifikasi');

  // Belum diverifikasi: tidak ada undangan sama sekali
  let inv = await call('GET', '/donors/me/invitations', sari);
  assert.equal(inv.body.length, 0);
  ok('sebelum diverifikasi admin, belum ada pendonor yang diundang');

  // --- Hak akses admin ---
  assert.equal((await call('PATCH', `/admin/requests/${rid}/verify`, budi, { approve: true })).status, 403);
  assert.equal((await call('GET', `/requests/${rid}`, sari)).status, 403);
  ok('non-admin tidak bisa verifikasi, orang lain tidak bisa lihat detail');

  // --- Verifikasi: tahap 1 (3 km) ---
  const ver = await call('PATCH', `/admin/requests/${rid}/verify`, admin, { approve: true });
  assert.equal(ver.status, 200);
  assert.equal(ver.body.status, 'active');
  assert.equal(ver.body.invited, 2, 'tahap 3 km: Sari (O+) dan "Baru" (A+, belum pernah donor)');
  inv = await call('GET', '/donors/me/invitations', sari);
  assert.equal(inv.body.length, 1);
  assert.ok(Number(inv.body[0].distance_km) < 3);
  // Dimas (A+) kompatibel & dekat tapi masih masa jeda -> tidak diundang
  assert.equal((await call('GET', '/donors/me/invitations', dimas)).body.length, 0);
  // Pemohon sendiri tidak diundang walau tidak punya profil; donor O+/A- jauh belum diundang
  const seed = await db.query('SELECT donor_id FROM request_matches WHERE request_id = ?', [rid]);
  assert.deepEqual(seed.map((r) => r.donor_id).sort((a, b) => a - b), [3, reg.body.user.id]);
  ok('tahap 3 km: hanya pendonor kompatibel + lewat masa jeda + terdekat yang diundang');

  // Verifikasi dua kali ditolak
  assert.equal((await call('PATCH', `/admin/requests/${rid}/verify`, admin, { approve: true })).status, 404);

  // --- Sari menyanggupi; notifikasi sampai ke pemohon ---
  assert.equal((await call('POST', `/requests/${rid}/respond`, dimas, { response: 'accepted' })).status, 404);
  assert.equal((await call('POST', `/requests/${rid}/respond`, sari, { response: 'mungkin' })).status, 400);
  const acc = await call('POST', `/requests/${rid}/respond`, sari, { response: 'accepted' });
  assert.equal(acc.status, 200);
  assert.equal((await call('POST', `/requests/${rid}/respond`, sari, { response: 'accepted' })).status, 404);
  const notifBudi = await call('GET', '/notifications', budi);
  assert.ok(notifBudi.body.items.some((n) => n.title === 'Ada pendonor yang menyanggupi'));
  const mine = await call('GET', '/requests/mine', budi);
  assert.equal(Number(mine.body[0].committed), 1);
  // Tandai dibaca: dua kali berturut-turut tetap sukses, notifikasi orang lain tidak bisa diubah
  const nid = notifBudi.body.items[0].id;
  assert.equal((await call('PATCH', `/notifications/${nid}/read`, budi)).status, 200);
  assert.equal((await call('PATCH', `/notifications/${nid}/read`, budi)).status, 200);
  assert.equal((await call('PATCH', `/notifications/${nid}/read`, sari)).status, 404);
  assert.equal((await call('PATCH', '/notifications/read-all', budi)).status, 200);
  assert.equal((await call('GET', '/notifications', budi)).body.unread, 0);
  ok('pendonor menyanggupi, pemohon dapat notifikasi, jumlah penyanggup tercatat');

  // --- Perluasan radius: 1 dari 2 kantong -> terus diperluas ---
  let n = await escalateRequests(); // -> 5 km (tidak ada donor baru)
  assert.equal(n, 1);
  let r = (await db.query('SELECT stage_index FROM blood_requests WHERE id = ?', [rid]))[0];
  assert.equal(r.stage_index, 1);
  assert.equal((await call('GET', '/donors/me/invitations', lina)).body.length, 0, 'Lina 5,3 km belum terjangkau 5 km');
  await escalateRequests(); // -> 10 km, Lina (O-) masuk
  r = (await db.query('SELECT stage_index FROM blood_requests WHERE id = ?', [rid]))[0];
  assert.equal(r.stage_index, 2);
  const linaInv = await call('GET', '/donors/me/invitations', lina);
  assert.equal(linaInv.body.length, 1);
  ok('radius diperluas bertahap (3 -> 5 -> 10 km) dan pendonor baru diundang');

  // --- Konfirmasi donor + masa jeda ---
  assert.equal((await call('POST', `/requests/${rid}/confirm-donation`, budi, { donor_id: 5 })).status, 409, 'Lina belum menyanggupi');
  assert.equal((await call('POST', `/requests/${rid}/confirm-donation`, sari, { donor_id: 3 })).status, 403, 'bukan pemilik');
  const c1 = await call('POST', `/requests/${rid}/confirm-donation`, budi, { donor_id: 3 });
  assert.equal(c1.status, 200);
  assert.equal(c1.body.request_fulfilled, false);
  const last = (await db.query('SELECT (last_donation_date = CURDATE()) AS today FROM donor_profiles WHERE user_id = 3'))[0];
  assert.equal(Number(last.today), 1);
  ok('konfirmasi donor memperbarui masa jeda dan belum menandai terpenuhi (1 dari 2)');

  await call('POST', `/requests/${rid}/respond`, lina, { response: 'accepted' });
  const c2 = await call('POST', `/requests/${rid}/confirm-donation`, admin, { donor_id: 5 });
  assert.equal(c2.body.request_fulfilled, true);
  const done = (await db.query('SELECT status FROM blood_requests WHERE id = ?', [rid]))[0];
  assert.equal(done.status, 'fulfilled');
  assert.equal((await call('GET', '/donors/me/history', sari)).body.length, 1);
  ok('2 dari 2 kantong terkonfirmasi -> permintaan terpenuhi, riwayat donor tercatat');

  // --- Sari baru donor, jadi tidak boleh diundang lagi (masa jeda) ---
  const second = await call('POST', '/requests', budi, {
    patient_name: 'Pak Eko', blood_type: 'O', rhesus: '+', units_needed: 1,
    hospital_name: 'RS Pusat Surabaya', latitude: -7.2575, longitude: 112.7521,
  });
  await call('PATCH', `/admin/requests/${second.body.id}/verify`, admin, { approve: true });
  assert.equal((await call('GET', '/donors/me/invitations', sari)).body.filter((i) => i.request_id === second.body.id).length, 0);
  ok('pendonor yang baru donor tidak diundang lagi (masa jeda aktif)');

  // --- Penolakan admin & pembatalan ---
  const third = await call('POST', '/requests', budi, {
    patient_name: 'Tes', blood_type: 'B', rhesus: '+', units_needed: 1, hospital_name: 'RS X', latitude: -7.3, longitude: 112.7,
  });
  assert.equal((await call('PATCH', `/admin/requests/${third.body.id}/verify`, admin, { approve: false })).status, 400);
  const rej = await call('PATCH', `/admin/requests/${third.body.id}/verify`, admin, { approve: false, reason: 'Data tidak lengkap' });
  assert.equal(rej.body.status, 'rejected');
  assert.ok((await call('GET', '/notifications', budi)).body.items.some((x) => x.title === 'Permintaan ditolak'));
  ok('admin menolak permintaan dengan alasan, pemohon diberi tahu');

  // --- Kedaluwarsa setelah radius terakhir ---
  for (let i = 0; i < 6; i++) await escalateRequests();
  const exp = (await db.query('SELECT status FROM blood_requests WHERE id = ?', [second.body.id]))[0];
  assert.equal(exp.status, 'expired');
  ok('radius terakhir habis dan kantong belum terpenuhi -> permintaan kedaluwarsa');

  // --- Statistik admin ---
  const stats = await call('GET', '/admin/stats', admin);
  assert.equal(stats.status, 200);
  assert.ok(stats.body.totals.donations >= 2);
  assert.equal((await call('GET', '/admin/stats', budi)).status, 403);
  ok('statistik admin tersedia dan hanya untuk admin');

  console.log(`\n${passed} kelompok pengujian lulus`);
  server.close();
  await db.pool.end();
}

main().catch(async (e) => {
  console.error('GAGAL:', e);
  await db.pool.end().catch(() => {});
  process.exit(1);
});
