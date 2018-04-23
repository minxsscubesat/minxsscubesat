;+
; NAME:
;   minxss_packet_time_to_utc
;
; PURPOSE:
;   Convert the time provided in any/all MinXSS packets into UTC
;
; INPUTS:
;   packetTime [double]: GPS time from a MinXSS packet structure, which is always in the form packet.time, where
;                        packet is hk, log, sci, adcs1, adcs2, adcs3, or adcs4. 
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   timeUtcHours [double]: The UTC time in hours. This is the same format that the frequently used "ptime" variable
;                          defined in many of the minxss plotting routines. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   timeUtcHours = minxss_packet_time_to_utc(hk.time)
;
; MODIFICATION HISTORY:
;   2015/08/27: James Paul Mason: Wrote script.
;-
FUNCTION minxss_packet_time_to_utc, packetTime

; Do the conversion - extracted from minxss_plots_adcs
packet_time_yd = jd2yd(gps2jd(packetTime))
time1 = min(packet_time_yd)
time_date = long(time1)
time_year = long(time_date / 1000.)
time_doy = time_date mod 1000L
yd_base = long(time_year * 1000L + time_doy)
timeUtcHours = (packet_time_yd - yd_base) * 24.  ; convert to hours since time1 YD

return, timeUtcHours
END