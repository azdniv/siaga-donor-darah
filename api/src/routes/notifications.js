'use strict';
const router = require('express').Router();
const db = require('../db');
const { auth } = require('../middleware/auth');

router.use(auth);

// Klien memanggil ini secara berkala (polling). ?after_id=123 hanya mengambil yang lebih baru.
router.get('/', async (req, res, next) => {
  try {
    const afterId = Number(req.query.after_id) || 0;
    const items = await db.query(
      `SELECT * FROM notifications
        WHERE user_id = ? AND id > ?
        ORDER BY id DESC LIMIT 100`,
      [req.user.id, afterId]
    );
    const c = await db.query(
      'SELECT COUNT(*) AS unread FROM notifications WHERE user_id = ? AND is_read = 0',
      [req.user.id]
    );
    res.json({ unread: Number(c[0].unread), items });
  } catch (e) {
    next(e);
  }
});

// Daftarkan /read-all sebelum /:id/read agar tidak tertukar.
router.patch('/read-all', async (req, res, next) => {
  try {
    await db.query('UPDATE notifications SET is_read = 1 WHERE user_id = ?', [req.user.id]);
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

router.patch('/:id/read', async (req, res, next) => {
  try {
    const own = await db.query('SELECT id FROM notifications WHERE id = ? AND user_id = ?', [
      req.params.id,
      req.user.id,
    ]);
    if (!own.length) return res.status(404).json({ error: 'Notifikasi tidak ditemukan' });
    await db.query('UPDATE notifications SET is_read = 1 WHERE id = ?', [req.params.id]);
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
