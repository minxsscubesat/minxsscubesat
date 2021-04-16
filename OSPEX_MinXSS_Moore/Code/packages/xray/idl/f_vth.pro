;+
;Name:
;   F_VTH
;PURPOSE:
;   This function returns the optically thin thermal bremsstrahlung radiation function
;   as differential spectrum seen at Earth in units of photon/(cm2 s keV)
;
;CATEGORY:
;   SPECTRA, XRAYS (>0.1 keV)
;INPUTS:
;   E  energy vector in keV
;   apar[0]  em_49, emission measure units of 10^49
;   apar[1]  KT, plasma temperature in keV, restricted to a range from 1.01 MegaKelvin to <998 MegaKelvin in keV
;     i.e.  0.0870317 - 86.0 keV
;   apar[2]  Relative abundance for Fe, Ni, Si, and Ca. S as well at half the deviation from 1 as Fe.
;            Relative to coronal abundance for Chianti
;            Relative to solar abundance for Mewe
;           (unless user selects a different abundance table manually)
;   If vth for multiple temperatures is desired, pass an array of temperatures through
;   multi_temp keyword.  apar[1] will be ignored in this case.
;   If rel_abun keyword is used, apar[2] is set to keyword value.
;
;KEYWORD INPUTS:
;   LINES - Only return lines
;   CONTINUUM - Only return continuum (same as setting NOLINE keyword)
;   NOLINE - Only return continuum
;   CHIANTI - If set, use chianti_kev
;   MEWE - If set, use mewe_kev
;   REL_ABUN - 2x2 array giving Fe, Ni abundance [ 26,x],[28,x] ],  If rel_abun keyword not used,
;     the value of x is taken from apar(2) to make 2x5 array for Fe, Ni, Si, and Ca.
;	  S is also included but at half the deviation from nominal as the others.  If that's not there either, x is 1.
;   BREM49 - if set, and if e is a 1d vector, the function used is brem_49, see METHOD
;   Defaults are to return full spectrum (lines+continuum), chianti
;
;CALLS:
;   mk_contiguous, BREM_49, MEWE_KEV, CHIANTI_KEV
;
;Common Blocks:
;   None
;
;Method:
;   If energy array starts at gt 8 keV, then noline is set to calc pure
;     free-free continuum from either chianti_kev or mewe_kev.
;   If edges weren't passed as 2xn array, use Brem_49 function.
;
; History:
;   ras, 17-may-94
;   ras, 14-may-96, checked for 2xn energies, e
;   Version 3, 23-oct-1996, revised check for 2xn energies, e
;   ras, 10-apr-2002, ras, default to vlth() when bottom energy
;   is less than 8 keV.
;   ras, 2-may-2003, support relative abundance pass through to mewe_kev
;     call mewe_kev directly, no longer uses interpolation table in vlth.pro
;   ras, 25-jun-2003, added NOLINE keyword passed through to mewe_kev
;   Kim Tolbert, 2004/03/04 - added _extra so won't crash if keyword is used in call
;   ras, 31-aug-2005, modified to allow calls to chianti_kev via VTH_METHOD environment var.
;   Kim Tolbert, 10-Mar-2006.  removed f_vth_funct keyword, added chianti, mewe, lines,
;     and continuum keywords.  Chianti is now the default.
;   ras 24-mar-2006, support call with multiple temperatures (used in dem integration)
;     through extension of apar.  apar[1:*] is the temperature array
;   Kim, 4-Apr-2006, merged ras 24-mar changes with 10-mar changes.
;     Also fixed bug: transpose result if mewe *AND* multi temp.
;     Also, if brem_49 is called, it didn't handle multi temp, so loop through temps
;     Now brem_49 is only called if e does not have lower/upper edges.  If lowest e is
;     > 8., set noline but call mewe_kev or chianti_kev (previously called brem_49)
;   Kim, 19-Apr-2006.  Now vth has 3 params - added abundance (for Fe,Ni) as 3rd param.
;     Changed RAS multi temp implementation.  Now if multiple temps pass through multi_temp
;     keyword.  Also added noline keyword back in for compatibility with spex.
;	RAS, 8-may-2008, Added 3 more elements for abundance deviation to support all 5 low fip elements
;		important above 1 keV, Fe, Ni, Si, Ca, and S.  Deviation of S from 1. is half that for
;		Fe as S is a mid-FIP element.
; Kim, 12-Aug-2013. If apar[0] is 0, return an array of 0s right away.
; Kim, 13-May-2014. Use check_math to avoid printing underflow errors. 
; 26-may-2015, richard.schwartz@nasa.gov (RAS) 
;   1d e (energy) vectors converted to 2xN for use unless used with the new BREM49 keyword toggle
;   added documentation and warning about the range of allowed temperatures 
;-

