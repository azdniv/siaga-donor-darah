'use strict';
const router = require('express').Router();
const db = require('../db');
const { HttpError } = require('../errors');
const { auth, requireAdmin } = require('../middleware/auth');
const { activateRequest } = require('../services/dispatch');

router.use(auth, requireAdmin);

// Daftar permintaan, bisa difilter ?status=pending_verification
router.get('/requests', async (req, res, next) => {
  try {
    const params = [];
    let where = '';
    if (req.query.status) {
      params.push(req.query.status);
      where = 'WHERE r.status = ?';
    }
    const rows = await db.query(
      `SELECT r.*, u.name AS requester_name, u.phone AS requester_phone
         FROM blood_requests r JOIN users u ON u.id = r.requester_id
         ${where} ORDER BY r.created_at DESC, r.id DESC`,
      params
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

// Setujui / tolak permintaan. Bila disetujui, penyebaran ke pendonor dimulai.
router.patch('/requests/:id/verify', async (req, res, next) => {
  try {
    const { approve, reason } = req.body;
    if (typeof approve !== 'boolean') return res.status(400).json({ error: 'approve harus true/false' });
    if (!approve && !reason) return res.status(400).json({ error: 'Alasan penolakan wajib diisi' });

    const result = await db.withTx(async (conn) => {
      const rows = await db.q(
        conn,
        `SELECT * FROM blood_requests WHERE id = ? AND status = 'pending_verification' FOR UPDATE`,
        [req.params.id]
      );
      const request = rows[0];
      if (!request) throw new HttpError(404, 'Permintaan tidak ditemukan atau sudah diverifikasi');

      await db.q(
        conn,
        'UPDATE blood_requests SET verified_by = ?, verified_at = NOW(), reject_reason = ? WHERE id = ?',
        [req.user.id, approve ? null : reason, request.id]
      );
      let invited = 0;
      if (approve) {
        invited = await activateRequest(conn, request);
        await db.q(conn, 'INSERT INTO notifications (user_id, request_id, title, message) VALUES (?,?,?,?)', [
          request.requester_id, request.id, 'Permintaan disetujui',
          `Permintaanmu aktif dan ${invited} pendonor terdekat sudah diundang.`,
        ]);
      } else {
        await db.q(conn, "UPDATE blood_requests SET status = 'rejected' WHERE id = ?", [request.id]);
        await db.q(conn, 'INSERT INTO notifications (user_id, request_id, title, message) VALUES (?,?,?,?)', [
          request.requester_id, request.id, 'Permintaan ditolak', `Alasan: ${reason}`,
        ]);
      }
      return { id: request.id, status: approve ? 'active' : 'rejected', invited };
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
});

// Statistik ringkas untuk dashboard admin.
router.get('/stats', async (req, res, next) => {
  try {
    const byStatus = await db.query('SELECT status, COUNT(*) AS total FROM blood_requests GROUP BY status');
    const donorsByType = await db.query(
      `SELECT CONCAT(blood_type, rhesus) AS golongan, COUNT(*) AS total
         FROM donor_profiles GROUP BY blood_type, rhesus ORDER BY golongan`
    );
    const totals = await db.query(
      `SELECT (SELECT COUNT(*) FROM users) AS users,
              (SELECT COUNT(*) FROM donor_profiles WHERE is_available = 1) AS donors_available,
              (SELECT COUNT(*) FROM donations) AS donations`
    );
    res.json({ requests_by_status: byStatus, donors_by_blood_type: donorsByType, totals: totals[0] });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
