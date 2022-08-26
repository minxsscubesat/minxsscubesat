;
;	create_xspec_response_file.pro
;
;	Create MinXSS / DAXSS Response FITS file
;		OSPEX RMF Info: Redistribution Matrix (RMF) compressed format as BINTABLE
;		OSPEX RMF Info: Energy boundaries (EBOUNDS) as BINTABLE
;		OSPEX ARF Info: Effective area (ARF) as BINTABLE
;
;	References:
;		PHA Type-1:  Save DAXSS/MinXSS spectra into FITS file
;			https://heasarc.gsfc.nasa.gov/docs/heasarc/ofwg/docs/spectra/ogip_92_007.pdf
;		RMF: Redistribution Matrix File (RMF, FITS file) – static per instrument
;			https://heasarc.gsfc.nasa.gov/docs/heasarc/caldb/docs/memos/cal_gen_92_002/cal_gen_92_002.html
;		ARF: Ancillary Response File (ARF, FITS file) – static per instrument
;			See instructions for ARF with the RMF documentation
;
;	INPUTS
;		minxss_cal_file		Name of MinXSS/DAXSS calibration file
;
;	OUTPUTS
;		FITS file is written *.FITS
;
;	PROCESS:
;		1.  Read MinXSS Response File (calibration file)
;		2.  Create 3099 x 1000 redistribution matrix
;		3.  Make the Redistribution Matrix
;		4.  Write the Redistribution Matrix (RMF)
;		5.  Write the EBOUNDS values (energy boundaries)
;		6.  Write the effective area (ARF)
;
;	NOTES
;		IDL code to read the output_file:
;		IDL>  data = eve_read_whole_fits( output_file, /verbose )
;
;	HISTORY
;		6/8/2022	Tom Woods, original code
;
pro create_xspec_response_file, minxss_cal_file

verbose = 1
ans = ' '
if n_params() lt 1 then begin
	print, 'USAGE: create_xspec_response_file, minxss_cal_file'
	fm = 3
	read, 'Enter MinXSS FM number (1-3) ? ', fm
	if (fm lt 1) or (fm gt 3) then return
	minxss_cal_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/minxss_fm' + $
			strtrim(fm,2) + '_response_structure.sav'
endif else begin
	; determine FM number from the file name
	ifm = strpos( strupcase(minxss_cal_file), 'FM', /reverse_search )
	if (ifm lt 0) then stop, 'ERROR finding FM number !!!'
	fm = long(strmid(minxss_cal_file,ifm+2))
endelse

;  Configure Mission and Instrument names
fm_name = 'MinXSS-'+strtrim(fm,2)
if (fm eq 3) then fm_name = 'InspireSat-1'
instr_name = 'X123'
if (fm eq 3) then instr_name = 'DAXSS'
filter_name = 'Be'
if (fm eq 3) then filter_name = 'Be/Kapton'
det_name = 'Amptek X123'
if (fm ge 2) then det_name = 'Amptek X123 SDD'

; *************************************************************************************************
;	1.  Read MinXSS Response File (calibration file)
;			Also read the DRM_COMPLETE file for MinXSS-1 to get the Compton Scattering contributions
;
if verbose then print, 'Reading ', minxss_cal_file
restore, minxss_cal_file   ; minxss_detector_response

fm1_drm_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/DRM_COMPLETE_MINXSS_X123_FM1_ALL_OSPEX_FWHM_0_240_keV.SAV'
if verbose then print, 'Reading ', fm1_drm_file
; use the MINXSS_X123_FM1_OSPEX_RESPONSE_MATRIX_BIN_NORM (993 x 994) array
;		MINXSS_X123_FM1_OSPEX_EDGES_IN      DOUBLE    = Array[2, 994]
;		MINXSS_X123_FM1_OSPEX_EDGES_OUT		DOUBLE    = Array[2, 993]
restore, fm1_drm_file

