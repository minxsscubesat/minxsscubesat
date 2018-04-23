CREATE TABLE `minxss_sdcard_db`.`sci` (
  `GPS_time` DECIMAL(17,7) UNSIGNED NOT NULL COMMENT 'This is the time in GPS seconds that the data was logged on MinXSS. ',
  `UTC_log_time` DATETIME NULL COMMENT 'The date/time, in UTC, that the data was logged',
  PRIMARY KEY (`GPS_time`)  COMMENT '')
COMMENT = 'Stores data coming from SCI packets.';