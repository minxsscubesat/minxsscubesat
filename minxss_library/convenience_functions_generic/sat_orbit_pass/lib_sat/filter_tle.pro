pro filter_tle,tle
  ;Check all the line 1s are labeled 1
  w=where(strmid(tle[*].line1,0,1) ne '1',count,complement=nw,ncomp=ncount)
  if ncount eq 0 then message,"No valid TLEs"
  if count gt 0 then tle=tle[nw]
  ;check all the line 2s are labeled 2
  w=where(strmid(tle[*].line2,0,1) ne '2',count,complement=nw,ncomp=ncount)
  if ncount eq 0 then message,"No valid TLEs"
  if count gt 0 then tle=tle[nw]
  ;check that the sat ids are the same
  w=where(strmid(tle[*].line2,0,1) ne '2',count,complement=nw,ncomp=ncount)
  if ncount eq 0 then message,"No valid TLEs"
  if count gt 0 then tle=tle[nw]

  ; TURN OFF checksum for testing TLE manually installed
  DO_CHECKSUM = 0
  if (DO_CHECKSUM ne 0) then begin
    ;check the checksum on line 1
    w=where(~check_checksum(tle[*].line1),count,complement=nw,ncomp=ncount)
    if ncount eq 0 then message,"No valid TLEs"
    if count gt 0 then tle=tle[nw]
    ;check the checksum on line 2
    w=where(~check_checksum(tle[*].line2),count,complement=nw,ncomp=ncount)
    if ncount eq 0 then message,"No valid TLEs"
    if count gt 0 then tle=tle[nw]
  endif

  ;Now for the hard part. Check that each tle is consistent with its two neighbors
  ;   Outlier Threshold
  MaxSD = 5.d0
  neighbor_consistency,tle,cr,cv

;     The following values of rMean, rSd, vMean, vSD were
;     obtained from the second of two rounds of this filter
;     on the first 3996 TLE sets for the UARS orbit.
      rMean=1.243155E+00
      rSD=8.018418E-01
      vMean=1.257520E+00
      vSD=8.275024E-01

      rdev = (cR-rMean)/rSD
      vdev = (cV-vMean)/vSD
      tdev = abs( rdev )*abs( vdev)
  w=where(logical_or(logical_or(abs( rdev ) gt MaxSD*4, abs( vdev ) gt MaxSD*4),tdev gt MaxSD*8),count,complement=nw,ncomp=ncount)
  if ncount eq 0 then message,"No valid TLEs"
  if count gt 0 then tle=tle[nw]

end
