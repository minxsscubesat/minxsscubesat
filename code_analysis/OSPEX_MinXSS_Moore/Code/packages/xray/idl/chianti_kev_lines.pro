pro chianti_kev_getp, out, sline, logt, mgtemp, nsline, p
	nltemp = n_elements(logt)
	mtemp = n_elements( mgtemp )
	selt = value_locate( logt, alog10(mgtemp))
	p    = fltarr( nsline, mtemp )
	for i=0,mtemp-1 do begin
		indx = (selt[i]-1+indgen(3))<(nltemp-1)>0
		tband = logt[indx]
		v = float(out.lines[sline].int[indx])

		s=1
		u=alog10(mgtemp[i])
		x0 = tband[0] & x1=tband[1] & x2=tband[2]
	;	;Quadratic interpolation from interpol.pro
		p[0,i] = reform( v[s-1,*] * ((u-x1) * (u-x2) / ((x0-x1) * (x0-x2))) + $
			            v[s,*] *   ((u-x0) * (u-x2) / ((x1-x0) * (x1-x2))) + $
			            v[s+1,*] * ((u-x0) * (u-x1) / ((x2-x0) * (x2-x1))) )
		endfor

end
;+
 ;  PROJECT:
 ;    SSW/XRAY
 ;  NAME:
 ;    CHIANTI_KEV_LINES
 ;  PURPOSE:
 ;    This function returns a thermal spectrum (line + continuum) for EM=1.e44 cm^-3
 ;    Uses a database of line and continua spectra obtained from the CHIANTI distribution
 ;
 ;  CALLING SEQUENCE:
 ;    Flux = Chianti_kev_lines(Te6, energy_in, /kev, /earth, /photon, /edges)       ; ph cm-2 s-1 keV-1 at the Earth
 ;
 ;  INPUTS:
 ;    Te6    = Electron Temperature in MK (may be a vector, now true 24-mar-2006)
 ;    Energy_in = Array of 2XN energies in keV, if 1D then they are assumed to be contiguous lower
 ;   and upper energy edges
 ;
 ;  CALLS:
 ;
 ;
 ;  OUTPUTS:
 ;    Flux   = Fluxes in ph s-1 or erg s-1
 ;      Fluxes = fltarr(N_elements(wave),N_elements(Te6))
 ;
 ;  OPTIONAL INPUT KEYWORDS:

 ;    EDGES      = If set, interpret Wave as a 2XN set of channel boundaries
 ;    KEV        = Units of wave are in keV, output units will be ph keV-1
 ;     If KEV is set, assumes EDGES is set so EDGES must be 2XN
 ;    EARTH_FLUX = calculate flux in units cm-2 s-1 (bin unit, ang or keV)-1
 ;    DATE       = optional date for calculation of earth flux, def='2-apr-92'
 ;    FILE_IN    = explicit file name for xlinflx.
 ;    REL_ABUN   = A 2XN array, where the first index gives the atomic number
 ;     of the element and the second gives its relative abundance
 ;     to its nominal value given by ABUN.
 ;  RESTRICTIONS:
 ;    N.B. If both edges aren't specified in WAVE, then the bins of WAVE must
 ;   be equally spaced.
 ;  METHOD:
 ;    Reads in a database from $SSWDB_XRAY/chianti, nominally 'chianti_setup.geny'
 ;  COMMON BLOCKS:
 ;
 ;
 ;   CHIANTI_KEV_LINES holds the line database obtained from CHIANTI.
 ;  MODIFICATION HISTORY:
 ;  richard.schwartz@gsfc.nasa.gov, 8-feb-2005
 ;      29-aug-2005 to used compressed .sav file
 ;	24-apr-2006, richard.schwartz - removed ab_filename, call xr_rd_abundance
 ;		which determines values from XR_AB_FILE and XR_AB_TYPE environ vars
 ;	24-mar-2006, richard.schwartz - modified to work with arrays of temperatures
 ;		to make the dem procedures more efficient
 ;	21-mar-2006, richard.schwartz@gsfc.nasa.gov, uses chianti_kev_load_common to
 ;		manage database files. Default database files updated to work down to 1 keV

 ;	29-jun-2006, richard.schwartz, lines are now spread over two adjacent bins in most
 ;	cases such that their energy weighted position agrees with the true energy centeroid for that line.
 ;	If the maximum bin width is lt .01 keV, then this feature is disabled unless the environment
 ;	variable, wghtline is set to 'T'. By setting wghtline to 'F' this feature can be disabled.
 ;  7-Jul-2006, richard.schwartz.  Fixed error in etst test.
 ;  18-jul-2006, richard.schwartz prevents wide bins from using the centroid weighting
 ;		technique as this can result in bizarre problems in the previous implementation of
 ;		the thermal dem integrating functions
 ;  2007/11/09, PSH (shilaire@ssl.berkeley.edu):
 ;		added warning message, in case user uses this routine below 1 keV/above 12.42A..
 ;
 ;-

function chianti_kev_lines, temp, energy_in, kev=kev, file_in=file_in, $
      earth=earth, rel_abun=rel_abun,  $
      _extra=_extra
;photons/cm2/sec/kev

ss = KEYWORD_SET(kev) ? energy_in[0] lt 0.1 : last_item(energy_in) GT 124.0
IF ss THEN begin
	MESSAGE,/INFO,'Should not be used below 0.1 keV/above 124.0A)'
	return, 0.0
	end

