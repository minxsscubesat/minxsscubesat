PRO print_current_gpstime

WHILE 1 DO BEGIN
  print, long(jd2gps(JPMiso2jd(jpmsystime(/UTC))))
  wait, 1
ENDWHILE

END