;
;	define Output file
;
slash = path_sep()
wslash = strpos(minxss_cal_file, slash, /reverse_search)
if (wslash gt 0) then in_dir = strmid(minxss_cal_file,0,wslash+1) else in_dir = ''
output_file = in_dir + 'minxss_fm' + strtrim(fm,2) + '_RMF_ARF.fits'
rmf_file = in_dir + 'minxss_fm' + strtrim(fm,2) + '_RMF.fits'
arf_file = in_dir + 'minxss_fm' + strtrim(fm,2) + '_ARF.fits'

if verbose then begin
	print, ' '
	print, 'Output file will be ', output_file
	print, ' '
endif

; *************************************************************************************************
;		2.  Create 3099 x 1000 redistribution matrix
;			3099 energy bins is from MinXSS-1 original calibration file
;			1000 bins are the X123 channels (EBOUNDS), starting at 0.1 keV
;
;  make the 3099-element array for model energy bins
E_NUM = 3099L
E_NUM_STR = '3099'
if (e_num ne n_elements(minxss_detector_response.PHOTON_ENERGY)) then begin
	stop, 'ERROR with E_NUM not being right dimension for PHOTON_ENERGY !!!'
	return
endif
energy = minxss_detector_response.PHOTON_ENERGY
energy_step = energy[1] - energy[0]
energy_low = energy - energy_step/2.
energy_high = energy + energy_step/2.

; make the 1000-element array for X123 energy bins
BIN_NUM = 1000L
BIN_NUM_STR = '1000'
e_width = minxss_detector_response.X123_ENERGY_GAIN_KEV_PER_BIN
e_offset = minxss_detector_response.X123_ENERGY_OFFSET_KEV_ORBIT
ebins_all = findgen(1024) * e_width + e_offset
wkeep = where(ebins_all ge 0.1)
ebins = ebins_all[wkeep[0]:wkeep[0]+BIN_NUM-1L]
elow = ebins - e_width/2.
ehigh = ebins + e_width/2.

print, 'Keeping X123 bins: ',wkeep[0],wkeep[0]+BIN_NUM-1L

; *************************************************************************************************
;		3A.  Make the Redistribution Matrix
;				First fill in the Compton scattering contribution from DRM_COMPLETE_MINXSS_X123_FM1_ALL_OSPEX
;				Add diagonal line with Gaussian smoothing for energy resolution
;				Add Si K, Si L-2s, Si L-2p
;				Do NOT add in Be photoelectrons
;
matrix = fltarr(bin_num, e_num)
matrix_limit = 1E-6
matrix_limit_str = string(matrix_limit,format='(E7.1)')

; prepare to use the Compton Scattering result in MINXSS_X123_FM1_OSPEX_RESPONSE_MATRIX_BIN_NORM
; limit Compton scattering for above 12 keV for x-axis and above 10 keV for y-axis
ospex_energy_in = (MINXSS_X123_FM1_OSPEX_EDGES_IN[0,*] + MINXSS_X123_FM1_OSPEX_EDGES_IN[1,*])/2.
ospex_energy_out = (MINXSS_X123_FM1_OSPEX_EDGES_OUT[0,*] + MINXSS_X123_FM1_OSPEX_EDGES_OUT[1,*])/2.
ospex_matrix_norm = MINXSS_X123_FM1_OSPEX_RESPONSE_MATRIX_BIN_NORM
num_in = n_elements(ospex_energy_in) & num_out = n_elements(ospex_energy_out)
for i=0L,num_in-1 do ospex_matrix_norm[*,i] = ospex_matrix_norm[*,i] / total(ospex_matrix_norm[*,i])
wlow = where( ospex_matrix_norm lt matrix_limit, num_low )
if (num_low gt 1) then ospex_matrix_norm[wlow] = 0.
oldx1 = (where(ospex_energy_out ge min(ebins)))[0] & oldx2 = (where(ospex_energy_out lt 10))[-1]
oldy1 = (where(ospex_energy_in gt 12))[0] & oldy2 = (where(ospex_energy_in le max(energy)))[-1]
;	First fill in the Compton scattering contribution from DRM_COMPLETE_MINXSS_X123_FM1_ALL_OSPEX
; 	Use KRIG2D to interpolate in 2-D
x1 = (where(ebins ge ospex_energy_out[oldx1]))[0] & x2 = (where(ebins lt 10))[-1]
y1 = (where(energy gt 12))[0] & y2 = (where(energy le ospex_energy_in[oldy2]))[-1]
; print, 'KRIG2D is processing for the Compton Scattering (this will take a few minutes)...'
;  KRIG2D is too slow
;compton_scatter = KRIG2D( ospex_matrix_norm[oldx1:oldx2,oldy1:oldy2], $
;						xvalues=ospex_energy_out[oldx1:oldx2], yvalues=ospex_energy_in[oldy1:oldy2], $
;						nx=(x2-x1+1), ny=(y2-y1+1), xout=xout, yout=yout, linear=[1.,1.] )
print, 'Re-grid Compton Scatter input:  ', energy[y1], energy[y2],  $
		' ; maxtrix: ', ospex_energy_in[oldy1], ospex_energy_in[oldy2]
