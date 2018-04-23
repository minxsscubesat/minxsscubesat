pro xrs_responsivity, channel, henke_thickness, fm=fm, spectrum=spectrum, path_prefix=path_prefix, help=help

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
  message, /info, 'ASSUMES Mewe 2 MK spectrum located at path_prefix + /goesr-work/science_analysis/amir/idl/mewe_spectrum_2MK.sav ... can OVERRIDE location by setting [spectrum]=full/path/to/file, or can provide [spectrum] as 2xN array with spectrum[0,*] = wavelength in Angstrom, spectrum[1,*] = irradiance in photon/s/cm^2/Ang
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
  ; If spectrum keyword NOT set, then read MEKAL file
  restore, path_prefix + '/goesr-work/science_analysis/amir/data/mewe_spectrum_2MK.sav'
endif else begin
  if size(spectrum, /type) eq size('',/ type) then begin
    ; If spectrum keyword set to path then load THAT file...
    restore, spectrum
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
  ; Convert photons/sec at the Sun, to photon flux [ph/s/cm^2/Ang] at 1 AU ... EM is irrelevant as it is a scale factor that drops out during responsivity calc
  mirr /= ((4 * !dpi * 1.496d13^2) * dmwv)  ; divide 1/4*pi*R^2 with R = 1 AU, divide out wavelength bin widths
endif

; Convert Henke responsivity from el/ph to A/W = C/J
resp *= 1.602177d-19 / en  ; convert electrons to Coulombs and photons to Joules

; Convert spectrum from ph/s/cm^2/Ang to W/m^2/Ang
mirr *= men * 1e4  ; convert photons to Joules and cm^-2 to m^-2

; Calculate responsivity

i18 = (strmid(ch,0,1) eq 'A') ? where((mwv ge 0.5) and (mwv le 4.)) : where((mwv ge 1.) and (mwv le 8.))

responsivity = xrs_area(ch, fm=fm) * 1e-4 * total(mirr * (interpol(resp, wv, mwv) > 0) * dmwv) / total(mirr[i18] * dmwv)

print, "XRS responsivity for " + strtrim(henke_thickness,2) + " microns:  " + string(responsivity, format='(e16.5)') + " [A / (W/m^2)]

return

END
