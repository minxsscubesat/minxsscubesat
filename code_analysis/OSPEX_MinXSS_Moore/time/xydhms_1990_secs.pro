; main_program xydhms_1990_secs
;
; Exercise driver for function ydhms_1990_secs
;
; B. Knapp, 1999-03-17
;
  N_TRIALS = 100l
;
  for j=1,N_TRIALS do begin
;
;    Random date in 1998-2000 time period
     s1 = (8.d0+3.d0*randomu( seed ))*365.25d0*86400.d0
     d  = ydhms_1990_secs( s1 )
     s2 = ydhms_1990_secs( d )
     print, j, s1, d, s2, s1-s2, format="(i6,e13.6,a20,e13.6,e10.3)"
;
  endfor
  end
