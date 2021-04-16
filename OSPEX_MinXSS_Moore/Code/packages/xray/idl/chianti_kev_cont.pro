
;+
 ;  PROJECT:
 ;    SSW/XRAY
 ;  NAME:
 ;    CHIANTI_KEV
 ;  PURPOSE:
 ;    This function returns a thermal spectrum (line + continuum) for EM=1.e44 cm^-3
 ;    Uses a database of line and continua spectra obtained from the CHIANTI distribution
 ;
 ;  CALLING SEQUENCE:
 ;    Flux = Chianti_kev(Te6, energy, /kev, /earth, /photon, /edges)       ; ph cm-2 s-1 keV-1 at the Earth
 ;
 ;  INPUTS:
 ;    Te6    = Electron Temperature in MK (may be a vector)
 ;    Energy   = Array of 2XN energies in keV, if 1D then they are assumed to be contiguous lower
 ;   and upper energy edges
 ;
 ;  CALLS:
 ;
 ;
 ;  OUTPUTS:
 ;    Flux   = Fluxes in ph s-1 or erg s-1
 ;      Fluxes = fltarr(N_elements(Te6),N_elements(wave))
 ;
 ;  OPTIONAL INPUT KEYWORDS:
 ;    PHOTON = If set, calculation is made in ph s-1 (default)
 ;    ERG    = If set, calculation is made in erg s-1
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
 ;    Reads in a database from $SSWDB_XRAY, nominally 'chianti_setup.geny'
 ;  COMMON BLOCKS:
 ;   CHIANTI_KEV_CONT holds the continuum database obtained from CHIANTI.
 ;   CHIANTI_KEV_ABUNDANCE holds the abundance information used in chianti_kev
 ;  MODIFICATION HISTORY:
 ;  richard.schwartz@gsfc.nasa.gov, 8-feb-2005
 ;      29-aug-2005 to used new format .sav file
 ;   added protection against non finite values
 ;
 ;	21-mar-2006, richard.schwartz@gsfc.nasa.gov, uses chianti_kev_load_common to
 ;		manage database files. Default database files updated to work down to 1 keV
 ;	24-apr-2006, richard.schwartz - removed ab_filename, call xr_rd_abundance
 ;		which determines values from XR_AB_FILE and XR_AB_TYPE environ vars
 ;	2-may-2006, added protection for energy range extremes
 ;      2007/11/09, PSH (shilaire@ssl.berkeley.edu):
 ;	added warning message, in case user uses this routine below 1 keV/above 12.42A..
 ;-

function chianti_kev_cont, temp, energy, kev=kev,  file_in=file_in, $
    tcont=tcont, reload=reload, earth=earth, rel_abun=rel_abun, $
    use_interpol = use_interpol, $
    _extra=_extra
;photons/cm2/sec/kev


ss = KEYWORD_SET(kev) ? energy[0] lt 0.1 : last_item(energy) GT 124.0

IF ss THEN begin
	MESSAGE,/INFO,'Should not be used below 0.1 keV/above 124.0A)'
	return, 0.0
	end



;Load the default data files for cont, line, and abundance into the common blocks
chianti_kev_common_load, linefile=file_in, /NO_ABUND,  _extra=_extra

abundance = xr_rd_abundance(_extra=_extra) ;controlled thru environ vars, XR_AB_FILE, XR_AB_TYPE


common chianti_kev_cont, zindex, totcont, totcont_lo, edge_str, ctemp, chianti_doc, file

;	21-mar-2006, richard.schwartz@gsfc.nasa.gov, uses chianti_kev_load_common to
;		manage database files. Default database files updated to work down to 1 keV


rel_abun = keyword_set( rel_abun ) ? rel_abun : $
 (keyword_set(rel_abun_com)? rel_abun_com :reform( [26, 1.0, 28, 1.0], 2,2) )



conversion= 12.39854
mgtemp = temp * 1e6
u=alog10(mgtemp)
default, energy, get_edges( 3.+findgen(1001)*.006,/edges_2)


nspec = n_elements( spectrum )

;Add in continuum
wedg = get_edges( energy, /width)
ewvl  = conversion/edge_str.wvl
wwvl  = edge_str.wavestep
nwvl  = n_elements(ewvl)

