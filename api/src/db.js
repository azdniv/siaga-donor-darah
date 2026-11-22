'use strict';
require('dotenv').config();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  uri: process.env.DATABASE_URL || 'mysql://root@localhost:3306/siaga_donor',
  waitForConnections: true,
  connectionLimit: 10,
  timezone: 'Z',            // DATETIME dibaca/ditulis sebagai UTC
  dateStrings: ['DATE'],    // kolom DATE jadi 'YYYY-MM-DD'
  decimalNumbers: true,     // DECIMAL jadi angka, bukan string
  // Kolom TINYINT(1) (is_available, is_read) dikirim sebagai true/false, bukan 1/0.
  typeCast: (field, next) => {
    if (field.type === 'TINY' && field.length === 1) {
      const v = field.string();
      return v === null ? null : v === '1';
    }
    return next();
  },
});

// Semua koneksi memakai UTC supaya NOW()/CURDATE() konsisten.
pool.on('connection', (conn) => conn.query("SET time_zone = '+00:00'"));

/** Jalankan query dan kembalikan hasilnya (array baris untuk SELECT, header untuk INSERT/UPDATE). */
async function q(executor, sql, params) {
  const [result] = await executor.query(sql, params);
  return result;
}

const query = (sql, params) => q(pool, sql, params);

/**
 * Jalankan fn(conn) dalam satu transaksi. Commit bila selesai,
 * rollback bila ada error (termasuk HttpError yang sengaja dilempar).
 */
async function withTx(fn) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (e) {
    try { await conn.rollback(); } catch { /* abaikan */ }
    throw e;
  } finally {
    conn.release();
  }
}

module.exports = { pool, q, query, withTx };
