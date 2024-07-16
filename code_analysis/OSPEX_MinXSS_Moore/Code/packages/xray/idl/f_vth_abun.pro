;+
;Name:
;   F_VTH_ABUN
;PURPOSE:
;   This function returns the optically thin thermal bremsstrahlung radiation function
;   as differential spectrum seen at Earth in units of photon/(cm2 s keV)
;   Same as f_vth except relative abundance for all low-fip elements are controlled by
;   separate parameters.
;
;CATEGORY:
;   SPECTRA, XRAYS (>0.5 keV)
;INPUTS:
;   E  energy vector in keV 
;   apar[0]  em_49, emission measure units of 10^49
;   apar[1]  KT, plasma temperature in keV
;   apar[2]  Relative abundance for Fe 
;   apar[3]  Relative abundance for Ca
;   apar[4]  Relative abundance for S
;   apar[5]  Relative abundance for Mg
;   apar[6]  Relative abundance for Si
;   apar[7]  Relative abundance for Ar
;   apar[8]  Relative abundance for He, C, N, O, F, Ne, Na, Al, K
;   apar[9]  Relative abundance for Ni
   
;            Abundances are relative to coronal abundance for Chianti
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
;   REL_ABUN - 2xn array giving abundance for separate elements in the form [ [atomic number1, abundance1], [atomic number2, abundance2],... ]
;     If rel_abun keyword not used, then the value of abundances are taken from apar[2-7].  Any that aren't passed in, are set to 1.
;
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
;	Kim, 12-May-2008.  Now has 6 params - changed 8-may mod so that abundances for Fe,Ca, S, Si are  
;		input through parameters 2 - 5 respectively. Ni abun is set to same as Fe.
; Kim, 30-Jun-2008. Now has 8 params - added argon abundance in apar[6], abundance for 
;   He, C, N, O, F, Ne, Na, Mg, Al, K in apar[7] (these 10 will vary together)
;   Also, made this routine call f_vth (previously code was duplicated - dumb)
; Christopher S. Moore, 30-Jun-2017. Now has 9 params - seperated the Ni abundance from Fe. abundance in apar[9]

;
;-

function f_vth_abun, e, apar, rel_abun=rel_abun, _extra=_extra

npar = n_elements(apar)
abunfe = npar lt 3 ? 1. : apar[2]
abunca = npar lt 4 ? 1. : apar[3]
abuns  = npar lt 5 ? 1. : apar[4]
abunmg = npar lt 6 ? 1. : apar[5]
abunsi = npar lt 7 ? 1. : apar[6]
abunar = npar lt 8 ? 1. : apar[7]
;abunni = npar lt 9 ? 1. : apar[8]
abun10 = npar lt 9 ? 1. : apar[8]

rel_abun = keyword_set(rel_abun) ? rel_abun : $
   reform( [2, abun10, $
            6, abun10, $
            7, abun10, $
            8, abun10, $
            9, abun10, $
           10, abun10, $
           11, abun10, $
           12, abunmg, $
           13, abun10, $
           14, abunsi, $
           16, abuns, $
           18, abunar, $
           19, abun10, $
           20, abunca, $
           26, abunfe, $
           28, abunfe], 2,16)

;print,'rel_abun in f_vth_abun = ',rel_abun

return, f_vth (e, apar, rel_abun=rel_abun, _extra=_extra)

end