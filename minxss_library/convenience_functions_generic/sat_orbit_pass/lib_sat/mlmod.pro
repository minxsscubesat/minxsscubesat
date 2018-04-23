;Calculates the mod function as done in matlab. This will
;always return a positive number between 0 and y.
function mlmod,x,y
  return,x - floor(float(x)/float(y))*y
end
