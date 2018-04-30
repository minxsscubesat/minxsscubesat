pro kill
   compile_opt idl2
   
   w = getwindows()
   if n_elements(w) gt 0 then foreach i, w do i.close
end