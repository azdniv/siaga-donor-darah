'use strict';
const router = require('express').Router();
const db = require('../db');
const { HttpError } = require('../errors');
const { auth } = require('../middleware/auth');
const { markFulfilledIfDone } = require('../services/dispatch');

router.use(auth);

const isNum = (v) => typeof v === 'number' && Number.isFinite(v);

// Pemohon membuat permintaan. Statusnya menunggu verifikasi admin.
router.post('/', async (req, res, next) => {
  try {
    const { patient_name, blood_type, rhesus, units_needed, hospital_name, latitude, longitude, note } = req.body;
    if (!patient_name || !hospital_name) {
      return res.status(400).json({ error: 'patient_name dan hospital_name wajib diisi' });
    }
    if (!['A', 'B', 'AB', 'O'].includes(blood_type) || !['+', '-'].includes(rhesus)) {
      return res.status(400).json({ error: 'Golongan darah / rhesus tidak valid' });
    }
    if (!Number.isInteger(units_needed) || units_needed < 1 || units_needed > 20) {
      return res.status(400).json({ error: 'units_needed harus bilangan bulat 1-20' });
    }
    if (!isNum(latitude) || !isNum(longitude)) {
      return res.status(400).json({ error: 'latitude dan longitude harus angka' });
    }
    const result = await db.query(
      `INSERT INTO blood_requests
         (requester_id, patient_name, blood_type, rhesus, units_needed, hospital_name, latitude, longitude, note)
       VALUES (?,?,?,?,?,?,?,?,?)`,
      [req.user.id, patient_name, blood_type, rhesus, units_needed, hospital_name, latitude, longitude, note || null]
    );
    const rows = await db.query('SELECT * FROM blood_requests WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (e) {
    next(e);
  }
});

// Daftar permintaan milik saya, lengkap dengan jumlah pendonor yang sudah menyanggupi.
router.get('/mine', async (req, res, next) => {
  try {
    const rows = await db.query(
      `SELECT r.*,
              (SELECT COUNT(*) FROM request_matches m WHERE m.request_id = r.id) AS invited,
              (SELECT COUNT(*) FROM request_matches m
                WHERE m.request_id = r.id AND m.status IN ('accepted','donated')) AS committed,
              (SELECT COUNT(*) FROM donations d WHERE d.request_id = r.id) AS donated
         FROM blood_requests r
        WHERE r.requester_id = ? ORDER BY r.created_at DESC, r.id DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

// Detail permintaan (pemilik atau admin). Kontak pendonor hanya untuk yang sudah menyanggupi.
router.get('/:id', async (req, res, next) => {
  try {
    const rows = await db.query('SELECT * FROM blood_requests WHERE id = ?', [req.params.id]);
    const request = rows[0];
    if (!request) return res.status(404).json({ error: 'Permintaan tidak ditemukan' });
    if (request.requester_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Bukan permintaan milikmu' });
    }
    const committed = await db.query(
      `SELECT m.donor_id, m.status, m.distance_km, u.name, u.phone
         FROM request_matches m JOIN users u ON u.id = m.donor_id
        WHERE m.request_id = ? AND m.status IN ('accepted','donated')
        ORDER BY m.distance_km`,
      [request.id]
    );
    const counts = await db.query('SELECT COUNT(*) AS invited FROM request_matches WHERE request_id = ?', [
      request.id,
    ]);
    res.json({ ...request, invited: Number(counts[0].invited), committed_donors: committed });
  } catch (e) {
    next(e);
  }
});

// Pemohon membatalkan permintaan.
router.patch('/:id/cancel', async (req, res, next) => {
  try {
    const result = await db.query(
      `UPDATE blood_requests SET status = 'cancelled'
        WHERE id = ? AND requester_id = ? AND status IN ('pending_verification','active')`,
      [req.params.id, req.user.id]
    );
    if (!result.affectedRows) {
      return res.status(404).json({ error: 'Permintaan tidak ditemukan atau tidak bisa dibatalkan' });
    }
    const rows = await db.query('SELECT * FROM blood_requests WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

// Pendonor menyanggupi / menolak undangan.
router.post('/:id/respond', async (req, res, next) => {
  try {
    const { response } = req.body;
    if (!['accepted', 'declined'].includes(response)) {
      return res.status(400).json({ error: "response harus 'accepted' atau 'declined'" });
    }
    const match = await db.withTx(async (conn) => {
      const reqRows = await db.q(conn, 'SELECT * FROM blood_requests WHERE id = ? FOR UPDATE', [req.params.id]);
      const request = reqRows[0];
      if (!request || request.status !== 'active') throw new HttpError(409, 'Permintaan sudah tidak aktif');

      const upd = await db.q(
        conn,
        `UPDATE request_matches SET status = ?, responded_at = NOW()
          WHERE request_id = ? AND donor_id = ? AND status = 'notified'`,
        [response, request.id, req.user.id]
      );
      if (!upd.affectedRows) throw new HttpError(404, 'Tidak ada undangan yang menunggu responsmu');

      const rows = await db.q(conn, 'SELECT * FROM request_matches WHERE request_id = ? AND donor_id = ?', [
        request.id,
        req.user.id,
      ]);
      if (response === 'accepted') {
        const u = await db.q(conn, 'SELECT name FROM users WHERE id = ?', [req.user.id]);
        await db.q(
          conn,
          'INSERT INTO notifications (user_id, request_id, title, message) VALUES (?,?,?,?)',
          [request.requester_id, request.id, 'Ada pendonor yang menyanggupi',
           `${u[0].name} bersedia mendonorkan darah untuk ${request.patient_name} (${rows[0].distance_km} km).`]
        );
      }
      return rows[0];
    });
    res.json(match);
  } catch (e) {
    next(e);
  }
});

// Pemohon / admin mengonfirmasi bahwa pendonor benar-benar sudah mendonor.
router.post('/:id/confirm-donation', async (req, res, next) => {
  try {
    const donorId = Number(req.body.donor_id);
    if (!Number.isInteger(donorId)) return res.status(400).json({ error: 'donor_id wajib diisi' });

    const result = await db.withTx(async (conn) => {
      const reqRows = await db.q(conn, 'SELECT * FROM blood_requests WHERE id = ? FOR UPDATE', [req.params.id]);
      const request = reqRows[0];
      if (!request) throw new HttpError(404, 'Permintaan tidak ditemukan');
      if (request.requester_id !== req.user.id && req.user.role !== 'admin') {
        throw new HttpError(403, 'Bukan permintaan milikmu');
      }
      if (request.status !== 'active') throw new HttpError(409, 'Permintaan sudah tidak aktif');

      const upd = await db.q(
        conn,
        `UPDATE request_matches SET status = 'donated'
          WHERE request_id = ? AND donor_id = ? AND status = 'accepted'`,
        [request.id, donorId]
      );
      if (!upd.affectedRows) throw new HttpError(409, 'Pendonor ini belum menyanggupi');

      await db.q(
        conn,
        'INSERT INTO donations (request_id, donor_id, confirmed_by, donated_at) VALUES (?,?,?,CURDATE())',
        [request.id, donorId, req.user.id]
      );
      // Mulai masa jeda donor dari hari ini.
      await db.q(conn, 'UPDATE donor_profiles SET last_donation_date = CURDATE(), updated_at = NOW() WHERE user_id = ?', [
        donorId,
      ]);
      await db.q(
        conn,
        'INSERT INTO notifications (user_id, request_id, title, message) VALUES (?,?,?,?)',
        [donorId, request.id, 'Terima kasih sudah mendonor',
         'Donormu sudah dikonfirmasi. Masa jeda donor berikutnya mulai dihitung hari ini.']
      );
      const fulfilled = await markFulfilledIfDone(conn, request.id);
      return { confirmed: true, request_fulfilled: fulfilled };
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
});

module.exports = router;
