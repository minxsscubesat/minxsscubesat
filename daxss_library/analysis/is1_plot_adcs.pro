;
;	is1_plot_adcs.pro
;
;	Plot trends of ADCS data
;
;	3-30-2022	Tom Woods    Plots with just Beacon data
;
;	USAGE:  .run is1_plot_adcs.pro
;

if n_elements(hk_jd lt 1) then begin
	hk_file ='/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level0c/daxss_l0c_merged_2022_089.sav'
	print, 'Restoring DAXSS Level 0C file: ', hk_file
	restore,hk_file
	hk_jd = gps2jd(hk.time)
endif

setplot
cc = rainbow(7)
cs = 2.0
ans = ' '

;
;	Plot ADCS_INFO flags
;
plot,hk_jd,hk.adcs_att_valid*0.9+0.1,XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time'],ytit='Beacon ADCS Info Flags',yr=[0,10],ys=1
xx=ymd2jd(2022,2,3)
xyouts,xx,0.3,'ATT_VALID',charsize=cs

oplot,hk_jd,hk.adcs_refs_valid*0.9+1.1,color=cc[0]
xyouts,xx,1.3,'REFS_VALID',charsize=cs,color=cc[0]

oplot,hk_jd,hk.adcs_time_valid*0.9+2.1,color=cc[1]
xyouts,xx,2.3,'TIME_VALID',charsize=cs,color=cc[1]

oplot,hk_jd,hk.adcs_mode_sun*0.9+3.1,color=cc[3]
xyouts,xx,3.3,'MODE_SUN',charsize=cs,color=cc[3]

oplot,hk_jd,hk.adcs_recom_sun_pt*0.9+4.1,color=cc[4]
xyouts,xx,4.3,'REC_SUN_PT',charsize=cs,color=cc[4]

oplot,hk_jd,hk.adcs_sun_pt_state*0.5+5.1,color=cc[5]
xyouts,xx,5.3,'SUN_PT_ST',charsize=cs,color=cc[5]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_WHEEL_TEMP 1-3
;
plot,hk_jd,hk.adcs_wheel_temp1,/nodata, ytit='Beacon ADCS Wheel Temp',yr=[0,30],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
oplot,hk_jd,hk.adcs_wheel_temp1,color=cc[0]
xx=ymd2jd(2022,2,3)
yy = 2 & dy = 5
xyouts,xx,yy,'Temp-1',charsize=cs,color=cc[0]

oplot,hk_jd,hk.adcs_wheel_temp2,color=cc[3]
xyouts,xx,yy+dy,'Temp-2',charsize=cs,color=cc[3]

oplot,hk_jd,hk.adcs_wheel_temp3,color=cc[5]
xyouts,xx,yy+2*dy,'Temp-3',charsize=cs,color=cc[5]

oplot, hk_jd, hk.adcs_mode_sun*27+1, color=cc[1]
xyouts,xx,26, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_WHEEL_SP 1-3
;
plot,hk_jd,hk.adcs_wheel_sp1,/nodata, ytit='Beacon ADCS Wheel Speed',yr=[-1000,1500],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
oplot,!x.crange,[0,0],line=2
oplot,hk_jd,hk.adcs_wheel_sp1,color=cc[0]
xx=ymd2jd(2022,2,3)
yy = -400 & dy = 200
xyouts,xx,yy+dy,'Speed-1',charsize=cs,color=cc[0]

oplot,hk_jd,hk.adcs_wheel_sp2,color=cc[3]
xyouts,xx,yy,'Speed-2',charsize=cs,color=cc[3]

oplot,hk_jd,hk.adcs_wheel_sp3,color=cc[5]
xyouts,xx,yy+3*dy,'Speed-3',charsize=cs,color=cc[5]

oplot, hk_jd, hk.adcs_mode_sun*2100-900, color=cc[1]
xyouts,xx,1100, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_WHEEL_SP 1-3   -  Zoom in for Fine Point Mode
;
wzoom = where(hk_jd ge ymd2jd(2022,3,17.7) AND hk_jd lt ymd2jd(2022,3,21.8))
wzoom2 = where(hk_jd ge ymd2jd(2022,3,17.2) AND hk_jd lt ymd2jd(2022,3,21.8))
plot,hk_jd[wzoom2],hk[wzoom2].adcs_wheel_sp1,/nodata, ytit='Beacon ADCS Wheel Speed',yr=[-1000,1500],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
oplot,!x.crange,[0,0],line=2
oplot,hk_jd[wzoom],hk[wzoom].adcs_wheel_sp1,color=cc[0],psym=4
xx=ymd2jd(2022,3,17.1)
yy = -400 & dy = 200
xyouts,xx,yy+dy,'Speed-1',charsize=cs,color=cc[0]

oplot,hk_jd[wzoom],hk[wzoom].adcs_wheel_sp2,color=cc[3],psym=5
xyouts,xx,yy,'Speed-2',charsize=cs,color=cc[3]

oplot,hk_jd[wzoom],hk[wzoom].adcs_wheel_sp3,color=cc[5],psym=6
xyouts,xx,yy+3*dy,'Speed-3',charsize=cs,color=cc[5]

oplot, hk_jd, hk.adcs_mode_sun*2100-900, color=cc[1]
xyouts,xx,1100, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_BODY_RT 1-3
;
plot,hk_jd,hk.adcs_body_rt1,/nodata, ytit='Beacon ADCS Body Rate',yr=[-1E6,1E6],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
oplot,!x.crange,[0,0],line=2
oplot,hk_jd,hk.adcs_body_rt1,color=cc[0]
xx=ymd2jd(2022,2,3)
yy = -4E5 & dy = 2E5
xyouts,xx,yy+0*dy,'Rate-1',charsize=cs,color=cc[0]

