;
;	Convert launch insertion orbital elements into TLE
;
;	TLE definitions on Space-Track also here:
;		https://www.celestrak.com/NORAD/documentation/tle-fmt.php
;
;	2/12/22  Tom Woods
;
;	INCOMPLETE code - do NOT use
;
function tle_checksum, string

checksum = 0

return, checksum
end

pro tle_from_orbital_elements, epoch_yyyydoy, inclination, RAAN, Eccentricity, $
			Argument_Perigee, True_Anomaly, tle=tle

if n_params() lt 6 then begin
	print, 'USAGE: tle_from_orbital_elements, epoch_yyyydoy, inclination, RAAN, Eccentricity, $'
	print, '                       Argument_Perigee, True_Anomaly'
	tle = -1
	return
endif

;mean_anomaly_radians = Mean_Anomaly * !pi / 180.D0
;true_anomaly = Mean_Anomaly + (2.*Eccentricity - 0.25*Eccentricity^3.) $
;			+ (5./4.) * (Eccentricity^2.) * sin(2.*mean_anomaly_radians) $
;			+ (13./12.) * (Eccentricity^3.) * sin(3.*mean_anomaly_radians)

mean_anomaly = True_Anomaly - (2.*Eccentricity - 0.25*Eccentricity^3.)
print, 'Mean Anomaly (deg) = ', Mean_Anomaly
print, 'True Anomaly (deg) = ', True_Anomaly

tle = strarr(2)
tle[0] = ' '
tle[1] = ' '

print, 'TLE is '
print, tle[0]
print, tle[1]

return
end

