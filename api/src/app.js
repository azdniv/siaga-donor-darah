'use strict';
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/auth', require('./routes/auth'));
app.use('/donors', require('./routes/donors'));
app.use('/requests', require('./routes/requests'));
app.use('/notifications', require('./routes/notifications'));
app.use('/admin', require('./routes/admin'));

app.use((req, res) => res.status(404).json({ error: 'Endpoint tidak ditemukan' }));

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err.status) return res.status(err.status).json({ error: err.message });
  console.error(err);
  res.status(500).json({ error: 'Terjadi kesalahan pada server' });
});

module.exports = app;
