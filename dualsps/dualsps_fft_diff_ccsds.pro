;
;	dualsps_fft_diff_ccsds
;
;	Compare and subtract off atmospheric seeing effects for GONG TTM tests with open loop and tracking
;
;	INPUTS:
;		pd_track		Tracking data:  plotdata from dualsps_track.pro
;		pd_open			Open Loop data:  plotdata from dualsps_track.pro
;		cutoff			Cutoff high frequency - default is 1 Hz
;
pro dualsps_fft_diff_ccsds, pd_track, pd_open, cutoff=cutoff, debug=debug

if n_params() lt 2 then begin
	print, 'USAGE: dualsps_fft_diff_ccsds, pd_track, pd_open, cutoff=cutoff, /debug'
	print, '    where '
	print, '            pd_track and pd_open are "plotdata" from dualsps_track_ccsds.pro '
	return
endif

if not keyword_set(cutoff) then cutoff = 1.0	; Default cutoff frequency
cutoffstr = 'cutoff=' + string(cutoff,format='(F4.2)') + ' Hz'

;
;	put data onto constant time grid and same length
;
num_open = max(pd_open.time) - min(pd_open.time)
num_track = max(pd_track.time) - min(pd_track.time)
if (num_open gt num_track) then begin
	num_sec = num_open
endif else begin
	num_sec = num_track
endelse
num_sec -= 1.0
num_bins = long(num_sec * 5.)  ; 0.2 sec steps
num_bins2 = num_bins/2L
num_bins = num_bins2 * 2L   ; make even
time_grid = (findgen(num_bins)+1) * 0.2

open_x = interpol( pd_open.control_x, pd_open.time, time_grid+min(pd_open.time) )
open_y = interpol( pd_open.control_y, pd_open.time, time_grid+min(pd_open.time) )

track_x = interpol( pd_track.control_x, pd_track.time, time_grid+min(pd_track.time) )
track_y = interpol( pd_track.control_y, pd_track.time, time_grid+min(pd_track.time) )

;
;	do FFT for each control X & Y
;
open_x_fft = fft( open_x )
open_y_fft = fft( open_y )

track_x_fft = fft( track_x )
track_y_fft = fft( track_y )

ww = indgen(num_bins2-1) + 1	; skip index of 0
ww_neg = num_bins-1 - ww 		; negative frequency side of FFT
fx = ww / (num_bins * 0.2)		; frequency of FFT
px = 1./fx						; period of FFT


;
;	do inverse FFT with cutoff frequency cleared
;
whigh = where( fx lt cutoff )
whigh_neg = num_bins-1 - whigh
wlow = where( fx ge cutoff )
wlow_neg = num_bins-1 - wlow

open_x_fft_low = open_x_fft
open_x_fft_low[wlow] = 0.
open_x_fft_low[wlow_neg] = 0.
open_x_low = abs(fft( open_x_fft_low, /inverse ))

open_x_fft_high = open_x_fft
open_x_fft_high[whigh] = 0.
open_x_fft_high[whigh_neg] = 0.
open_x_high = abs(fft( open_x_fft_high, /inverse ))

print, ' '
print, 'Open Loop Control X Jitter ALL  Frequency (arc-sec) = ', stddev(open_x)
print, 'Open Loop Control X Jitter Low  Frequency (arc-sec) = ', stddev(open_x_low)
print, 'Open Loop Control X Jitter High Frequency (arc-sec) = ', stddev(open_x_high)

track_x_fft_low = track_x_fft
track_x_fft_low[wlow] = 0.
track_x_fft_low[wlow_neg] = 0.
track_x_low = abs(fft( track_x_fft_low, /inverse ))

track_x_fft_high = track_x_fft
track_x_fft_high[whigh] = 0.
track_x_fft_high[whigh_neg] = 0.
track_x_high = abs(fft( track_x_fft_high, /inverse ))

print, ' '
print, 'Tracking Control X Jitter ALL  Frequency (arc-sec) = ', stddev(track_x)
print, 'Tracking Control X Jitter Low  Frequency (arc-sec) = ', stddev(track_x_low)
print, 'Tracking Control X Jitter High Frequency (arc-sec) = ', stddev(track_x_high)

open_y_fft_low = open_y_fft
open_y_fft_low[wlow] = 0.
open_y_fft_low[wlow_neg] = 0.
open_y_low = abs(fft( open_y_fft_low, /inverse ))

