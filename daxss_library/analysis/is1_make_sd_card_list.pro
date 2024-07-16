;
;	is1_make_sd_card_list.pro
;
;	Make a list of SD Card usage a function of time
;
;	Usage:  is1_make_sd_card_list
;
;	History:
;	2/6/2023	T. Woods  Original code
;
pro is1_make_sd_card_list, file_out=file_out, version=version, debug=debug

; configure version
if not keyword_set(version) then version = '2.0.0'
version_str = string(version)

;read DAXSS Level 0C file to get beacon (HK) packets
dir0c = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'level0c' + path_sep()
file0c = 'daxss_l0c_all_mission_length_v' + version_str + '.sav'
print, '***** Reading '+dir0c+file0c
restore, dir0c + file0c

; prepare output file
if not keyword_set(file_out) then begin
	sd_dir = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'sd_card' + path_sep()
	sd_file = 'is1_sd_card_list_v' + version_str + '.txt'
	file_out = sd_dir + sd_file
endif

;  find SD-card boundaries for DAXSS packets (SCID):  hk.SD_WRITE_SCID
SCID_BAD = 0UL
SCID_0_LOWER = ulong(1.)
SCID_0_UPPER = ulong(3000.)
SCID_ODD_LOWER = ulong(3000.)
SCID_ODD_UPPER = ulong(5E5)
SCID_1_LOWER = ulong(5E5)
SCID_1_UPPER = ulong(9.2E6)
SCID_2_LOWER = ulong(9.2E6)
SCID_2_UPPER = ulong(2.5E7)

wgood = where( (hk.SD_WRITE_SCID gt SCID_BAD), num_good )
hk_jd = hk[wgood].time_jd
hk_time = jd2yd(hk_jd)
hk_scid = hk[wgood].SD_WRITE_SCID

hk_sd_type = intarr(num_good)
wsd0 = where( (hk_scid ge SCID_0_LOWER) AND (hk_scid lt SCID_0_UPPER) )
hk_sd_type[wsd0] = 0
wsd1 = where( (hk_scid ge SCID_1_LOWER) AND (hk_scid lt SCID_1_UPPER) )
hk_sd_type[wsd1] = 1
wsd2 = where( (hk_scid ge SCID_2_LOWER) ) ; AND (hk_scid lt SCID_2_UPPER) )
hk_sd_type[wsd2] = 2
wsd = where( (hk_scid ge SCID_ODD_LOWER) AND (hk_scid lt SCID_ODD_UPPER) )
hk_sd_type[wsd] = -1   ; -1 means bad data set or unknown SD-card

diff = hk_sd_type - shift(hk_sd_type,1)
wshift = where(diff ne 0, num_shift)
if wshift[0] ne 0 then begin
	wshift = [0, wshift]
	num_shift += 1L
endif
aList = { time_yd: 0.0D0, sd_card_number: 0 }
theList = replicate( aList, num_shift )
theList.time_yd = hk_time[wshift]
theList.sd_card_number = hk_sd_type[wshift]
print, '***** SD-Card for SCID packets changed ', num_shift, ' times.'
for i=0,num_shift-1 do print, i, theList[i].sd_card_number, theList[i].time_yd
print, ' '

; plot SD-card changes
setplot & cc=rainbow(7) & cs=2.0
plot, hk_jd, hk_scid, psym=-4, yr=[0,max(hk_scid)*1.1], ys=1, ytitle='SD_WRITE_SCID', $
	XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
dy = (!y.crange[1]-!y.crange[0])/12.
yy = !y.crange[1] - 3*dy
for i=0,num_shift-1 do begin
	theJD = yd2jd(theList[i].time_yd)
	oplot, theJD*[1.,1], !y.crange, line=2, color=cc[0]
	xyouts, theJD, yy+dy*theList[i].sd_card_number, strtrim(theList[i].sd_card_number,2), $
				charsize=cs, color=cc[0]
endfor

;  find SD-card boundaries for Beacon packets (HK)
; hk. SD_WRITE_BEACON
;  merge results into single List

;  save List
print, '***** Writing SD-Card List to '+file_out
openw, lun, file_out, /get_lun
printf,lun, '; Time_YYYYYDOY SD_Number : created '+systime()
format = '(F18.6,I8)'
for i=0,num_shift-1 do printf,lun, theList[i].time_yd, theList[i].sd_card_number, format=format
printf,lun, ' '
close, lun
free_lun, lun

if keyword_set(debug) then stop, 'DEBUG at end of is1_make_sd_card_list.pro ...'
return
end
