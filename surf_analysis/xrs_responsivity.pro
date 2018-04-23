;
;	Original code by Amir Caspi in 2013
;	Modified by Tom Woods to work on office Mac for making XRS Cal Reports
;	May-1-2015  TW   Added APEC spectrum options to the Mewe Option
;	June-26-2017 TW  Added Flat Spectrum option (preferred method from previous GOES XRS)
;
pro xrs_responsivity, channel, henke_thickness, fm=fm, spectrum=spectrum, $
						mewe2K=mewe2K, qs_apec=qs_apec, ar_apec=ar_apec, flat_spectrum=flat_spectrum, $
						path_prefix=path_prefix, help=help, debug=debug

; Calculate the responsivity (A / [W/m^2]) for an XRS channel with a Be filter of a given Henke-model thickness
; Channel must be one of: A1, B1, A2, B2 [needed to get accurate aperture area]
; henke_thickness must be specified in microns
; Reponsivity uses CDRL 80 equations 4.8, 4.17, assumes MEKAL 2 MK spectrum
; Prints output to screen

if (n_params() lt 2) or keyword_set(help) then begin
  message, /info, 'USAGE: xrs_responsivity, <channel>, <henke_thickness> [, spectrum=spectrum, path_prefix=path_prefix, help=help]'
  message, /info, 'CALCULATES responsivity (in A/[W/m^2]) for an XRS channel with Be filter of given Henke-model thickness
  message, /info, '<channel> must be one of: A1, B1, A2, B2; this is needed for an accurate aperture area.'
  message, /info, '<henke_thickness> must be in MICRONS.'
    message, /info, 'FLAT Spectrum option is preferred and is used for the /flat_spectrum option.'
  message, /info, 'Reference spectra options are /mewe2K, /qs_apec, /ar_apec'
  message, /info, 'Default spectrum ASSUMES Mewe 2 MK spectrum located at path_prefix + /goesr-work/science_analysis/amir/idl/mewe_spectrum_2MK.sav'
  message, /info, '   You can OVERRIDE location by setting [spectrum]=full/path/to/file, or can provide [spectrum] as 2xN array with spectrum[0,*] = wavelength in Angstrom, spectrum[1,*] = irradiance in photon/s/cm^2/Ang'
  message, /info, 'Set [path_prefix] if needed to find spectrum file.'
  return
endif

path_prefix = keyword_set(path_prefix) ? path_prefix : ''
valid_channels = ['A1','B1','A2','B2']
ch = strmid(strupcase(channel),0,2)
if (where(ch eq valid_channels) eq -1) then begin
  message, /info, 'ERROR: Invalid XRS channel.  Expected A1, A2, B1, or B2.'
  return
endif

; Get Henke response for 55 µm Silicon, 70 Å SiO absorption layer, and specified thicknesses
diode_param, ['Be'], [henke_thickness]*1E4, wv, resp, si=55.E4, ox=70., /noplot
; Wavelength given in Å
; Response given in electron/photon
wv = reverse(wv)
resp = reverse(resp)

; Get the spectrum ...
if not keyword_set(spectrum) then begin
  if keyword_set(flat_spectrum) then begin
    print, 'Using FLAT Spectrum...'
    mwv = wv
    mirr = mwv/mwv  ; unity (flat) spectrum
    spectrum = [[mwv], [mirr]]
    sp_name = 'FLAT-Sp'
  endif else if keyword_set(qs_apec) then begin
    apec = read_dat('APEC_quiet_spectrum.dat')
    print, 'Using APEC QS Spectrum...'
    mwv = reform(apec[0,*])
    mirr = reform(apec[2,*])
    sp_name = 'APEC-Quiet'
  endif else if keyword_set(ar_apec) then begin
    apec = read_dat('APEC_active_spectrum.dat')
    print, 'Using APEC AR Spectrum...'
    mwv = reform(apec[0,*])
    mirr = reform(apec[2,*])
    sp_name = 'APEC-Active'
  endif else begin
    ; If spectrum keyword NOT set, then default is to read MEKAL Mewe 2MK file
    ; restore, path_prefix + '/goesr-work/science_analysis/amir/data/mewe_spectrum_2MK.sav'
    restore, 'mewe_spectrum_2MK.sav'
    print, 'Using Mewe-2K Spectrum...'
    sp_name = 'Mewe-2K'
  endelse
endif else begin
  sp_name = 'Custom-Sp'
  if size(spectrum, /type) eq size('',/ type) then begin
    ; If spectrum keyword set to path then load THAT file...
    restore, spectrum   ;  mwv, mirr  required in the restore file
  endif else if (size(spectrum, /dim))[0] eq 2 then begin
    ; If specified as 2xN array, then use it directly...
    mwv = reform(spectrum[0,*])
    mirr = reform(spectrum[1,*])
  endif else begin
    ; Else output error message for impropr formatting
    message, /info, 'Improper [spectrum] keyword... must be full/path/to/mewe/file **OR** 2xN array with spectrum[0,*] = wavelength in Ang and spectrum[1,*] = irradiance in photon/s/cm^2/Ang'
    return
  endelse
endelse

; Get conversion from Angstroms to Joules
a2J = 1.986446d-15  ; energy [Joules] = a2J / wavelength [Ang]
en = a2J/wv
men = a2J/mwv
dmwv = get_edges(mwv, /wid)
mwv2xN = [mwv, mwv[n_elements(mwv)-1]+mean(dmwv)] - mean(dmwv)/2.
men2xN = a2J/mwv2xN
; If Mewe spectrum read from file...
if (n_elements(spectrum) le 1) then begin
  ; Convert photons/sec at the Sun, to photon flux [ph/s/cm^2/Ang] at 1 AU
  ;	... EM is irrelevant as it is a scale factor that drops out during responsivity calc
  ; divide 1/4*pi*R^2 with R = 1 AU, divide out wavelength bin widths
  mirr /= ((4 * !dpi * 1.496d13^2) * dmwv)
endif

; Convert Henke responsivity from el/ph to A/W = C/J
resp *= 1.602177d-19 / en  ; convert electrons to Coulombs and photons to Joules

; Convert spectrum from ph/s/cm^2/Ang to W/m^2/Ang
mirr *= men * 1e4  ; convert photons to Joules and cm^-2 to m^-2

; Calculate responsivity

i18 = (strmid(ch,0,1) eq 'A') ? where((mwv ge 0.5) and (mwv le 4.)) : where((mwv ge 1.) and (mwv le 8.))

responsivity = xrs_area(ch, fm=fm) * 1e-4 * total(mirr * (interpol(resp, wv, mwv) > 0) * dmwv) / total(mirr[i18] * dmwv)

print, "XRS responsivity for " + strtrim(henke_thickness,2) + " microns for " + sp_name + ': ' + string(responsivity, format='(e16.5)') + " [A / (W/m^2)]"

if (ch eq 'A1') or (ch eq 'A2') then bandpass_width = 4. - 0.5 else bandpass_width = 8. - 1.
flat_response = xrs_area(ch, fm=fm) * 1e-4 * total((interpol(resp, wv, mwv) > 0) * dmwv) / bandpass_width
print, ' '
print, "XRS FLAT responsivity for " + strtrim(henke_thickness,2) + " microns for " + sp_name + ': ' + string(flat_response, format='(e16.5)') + " [A / (W/m^2)]"

print, ' '
print, 'RATIO of Ref Sp Responsivity to Flat Sp Responsivity = ', responsivity / flat_response

if keyword_set(debug) then stop, 'DEBUG at end of xrs_responsivity.pro ...'
return

END
