;
;	extract GOES time series
;
;	Tom Woods
;	1/5/05
;
function  extract_goes_ts, yyyydoy, short=short

if n_params() lt 1 then begin
  print, 'USAGE:  goes_ts = extract_goes_ts( yyyydoy, [/short] )'
  print, '             return GOES time series - default is 1-8 Angstroms'
  print, '             or the 0.5-4 Angstroms if /short is given
  return, -1
endif

goes_ts = -1
dolong = 1
if keyword_set(short) then dolong = 0

;
;    restore goes data a year at a time
;
year1 = long(min(yyyydoy)/1000L)
year2 = long(max(yyyydoy)/1000L)

;  Updated path for GOES data for MinXSS dropbox
sdir = getenv('minxss_data')
if strlen(sdir) gt 0 then sdir = sdir + '/ancillary/goes/'

for yr=year1,year2 do begin
  print, 'EXTRACT_GOES_TS: reading data for ', strtrim(yr,2), ' ...'
  restore, sdir+'goes_1mdata_widx_'+strtrim(yr,2)+'.sav'
  tgoes = double(goes.time)
  if (dolong ne 0) then fgoes = goes.long else fgoes = goes.short
  if (yr eq year1) then goes_ts = [ [tgoes], [fgoes] ] $
  else goes_ts = [ goes_ts, [[tgoes], [fgoes]] ]
endfor

;	convert GPS time to YYYYDOY fractional time
goes_ts[*,0] = jd2yd(gps2jd(goes_ts[*,0]))

return, goes_ts
end
