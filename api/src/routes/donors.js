'use strict';
const router = require('express').Router();
const db = require('../db');
const { auth } = require('../middleware/auth');

router.use(auth);

const isNum = (v) => typeof v === 'number' && Number.isFinite(v);
const isDate = (v) => typeof v === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v);

// Buat / ubah profil pendonor milik sendiri.
router.put('/me', async (req, res, next) => {
  try {
    const { blood_type, rhesus, latitude, longitude, is_available, last_donation_date } = req.body;
    if (!['A', 'B', 'AB', 'O'].includes(blood_type) || !['+', '-'].includes(rhesus)) {
      return res.status(400).json({ error: 'Golongan darah / rhesus tidak valid' });
    }
    if (!isNum(latitude) || !isNum(longitude)) {
      return res.status(400).json({ error: 'latitude dan longitude harus angka' });
    }
    if (last_donation_date && !isDate(last_donation_date)) {
      return res.status(400).json({ error: 'last_donation_date harus berformat YYYY-MM-DD' });
    }
    const avail = typeof is_available === 'boolean' ? (is_available ? 1 : 0) : null;
    await db.query(
      `INSERT INTO donor_profiles (user_id, blood_type, rhesus, latitude, longitude, is_available, last_donation_date)
       VALUES (?, ?, ?, ?, ?, COALESCE(?, 1), ?)
       ON DUPLICATE KEY UPDATE
         blood_type = VALUES(blood_type), rhesus = VALUES(rhesus),
         latitude = VALUES(latitude), longitude = VALUES(longitude),
         is_available = COALESCE(?, is_available),
         last_donation_date = VALUES(last_donation_date),
         updated_at = NOW()`,
      [req.user.id, blood_type, rhesus, latitude, longitude, avail, last_donation_date || null, avail]
    );
    const rows = await db.query('SELECT * FROM donor_profiles WHERE user_id = ?', [req.user.id]);
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

router.get('/me', async (req, res, next) => {
  try {
    const rows = await db.query('SELECT * FROM donor_profiles WHERE user_id = ?', [req.user.id]);
    if (!rows.length) return res.status(404).json({ error: 'Profil pendonor belum dibuat' });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

// Aktif / nonaktifkan ketersediaan.
router.patch('/me/availability', async (req, res, next) => {
  try {
    if (typeof req.body.is_available !== 'boolean') {
      return res.status(400).json({ error: 'is_available harus true/false' });
    }
    const existing = await db.query('SELECT user_id FROM donor_profiles WHERE user_id = ?', [req.user.id]);
    if (!existing.length) return res.status(404).json({ error: 'Profil pendonor belum dibuat' });
    await db.query('UPDATE donor_profiles SET is_available = ?, updated_at = NOW() WHERE user_id = ?', [
      req.body.is_available ? 1 : 0,
      req.user.id,
    ]);
    const rows = await db.query('SELECT * FROM donor_profiles WHERE user_id = ?', [req.user.id]);
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

// Undangan donor yang masuk ke saya.
router.get('/me/invitations', async (req, res, next) => {
  try {
    const rows = await db.query(
      `SELECT m.id AS match_id, m.status, m.distance_km, m.notified_at,
              r.id AS request_id, r.patient_name, r.blood_type, r.rhesus,
              r.units_needed, r.hospital_name, r.latitude, r.longitude, r.note,
              r.status AS request_status
         FROM request_matches m
         JOIN blood_requests r ON r.id = m.request_id
        WHERE m.donor_id = ?
        ORDER BY m.notified_at DESC, m.id DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

// Riwayat donor yang sudah dikonfirmasi.
router.get('/me/history', async (req, res, next) => {
  try {
    const rows = await db.query(
      `SELECT d.id, d.donated_at, r.hospital_name, r.blood_type, r.rhesus
         FROM donations d JOIN blood_requests r ON r.id = d.request_id
        WHERE d.donor_id = ? ORDER BY d.donated_at DESC, d.id DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

module.exports = router;
