pro check_ortho,nu
  print,"Row 0 length error",sqrt(total(nu[0,*]^2))-1d
  print,"Row 1 length error",sqrt(total(nu[1,*]^2))-1d
  print,"Row 2 length error",sqrt(total(nu[2,*]^2))-1d
  print,"Col 0 length error",sqrt(total(nu[*,0]^2))-1d
  print,"Col 1 length error",sqrt(total(nu[*,1]^2))-1d
  print,"Col 2 length error",sqrt(total(nu[*,2]^2))-1d
  print,"row0.row1 error",total(nu[0,*]*nu[1,*])
  print,"row0.row2 error",total(nu[0,*]*nu[2,*])
  print,"row1.row2 error",total(nu[1,*]*nu[2,*])
  print,"col0.col1 error",total(nu[*,0]*nu[*,1])
  print,"col0.col2 error",total(nu[*,0]*nu[*,2])
  print,"col1.col2 error",total(nu[*,1]*nu[*,2])
end
