;
;	minxss1_time_offset.pro
;
;	Fix time offset for RTC clock drift during MinXSS-1 mission
;
;	Changes in minxss_read_packets.pro
; AFTER Line 451:  packet_time = double(packet_time1) + packet_time2 / 1000.D0
;		packet_time += minxss1_time_offset( packet_time )
;
;	INPUT:
;		GPS_seconds
;	OUTPUT:
;		offset in seconds to add to the MinXSS time in units of GPS_seconds
;
function minxss1_time_offset, packet_gps_time
	;
	;		Robert Sewell analysis of real-time RTC clock messages time versus HYDRA clock time
	;		Fit for Period 1 is before Aug 17, 2016 and Period 2 is after Aug 25, 2016
	packet_jd = gps2jd(packet_gps_time)
	time_offset = 0.0D0
	if (packet_jd lt 2457617.5D0 ) then time_offset = -0.084309179D0 * packet_jd + 207198.41D0
	if (packet_jd ge 2457626.5D0 ) then time_offset = -0.093409167D0 * packet_jd + 229565.90D0
	return, time_offset
END