print, 'Re-grid Compton Scatter output: ', ebins[x1], ebins[x2], $
		' ; maxtrix: ', ospex_energy_out[oldx1], ospex_energy_out[oldx2]
compton_scatter = congrid( ospex_matrix_norm[oldx1:oldx2,oldy1:oldy2], (x2-x1+1), (y2-y1+1), /center, /interp )
; stop, 'DEBUG Compton_Scatter 2-D interpolation...'
wlow = where( compton_scatter lt matrix_limit, num_low )
if (num_low gt 1) then compton_scatter[wlow] = 0.
; ***** Add the Compton Scatter part after the matrix is made and normalized
; matrix[x1:x2,y1:y2] = compton_scatter

; define number of X-axis (energy out) bins to consider for gaussian function range
dX = long(((minxss_detector_response.X123_NOMINAL_SPECTRAL_RESOLUTION / e_width) > 1) * 10.)

;	interpolate to energy for the energy resolution
ENERGY_RES_MIN = e_width
energy_res = interpol( minxss_detector_response.X123_SPECTRAL_RESOLUTION_ARRAY, $
					minxss_detector_response.PHOTON_ENERGY, energy) > ENERGY_RES_MIN
energy_res_si_k = interpol( minxss_detector_response.X123_SPECTRAL_RESOLUTION_ARRAY, $
					minxss_detector_response.PHOTON_ENERGY, $
					energy-minxss_detector_response.X123_SI_K_EDGE_ENERGY_KEV) > ENERGY_RES_MIN
energy_res_si_L2s = interpol( minxss_detector_response.X123_SPECTRAL_RESOLUTION_ARRAY, $
					minxss_detector_response.PHOTON_ENERGY, $
					energy-minxss_detector_response.X123_SI_L_2S_EDGE_ENERGY_KEV) > ENERGY_RES_MIN
energy_res_si_L2p = interpol( minxss_detector_response.X123_SPECTRAL_RESOLUTION_ARRAY, $
					minxss_detector_response.PHOTON_ENERGY, $
					energy-minxss_detector_response.X123_SI_L_2P_EDGE_ENERGY_KEV) > ENERGY_RES_MIN

