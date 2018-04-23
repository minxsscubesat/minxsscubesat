function la_to_jd,la
;
; $Id: la_to_jd.pro,v 1.2 2002/08/07 22:06:48 bboyle Exp $
;
if n_params() ne 1 then begin
  message,/info,'Usage: result=la_to_jd(la)'
  return,0.0
endif

year = double(strmid(la,0,4))
doy = double(strmid(la,5,3))
hour = double(strmid(la,9,2))
minute = double(strmid(la,12,2))
for i=0,n_elements(la)-1 do $
  second = double(strmid(la(i),15,strlen(la(i))-15))
yyddd=year*1000 + doy + hour/24.0d0 + minute/1440.0d0 + second/86400.0d0

return,yd2jd(yyddd)
end
