pro test_sgp4,infn,compfn,oufn
  if n_elements(infn) eq 0 then infn='sgp4-ver.tle'
  if n_elements(compfn) eq 0 then compfn='tcppver.out.orig'
  if n_elements(oufn) eq 0 then oufn='idlver.out'

  openr,compf,compfn,/get_lun
  openw,ouf,oufn,/get_lun

  tle=load_tle(infn,/no_filter)
  for i=0,n_elements(tle)-1 do begin
    s=''
    readf,compf,s
    satname=string(format='(%"%d xx")',tle[i].satnum)
    print,satname
    printf,ouf,satname
    n=fix(tle[i].stopmfe-tle[i].startmfe)/tle[i].deltamin+1
    t=dindgen(n)*tle[i].deltamin+tle[i].startmfe
    if abs(t[0]) gt 0.0001 then t=[0d,t]
    if abs(t[n_elements(t)-1]-tle[i].stopmfe) gt 0.0001 then t=[t,tle[i].stopmfe]
    sgp4core_sgp4,tle[i],t,r,v,error=error
    ok=where(error eq 0,count)
    if count gt 0 then begin
      t=t[ok]
      r=r[ok,*]
      v=v[ok,*]
      for j=0,n_elements(t)-1 do begin
        ss=string(format='(%"%17.8f%17.8f%17.8f%17.8f%13.9f%13.9f%13.9f")',t[j],r[j,0],r[j,1],r[j,2],v[j,0],v[j,1],v[j,2])
        readf,compf,s
        printf,ouf,ss
        s=strmid(s,0,strlen(ss))
        if s ne ss then begin
          print,ss+" calc"
          print,s +" file"
        end
      end
    end
  end
  free_lun,compf,ouf
end
