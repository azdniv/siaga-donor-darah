'use strict';
/**
 * Inti aplikasi: logika pencocokan pendonor.
 * Semua fungsi di sini murni (tanpa database) supaya mudah diuji.
 *
 * Tiga syarat pendonor layak:
 *   1. golongan darah + rhesus kompatibel dengan pasien
 *   2. masa jeda donor sudah terpenuhi (default 90 hari)
 *   3. berada dalam radius tahap saat ini, diurutkan dari yang terdekat
 */

// Tahap penyebaran: radius diperluas bertahap bila kantong darah belum terpenuhi.
const RADIUS_STAGES_KM = [3, 5, 10, 25, 50];

// Golongan ABO: donor -> penerima yang boleh menerima (donor sel darah merah).
const ABO_CAN_GIVE_TO = {
  O: ['O', 'A', 'B', 'AB'],
  A: ['A', 'AB'],
  B: ['B', 'AB'],
  AB: ['AB'],
};

/** Apakah donor boleh mendonorkan darah ke pasien (ABO + rhesus). */
function canDonate(donor, recipient) {
  if (!ABO_CAN_GIVE_TO[donor.blood_type]) return false;
  const aboOk = ABO_CAN_GIVE_TO[donor.blood_type].includes(recipient.blood_type);
  // Rhesus negatif hanya boleh menerima dari rhesus negatif.
  const rhOk = recipient.rhesus === '+' ? true : donor.rhesus === '-';
  return aboOk && rhOk;
}

/** Jarak dua titik koordinat (km) dengan rumus Haversine. */
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

/** Apakah masa jeda donor terakhir sudah lewat. Belum pernah donor = boleh. */
function isPastDonationInterval(lastDonationDate, now = new Date(), intervalDays = 90) {
  if (!lastDonationDate) return true;
  const last = new Date(lastDonationDate);
  const diffDays = (now.getTime() - last.getTime()) / 86400000;
  return diffDays >= intervalDays;
}

/**
 * Pilih pendonor untuk satu tahap.
 * @param request  {blood_type, rhesus, latitude, longitude, requester_id}
 * @param donors   [{user_id, blood_type, rhesus, latitude, longitude, is_available, last_donation_date}]
 * @param opts     {radiusKm, limit, excludeIds, now, intervalDays}
 * @returns        [{donor, distance_km}] urut dari terdekat
 */
function selectDonors(request, donors, opts) {
  const {
    radiusKm,
    limit = Infinity,
    excludeIds = [],
    now = new Date(),
    intervalDays = 90,
  } = opts;
  const excluded = new Set(excludeIds);

  return donors
    .filter((d) => d.is_available)
    .filter((d) => d.user_id !== request.requester_id)
    .filter((d) => !excluded.has(d.user_id))
    .filter((d) => canDonate(d, request))
    .filter((d) => isPastDonationInterval(d.last_donation_date, now, intervalDays))
    .map((d) => ({
      donor: d,
      distance_km: haversineKm(request.latitude, request.longitude, d.latitude, d.longitude),
    }))
    .filter((x) => x.distance_km <= radiusKm)
    .sort((a, b) => a.distance_km - b.distance_km)
    .slice(0, limit);
}

module.exports = {
  RADIUS_STAGES_KM,
  canDonate,
  haversineKm,
  isPastDonationInterval,
  selectDonors,
};
