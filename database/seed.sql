-- Data contoh untuk demo (sekitar Surabaya). Jalankan setelah schema.sql.
-- Password contoh: admin -> admin123, semua akun lain -> password123
-- (nilai di bawah adalah hash bcrypt, bukan password asli)
USE siaga_donor;

INSERT INTO users (name, email, password_hash, phone, role) VALUES
  ('Admin PMI',      'admin@siaga.test', '$2a$10$R5lNfVdCsFwZAMGPUU2ExOyg3TD/NhTqX3Gjdkwgo.qqG3OFES4.2', '081200000000', 'admin'),
  ('Budi Pemohon',   'budi@siaga.test',  '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000001', 'user'),
  ('Sari Pendonor',  'sari@siaga.test',  '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000002', 'user'),
  ('Dimas Pendonor', 'dimas@siaga.test', '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000003', 'user'),
  ('Lina Pendonor',  'lina@siaga.test',  '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000004', 'user'),
  ('Rizky Pendonor', 'rizky@siaga.test', '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000005', 'user'),
  ('Wulan Pendonor', 'wulan@siaga.test', '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000006', 'user'),
  ('Fajar Pendonor', 'fajar@siaga.test', '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000007', 'user'),
  ('Nadia Pendonor', 'nadia@siaga.test', '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000008', 'user'),
  ('Teguh Pendonor', 'teguh@siaga.test', '$2a$10$0uuFxJGTkJmEJf.eLd.IsuN8sj7F.BitomZDG7P5Tgt218phhAqSS', '081200000009', 'user');

-- Pendonor tersebar dari dekat sampai jauh dari RS di pusat Surabaya (-7.2575, 112.7521).
-- Ada yang masih dalam masa jeda donor dan ada yang sedang tidak tersedia, untuk didemokan.
INSERT INTO donor_profiles (user_id, blood_type, rhesus, latitude, longitude, is_available, last_donation_date) VALUES
  (3,  'O',  '+', -7.2650, 112.7480, 1, DATE_SUB(CURDATE(), INTERVAL 200 DAY)),  -- sangat dekat, eligible
  (4,  'A',  '+', -7.2800, 112.7600, 1, DATE_SUB(CURDATE(), INTERVAL 30 DAY)),   -- masih masa jeda
  (5,  'O',  '-', -7.3000, 112.7300, 1, NULL),                                   -- donor universal, belum pernah donor
  (6,  'B',  '+', -7.3200, 112.7900, 1, DATE_SUB(CURDATE(), INTERVAL 120 DAY)),
  (7,  'A',  '-', -7.4500, 112.7200, 1, DATE_SUB(CURDATE(), INTERVAL 100 DAY)),  -- ~22 km
  (8,  'AB', '+', -7.2400, 112.7400, 0, DATE_SUB(CURDATE(), INTERVAL 365 DAY)),  -- sedang tidak tersedia
  (9,  'O',  '+', -7.5300, 112.6900, 1, DATE_SUB(CURDATE(), INTERVAL 300 DAY)),  -- ~32 km
  (10, 'B',  '-', -7.9800, 112.6300, 1, DATE_SUB(CURDATE(), INTERVAL 150 DAY));  -- Malang, jauh
