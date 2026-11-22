-- =====================================================================
-- Skema database: Aplikasi Siaga Donor Darah (MySQL 8 / MariaDB 10.5+)
-- Cara pakai (Laragon): buka HeidiSQL -> File -> Run SQL file -> pilih file ini.
-- Atau dari terminal:   mysql -u root < schema.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS siaga_donor
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE siaga_donor;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS notifications, donations, request_matches,
                     blood_requests, donor_profiles, users;
SET FOREIGN_KEY_CHECKS = 1;

-- Akun. Satu akun bisa jadi pemohon sekaligus pendonor (donor_profiles opsional).
CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone         VARCHAR(20),
  role          VARCHAR(10)  NOT NULL DEFAULT 'user',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_users_role CHECK (role IN ('user', 'admin'))
) ENGINE = InnoDB;

-- Profil pendonor: golongan darah, lokasi, ketersediaan, donor terakhir.
CREATE TABLE donor_profiles (
  user_id            INT PRIMARY KEY,
  blood_type         VARCHAR(2) NOT NULL,
  rhesus             CHAR(1)    NOT NULL,
  latitude           DOUBLE     NOT NULL,
  longitude          DOUBLE     NOT NULL,
  is_available       TINYINT(1) NOT NULL DEFAULT 1,
  last_donation_date DATE NULL,
  updated_at         DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_donor_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_donor_type CHECK (blood_type IN ('A', 'B', 'AB', 'O')),
  CONSTRAINT chk_donor_rh   CHECK (rhesus IN ('+', '-')),
  CONSTRAINT chk_donor_lat  CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT chk_donor_lon  CHECK (longitude BETWEEN -180 AND 180)
) ENGINE = InnoDB;

-- Permintaan darah dari pemohon (pasien/keluarga).
CREATE TABLE blood_requests (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  requester_id     INT NOT NULL,
  patient_name     VARCHAR(100) NOT NULL,
  blood_type       VARCHAR(2)   NOT NULL,
  rhesus           CHAR(1)      NOT NULL,
  units_needed     INT          NOT NULL,
  hospital_name    VARCHAR(150) NOT NULL,
  latitude         DOUBLE       NOT NULL,
  longitude        DOUBLE       NOT NULL,
  note             TEXT NULL,
  status           VARCHAR(25)  NOT NULL DEFAULT 'pending_verification',
  reject_reason    TEXT NULL,
  verified_by      INT NULL,
  verified_at      DATETIME NULL,
  stage_index      INT NOT NULL DEFAULT 0,     -- tahap radius yang sedang berjalan
  stage_started_at DATETIME NULL,              -- kapan tahap itu dimulai
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_req_requester FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_req_verifier  FOREIGN KEY (verified_by)  REFERENCES users(id),
  CONSTRAINT chk_req_type  CHECK (blood_type IN ('A', 'B', 'AB', 'O')),
  CONSTRAINT chk_req_rh    CHECK (rhesus IN ('+', '-')),
  CONSTRAINT chk_req_units CHECK (units_needed BETWEEN 1 AND 20),
  CONSTRAINT chk_req_status CHECK (status IN ('pending_verification', 'active', 'fulfilled',
                                              'rejected', 'expired', 'cancelled')),
  INDEX idx_requests_status (status),
  INDEX idx_requests_requester (requester_id)
) ENGINE = InnoDB;

-- Undangan ke pendonor untuk satu permintaan + responsnya.
CREATE TABLE request_matches (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  request_id   INT NOT NULL,
  donor_id     INT NOT NULL,
  distance_km  DECIMAL(7,2) NOT NULL,
  stage_index  INT NOT NULL,
  status       VARCHAR(15) NOT NULL DEFAULT 'notified',
  notified_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  responded_at DATETIME NULL,
  CONSTRAINT fk_match_request FOREIGN KEY (request_id) REFERENCES blood_requests(id) ON DELETE CASCADE,
  CONSTRAINT fk_match_donor   FOREIGN KEY (donor_id)   REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_match_status CHECK (status IN ('notified', 'accepted', 'declined', 'donated')),
  UNIQUE KEY uq_match (request_id, donor_id),
  INDEX idx_matches_donor (donor_id, status)
) ENGINE = InnoDB;

-- Riwayat donor yang sudah dikonfirmasi.
CREATE TABLE donations (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  request_id   INT NOT NULL,
  donor_id     INT NOT NULL,
  confirmed_by INT NOT NULL,
  donated_at   DATE NOT NULL,
  CONSTRAINT fk_don_request   FOREIGN KEY (request_id)   REFERENCES blood_requests(id) ON DELETE CASCADE,
  CONSTRAINT fk_don_donor     FOREIGN KEY (donor_id)     REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_don_confirmer FOREIGN KEY (confirmed_by) REFERENCES users(id),
  UNIQUE KEY uq_donation (request_id, donor_id)
) ENGINE = InnoDB;

-- Notifikasi dalam aplikasi (diambil klien lewat polling, tanpa Firebase/FCM).
CREATE TABLE notifications (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  request_id INT NULL,
  title      VARCHAR(150) NOT NULL,
  message    TEXT NOT NULL,
  is_read    TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notif_user    FOREIGN KEY (user_id)    REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_request FOREIGN KEY (request_id) REFERENCES blood_requests(id) ON DELETE CASCADE,
  INDEX idx_notif_user (user_id, is_read, id)
) ENGINE = InnoDB;
