;+
;
; History:
;	Circa 2002, ras
;	31-aug-2012, ras, leave dem_int undefined for chianti_version 7 or greater
;	1-sep-2012, ras, fixed two photon error thanks to Jim McTiernan
;	20-June-2017, Christopher Samuel Moore, madified with new extended CHIANT continuum data, to fgo from 5 - 8 MK and 0.1 - 30 keV (be cautius below 1 keV, the spectral resolution and accuracy of the continuum is poor!!)
;-
function setup_chianti_cont_test_cm, ioneq, kmin, kmax, temp_range, nelem=nelem,$
    ntemp=ntemp, nedge=nedge, genxfile=genxfile, overwrite=overwrite



default, genxfile, 'chianti_setup_cont_test_cm.geny'
default, overwrite, 0
fcount = 0
If not overwrite then begin
    foundfile = loc_file(path=[curdir(),'$SSWDB_XRAY'], genxfile,count=fcount)
    overwrite = 1 - (fcount < 1)
    endif

if overwrite then begin
default,ioneq, 'CHIANTI'
default, nelem, 15 ;choose 15 most abundant elements from following list
;abundances saved will be 1 relative to hydrogen, actual abundances applied as needed
;this has the coronal abundance of the first 30 elements
abund='sun_coronal_1992_feldman_ext.abund'
chianti_dbase= concat_dir('SSW_CHIANTI','dbase')
ioneq_file = loc_file(path=concat_dir(chianti_dbase,'ioneq'),'*.ioneq')
select = where( strpos(STRLOWCASE(ioneq_file),STRLOWCASE(ioneq)) ne -1)
ioneq_name = ioneq_file[ select[0] ]

abund_file = loc_file(path=concat_dir(chianti_dbase,'abundance'),'*.abund')
select = where( strpos(STRLOWCASE(abund_file),STRLOWCASE(abund)) ne -1)
abund_file = abund_file[ select[0] ]


conversion= 12.39854
;default,kmin, 3.0
;default,kmax,  9.0
default,kmin, 0.1
default,kmax,  30.0
wmin = conversion/kmax
wmax = conversion/kmin
edensity = 1.e11 ;cm-3
verbose = 0
;default,temp_range, [1., 100.]*1e6
default,temp_range, [0.1, 100.]*1e6
;default, ntemp, 400
default, ntemp, 600
temp = temp_range[0] * 10^(findgen(ntemp)/(ntemp-1)*alog10((temp_range[1]/temp_range[0])))


n=n_elements(edensity)
nt=n_elements(temp)
IF nt NE 1 THEN no_sum_int=1


COMMON elements,abundcom,abund_ref,ioneqcom,ioneq_logt,ioneq_ref

read_abund,abund_file,abundances,abundance_ref
select = where( abundances gt 0, nselect)
ord  = sort( abundances[select] )
nord = n_elements(ord)
ord = ord[ nord-nelem:*]
select = select[ord]
zindex = select
abundances = abundances * 0.0
abundances[zindex] =  1.0 ;set all abundances to 1 and set abundances as needed in chianti_kev

abundcom = abundances
abund_ref = 'abundances set to 1'
read_ioneq,ioneq_name,iont,ioneq,ion_ref
ioneqcom = ioneq
ioneq_logt = iont
ioneq_ref = ion_ref

default, nedge, 1000
wavestep= float(wmax-wmin)/nedge
nw=fix((wmax-wmin)/wavestep+0.1)
lambda1=findgen(nedge+1)*wavestep+wmin
;;add in wavelengths around 8.81 kev
lambda1 = get_uniq( [lambda1, 1.4025+findgen(10)*.001/2])
wvl = get_edges(lambda1,/mean)
wavestep = get_edges(lambda1, /width)
nw = n_elements(wvl)
lambda = wvl
edge_str = {conversion:conversion, wvledge: lambda1, wvl: wvl, wavestep: wavestep}



;From isothermal
if float(chianti_version()) lt 7.0 then dem_int=1d0/0.1/alog(10.)/temp
abund_arr =  abundcom
select= where( abundcom gt 0.0, nelem)
totcont= dblarr(nw, ntemp, nelem)
;Build continua for all ions separately
for i=0,nelem-1 do begin
    abundcom = abundcom * 0.0
    abundcom[select[i]] = 1.0
    min_abund = 1.0

    freebound, temp, lambda,fb,/no_setup,min_abund=min_abund, $
       /photons, dem_int=dem_int
    print,'FREEBOUND,  select[i]+1, abundcom ',I, select[i]+1, abundcom
    print,'Total',total(fb)
    freefree,temp, lambda,ff,/no_setup,min_abund=min_abund, $
       /photons, dem_int=dem_int
    print,'FREEFREE ',I
    print,'total',total(ff)
    ;We're selecting 1 elem at a time where abundcom gt min_abund
    ;RAS, 1-sep-2012 - thanks to the sharp eye of Jim McTiernan
    two_photon, temp,  lambda, two_phot,/no_setup,min_abund=.01, $
       edensity=edensity, /photons, dem_int=dem_int
    print,'2PHOTON', I
    print,'total',total(two_phot)
    totcont[0,0,i]=(fb+ff+two_phot)/1d40*$
        ((wavestep + lambda*0.0)#(1.+temp*0.0))
    endfor
;Restore original abundance
abundcom = abund_arr
cversion = chianti_version()
lobound = where( lambda lt 1.0, nlo)
totcont_lo  = totcont[lobound,*,*]
totcont  = float(totcont[nlo:*,*,*])

chianti_doc = {ion_file: ioneq_name, ion_ref: ion_ref, version: cversion}
ctemp = temp
savegenx, zindex,  totcont, totcont_lo, $
    edge_str, ctemp, chianti_doc, $
    file=genxfile, /overwrite
    
  save,/compress, zindex,  totcont, totcont_lo, edge_str, ctemp, chianti_doc, file='chianti_setup_cont_test_cm.sav'
    
endif

return, fcount ge 1 ? foundfile[0] : genxfile

end