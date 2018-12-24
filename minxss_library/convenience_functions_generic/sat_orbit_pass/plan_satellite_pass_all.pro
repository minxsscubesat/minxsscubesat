;
; plan_satellite_pass_all.pro
;
; Plan Satellite Pass calculations for all LASP CubeSats
;
; Dec. 2018:  Stations are Boulder, Fairbanks, and Parker
;

pro plan_satellite_pass_all, verbose=verbose

; First call needs to update TLEs and Orbit numbers:  this line updates Orbits if out of sync
; plan_satellite_pass,'Boulder',yd2jd([2018337.D0+(18.+34./60.)/24.,2018347.D0]),/verbose

; First call needs to update TLEs and Orbit numbers
print, 'PROCESSING pass plans for BOULDER...'
plan_satellite_pass,'Boulder', verbose=verbose

; Other calls can skip updating TLEs and Orbit numbers
print, 'PROCESSING pass plans for FAIRBANKS...'
plan_satellite_pass,'Fairbanks',/no_update,/no_orbit, verbose=verbose

print, 'PROCESSING pass plans for PARKER...'
plan_satellite_pass,'Parker',/no_update,/no_orbit, verbose=verbose

return
end

