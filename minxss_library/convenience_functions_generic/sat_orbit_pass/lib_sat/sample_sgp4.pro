pro sample_sgp4, time, rd, sunlight
  path_name = ['','']
  ;Change this for other computers (direct it to the google drive)
  ;This must be changed here AND below in the event procedure AND Sample_sgp4.pro AND TLE_data.pro
  ;path_name[0] = 'C:\Users\Christina\Google Drive\'
  path_name[0] = 'C:\Users\rocket\Google Drive\CubeSat\'
  
  
  ;t = systime(/utc,/jul) ; julian date for the current time
  t = time
  satid=25544 ;sat id for ISS
  theta=gmst(t,/julian)

  ;Run MSGP4 to calculate the position and velocity of the spacecraft at each point
  path_name[1] = 'MinXSS Server\8000 Ground Software\8030 MinXSS_Data_Vis_Software\sgp4'
  spacecraft_pv,satid,t,pv,tle_path = strjoin(path_name)
  
  ;pv is state vector. pv[0:2] is position vector in Earth-centered Inertial, in km. pv[3:5] is velocity in same frame in km/s

  ;Calculate RA/Dec/Radius (inertial lon/lat/rad) of the state vectors
  rd=pv[0:2]*0 
  rd[0]=atan(pv[1],pv[0])*!radeg ;RA in degrees
  rd[0]=mlmod(rd[0]-theta,360d)    ;Convert RA to longitude and
  w=where(rd[0] gt 180d,count)       ;  force to between -180deg
  if count gt 0 then rd[0,w]-=360d     ;  and +180deg
  rho=sqrt(pv[0]^2+pv[1]^2)
  rd[1]=atan(pv[2],rho)*!radeg     ;Dec in degrees
  rd[2]=sqrt(rho^2+pv[2]^2)        ;Radius in km
  
  
;  Print, 'longitude', rd[0]   ;rd[0] is longitude of subspacecraft point
;  print, 'latitude', rd[1]   ;rd[1] is latitude
;  print, 'distance', rd[2]   ;rd[2] is distance from center of Earth to spacecraft
 
  
  sun=sunvec(jd=t) ;unit vector from center of Earth to sun in Earth-centered Inertial
  r=pv[0:2]
  
  comp_r_sun=dotp(sun,r) ;component of spacecraft position in direction of sun
  if comp_r_sun gt 0 then begin
   ; print, "in sunlight"
    sunlight = 1
  end else begin
    proj_r_sun=sun*comp_r_sun
    perp_r_sun=r-proj_r_sun
    r_e=6378.137 ; equatorial radius of Earth in km
    if sqrt(total(perp_r_sun^2)) lt r_e then begin
    ;  print,"in shadow"
      sunlight = 0
    end else begin
     ; print,"in sunlight"
      sunlight = 1
    end 
  end 
end  