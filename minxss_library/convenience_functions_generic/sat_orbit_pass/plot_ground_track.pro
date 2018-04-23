;
;	plot_orbit for SDO
;
pro plot_orbit,p_,coast_xyz,ap_idx,pe_idx,pts_per_hour,axis

  ;  slash for Mac = '/', PC = '\'
  if !version.os_family eq 'Windows' then slash = '\' else slash = '/'

  p=p_
  resolve_grid,coast_xyz,x=x,y=y,z=z
  scl=([-1,-1,1])[axis]
  xf=([-1,1,1])[axis]
  xi=([1,0,0])[axis]
  yi=([2,2,1])[axis]
  title_l=["towards Sun","from Solar West","from Solar North"]
  axis_l=["x","y","z"]
  pa=p[*,axis]
  px=p[*,xi]
  py=p[*,yi]
  w=where(pa*scl lt 0 and px^2+py^2 lt 6378.140d^2,count)
  if count gt 0 then begin
    pa[w]=!values.d_nan
    px[w]=!values.d_nan
    py[w]=!values.d_nan
  end
  xr=[min(px,/nan,max=xr_max),0]
  xr[1]=xr_max
  if xf lt 0 then xr=reverse(xr)
  plot,px,py,/iso,title=title_l[axis],xtitle=axis_l[xi]+" km",ytitle=axis_l[yi]+" km",background=255,color=0,xrange=xr
  q=dindgen(25)*2*!dpi/24d
  c=cos(q)*6378.140d
  s=sin(q)*6378.140d
  oplot,c,s,color=0
  xt=[0d,-12000d,!values.d_nan]
  yt=[c[0],c[0],!values.d_nan]
  zt=[s[0],s[0],!values.d_nan]
  for i=1,23 do begin
    xt=[xt,0d,-12000d,!values.d_nan]
    yt=[yt,c[i],c[i],!values.d_nan]
    zt=[zt,s[i],s[i],!values.d_nan]
  end
  t=[[xt],[yt],[zt]]
  g=[[x],[y],[z]]*6378.140d
  w=where(g[*,axis]*scl lt 0,count)
  if count gt 0 then g[w,*]=!values.f_nan
  gx=g[*,xi]
  gy=g[*,yi]
  tx=t[*,xi]
  ty=t[*,yi]
  oplot,gx,gy,color=0
  oplot,tx,ty,color=0
  kolor=bytarr(n_elements(px))+254
  ineclipse=where(p[*,0] lt 0 and p[*,1]^2+p[*,2]^2 lt 6378.140d^2,count)
  if count gt 0 then kolor[ineclipse]=0
  if axis eq 0 then if count gt 0 then xyouts,0,-38000,string(format='(%"%d minute eclipse")',count),color=0
  plots,px,py,color=kolor
  mp_idx=n_elements(px)/2
  oplot,[1d,1]*px[mp_idx],[1d,1]*py[mp_idx],psym=2,symsize=3,color=64<kolor[mp_idx]
  oplot,[1d,1]*px[ap_idx],[1d,1]*py[ap_idx],psym=5,symsize=2,color=kolor[ap_idx]
  oplot,[1d,1]*px[pe_idx],[1d,1]*py[pe_idx],psym=8,symsize=2,color=kolor[pe_idx]
  plots,px[0:*:pts_per_hour],py[0:*:pts_per_hour],psym=1,color=kolor[0:*:pts_per_hour]

end