for i=0L,E_NUM-1L do begin
	;	Add diagonal line with Gaussian smoothing for energy resolution
	; 			find output energy bins for this input energy bin
	;			make gaussian profile and throughput is 1.0 (100%)

	temp = min(abs(energy[i]-ebins),xxctr)
	xx1 = (xxctr - dX) > 0  &  xx2 = (xxctr + dX) < (bin_num-1)
	if (xxctr lt (bin_num-1)) then BEGIN
		do_normalization = 1
		matrix[xx1:xx2,i] += gauss_normalized( ebins[xx1:xx2], [energy_res[i],energy[i]])
	endif else begin
		do_normalization = 0
		if (xx1 lt (bin_num-1)) then matrix[xx1:xx2,i] += gauss_normalized( ebins[xx1:xx2], [energy_res[i],energy[i]])
	endelse

	;	Add Si K
	;			find output energy bins for this input energy bin - subtract off Si K edge first
	;			make gaussian profile and throughput is Si K throughput
	si_offset = minxss_detector_response.X123_SI_K_EDGE_ENERGY_KEV
	temp = min(abs(energy[i]-si_offset-ebins),xxctr)
	xx1 = (xxctr - dX) > 0  &  xx2 = (xxctr + dX) < (bin_num-1)
	if (energy[i] ge si_offset) AND (xx1 lt (bin_num-1)) then matrix[xx1:xx2,i] += $
						gauss_normalized( ebins[xx1:xx2], [energy_res_si_k[i],energy[i]-si_offset]) $
						* minxss_detector_response.X123_SI_K_ESCAPE_PROBABILITY[i]

	;	Add Si L-2s
	;			find output energy bins for this input energy bin - subtract off Si K edge first
	;			make gaussian profile and throughput is Si K throughput
	si_offset = minxss_detector_response.X123_SI_L_2S_EDGE_ENERGY_KEV
	temp = min(abs(energy[i]-si_offset-ebins),xxctr)
	xx1 = (xxctr - dX) > 0  &  xx2 = (xxctr + dX) < (bin_num-1)
	if (energy[i] ge si_offset) AND (xx1 lt (bin_num-1)) then matrix[xx1:xx2,i] += $
						gauss_normalized( ebins[xx1:xx2], [energy_res_si_L2s[i],energy[i]-si_offset]) $
						* minxss_detector_response.X123_SI_L_2S_ESCAPE_PROBABILITY[i]

	;	Add Si L-2p
	;			find output energy bins for this input energy bin - subtract off Si K edge first
	;			make gaussian profile and throughput is Si K throughput
	si_offset = minxss_detector_response.X123_SI_L_2P_EDGE_ENERGY_KEV
	temp = min(abs(energy[i]-si_offset-ebins),xxctr)
	xx1 = (xxctr - dX) > 0  &  xx2 = (xxctr + dX) < (bin_num-1)
	if (energy[i] ge si_offset) AND (xx1 lt (bin_num-1)) then matrix[xx1:xx2,i] += $
						gauss_normalized( ebins[xx1:xx2], [energy_res_si_L2p[i],energy[i]-si_offset]) $
						* minxss_detector_response.X123_SI_L_2P_ESCAPE_PROBABILITY[i]

	;	3B.  Normalize the Redistribution Matrix so every row is exactly 1.0 (but only if on-diagonal is present)
	if (do_normalization ne 0) then matrix[*,i] = matrix[*,i] / total(matrix[*,i])
endfor

; ***** Add the Compton Scatter part now - after the matrix is made and normalized
;  COMPTON SCATTER does not look right (all at low energies - it should be just below the on-diagonal at high energy)
; matrix[x1:x2,y1:y2] = compton_scatter

; force normalization to be 1 or lower
row = total(matrix,1)
whigh = where(row gt 1.0,numhigh)
if (numhigh gt 0) then begin
	for j=0L,numhigh-1 do matrix[*,whigh[j]] /= row[whigh[j]]
endif

;		Force zero for low values
wlow = where( matrix lt matrix_limit, num_low )
if (num_low gt 1) then matrix[wlow] = 0.
row = total(matrix,1)
col = total(matrix,2)

;   Plots for debugging the matrix
setplot & cc=rainbow(31)
wset, 0
plot,ebins,matrix[*,100],/ylog,yr=[1E-7,1],xr=[0,21],ys=1,xs=1
for k=100,3000,200 do oplot,ebins,matrix[*,k],color=cc[long(k / 100)]
window,1, title='Response Matrix', xsize=1000,ysize=1000, xpos=100, ypos=100
ccc=rainbow(256,/image)
tvscl,alog10(rebin(matrix[*,0:2999],1000,1000) > 1E-6)
wset, 0
cc=rainbow(7)

