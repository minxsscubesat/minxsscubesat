function dotp,a,b
  resolve_grid,a,x=ax,y=ay,z=az,w=aw,v=av,u=au,t=at,s=as
  resolve_grid,b,x=bx,y=by,z=bz,w=bw,v=bv,u=bu,t=bt,s=bs
  acc=ax*bx
  if n_elements(ay) gt 0 and n_elements(by) gt 0 then acc+=ay*by
  if n_elements(az) gt 0 and n_elements(bz) gt 0 then acc+=az*bz
  if n_elements(aw) gt 0 and n_elements(bw) gt 0 then acc+=aw*bw
  if n_elements(av) gt 0 and n_elements(bv) gt 0 then acc+=av*bv
  if n_elements(au) gt 0 and n_elements(bu) gt 0 then acc+=au*bu
  if n_elements(at) gt 0 and n_elements(bt) gt 0 then acc+=at*bt
  if n_elements(as) gt 0 and n_elements(bs) gt 0 then acc+=as*bs
  return,acc
end
