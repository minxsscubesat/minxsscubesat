;
; $Id: jd_to_la.pro,v 1.2 2002/08/07 22:16:31 bboyle Exp $
;
pro jd_to_la,jd,la

yd = jd2yd(jd)

yr = fix(yd / 1000)
doy = fix(yd - yr * 1000)
fraction = yd - long(yd)
hr = fix((fraction + 0.5d0 / 86400.0d0) * 24)
minute = fix((fraction - fix(hr) / 24.0d0 + 0.5d0 / 86400.d0) * 1440)
sec = fix((fraction - fix(hr) / 24.0d0 - fix(minute) / 1440.0d0 + $
	0.5d0 / 86400.0d0)*86400)

yr = strtrim(yr,2)
doy = strmid(strtrim(doy+1000,2),1,3)
hr = strmid(strtrim(hr+100,2),1,2)
minute = strmid(strtrim(minute+100,2),1,2)
sec = strmid(strtrim(sec+100,2),1,2)

la = yr + '/' + doy + '-' + hr + ':' + minute + ':' + sec

end
