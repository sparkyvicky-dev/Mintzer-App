-- V3 push engine — CREATE ONLY. Does not alter users / orders / existing notification rows.
-- Run once in phpMyAdmin on the live Mintzer DB. Safe to re-run (IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS `v3_push_devices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `fcm_token` VARCHAR(512) NOT NULL,
  `platform` VARCHAR(32) NOT NULL DEFAULT 'android',
  `app_channel` VARCHAR(32) NOT NULL DEFAULT 'flutter_v3',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `v3_push_devices_token_uq` (`fcm_token`(191)),
  KEY `v3_push_devices_user_idx` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `v3_push_prefs` (
  `user_id` BIGINT UNSIGNED NOT NULL,
  `master` TINYINT(1) NOT NULL DEFAULT 1,
  `deals` TINYINT(1) NOT NULL DEFAULT 1,
  `orders` TINYINT(1) NOT NULL DEFAULT 1,
  `payments` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `v3_push_outbox` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `event_type` VARCHAR(64) NOT NULL,
  `channel` VARCHAR(32) NOT NULL DEFAULT 'mintzer_deals',
  `title` VARCHAR(255) NOT NULL,
  `body` VARCHAR(512) NOT NULL,
  `data_json` JSON NULL,
  `status` VARCHAR(24) NOT NULL DEFAULT 'pending',
  `scheduled_at` TIMESTAMP NULL DEFAULT NULL,
  `sent_at` TIMESTAMP NULL DEFAULT NULL,
  `error` VARCHAR(255) NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `v3_push_outbox_user_status_idx` (`user_id`, `status`),
  KEY `v3_push_outbox_sched_idx` (`status`, `scheduled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `v3_push_send_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `event_type` VARCHAR(64) NOT NULL,
  `deal_id` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `v3_push_send_log_user_day_idx` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
