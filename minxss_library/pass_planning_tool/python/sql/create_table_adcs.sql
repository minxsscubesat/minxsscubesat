CREATE TABLE `minxss_sdcard_db`.`adcs` (
  `GPS_time` DECIMAL(17,7) NOT NULL COMMENT 'This is the time in GPS seconds that the data was logged on MinXSS. ',
  `packet_type` TINYINT NOT NULL COMMENT 'There are 4 ADCS packets. This column distinguishes among the four, having valid values of 1,2,3, or 4.',
  `UTC_log_time` DATETIME NULL COMMENT 'The date/time, in UTC, that the data was logged',
  PRIMARY KEY (`GPS_time`, `packet_type`)  COMMENT '');