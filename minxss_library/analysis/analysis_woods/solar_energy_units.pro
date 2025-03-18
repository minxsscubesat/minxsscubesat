;
;  SOLAR_ENERGY_UNITS
;
;	Convert solar spectrum in units of photons/sec/cm^2 to Watts/m^2
;
;	INPUT
;		wave_energy		Energy keV bins assumed, but nm or Angstrom option can be used
;		flux_photon		Irradiance in photon units of photons/sec/cm^2
;		/nm				Option to assume wave_energy is in units of nm
;		/Angstrom		Option to assume wave_energy is in units of Angstrom
;
;	OUTPUT
;		flux_energy		Irradiance converted to energy units of Watts/m^2
;
;	HISTORY
;		2/20/2025	T. Woods, original code
;
function solar_energy_units, wave_energy, flux_photon, nm=nm, Angstrom=Angstrom

	if n_params() lt 2 then begin
		print, 'USAGE: flux_energy = solar_energy_units( energy, flux_photon )'
		return, -1L
	endif

    ; Constants
    h = 6.626D-34  ; Planck's constant in J·s
    c = 2.998D8      ; Speed of light in m/s
    conversion_factor = 1.0D4  ; cm² to m²

	; calculate wavelength in meters
	if keyword_set(nm) then begin
		wavelength_m = wave_energy * 1D-9	; Convert nm to meters
	endif else if keyword_set(Angstrom) then begin
	    ; Convert wavelength from Angstroms to meters if needed
    	wavelength_m = wave_energy * 1D-10  ; Convert Angstroms to meters
	endif else begin
		; Assume energy units of keV
		wavelength_m = (12.398 / wave_energy) * 1D-10 ; Convert keV to meters
	endelse

    ; Compute photon energy in Joules
    E_photon = (h * c) / wavelength_m

    ; Convert flux: photons/s/cm² to Watts/m²
    flux_energy = flux_photon * E_photon * conversion_factor

    return, flux_energy
END