;function f_vth, e, apar, noline=noline, f_vth_funct=f_vth_funct, _extra=_extra

function f_vth, e, apar, multi_temp=multi_temp, $
	rel_abun=rel_abun, $
	lines=lines, continuum=continuum, $
	noline=noline_keyword, $
	chianti=chianti, mewe=mewe, $
	brem49 = brem49, $
	_extra=_extra

; if emission measure is 0, just figure out how many energy bins there are and return an array of 0s
if apar[0] eq 0. then begin
  n_e = n_elements(e)
  nbin = n_e - 1
  if n_e eq 2 then nbin = 1 else if (size(e))[0] eq 2 then nbin = n_e/2.
  return, fltarr(nbin)
endif 
mk2kev = 0.08617
; default is chianti, unless mewe is set
func = keyword_set(mewe) ? 'MEWE_KEV' : 'CHIANTI_KEV'

; default is continuum+lines.  If either cont or lines is set - then just do that one.
noline = 0 & nocont = 0
if keyword_set(continuum) then noline = 1 else if keyword_set(lines) then nocont = 1

; if noline keyword is used, let that take precedence
if exist(noline_keyword) then begin
	noline = noline_keyword
	nocont = 0
endif

if not keyword_set(rel_abun) then begin
  abun = n_elements(apar) eq 2 ? 1. : apar[2]
  ;we modify the abundance for sulfur, a mid-fip element only half of the abundance deviation for Fe
  dabun = 1.-abun
  abun16 = 1. - (dabun/2.)
  rel_abun = reform( [12,abun,14,abun,16,abun16,20,abun,26,abun,28,abun], 2,6)
endif

;print,'rel_abun in f_vth = ',reform(rel_abun,4)
;print, 'nocont, noline = ', nocont, noline

temp = apar[1]
if keyword_set(multi_temp) then temp = multi_temp
ntemp = n_elements(temp)
if ntemp eq 1 then temp = temp[0]  ; if multi_temp has single elem, make it scalar
;valid_trange = [1.01, 998.0] * mk2kev
valid_trange = [0.11, 998.0] * mk2kev
inrange = in_range( temp, valid_trange ) ;test for range in keV
if ~inrange then begin
;  message, 'Out of range temperature. Valid range is 1.01 - 998.0 MegaKelvin or 0.0870317 - 85.9977 keV'
  message, 'Out of range temperature. Valid range is 0.11 - 998.0 MegaKelvin or 0.00948 - 85.9977 keV'
endif
edges = e
; can only call chianti_kev or mewe_kev if edges are in the form [2,n].  If only 2 elements, assume
; they are the lower,upper edges of a single bin.
; Convert 1D edges to 2D unless explicitly inhibited by setting BREM49
if ~keyword_set( brem49 ) and ( n_elements( edges ) gt 1 ) then edges = get_edges( /edges_2, edges )
if (size(edges))[0] eq 2 or n_elements(edges) eq 2  then begin

    ; if lowest edges is > 8. keV, don't do lines
    if edges[0] gt 8.0 then noline = 1

   ; energy edges sent to chianti_kev or mewe_kev must be contiguous.  If they're not, make them
   ; contiguous, but then only use the results for the energy bins requested (eindx bins)
   ; contig will be 0 if edges weren't already contiguous
   contig = 1
   mk_contiguous, edges, edges_c, eindx, test=contig
   edges_c = contig ? edges : edges_c

   result = apar[0]* $
      float( call_function(func, temp / mk2kev , edges_c, $
      /photon, /edges, /keV, /earth, $
      noline=noline, nocont=nocont, rel_abun=rel_abun, _extra=_extra ) * 1.e5)

   result = keyword_set(mewe) and ntemp gt 1 ? transpose(result) : result
   result = contig ? result : result[eindx,*]

endif

; if didn't calculate results above, then use brem_49
if not exist(result) then begin
    if ntemp eq 1 then result = apar[0]*brem_49(get_edges(e,/mean),temp) else begin
       emean = get_edges(e,/mean)
	   result = fltarr(n_elements(emean), ntemp)
	   for it = 0,ntemp-1 do $
	      result[0,it] = apar[0]*brem_49(emean,temp[it])
	endelse
endif

; Clear underflow errors so they don't print
chk=check_math(mask=32)

return, result

end