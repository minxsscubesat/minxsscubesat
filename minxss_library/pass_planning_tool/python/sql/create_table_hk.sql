CREATE TABLE hk (
  GPS_time DECIMAL(17,7) UNSIGNED NOT NULL COMMENT 'This is the time in GPS seconds that the data was logged on MinXSS. ',
  HK_SD_write MEDIUMINT UNSIGNED NULL COMMENT 'HK SD write offset',
  SCI_SD_write MEDIUMINT UNSIGNED NULL COMMENT '',
  LOG_SD_write MEDIUMINT UNSIGNED NULL COMMENT '',
  LOG_SD_read MEDIUMINT UNSIGNED NULL COMMENT 'LOG SD read offset. We want all LOG data, so it\'s easiest if we check both read and write',
  ADCS_SD_write MEDIUMINT NULL COMMENT '',
  XIMG_SD_write MEDIUMINT NULL COMMENT '',
  DIAG_SD_write MEDIUMINT NULL COMMENT '',
  is_eclipse TINYINT NULL COMMENT 'are we in eclipse during this time?',
  UTC_rx_time DATETIME NULL COMMENT 'The date/time, in UTC, that we received the data',
  UTC_log_time DATETIME NULL COMMENT 'The date/time, in UTC, that the data was logged',
  PRIMARY KEY (GPS_time)  COMMENT '')
COMMENT = 'Stores data coming from the HK packets.';