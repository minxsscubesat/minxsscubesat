; main_program xjd2vms
;
; Unit tester for jd2vms.pro
;
; B. Knapp, 97.11.12
;           98.06.09, IDL v. 5 compliance
;
; Generate an array of random Julian Day Numbers
  n = 1000L
  jd1 = 1721059.5d0+randomu( seed, n )*1000000.d0
;
; Add a few that will test day-boundary cases
  m = 100L
  jd2 = floor( 1721059.5d0+randomu( seed, m )*1000000.d0 )+ $
     (randomu( seed, m )*4.d0-2.d0)/8.64d6
  jd3 = floor( 1721059.5d0+randomu( seed, m )*1000000.d0 )+ $
     0.5d0+(randomu( seed, m )*4.d0-2.d0)/8.64d6
  jd = [jd1,jd2,jd3]
;
; Convert these to VMS, then back to JD
  vms1 = jd2vms( jd )
  jdx = vms2jd( vms1 )
  vms2 = jd2vms( jdx )
;
; Any differences?
  djd = jdx-jd
  dj = where(abs(djd) gt 1./8.64d6, ndj)
  if ndj gt 0 then for j=0,ndj-1 do $
     print, jd[dj[j]],jdx[dj[j]],djd[dj[j]], $
        format="(2f25.10,e12.3)"
  dv = where(vms1 ne vms2, ndv)
  if ndv gt 0 then for j=0,ndv-1 do $
     print, vms1[dv[j]], vms2[dv[j]], $
    format="(2a25)"
  if ndj eq 0 and ndv eq 0 then print, "Test passed"
;
  end