open_y_fft_high = open_y_fft
open_y_fft_high[whigh] = 0.
open_y_fft_high[whigh_neg] = 0.
open_y_high = abs(fft( open_y_fft_high, /inverse ))

print, ' '
print, 'Open Loop Control Y Jitter ALL  Frequency (arc-sec) = ', stddev(open_y)
print, 'Open Loop Control Y Jitter Low  Frequency (arc-sec) = ', stddev(open_y_low)
print, 'Open Loop Control Y Jitter High Frequency (arc-sec) = ', stddev(open_y_high)

track_y_fft_low = track_y_fft
track_y_fft_low[wlow] = 0.
track_y_fft_low[wlow_neg] = 0.
track_y_low = abs(fft( track_y_fft_low, /inverse ))

track_y_fft_high = track_y_fft
track_y_fft_high[whigh] = 0.
track_y_fft_high[whigh_neg] = 0.
track_y_high = abs(fft( track_y_fft_high, /inverse ))

print, ' '
print, 'Tracking Control Y Jitter ALL  Frequency (arc-sec) = ', stddev(track_y)
print, 'Tracking Control Y Jitter Low  Frequency (arc-sec) = ', stddev(track_y_low)
print, 'Tracking Control Y Jitter High Frequency (arc-sec) = ', stddev(track_y_high)
print, ' '

setplot
cc =rainbow(7)
cs = 2.0

yrange = [ min(abs(track_x_fft)), max(abs(open_x_fft)) ]

plot, fx, abs(open_x_fft[ww]),/ylog, yrange=yrange, ys=1, $
		xtitle='Frequency (sec!U-1!N)', ytitle='FFT', title='Control X, '+cutoffstr
oplot, fx, abs(track_x_fft[ww]), color=cc[3]
oplot, cutoff*[1,1], 10.^!y.crange, line=2
xx = !x.crange[0]*0.05 + !x.crange[1]*0.95
yy = 10.^!y.crange[1]
my = 5.
yy /= my
xyouts, xx, yy, 'Open Loop', charsize = cs, align=1
xyouts, xx, yy/my, 'Tracking', color=cc[3], charsize=cs, align=1
xyouts, cutoff*1.1, yy, string(stddev(open_x_high),format='(F6.2)')+' asec', charsize = cs
xyouts, cutoff*0.9, yy, string(stddev(open_x_low),format='(F6.2)'), align=1, charsize = cs
xyouts, cutoff*1.1, yy/my, string(stddev(track_x_high),format='(F6.2)')+' asec', color=cc[3], charsize=cs
xyouts, cutoff*0.9, yy/my, string(stddev(track_x_low),format='(F6.2)'), align=1, color=cc[3], charsize=cs

ans = ' '
read, 'Next Plot ? ', ans

yrange = [ min(abs(track_y_fft)), max(abs(open_y_fft)) ]

plot, fx, abs(open_y_fft[ww]),/ylog, yrange=yrange, ys=1, $
		xtitle='Frequency (sec!U-1!N)', ytitle='FFT', title='Control Y, '+cutoffstr
oplot, fx, abs(track_y_fft[ww]), color=cc[3]
oplot, cutoff*[1,1], 10.^!y.crange, line=2
xx = !x.crange[0]*0.05 + !x.crange[1]*0.95
yy = 10.^!y.crange[1]
my = 5.
yy /= my
xyouts, xx, yy, 'Open Loop', charsize = cs, align=1
xyouts, xx, yy/my, 'Tracking', color=cc[3], charsize=cs, align=1
xyouts, cutoff*1.1, yy, string(stddev(open_y_high),format='(F6.2)')+' asec', charsize = cs
xyouts, cutoff*0.9, yy, string(stddev(open_y_low),format='(F6.2)'), align=1, charsize = cs
xyouts, cutoff*1.1, yy/my, string(stddev(track_y_high),format='(F6.2)')+' asec', color=cc[3], charsize=cs
xyouts, cutoff*0.9, yy/my, string(stddev(track_y_low),format='(F6.2)'), align=1, color=cc[3], charsize=cs

read, 'Next Plot ? ', ans

if keyword_set(debug) then begin
	stop, 'DEBUG at end of dualsps_fft_diff_ccsds ...'
endif
end
