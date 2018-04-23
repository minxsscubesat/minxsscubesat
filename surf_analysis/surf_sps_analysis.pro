;
;	surf_sps_process.pro
;
;	Process SURF SPS Cruciform Scan data to get angle calibrations
;

fm_num = 1
read, 'Enter Flight Model number (1 or 2) ? ', fm_num
if (fm_num lt 1) then fm_num = 1
if (fm_num gt 2) then fm_num = 2

surfer_dir = '/Users/Shared/Projects/MinXSS/surf_2014/surfer/'
tlm_dir_base = '/Users/Shared/Projects/MinXSS/surf_2014/'

if (fm_num eq 1) then begin
  tlm_dir = tlm_dir_base + 'fm1/'
  surfer_alpha = 'SURF_102314_201847.txt'
  tlm_alpha = 'tlm_packets_2014_296_14_16_47.out'
  surfer_beta = 'SURF_102314_203931.txt'
  tlm_beta = 'tlm_packets_2014_296_14_39_10.out'
endif else begin
  tlm_dir = tlm_dir_base + 'fm2/'
  surfer_alpha = 'SURF_102314_170348.txt'
  tlm_alpha = 'tlm_packets_2014_296_11_03_34.out'
  surfer_beta = 'SURF_102314_173057.txt'
  tlm_beta = 'tlm_packets_2014_296_11_30_44.out'
endelse

ctype = 'A'
read, 'Enter cruciform type (A=alpha or B=beta) ? ', ctype
ctype = strupcase(strmid(ctype,0,1))

if (ctype eq 'A') then begin
  surfer_file = surfer_alpha
  tlm_file = tlm_alpha
  scantype = 'Alpha'
  spstype = 'X'
endif else begin
  surfer_file = surfer_beta
  tlm_file = tlm_beta
  scantype = 'Beta'
  spstype = 'Y'
endelse

;  Use minxss_process_surfdata to read the data
;
; function minxss_process_surfdata, datafile, surffile, instr, fm=fm, surfdata=surfdata, $
;    tbase=tbase, ;toff=toff, darkman=darkman, darkauto=darkauto, despike=despike, debug=debug, $
;    correctbc=correctbc, help=help
;

data = minxss_process_surfdata( tlm_dir+tlm_file, surfer_dir+surfer_file, 'SPS', fm=fm_num, $
		surfdata=surfdata, /darkman, /despike, /debug )

; calculate "sdata" as alpha or beta values
;	Alpha = 0.707 * U + 0.707 * V
;	Beta = -0.707 * U + 0.707 * V
; set "cdata" as Quad Diode X or Y data
if (ctype eq 'A') then begin
  sdata = 0.707 * data.surfu + 0.707 * data.surfv
  cdata = data.quadx
endif else begin
  sdata = -0.707 * data.surfu + 0.707 * data.surfv
  cdata = data.quady
endelse

; Eliminate points while moving...
; First, check there's at least 2 stable points...
sdiff = sdata - shift(sdata,1)
sdiff[0] = sdiff[1]
;wgood = where( sdiff eq 0, numgood )
wgood = where( abs(sdiff) le 0.005, numgood ) ; Use 5 thousandths as epsilon
if (numgood lt 2) then stop, 'ERROR: no good data for finding Scan.  Debug...'
gooddiff = [wgood - shift(wgood,1), -999]
runstarts = where( gooddiff ne 1, numpoints )
if (numpoints lt 2) then stop, 'ERROR: no movement seen in scan.  Debug...'

; Find all the science data during stable periods, and mark it
sdata2 = fltarr(numpoints-1)
cdata2 = fltarr(numpoints-1)
for k = 1, n_elements(runstarts)-1 do begin
  sdata2[k-1] = mean(sdata[wgood[runstarts[k-1]]:wgood[runstarts[k]-1]])
  cdata2[k-1] = mean(cdata[wgood[runstarts[k-1]]:wgood[runstarts[k]-1]])
endfor

;
;	fit line to the extracted data
;
cfit = poly_fit( cdata2, sdata2, 1, yfit=sfit )
print, ' '
fit_str = scantype+' = '+strtrim(cfit[0],2)+' + '+strtrim(cfit[1],2)+' * '+spstype
print, 'FIT: '+fit_str
print, ' '

;
;	plot the cruciform scan data
;
setplot
cc = rainbow(7)
plot, sdata, cdata, psym=2, xtitle=scantype, ytitle=spstype, title='SPS FM-'+strtrim(fm_num,2)
oplot, sdata2, cdata2, psym=-6, color=cc[3]
oplot, sfit, cdata2, color=cc[0]
xx = !x.crange[0]*0.8 + !x.crange[1]*0.2
yy = !y.crange[0]*0.9 + !y.crange[1]*0.1
xyouts, xx, yy, fit_str

; also plot to EPS file
efile = 'surf_sps_fm'+strtrim(fm_num,2)+'_'+spstype+'_'+scantype+'.eps'
print, 'Writing EPS plot to ', efile
eps2_p, efile
setplot
cc=rainbow(7)
plot, sdata, cdata, psym=2, xtitle=scantype, ytitle=spstype, title='SPS FM-'+strtrim(fm_num,2)
oplot, sdata2, cdata2, psym=-6, color=cc[3]
oplot, sfit, cdata2, color=cc[0]
xyouts, xx, yy, fit_str
send2

end

