; main_program xgps2utc
;
; Exercise program for gps2utc
;
; B. Knapp, 2001-05-15
;
; RCS tags
;
; $Header: /mizar/proj/sorce/razor_db/RAZOR_UNIVERSE/DOMAIN_01/sorce/Archive/RZ_VCS/idl/datetime/xgps2utc.pro,v 1.2 2002/01/08 23:43:25 knapp Exp $
;
; $Log: xgps2utc.pro,v $
; Revision 1.2  2002/01/08 23:43:25  knapp
; Modify to make the tests round-trip pass-fail tests
;
;
; Test around 1999 Jan 1.0, where a leap second occurred.
; (Note: round-trip test is not possible, since the gps-to-utc
; conversion function is not one-to-one, i.e., it is not
; invertible.)
;
  jd0 = yd2jd(1980006.d0)
  jd1 = yd2jd(1999001.d0)
  utc0 = (jd1-jd0)*8.64d4
  utc = dindgen(5) - 2.d0 + utc0
  gps0 = utc0 + 13.d0
  gps = dindgen(5) - 2.d0 + gps0

; UTC0 (utc[2]) is really 1 second delayed (retarded) and occurs twice!
  utc[0] = utc[0]+1
  utc[1] = utc[1]+1
;
  nFail = 0
  for j=0,4 do begin
    if long64(gps2utc(gps[j])) ne long64(utc[j]) then nFail = nFail+1
  endfor
  if nFail gt 0 then $
    print, 'Fail!' $
  else $
    print, 'Pass.'
  end
