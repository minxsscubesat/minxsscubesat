;
;	lisird_f10_read.pro
;
;	Read F10.7 solar radio flux to return array of time in JD and the F10.7 adjusted-corrected set
;	This expects the F10.7 data file to be the LISIRD download of the CLS F10.7 record (1951-present)
;
;	1/31/2022   T. Woods
;
function lisird_f10_read, dir=dir, file=file, debug=debug

if not keyword_set(dir) then dir = getenv('minxss_data') + '/ancillary/f10/'

if not keyword_set(file) then file = 'lisird_cls_radio_flux_f107.dat'

data = read_dat( dir + file )

f10_jd = ymd2jd( reform(data[0,*]), reform(data[1,*]), reform(data[2,*]) )
f10 = reform(data[8,*])  ; pick the Adjusted & Corrected F10.7 column

f10_data = dblarr(2,n_elements(f10))
f10_data[0,*] = f10_jd
f10_data[1,*] = f10

if keyword_set(debug) then stop,'DEBUG at end of lisird_f10_read() ...'

return, f10_data
end
