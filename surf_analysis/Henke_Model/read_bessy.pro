;
;	program to read BESSY XP diode calibration files
;	also converts wavelength to nm and sensitivity to electrons/photon
;
function read_bessy, filename, plotIt=plotIt, best=best

if n_params(0) lt 1 then begin
	filename = ' '
	read, 'Enter filename : ', filename
endif

openr,lun,filename,/get_lun
s = ' '
readf,lun,s	; read header line
temp = fltarr(3)
cnt = 0

while ( not (eof(lun)) ) and (cnt lt 56) do begin
	readf,lun,temp
	if cnt eq 0 then data = temp else data = [[data], [temp]]
	cnt = cnt + 1
endwhile

close, lun
free_lun, lun

print, 'Read ',cnt, ' data points from ', filename
print, ' '
print, 'Converting wavelength to nm and sensitivity to electrons/photon...'
print, ' '

if keyword_set(best) then begin
  wgd = where( data[2,*] lt 10. )
  if (wgd[0] ne -1) then begin
    data = data[*,wgd]
    print, 'Data truncated to ', n_elements(wgd), ' points.'
    print, ' '
  endif
endif

data[1,*] = data[1,*] * data[0,*]  	; A/W -> electrons/photon
data[0,*] = 1239.7 / data[0,*]		; eV -> nm

if keyword_set(plotIt) then begin
	!fancy=6
	!xtitle = '!6Wavelength (nm'
	!ytitle ='!6Sens (e!U-!N/ph)'
	!mtitle = filename
	!p.multi=[0,1,2]
	plot,data[0,*],data[1,*],yrange=[0,10]
	!mtitle = ''
	plot_io,data[0,*],data[1,*]
	!p.multi=0
endif

return, data
end
