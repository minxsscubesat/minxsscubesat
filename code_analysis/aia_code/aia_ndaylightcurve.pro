
;  generation of n-day AIA lightcurves in select channels
;  by Karel Schrijver  14-July-2010
;
pro aia_ndaylightcurve,image,r,g,b,ndays=ndays,showimage=showimage,t0=t0,t1=t1
; usage examples:
; aia_ndaylightcurve,image,r,g,b,ndays=1,/showimage
; aia_ndaylightcurve,image,r,g,b,t0='2010/07/01',t1='2010/07/04',/showimage
;
if not(keyword_set(ndays)) then ndays=2
;
; retrieve last two days of total intensity information
if not(keyword_set(t0)) then t0=reltime(days=-ndays)
if not(keyword_set(t1)) then t1=reltime(/now)
ssw_jsoc_time2data,t0,t1, $
 key='t_obs,date__obs,wavelnth,wave_str,datamean',meta,ds='aia_test.synoptic2'
; select wavelengths to be plotted:
plotwave=[304,171,211,335,94] ; sorted from cool to hot
plotcolor=[24,22,2,11,17]*256./25. ; to match, roughly, 'standard colors'
plotnorm=[60,300,90,5,1.2] ; to normalize to a quiet day (2010/07/13 04UT)
;
set_plot,'z'
device,set_resolution=[1280,720]
;
loadct,23
tvlct,r,g,b,/get & r(255)=255 & g(255)=255 & b(255)=255 & tvlct,r,g,b
for i=0,n_elements(plotwave)-1 do begin
  index=where(meta.wavelnth eq plotwave(i))
  if i eq 0 then utplot_io,meta(index).date_obs,$
    meta(index).datamean/plotnorm(i),yrange=[0.7,100],ys=1,$
    xrange=[meta(index(0)).date_obs,$
            meta(index(n_elements(index)-1)).date_obs],xs=1,/nodata,$
    ytitle='Normalized AIA irradiance',color=255,chars=1.5
    outplot,meta(index).date_obs,$
      meta(index).datamean/plotnorm(i)*(1.2^i),$
      color=plotcolor(i),psym=10
  xyouts,150,500+25*i,string(plotwave(i)),/device,color=plotcolor(i),chars=1.5

 endfor
;
image=tvrd()
set_plot,'x'

if keyword_set(showimage) then begin
  window,0,xs=1280,ys=720
  tvlct,r,g,b
  tv,image
endif

return

end

