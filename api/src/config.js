'use strict';
require('dotenv').config();

// Baca angka dari env; nilai 0 tetap dianggap valid (bukan jatuh ke default).
const num = (v, fallback) =>
  v !== undefined && v !== '' && Number.isFinite(Number(v)) ? Number(v) : fallback;

module.exports = {
  port: num(process.env.PORT, 3000),
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-jangan-dipakai-di-produksi',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  donorIntervalDays: num(process.env.DONOR_INTERVAL_DAYS, 90),
  stageTimeoutMin: num(process.env.STAGE_TIMEOUT_MIN, 10),
  donorsPerUnit: num(process.env.DONORS_PER_UNIT, 3),
};
