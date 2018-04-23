;Linear array covering a range of values
;input
;  a - minimum value of the range
;  b - maximum value of the range
;  n - number of elements in the range
;  delta= - if set, n is ignored and this value is used as an
;           element spacing. n is then set to the appropriate value
;  /inc - "inclusive". When not set, the resulting array runs
;         from a to 'almost' b. There are n elements in the array,
;         but continuing the pattern, the n+1 element would have
;         the value b
;return
;  a 1D array of doubles, length n, with the appropriate values
;
;examples
;IDL> print,range(0,1,10)
;   0.0    0.1    0.2    0.3    0.4    0.5    0.6    0.7    0.8    0.9
;IDL> print,range(0,1,delta=0.1)
;   0.0    0.1    0.2    0.3    0.4    0.5    0.6    0.7    0.8    0.9
;Note that the values go from 0 to almost 1, but go up in steps of 0.1
;IDL> print,range(0,1,10,/inc)
;   0.0    0.1111    0.2222    0.3333    0.4444    0.5556    0.6667    0.7778    0.8889    1.0
;The values go from 0 to 1, but go up in steps of 0.111, 1/9, not 1/10
;IDL> print,range(0,1,11,/inc)
;   0.0    0.1    0.2    0.3    0.4    0.5    0.6    0.7    0.8    0.9   1.0
;IDL> print,range(0,1,delta=0.1,/inc)
;   0.0    0.1    0.2    0.3    0.4    0.5    0.6    0.7    0.8    0.9   1.0
;This one goes from 0 to 1, in steps of 1/10, but has 11 elements
function range,a,b,n,delta=delta,inc=inc
  if keyword_set(delta) then begin
    n=fix((double(b)-double(a))/double(delta))+1
    if keyword_set(inc) then n++
  end
  return,dindgen(n)*(double(b)-double(a))/double(n-keyword_set(inc))+double(a)
end

