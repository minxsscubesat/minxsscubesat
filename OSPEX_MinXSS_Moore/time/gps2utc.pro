  function gps2utc, gps
;
; Returns the UTC clock time (elapsed seconds since 1980 Jan 6.0)
; given the GPS time (elapsed TAI seconds since 1980 Jan 6.0).
;
; B. Knapp, 2001-05-15
;
; GPS epoch
  jd0 = yd2jd(1980006.d0)
  dTAI0 = tai_utc(jd0)
;
; 
; Assume the argument is UTC, then iterate until the correct dTAI
; is found
  jd1 = jd0 + gps/8.64d4
  dTAI1 = tai_utc(jd1)-dTAI0
  jd2 = jd1 - dTAI1/8.64d10
  dTAI2 = tai_utc(jd2)-dTAI0
  if dTAI2 eq dTAI1 then begin
     dTAI = dTAI2
  endif else begin
     jd3 = jd1-dTAI2/8.64d10
     dTAI3 = tai_utc(jd3)-dTAI0
     if dTAI3 eq dTAI2 then begin
        dTAI = dTAI3
     endif else begin
        jd4 = jd1-dTAI3/8.64d10
        dTAI = tai_utc(jd4)-dTAI0
     endelse
  endelse
;
  return, gps-dTAI/1.d6
  end

