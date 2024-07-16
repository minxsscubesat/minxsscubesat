  function longdate,y,mo,d,h,m,s

; Given string 'dd-mmm-yyyy hh:mm:ss.ss' or numbers y,mo,d,h,m,s
; returns double-precision yyyyddd.dd

; B. G. Knapp, 85.10.31, 97.11.17
;              98.06.09, IDL v. 5 compliance

  info = size(y)
  type = info[info[0]+1]
  if type eq 7 then $
     return,vms2yd(y) $
  else if 0 lt type and type lt 6 and n_params() ge 3 then begin
     case n_params() of
        6: dloc = d+h/24.d0+m/1440.d0+s/86400.d0
        5: dloc = d+h/24.d0+m/1440.d0
        4: dloc = d+h/24.d0
        3: dloc = d
     endcase
     return,ymd2yd(y,mo,dloc)
  endif else begin
     print,"                                                               "
     print,"  LONGDATE translates its argument(s) into a double precision  "
     print,"  date of the form yyyyddd.dd.  Permissible calling sequences  "
     print,"  are illustrated below.  Either a single argument containing  "
     print,"  a string of the form 'dd-mmm-yyyy hh:mm:ss.ss' (e.g.,        "
     print,"  '31-Oct-1985 23:59:59.99'); or up to six numerical arguments "
     print,"  giving the year, month, day, hour, minute, and second        "
     print,"  separately are permitted.  In either case, if the h:m:s      "
     print,"  information is omitted these values are taken as zero.       "
     print,"                                                               "
     print,"  date = longdate( vmsdate )                                   "
     print,"  date = longdate( yyyy, mm, dd, hh, mm, ss.ss )               "
     return,''
  endelse
;
  end