; stop, 'DEBUG after making the MATRIX ... '

; update so only keep Matrix data above 0.1 keV
wOK = where( energy ge 0.0999, num_OK )
E_NUM = num_OK
E_NUM_STR = strtrim(E_NUM,2)
; force Matrix to be above 0.1 keV
energy_low[wOK[0]] = 0.1

matrix1 = {ENERG_LO: 0.0, ENERG_HI: 0.0, N_GRP: 1, F_CHAN: 0, N_CHAN: bin_num, MATRIX: fltarr(bin_num)}
matrix_all = replicate(matrix1, e_num)
matrix_all.ENERG_LO = energy_low[wOK]
matrix_all.ENERG_HI = energy_high[wOK]
for ii=0L,e_num-1 do matrix_all[ii].MATRIX = reform(matrix[*,ii+wOK[0]])

; *************************************************************************************************
;		4.  Write the Redistribution Matrix (RMF)
;				First attempt is to do it without any compression
;
matrix_hdr = [ $
			"XTENSION  = 'BINTABLE'", $
			"EXTNAME  = 'MATRIX' / Redistribution MATRIX BINTABLE", $
			"MISSION  = '" + fm_name + "'", $
			"TELESCOP = '" + fm_name + "' / Mission Name", $
			"INSTRUME = '" + instr_name + "' / Instrument Name", $
			"DETNAM   = '" + det_name + "' / Detector Name", $
			"FILTER   = '" + filter_name + "' / Filter Material", $
			"ORIGIN   = 'CU/LASP'", $
			"CREATOR  = 'IDL create_xspex_response_file.pro'", $
			"CHANTYPE = 'PHA'", $
			"DETCHANS = " + BIN_NUM_STR, $
			"NUMGRP   = " + E_NUM_STR,  $
			"NUMELT    =               / Total number of response elements ", $
			"TLMIN4   = 0", $
			"EFFAREA  = 1.", $
			"LO_THRES = " + matrix_limit_str, $
			"HDUCLASS = 'OGIP'", $
			"HDUCLAS1 = 'RESPONSE'", $
			"HDUCLAS2 = 'RSP_MATRIX'", $
			"HDUCLAS3 = 'REDIST'", $
			"HDUVERS  = '1.3.0'", $
			"CCLS0001 = 'BCF'  / Basic Calibration File", $
			"CCNM0001 = 'MATRIX'", $
			"CDTP0001 = 'DATA'", $
			"CVSD0001 = '2022-02-27' / Valid Start Date", $
			"CVST0001 = '00:00:00' / Valid Start Time in UT", $
			"CDES0001 = 'Redistribution probability matrix'", $
			"EXTVER   =       1 / auto assigned by template parser", $
			"END" $
			]

if verbose then print, 'WRITING MATRIX (RMF) data...'
mwrfits, matrix_all, output_file, matrix_hdr, /CREATE

; *************************************************************************************************
;		5.  Write the EBOUNDS values (energy boundaries)
;
ebounds_hdr = [ $
			"XTENSION  = 'BINTABLE'", $
			"EXTNAME  = 'EBOUNDS' / Energy Boundaries BINTABLE", $
			"MISSION  = '" + fm_name + "'", $
			"TELESCOP = '" + fm_name + "' / Mission Name", $
			"INSTRUME = '" + instr_name + "' / Instrument Name", $
			"DETNAM   = '" + det_name + "' / Detector Name", $
			"FILTER   = '" + filter_name + "' / Filter Material", $
			"ORIGIN   = 'CU/LASP'", $
			"CREATOR  = 'IDL create_xspex_response_file.pro'", $
			"CHANTYPE = 'PHA'", $
			"DETCHANS = " + BIN_NUM_STR, $
			"HDUCLASS = 'OGIP'", $
			"HDUCLAS1 = 'RESPONSE'", $
			"HDUCLAS2 = 'EBOUNDS'", $
			"HDUVERS  = '1.2.0'",  $
			"CCLS0001 = 'BCF'  / Basic Calibration File", $
			"CCNM0001 = 'EBOUNDS'", $
			"CDTP0001 = 'DATA'", $
			"CVSD0001 = '2022-02-27' / Valid Start Date", $
			"CVST0001 = '00:00:00' / Valid Start Time in UT", $
			"CDES0001 = 'Energy bin values'", $
			"EXTVER   =       1 / auto assigned by template parser", $
			"END" $
			]
