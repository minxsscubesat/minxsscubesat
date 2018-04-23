function check_checksum,line,bt=bt
  b1=byte(line)
  c1=b1[68,*]
  b1=b1[0:67,*]
  w=where(b1 eq 45,count) ;find minus signs...
  if count gt 0 then b1[w]=49  ;change them to digit 1
  w=where(logical_or(b1 lt 48,b1 gt 57),count) ;find non-digits...
  if count gt 0 then b1[w]=48  ;change them to digit 0
  b1-=48 ;change from ascii digits to actual numbers
  c1-=48 ;likewise on checksum
  bt=total(b1,1) mod 10
  return,bt eq c1
end
