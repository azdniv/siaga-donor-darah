'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  canDonate,
  haversineKm,
  isPastDonationInterval,
  selectDonors,
} = require('../src/services/matching');

const TYPES = ['A', 'B', 'AB', 'O'];
const RH = ['+', '-'];

test('O- adalah donor universal', () => {
  for (const t of TYPES) {
    for (const r of RH) {
      assert.equal(canDonate({ blood_type: 'O', rhesus: '-' }, { blood_type: t, rhesus: r }), true);
    }
  }
});

test('AB+ hanya bisa menerima, bukan donor universal', () => {
  for (const t of TYPES) {
    for (const r of RH) {
      assert.equal(canDonate({ blood_type: t, rhesus: r }, { blood_type: 'AB', rhesus: '+' }), true);
    }
  }
  assert.equal(canDonate({ blood_type: 'AB', rhesus: '+' }, { blood_type: 'O', rhesus: '+' }), false);
});

test('rhesus positif tidak boleh mendonor ke pasien rhesus negatif', () => {
  assert.equal(canDonate({ blood_type: 'A', rhesus: '+' }, { blood_type: 'A', rhesus: '-' }), false);
  assert.equal(canDonate({ blood_type: 'A', rhesus: '-' }, { blood_type: 'A', rhesus: '+' }), true);
});

test('A tidak bisa ke B dan sebaliknya', () => {
  assert.equal(canDonate({ blood_type: 'A', rhesus: '+' }, { blood_type: 'B', rhesus: '+' }), false);
  assert.equal(canDonate({ blood_type: 'B', rhesus: '+' }, { blood_type: 'A', rhesus: '+' }), false);
});

test('jumlah pasangan kompatibel total 27 dari 64', () => {
  let n = 0;
  for (const dt of TYPES) for (const dr of RH) for (const rt of TYPES) for (const rr of RH) {
    if (canDonate({ blood_type: dt, rhesus: dr }, { blood_type: rt, rhesus: rr })) n++;
  }
  assert.equal(n, 27);
});

test('haversine: Surabaya - Malang sekitar 75-80 km', () => {
  const d = haversineKm(-7.2575, 112.7521, -7.9666, 112.6326);
  assert.ok(d > 75 && d < 82, `jarak ${d}`);
  assert.equal(Math.round(haversineKm(-7.25, 112.75, -7.25, 112.75)), 0);
});

test('masa jeda donor 90 hari', () => {
  const now = new Date('2026-11-21T00:00:00Z');
  assert.equal(isPastDonationInterval(null, now), true);
  assert.equal(isPastDonationInterval('2026-08-23', now), true); // 90 hari
  assert.equal(isPastDonationInterval('2026-08-24', now), false); // 89 hari
  assert.equal(isPastDonationInterval('2026-10-30', now), false);
});

const hospital = { blood_type: 'A', rhesus: '+', latitude: -7.2575, longitude: 112.7521, requester_id: 1 };
const mk = (id, bt, rh, lat, lon, extra = {}) => ({
  user_id: id, blood_type: bt, rhesus: rh, latitude: lat, longitude: lon,
  is_available: true, last_donation_date: null, ...extra,
});

test('selectDonors: hanya yang kompatibel, tersedia, lewat masa jeda, dalam radius, urut terdekat', () => {
  const now = new Date('2026-11-21T00:00:00Z');
  const donors = [
    mk(10, 'A', '+', -7.2800, 112.7600),                                   // ~2.9 km, ok
    mk(11, 'O', '-', -7.2650, 112.7480),                                   // ~1.2 km, ok (lebih dekat)
    mk(12, 'B', '+', -7.2600, 112.7500),                                   // golongan tidak cocok
    mk(13, 'A', '+', -7.2600, 112.7500, { is_available: false }),          // tidak tersedia
    mk(14, 'A', '+', -7.2600, 112.7500, { last_donation_date: '2026-11-01' }), // masih masa jeda
    mk(15, 'A', '+', -7.4500, 112.7200),                                   // ~21 km, di luar 3 km
    mk(1, 'A', '+', -7.2576, 112.7522),                                    // pemohon sendiri
  ];
  const res = selectDonors(hospital, donors, { radiusKm: 3, now });
  assert.deepEqual(res.map((x) => x.donor.user_id), [11, 10]);
  assert.ok(res[0].distance_km < res[1].distance_km);
});

test('selectDonors: memperluas radius menambah kandidat, excludeIds & limit dihormati', () => {
  const now = new Date('2026-11-21T00:00:00Z');
  const donors = [
    mk(10, 'A', '+', -7.2800, 112.7600),
    mk(11, 'O', '-', -7.2650, 112.7480),
    mk(15, 'A', '+', -7.4500, 112.7200),
  ];
  assert.equal(selectDonors(hospital, donors, { radiusKm: 3, now }).length, 2);
  assert.equal(selectDonors(hospital, donors, { radiusKm: 25, now }).length, 3);
  const next = selectDonors(hospital, donors, { radiusKm: 25, now, excludeIds: [10, 11] });
  assert.deepEqual(next.map((x) => x.donor.user_id), [15]);
  assert.equal(selectDonors(hospital, donors, { radiusKm: 25, now, limit: 1 }).length, 1);
});
