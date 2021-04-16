  function vms2ymd, vmsdate

; Translates VMS-formatted date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; to double-precision array [yyyy,mm,dd.dd]

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  string_type = 7
  info = size(vmsdate)
  type = info[info[0]+1]
  if type ne string_type then begin
     print,"                                                               "
     print,"  VMS2YMD translates a VMS-style date/time string of the form  "
     print,"  'dd-mmm-yyyy hh:mm:ss.ss' (e.g., '31-Dec-1999 23:59:59.99')  "
     print,"  to a double precision date of the form [yyyy, mm, dd.dd].    "
     print,"  Either a scalar or an array argument is accepted.            "
     print,"                                                               "
     print,"  ymd = vms2ymd( vmsdate )                                     "
     return,''
  endif
;
  month_names = ['JAN','FEB','MAR','APR','MAY','JUN', $
                 'JUL','AUG','SEP','OCT','NOV','DEC']
;
  n_elt = info[info[0]+2]
  vmsloc = strupcase(strtrim(vmsdate,2))
  p = where(strpos(vmsloc,'-') eq 1,np)
  if np gt 0 then vmsloc[p] = ' '+vmsloc[p]
  z = strlen(vmsloc)
  yy = fix(strmid(vmsloc,7,4))
;
  smon = strmid(vmsloc,3,3)
  mm = intarr(n_elt)
  for j=0,11 do begin
     mhave = where(smon eq month_names[j],nhave)
     if nhave gt 0 then mm[mhave] = j+1
  endfor
;
  d = fix(strmid(vmsloc,0,2))
  h = intarr(n_elt)
  ph = where(z ge 14, nh)
  if nh gt 0 then h[ph] = fix(strmid(vmsloc[ph],12,2))
  m = intarr(n_elt)
  pm = where(z ge 17, nm)
  if nm gt 0 then m[pm] = fix(strmid(vmsloc[pm],15,2))
  s = dblarr(n_elt)
  ps = where(z ge 20, ns)
  if ns gt 0 then s[ps] = double(strmid(vmsloc[ps],18,100))
;
  return, transpose( [[yy],[mm],[d+h/24.d0+m/1440.d0+s/86400.d0]] )
;
  end
