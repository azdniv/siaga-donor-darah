'use strict';
/**
 * Penyebaran permintaan ke pendonor secara bertahap per radius,
 * dan perluasan otomatis bila kantong darah belum terpenuhi.
 * Semua fungsi menerima `conn` (koneksi dalam transaksi).
 */
const db = require('../db');
const config = require('../config');
const { RADIUS_STAGES_KM, selectDonors } = require('./matching');

/** Kirim undangan untuk tahap `stageIndex`. Mengembalikan jumlah pendonor yang diundang. */
async function dispatchStage(conn, request, stageIndex) {
  const radiusKm = RADIUS_STAGES_KM[stageIndex];

  const donors = await db.q(conn, 'SELECT * FROM donor_profiles');
  const already = await db.q(conn, 'SELECT donor_id FROM request_matches WHERE request_id = ?', [request.id]);

  const picked = selectDonors(request, donors, {
    radiusKm,
    limit: request.units_needed * config.donorsPerUnit,
    excludeIds: already.map((r) => r.donor_id),
    intervalDays: config.donorIntervalDays,
  });

  for (const { donor, distance_km } of picked) {
    await db.q(
      conn,
      `INSERT INTO request_matches (request_id, donor_id, distance_km, stage_index)
       VALUES (?, ?, ?, ?)`,
      [request.id, donor.user_id, distance_km.toFixed(2), stageIndex]
    );
    await db.q(
      conn,
      `INSERT INTO notifications (user_id, request_id, title, message) VALUES (?, ?, ?, ?)`,
      [
        donor.user_id,
        request.id,
        `Dibutuhkan darah ${request.blood_type}${request.rhesus}`,
        `${request.hospital_name} membutuhkan ${request.units_needed} kantong darah ` +
          `${request.blood_type}${request.rhesus}. Jarak sekitar ${distance_km.toFixed(1)} km dari lokasimu.`,
      ]
    );
  }

  await db.q(conn, 'UPDATE blood_requests SET stage_index = ?, stage_started_at = NOW() WHERE id = ?', [
    stageIndex,
    request.id,
  ]);
  return picked.length;
}

/** Aktifkan permintaan yang sudah diverifikasi: mulai dari tahap radius pertama. */
async function activateRequest(conn, request) {
  await db.q(conn, "UPDATE blood_requests SET status = 'active' WHERE id = ?", [request.id]);
  return dispatchStage(conn, request, 0);
}

/** Tandai terpenuhi jika donor terkonfirmasi >= kebutuhan. */
async function markFulfilledIfDone(conn, requestId) {
  const rows = await db.q(
    conn,
    `SELECT r.units_needed, (SELECT COUNT(*) FROM donations d WHERE d.request_id = r.id) AS done
       FROM blood_requests r WHERE r.id = ?`,
    [requestId]
  );
  if (rows.length && Number(rows[0].done) >= rows[0].units_needed) {
    await db.q(conn, "UPDATE blood_requests SET status = 'fulfilled' WHERE id = ?", [requestId]);
    return true;
  }
  return false;
}

/**
 * Dijalankan berkala (cron). Untuk permintaan aktif yang tahapnya sudah lewat batas waktu
 * dan belum cukup pendonor yang menyanggupi: perluas ke radius berikutnya,
 * atau kedaluwarsakan bila radius terakhir sudah habis.
 */
async function escalateRequests() {
  const due = await db.query(
    `SELECT r.*,
            (SELECT COUNT(*) FROM request_matches m
              WHERE m.request_id = r.id AND m.status IN ('accepted', 'donated')) AS committed
       FROM blood_requests r
      WHERE r.status = 'active'
        AND r.stage_started_at <= NOW() - INTERVAL ? MINUTE`,
    [config.stageTimeoutMin]
  );

  let escalated = 0;
  for (const req of due) {
    if (Number(req.committed) >= req.units_needed) continue; // sudah cukup yang menyanggupi
    try {
      await db.withTx(async (conn) => {
        const next = req.stage_index + 1;
        if (next >= RADIUS_STAGES_KM.length) {
          await db.q(conn, "UPDATE blood_requests SET status = 'expired' WHERE id = ?", [req.id]);
          await db.q(
            conn,
            `INSERT INTO notifications (user_id, request_id, title, message)
             VALUES (?, ?, 'Permintaan kedaluwarsa', ?)`,
            [req.requester_id, req.id,
             'Radius pencarian sudah mencapai batas dan kantong darah belum terpenuhi. Hubungi PMI terdekat.']
          );
        } else {
          const n = await dispatchStage(conn, req, next);
          await db.q(
            conn,
            `INSERT INTO notifications (user_id, request_id, title, message)
             VALUES (?, ?, 'Pencarian diperluas', ?)`,
            [req.requester_id, req.id,
             `Pencarian diperluas ke radius ${RADIUS_STAGES_KM[next]} km (${n} pendonor baru diundang).`]
          );
        }
      });
      escalated++;
    } catch (e) {
      console.error('Gagal memperluas permintaan', req.id, e.message);
    }
  }
  return escalated;
}

module.exports = { dispatchStage, activateRequest, markFulfilledIfDone, escalateRequests };
