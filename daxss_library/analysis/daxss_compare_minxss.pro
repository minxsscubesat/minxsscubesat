;
;	daxss_compare_minxss.pro
;
;	Compare DAXSS spectra to MinXSS-1 spectra of similar GOES-X-ray level
;
;	T. Woods, 6/30/2022
;
pro daxss_compare_minxss, date, debug=debug

;  daxss_make_sp_average does half of the work
daxss_make_sp_average, date, data=daxss, goes_level=goes_ref, /nosave

;  minxss_find_goes_level does the other half of the work
minxss_find_goes_level, goes_ref, data=minxss

;
;	do comparison plot - plot two spectra
;
setplot & cc=rainbow(7) & cs=2.0

++++ To DO

;
;	do comparison plot - plot rato of two spectra
;
setplot & cc=rainbow(7) & cs=2.0

++++ To DO


if keyword_set(DEBUG) then stop, 'STOPPED:  debug at end of daxss_compare_minxss.pro ...'
return
end