logt = alog10( ctemp )
ntemp = n_elements(logt)
selt = value_locate( logt, alog10(mgtemp))
indx = (selt-1+indgen(3))<(ntemp-1)>0
tband = logt[indx]
;v = out.lines.int[indx]
s=1
u=alog10(mgtemp)
x0 = tband[0] & x1=tband[1] & x2=tband[2]

exponential = (ewvl#(1+fltarr(1,3))) / $
    ((fltarr(nwvl)+1.)#(10.^logt[indx]/11.6e6) )
exponential = exp(exponential<80.)
deltae = ewvl * wwvl / edge_str.wvl #(1.+fltarr(1,3))
gmean_en = get_edges(energy,/gmean)
;We include default_abundance because it will have zeroes for elements not included
;and ones for those included
default_abundance = abundance * 0.0
default_abundance[zindex] = 1.0
select= where( default_abundance gt 0, nselect)
tcont = gmean_en * 0.0
spectrum = double(tcont)

abundance_ratio = 1.0 + abundance*0.0
if keyword_set( rel_abun) then $
    abundance_ratio[rel_abun[0,*]-1] = rel_abun[1,*]
abundance_ratio =(default_abundance*abundance*abundance_ratio)
totcontindx = [totcont_lo[*, indx, *], totcont[*, indx, *] ]
tcdbase = double(totcontindx[*, *, *])
tcd     = double(totcontindx[*, *, 0])
for i=0,2 do tcd[0,i] = reform( tcdbase[*, i, *]) # abundance_ratio[select]
u = alog(u)
x1= alog(x1) & x0=alog(x0) & x2 = alog(x2)

gaunt = tcd/deltae * exponential


default, use_interpol, 1
;define valid range
vrange = where( gaunt[*,0] gt 0,nrange)
vrange1 = where( gaunt[*,1] gt 0,nrange1)
vrange = nrange lt nrange1 ? vrange : vrange1
vrange1 = where( gaunt[*,2] gt 0, nrange1)
vrange = nrange lt nrange1 ? vrange : vrange1
gaunt = gaunt[vrange,*]
ewvl  = ewvl[vrange]
maxe = ewvl[0]
vgmean = where(gmean_en lt maxe, nvg)
if nvg ge 1 then begin
	gmean_en = gmean_en[vgmean]
	if keyword_set( use_interpol) then begin
	    cont0 = interpol( gaunt[*,0], ewvl, gmean_en )
	    cont1 = interpol( gaunt[*,1], ewvl, gmean_en )
	    cont2 = interpol( gaunt[*,2], ewvl, gmean_en )
	    endif else begin
	    venergy = where( energy[1,*] lt maxe)
	    energyv = energy[*,venergy]
	    wen   = get_edges( energyv, /width )
	    e2 = (get_edges( conversion / edge_str.wvledge, /edges_2))[*,vrange]
	    cont0 = interp2integ( energyv, e2, gaunt[*,0] )/wen
	    cont1 = interp2integ( energyv, e2, gaunt[*,1] )/wen
	    cont2 = interp2integ( energyv, e2, gaunt[*,2] )/wen
	    endelse

	cont0 = alog(cont0) & cont1=alog(cont1) & cont2=alog(cont2)
	ynew  = exp(reform( cont0 * (u-x1) * (u-x2) / ((x0-x1) * (x0-x2)) + $
	            cont1 *   (u-x0) * (u-x2) / ((x1-x0) * (x1-x2)) + $
	            cont2 * (u-x0) * (u-x1) / ((x2-x0) * (x2-x1)) ))
	tcont[vgmean] = tcont[vgmean] + ynew


	tcont = tcont * exp( -1.0d0*((gmean_en/(temp/11.6))<80.))

	spectrum[vgmean] = spectrum[vgmean] + tcont * wedg
endif

 ;ras 13-apr-94
 funits =  1.      ;default units

chianti_kev_units, spectrum, funits, $
    kev=kev, wedg=wedg, earth=earth, date=date

;And failing everything else, set all nan, inf, -inf to 0.0
infinite = where( finite(spectrum) eq 0, ninfinite)
if ninfinite ge 1 then begin
    spectrum[infinite] = 0.0
    ;help, temp, ninifinite
    endif
return, float(spectrum)
end