mk_contiguous, energy_in, energy, eindx, test=test
darklines = -1
energy = test ? energy_in : energy
if test eq 0 then begin
	darklines=lindgen(n_elements(energy[0,*]))
	remove, eindx, darklines

	endif

;Load the default data files for cont, line, and abundance into the common blocks
chianti_kev_common_load, linefile=file_in, /NO_ABUND,  _extra=_extra

abundance = xr_rd_abundance(_extra=_extra) ;controlled thru environ vars, XR_AB_FILE, XR_AB_TYPE

common chianti_kev_lines, zindex, out, ion_info, file


rel_abun = exist( rel_abun ) ? rel_abun : $
 (exist(rel_abun_com)? rel_abun_com :reform( [26, 1.0, 28, 1.0], 2,2) )



conversion= 12.39854
mgtemp = temp * 1e6
default, energy, get_edges( 3.+findgen(1001)*.006,/edges_2)
mmenergy = minmax( energy )

eline = conversion / out.lines.wvl


sline = where(eline ge mmenergy[0] and eline le mmenergy[1], nsline)
mtemp = n_elements( temp )
nenrg = n_elements( energy[0,*])
spectrum = fltarr(nenrg, mtemp)

if nsline ge 1 then begin
	eline = eline[sline]

	logt = float(out.logt_isothermal) ;alog10 of database temperatures in degrees Kelvin


	chianti_kev_getp, out, sline,logt, mgtemp, nsline, p
	;

	abundance_ratio = 1.0 + abundance*0.0
	if exist( rel_abun) then $
	    abundance_ratio[rel_abun[0,*]-1] = rel_abun[1,*]

	;We include default_abundance because it will have zeroes for elements not included
	;and ones for those included
	default_abundance = abundance * 0.0
	default_abundance[zindex] = 1.0
	abund = (default_abundance*abundance*abundance_ratio)[out.lines[sline].iz-1]
	emiss = float(p) * rebin(abund,nsline,mtemp) ;* eline


	;wedg = get_edges( energy, /width)
	edge_products, energy, width=wedg, mean= energm, edges_1=energy1

	;iline = value_locate( energy[1,*], eline)+1
	;this integration over the emission in each line
	;requires that the emiss array and eline array both be
	;ordered in asecending line energy(keV).
	;Now chianti_kev_common_load (23-mar-2006) orders this array when
	;it is loaded
;
	;print, total(emiss)

	iline = value_locate( energy1, eline)
;	etst  = where( energm[iline] ge eline and iline gt 0, netst) ;adjacent bin will have lower energy

	hhh   = histogram( eline - energm[iline] , min=-10., max=10., bin=10, rev=rr)
	wghtlineenv = getenv('wghtline')
	wghtline = wghtlineenv eq 'T' or not (max(wedg) lt .01) ;(keV)
	wghtline = wghtlineenv eq 'F' ? 0 : wghtline
	;look for wide bins next to line bins, if too wide x 2 eline bin width
	;then don't spread out lines
	wedg0 = wedg[iline]
	wedg0a= wedg[iline-1>0]
	wedg0b= wedg[iline+1<(n_elements(wedg)-1)]
	wghtline =wghtline and (max( [wedg0a/wedg0, wedg0b/wedg0]) lt 2.) and (max(wedg0) lt 1.5)


if  wghtline then begin


	if hhh[0] ge 1 then begin
		etst = rr[rr[0]:rr[1]-1]
		itst = where( iline[etst] gt 0, nitst)

		if nitst ge 1 then begin
		etst = etst[itst]

		wght = double(f_div(energm[iline[etst]]-eline[etst], $
			energm[iline[etst]]-energm[iline[etst]-1]))
		wght = reproduce( wght, mtemp)

		temp        = emiss[etst, *]
		emiss[etst,*] = temp * (1.d0-wght)
		emiss       = [emiss, temp*wght]


		iline       = [iline, iline[etst]-1]
		endif
		endif

	if hhh[1] ge 1 then begin

		etst = rr[rr[1]:rr[2]-1]
		itst = where( iline[etst] le (nenrg-2), nitst)

		if nitst ge 1 then begin
		etst = etst[itst]

		wght = double(f_div(eline[etst] - energm[iline[etst]], $
			energm[iline[etst]+1]-energm[iline[etst]]))
		wght = reproduce( wght, mtemp)


		temp        = emiss[etst,*]
		emiss[etst,*] = temp * (1.d0-wght)
		emiss       = [emiss, temp*wght]

		iline       = [iline, iline[etst]+1]
		endif
		endif
		ord   = sort(iline)
		iline = iline[ord]
		for i=0,mtemp-1 do emiss[0,i] = emiss[ord,i]
	endif


	fline = histogram( iline,min= 0, max=nenrg-1, r=r)

	select = where( fline gt 0, nselect)
;	if nselect gt 0 then $
;	    for i=0,nselect-1 do spectrum[select[i]] = $
;	       total( emiss[ r[r[select[i]]:r[select[i]+1]-1] ] )
	if nselect gt 0 then begin

	    	for j=0,mtemp-1 do for i=0,nselect-1 do begin
				rr = r[r[select[i]]]
	    		spectrum[select[i],j] = $
	    	total( emiss[ rr:rr + fline[select[i]]-1,j])
				endfor



		 ;ras 13-apr-94
		 funits =  1.      ;default units

		chianti_kev_units, spectrum, funits, $
		    wedg=wedg, kev=kev, earth=earth, date=date
	endif
endif
spectrum = test? spectrum : spectrum[eindx,*]

return, spectrum
end