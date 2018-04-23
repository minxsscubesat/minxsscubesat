;
;	sp_normalize
;
;	Normalize spectrum to common resolution and to total signal
;
function sp_normalize, win, spin, wout, normalize=normalize

spout = interpol( spin, win, wout )
wbad = where( wout lt min(win) )
if wbad[0] ne -1 then spout[wbad] = 0.0
wbad = where( wout gt max(win) )
if wbad[0] ne -1 then spout[wbad] = 0.0

if keyword_set(normalize) then spout = spout / total(spout)

return, spout
end