function plot_ground_track,qgci2snr,now=now,tai_sec=tai_sec,tai_subsec=tai_subsec
  if n_elements(qgci2snr) eq 0 then qgci2snr=[0,0,0,1]; Identity quaternion by default

  ;Set up the Z-buffer
  set_plot,'z'
  usersym,[0,1,-1,0],[-1,1,1,-1]
  device,set_resolution=[1024,768]

  ;Load the coastline file if needed
  common coast_common,lat_coast,lon_coast
  if n_elements(lat_coast) eq 0 then begin
    coast_file = getenv('TLE_dir') + slash + 'coast' + slash + 'coast.sav'
    restore, coast_file
    ; restore,getenv('eve_code_l0c')+'/msgp4/coast.sav'
    lat_coast=reform(coast[1,*])
    lon_coast=reform(coast[0,*])
  end

  ;if given a TAI time, figure out the julian date for it
  if n_elements(tai_sec) gt 0 then begin
    tai_in=double(tai_sec)+double(tai_subsec)/2d^32
    tai_to_utc,tai_in, year, doy, sod, month, dd, hh, mm, ss, leap_sec
    now=yd2jd(double(year)*1000d +double(doy)+double(sod)/86400d)
  end

  ;If not given a time, use the current system time
  if n_elements(now) eq 0 then now=systime(/julian,/utc)
  now=now[0]     ;Make sure that now is a scalar

  ;Calculate calendar date from now
  caldat,now,mm,dd,yy,hh,nn,ss
  monthname=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  datestr=string(format='(%"%04d-%s-%02d %02d:%02d:%06.3fUTC")',yy,monthname[mm-1],dd,hh,nn,ss)


  manv=[2455243.61289352d, $ ;ENG BRN 2010/47 Feb 16 02:42:34UTC
        2455245.46435185d, $ ;AMF-1   2010/48 Feb 17 23:08:40UTC
        2455247.46138889d, $ ;AMF-2   2010/50 Feb 19 23:04:24UTC
        2455249.45032407d, $ ;AMF-2B  2010/52 Feb 21 22:48:28UTC
        2455251.53516204d, $ ;AMF-3   2010/55 Feb 24 00:50:38UTC
        2455254.26466435d, $ ;AMF-4   2010/57 Feb 26 18:21:07UTC
        2455256.56388889d, $ ;AMF-5   2010/60 Mar  1 01:32:00UTC
        2455258.51579861d, $ ;AMF-6   2010/62 Mar  3 00:22:45UTC
        2455261.41732639d, $ ;AMF-7   2010/64 Mar  5 22:00:57UTC
        2455264.61165509d, $ ;AMF-8   2010/68 Mar  9 02:40:47UTC
        2455267.52186343d, $ ;TMF-1   2010/71 Mar 12 00:31:29UTC
        2455269.96943287d, $ ;TMF-2   2010/73 Mar 14 11:15:59UTC
        2455272.44239583d]   ;TMF-3   2010/75 Mar 16 22:37:03UTC

  ;Figure out the intervals for calculating the orbit and drawing tick marks
  n_points=1440                      ; Number of points in orbit
  t_range=24d                        ; Number of hours, should be a whole even number
  pts_per_hour=fix(n_points/t_range) ; Number of points per hour, useful for drawing tick marks
  n_points=fix(pts_per_hour*t_range) ; Make sure there are a whole number of points per hour,
                                     ; so that the hour tick marks are exact. This means that
                                     ; the original n_points is only a guideline.
  mp_idx=n_points/2            ; Index of the middle point, which will be the current
                                     ; spacecraft location at the given input time.
  ;Calculate the julian dates
  t=now-(t_range/24d/2d)+dindgen(n_points)/double(n_points)*(t_range/24d)

  ;Calculate rotation of the Earth at each point in time, for longitude
  theta=gmst(t,/julian)

  force_reload=hh eq 6 or hh eq 18
  ;Run MSGP4 to calculate the position and velocity of the spacecraft at each point
  spacecraft_pv,36395,t,pv,status=status, $
                coorid=2,                 $ Return XYZ ECI coordinates
                /epoch,                   $ Run the elements from epoch-to-epoch, rather than
                                          $ using Barry's blending method (not good for a maneuvering
                                          $ spacecraft
                /no_nutation,             $ Leave vectors in TEME coordinates, instead of Mean of Date
                tle_path=getenv('TLE_dir')+slash, $
                force_reload=force_reload,$ Reload the elements fresh every time from the TLE file
                maneuver=manv             ; List of maneuver times

  ;Calculate RA/Dec/Radius (inertial lon/lat/rad) of the state vectors
  rd=pv[0:2,*]*0
  rd[0,*]=atan(pv[1,*],pv[0,*])*!radeg ;RA in degrees
  rd[0,*]=mlmod(rd[0,*]-theta,360d)    ;Convert RA to longitude and
  w=where(rd[0,*] gt 180d,count)       ;  force to between -180deg
  if count gt 0 then rd[0,w]-=360d     ;  and +180deg
  rho=sqrt(pv[0,*]^2+pv[1,*]^2)
  rd[1,*]=atan(pv[2,*],rho)*!radeg     ;Dec in degrees
  rd[2,*]=sqrt(rho^2+pv[2,*]^2)        ;Radius in km

  ;Find the index of the orbit apogee and perigee
  ap=max(rd[2,*],ap_idx,min=pe,subscript_min=pe_idx)
  !p.multi=[0,2,2]
  ;Draw the coastline on a 2D map
  plot,lon_coast,lat_coast,xrange=[-180,180],/xs,yrange=[-90,90],/ys,background=255,color=0
  xyouts,-175,-85,datestr,charsize=1,color=0
  xyouts,175,-85,string(format='(%"Alt: %8.1f km")',rd[2,mp_idx]-6378.140),charsize=1,align=1,color=0
  xyouts,175,-75,string(format='(%"Perigee: %8.1f km")',rd[2,pe_idx]-6378.137),charsize=1,align=1,color=0
  xyouts,175,-65,string(format='(%"Apogee: %8.1f km")',rd[2,ap_idx]-6378.137),charsize=1,align=1,color=0

  ;Delete the segment(s) which spans across 180deg longitude, if any
  w=where(abs(rd[0,*]) gt 90 and abs(shift(rd[0,*],1)) gt 90 and rd[0,*]*shift(rd[0,*],1) lt 0,count)
  if count gt 0 then rd[*,w]=!values.f_nan

  ;Draw the ground track
  oplot,rd[0,*],rd[1,*],color=254
  oplot,[1d,1]*rd[0,mp_idx],[1d,1]*rd[1,mp_idx],psym=2,symsize=3,color=64
  oplot,rd[0,0:*:pts_per_hour],rd[1,0:*:pts_per_hour],psym=1,color=254
  oplot,[1d,1]*rd[0,ap_idx],[1d,1]*rd[1,ap_idx],psym=5,symsize=2,color=254
  oplot,[1d,1]*rd[0,pe_idx],[1d,1]*rd[1,pe_idx],psym=8,symsize=2,color=254

  ;Calculate the 3D coastline points
  x_coast=cos(lat_coast*!dtor)*cos((lon_coast+theta[mp_idx])*!dtor)
  y_coast=cos(lat_coast*!dtor)*sin((lon_coast+theta[mp_idx])*!dtor)
  z_coast=sin(lat_coast*!dtor)

  ;Transform it to SNR space
  coast_xyz=quat_trans(qgci2snr,compose_grid(x_coast,y_coast,z_coast))
  p=quat_trans(qgci2snr,(transpose(pv))[*,0:2])

  ;Draw the three views of 3D space
  plot_orbit,p,coast_xyz,ap_idx,pe_idx,pts_per_hour,0
  plot_orbit,p,coast_xyz,ap_idx,pe_idx,pts_per_hour,1
  plot_orbit,p,coast_xyz,ap_idx,pe_idx,pts_per_hour,2

  img=tvrd()
  loadct,39,/silent
  tvlct,/get,r,g,b
  img=resize_img(temporary(img),r,g,b,[1280,960])

  img=transpose(rebin(img,640,480,3),[2,0,1])
  !p.multi=0
  return,img
end