ebounds1 = {CHANNEL: 0, E_MIN: 0.0, E_MAX: 0.0}
ebounds_all = replicate(ebounds1, bin_num)
ebounds_all.CHANNEL = indgen(bin_num)
ebounds_all.E_MIN = elow
ebounds_all.E_MAX = ehigh

if verbose then print, 'WRITING EBOUNDS data...'
mwrfits, ebounds_all, output_file, ebounds_hdr

; *************************************************************************************************
;		6.  Write the effective area (ARF)
;
eff_area_hdr = [ $
			"XTENSION  = 'BINTABLE'", $
			"EXTNAME  = 'SPECRESP' / Effective Area cm^2 BINTABLE", $
			"MISSION  = '" + fm_name + "'", $
			"TELESCOP = '" + fm_name + "' / Mission Name", $
			"INSTRUME = '" + instr_name + "' / Instrument Name", $
			"DETNAM   = '" + det_name + "' / Detector Name", $
			"FILTER   = '" + filter_name + "' / Filter Material", $
			"ORIGIN   = 'CU/LASP'", $
			"CREATOR  = 'IDL create_xspex_response_file.pro'", $
			"CHANTYPE = 'PHA'", $
			"DETCHANS = " + E_NUM_STR, $
			"HDUCLASS = 'OGIP'", $
			"HDUCLAS1 = 'RESPONSE'", $
			"HDUCLAS2 = 'SPECRESP'", $
			"HDUVERS  = '1.1.0'", $
			"CCLS0001 = 'BCF'  / Basic Calibration File", $
			"CCNM0001 = 'SPECRESP'", $
			"CDTP0001 = 'DATA'", $
			"CVSD0001 = '2022-02-27' / Valid Start Date", $
			"CVST0001 = '00:00:00' / Valid Start Time in UT", $
			"CDES0001 = 'Effective area spectral response in units of cm^2'", $
			"EXTVER   =       1 / auto assigned by template parser", $
			"END" $
			]

eff_area1 = {ENERG_LO: 0.0, ENERG_HI: 0.0, SPECRESP: 0.0}
eff_area_all = replicate(eff_area1, e_num)
eff_area_all.ENERG_LO = energy_low[wOK]
eff_area_all.ENERG_HI = energy_high[wOK]
; already in units of cm^2
effective_area_cm2 = interpol(minxss_detector_response.X123_EFFECTIVE_AREA, $
						minxss_detector_response.PHOTON_ENERGY, energy[wOK] )
eff_area_all.SPECRESP = effective_area_cm2

if verbose then print, 'WRITING SPECRESP (ARF) data...'
mwrfits, eff_area_all, output_file, eff_area_hdr

; *********   DONE    **************
if verbose then print, 'DONE writing to ' + output_file
print, ' '

;
;	Also make separate RMF file
;
if verbose then begin
	print, ' '
	print, 'RMF file is ', rmf_file
	print, ' '
endif
mwrfits, matrix_all, rmf_file, matrix_hdr, /CREATE
mwrfits, ebounds_all, rmf_file, ebounds_hdr

;
;	Also make separate ARF file
;
if verbose then begin
	print, ' '
	print, 'ARF file is ', ARf_file
	print, ' '
endif
mwrfits, eff_area_all, arf_file, eff_area_hdr, /CREATE

; debug
; stop, 'DEBUG at end...'

return
end
