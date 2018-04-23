function parse_tle_struct,line1,line2,line0=line0
  n=n_elements(line1)
  if n gt 1 then n=size(line1,/dim)
  result=make_array(n,value={tle_struct})
  if n_elements(line0) eq n then result[*].line0=line0
  result[*].line1=line1
  result[*].line2=line2
  result[*].satnum=long(strtrim(strmid(line1,2,5)))
  result[*].epochyr=fix(strmid(line1,18,2))+1900
  w=where(result[*].epochyr lt 1957,count)
  if count gt 0 then result[w].epochyr+=100
  result[*].epochdays=double(strmid(line1,20,12))
  result[*].ydepoch=double(result[*].epochyr)*1000d +result[*].epochdays
  result[*].jdepoch=yd2jd(result[*].ydepoch)
  result[*].ndot=double(strmid(line1,33,10))
  ndd6=double(strtrim(strmid(line1,44,6)))
  ndd6x=fix(strmid(line1,50,2))
  result[*].nddot=ndd6/1d5*10^ndd6x
  bstar=double(strtrim(strmid(line1,53,6)))
  bstarx=double(strmid(line1,59,2))
  result[*].bstar=bstar/1d5*10^bstarx
  result[*].inclo=double(strtrim(strmid(line2,8,8)))
  result[*].nodeo=double(strtrim(strmid(line2,17,8)))
  result[*].ecco=double(strtrim(strmid(line2,26,7)))/1d7
  result[*].argpo=double(strtrim(strmid(line2,34,8)))
  result[*].mo=double(strtrim(strmid(line2,43,8)))
  result[*].no=double(strtrim(strmid(line2,52,11)))
  n=result[*].no
  n=n*2d*!dpi/86400d; /get rad/second from rev/day
  result[*].ao=(398600.5/n^2)^(1d/3d)
  result[*].revnum=long(strtrim(strmid(line2,63,5)))
  w=where(strlen(line2) gt 70,count)
  if count gt 0 then begin
    result[w].startmfe=double(strtrim(strmid(line2[w],70,12)))
    result[w].stopmfe=double(strtrim(strmid(line2[w],82,12)))
    result[w].deltamin=double(strtrim(strmid(line2[w],94,12)))
  end
  return,result

end