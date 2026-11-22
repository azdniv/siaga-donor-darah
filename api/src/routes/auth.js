'use strict';
const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const config = require('../config');
const { auth } = require('../middleware/auth');

const sign = (u) =>
  jwt.sign({ id: u.id, role: u.role }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });

router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password, phone } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'name, email, dan password wajib diisi' });
    }
    if (String(password).length < 6) {
      return res.status(400).json({ error: 'Password minimal 6 karakter' });
    }
    const hash = await bcrypt.hash(password, 10);
    const result = await db.query(
      'INSERT INTO users (name, email, password_hash, phone) VALUES (?, LOWER(?), ?, ?)',
      [name, email, hash, phone || null]
    );
    const rows = await db.query('SELECT id, name, email, phone, role FROM users WHERE id = ?', [result.insertId]);
    res.status(201).json({ user: rows[0], token: sign(rows[0]) });
  } catch (e) {
    if (e.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Email sudah terdaftar' });
    next(e);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'email dan password wajib diisi' });
    const rows = await db.query('SELECT * FROM users WHERE email = LOWER(?)', [email]);
    const user = rows[0];
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Email atau password salah' });
    }
    delete user.password_hash;
    res.json({ user, token: sign(user) });
  } catch (e) {
    next(e);
  }
});

router.get('/me', auth, async (req, res, next) => {
  try {
    const users = await db.query('SELECT id, name, email, phone, role FROM users WHERE id = ?', [req.user.id]);
    if (!users.length) return res.status(404).json({ error: 'User tidak ditemukan' });
    const profiles = await db.query('SELECT * FROM donor_profiles WHERE user_id = ?', [req.user.id]);
    res.json({ ...users[0], donor_profile: profiles[0] || null });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