oplot,hk_jd,hk.adcs_body_rt2,color=cc[3]
xyouts,xx,yy+1*dy,'Rate-2',charsize=cs,color=cc[3]

oplot,hk_jd,hk.adcs_body_rt3,color=cc[5]
xyouts,xx,yy+3*dy,'Rate-3',charsize=cs,color=cc[5]

oplot, hk_jd, hk.adcs_mode_sun*18E5-9E5, color=cc[1]
xyouts,xx,8E5, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_BODY_RT 1-3 - ZOOM
;
plot,hk_jd[wzoom2],hk[wzoom2].adcs_body_rt1,/nodata, ytit='Beacon ADCS Body Rate',yr=[-1E6,1E6],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
oplot,!x.crange,[0,0],line=2
oplot,hk_jd[wzoom],hk[wzoom].adcs_body_rt1,color=cc[0],psym=4
xx=ymd2jd(2022,3,17.1)
yy = -4E5 & dy = 2E5
xyouts,xx,yy+0*dy,'Rate-1',charsize=cs,color=cc[0]

oplot,hk_jd[wzoom],hk[wzoom].adcs_body_rt2,color=cc[3],psym=5
xyouts,xx,yy+1*dy,'Rate-2',charsize=cs,color=cc[3]

oplot,hk_jd[wzoom],hk[wzoom].adcs_body_rt3,color=cc[5],psym=6
xyouts,xx,yy+3*dy,'Rate-3',charsize=cs,color=cc[5]

oplot, hk_jd, hk.adcs_mode_sun*18E5-9E5, color=cc[1]
xyouts,xx,8E5, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_SUN_VEC 1-3
;
plot,hk_jd,hk.adcs_sun_vec1,/nodata, ytit='Beacon ADCS Sun Vector',yr=[-1.1,1.1],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
oplot,!x.crange,[0,0],line=2
oplot,hk_jd,hk.adcs_sun_vec1,color=cc[0]
xx=ymd2jd(2022,2,3)
yy = -0.8 & dy = 0.2
xyouts,xx,yy+0*dy,'Vect-1',charsize=cs,color=cc[0]

oplot,hk_jd,hk.adcs_sun_vec2,color=cc[3]
xyouts,xx,yy+1*dy,'Vect-2',charsize=cs,color=cc[3]

oplot,hk_jd,hk.adcs_sun_vec3,color=cc[5]
xyouts,xx,yy+2*dy,'Vect-3',charsize=cs,color=cc[5]

oplot, hk_jd, hk.adcs_mode_sun*1.8-0.9, color=cc[1]
xyouts,xx,0.8, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_SUN_VEC 1-3 -  zoom
;
plot,hk_jd[wzoom2],hk[wzoom2].adcs_sun_vec1,/nodata, ytit='Beacon ADCS Sun Vector',yr=[-1.1,1.1],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
oplot,!x.crange,[0,0],line=2
oplot,hk_jd[wzoom],hk[wzoom].adcs_sun_vec1,color=cc[0],psym=4
xx=ymd2jd(2022,3,17.2)
yy = -0.8 & dy = 0.2
xyouts,xx,yy+0*dy,'Vect-1',charsize=cs,color=cc[0]

oplot,hk_jd[wzoom],hk[wzoom].adcs_sun_vec2,color=cc[3],psym=5
xyouts,xx,yy+1*dy,'Vect-2',charsize=cs,color=cc[3]

oplot,hk_jd[wzoom],hk[wzoom].adcs_sun_vec3,color=cc[5],psym=6
xyouts,xx,yy+2*dy,'Vect-3',charsize=cs,color=cc[5]

oplot, hk_jd, hk.adcs_mode_sun*1.8-0.9, color=cc[1]
xyouts,xx,0.8, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_SUN_VEC3 converted to Solar Offset in arc-minutes
;
offset_arc_min = (acos(abs(hk.adcs_sun_vec3)) * 180. / !pi) * 60.
plot,hk_jd,offset_arc_min, /nodata, ytit='Calc. Solar Offset (arc-min)',yr=[0,300.],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
oplot, hk_jd, offset_arc_min, color=cc[5]
xx=ymd2jd(2022,2,3)
yy = 100. & dy = 0.2
xyouts,xx,yy+0*dy,'Offset',charsize=cs,color=cc[5]

oplot, hk_jd, hk.adcs_mode_sun*270+10, color=cc[1]
xyouts,xx,250, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_CURR
;
plot,hk_jd,hk.adcs_curr, ytit='Beacon ADCS Current',yr=[0,1],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
xx=ymd2jd(2022,2,3)
yy = 0.2 & dy = 0.2
xyouts,xx,yy+0*dy,'Current',charsize=cs

oplot, hk_jd, hk.adcs_mode_sun*0.8+0.1, color=cc[1]
xyouts,xx,0.8, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

;
;	Plot ADCS_VOLT
;
plot,hk_jd,hk.adcs_volt, ytit='Beacon ADCS Volts',yr=[11.5,12.5],ys=1, $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
xx=ymd2jd(2022,2,3)
yy = 12.2 & dy = 0.2
xyouts,xx,yy+0*dy,'Volts',charsize=cs

oplot, hk_jd, hk.adcs_mode_sun*0.8+11.6, color=cc[1]
xyouts,xx,12.3, 'Fine-Point', charsize=cs, color=cc[1]

read, 'Next Plot ? ',ans

end


