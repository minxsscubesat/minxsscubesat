pro rotate_earth
  restore,'coast.sav'
  lat=coast[1,*]*!dtor
  lon=coast[0,*]*!dtor
  now=systime(/julian,/utc)
  t=now-0.5+dindgen(500)/500d
  theta=gmst(t,/julian)*!dtor
  for i=0,n_elements(t)-1 do begin
    x=cos(lat)*cos(lon+theta[i])
    y=cos(lat)*sin(lon+theta[i])
    z=sin(lat)
    w=where(z lt 0,count)
    if count gt 0 then begin
      x[w]=!values.f_nan      
      y[w]=!values.f_nan
      z[w]=!values.f_nan
    end
    plot,x,y,/iso
    wait,0.1
  end
end
