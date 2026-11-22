'use strict';
const cron = require('node-cron');
const app = require('./app');
const config = require('./config');
const { escalateRequests } = require('./services/dispatch');

// Tiap menit: perluas radius untuk permintaan yang belum terpenuhi.
cron.schedule('* * * * *', async () => {
  try {
    const n = await escalateRequests();
    if (n) console.log(`[cron] ${n} permintaan diperluas/dikedaluwarsakan`);
  } catch (e) {
    console.error('[cron] gagal:', e.message);
  }
});

app.listen(config.port, () => {
  console.log(`API Siaga Donor Darah berjalan di http://localhost:${config.port}`);
});
