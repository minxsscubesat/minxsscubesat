  function ymd2vms, y, m, d

; Given date(s) in the form of [yyyy, mm, dd.dd], returns VMS date
; string(s) of the form 'dd-mmm-yyyy hh:mm:ss.ss'.

; B. Knapp, 97.11.14
;           98.06.11, IDL v. 5 compliance
;           98.06.12, Use round instead of nint

; Input must be three scalars or three 1-dimensional arrays of length n,
; or single 1-dimensional array of length 3, or a 2-dimensional array
; with dimensions [3,n].
;
  info = size(y)
  case n_params() of
       1:begin
           show_usage = info[1] ne 3
           if not show_usage then begin
             yloc = (y[0,*])[*]
             mloc = (y[1,*])[*]
             dloc = double((y[2,*])[*])
           endif
         end
       3:begin
           ny = n_elements(y)
           show_usage = ny ne n_elements(m) or ny ne n_elements(d)
           if not show_usage then begin
             yloc = y
             mloc = m
             dloc = double(d)
           endif
         end
    else:show_usage = 1 eq 1
  endcase
  
  if show_usage then begin
     print,"                                                               "
     print,"  YMD2VMS translates dates of the form [yyyy, mm, dd.dd] to    "
     print,"  VMS date strings of the form 'dd-mmm-yyyy hh:mm:ss.ss. The   "
     print,"  input date may be a single date (three scalars y, m, d, or   "
     print,"  a 1-dimensional array of length 3) or multiple dates (three  "
     print,"  1-dimensional arrays of the same length n, or a 2-dimensional"
     print,"  array with dimensions [3,n]).                                "
     print,"                                                               "
     print,"  vms = ymd2vms( ymd )                                         "
     return,''
  endif
;
  month_names  = [ 'Jan','Feb','Mar','Apr','May','Jun', $
                   'Jul','Aug','Sep','Oct','Nov','Dec' ]
;
; Input must be handled in blocks of 1024, due to IDL's string-array
; conversion limitation
  n = n_elements( yloc )
  for k=0L,n-1,1024 do begin
     u = (k+1023L) < (n-1)
     yk = yloc[k:u]
     mk = mloc[k:u]
     dk = dloc[k:u]

;    To allow for arrays, each part is converted separately.  Deal with the
;    fractional part of the day first (rounding off to the nearest hundredth
;    of a second), just in case we should round up to the following day.
;
     t = round( (dk mod 1.0d0)*8.64d6 )
     cc = string( t mod 100, format="('.',i2.2)" )
     t = t/100L
     ss = string( t mod  60, format="(':',i2.2)" )
     t = t/60L
     mm = string( t mod  60, format="(':',i2.2)" )
     h = t/60L
     z = where( h eq 24, nz )
     if nz gt 0 then begin
        ymd2 = jd2ymd( ymd2jd( yk[z], mk[z], floor( dk[z] ) ) + 1 )
        yk[z] = (ymd2[0,*])[*]
        mk[z] = (ymd2[1,*])[*]
        dk[z] = (ymd2[2,*])[*]
        h[z] = 0
     endif
     hh = string( h, format="(' ',i2.2)" )
;
;    Now assemble the parts
     dd   = string( long( dk ), format="(i2,'-')"   )
     mmm  = month_names[ mk-1 ]
     yyyy = string( long( yk ), format="('-',i4)"   )
;
     sk = dd+mmm+yyyy+hh+mm+ss+cc
     if k eq 0 then $
        s = sk $
     else $
        s = [ temporary(s), sk ]
  endfor
;
  if info[0] eq 0 and n_params() eq 3  then $
     return,s[0] $
  else $
     return,s
;
  end
