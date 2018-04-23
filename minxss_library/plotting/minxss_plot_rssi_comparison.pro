;+
; NAME:
;   minxss_plot_rssi_comparison
;
; PURPOSE:
;   Compare RSSI histograms between MinXSS and CSSWE
;
; INPUTS:
;   No variable inputs, but restores data from the disk. There inherent assumptoin is that those data are available on
;   the local hard disk. 
;
; OPTIONAL INPUTS:
;   fm [integer]: Set to 1 or 2 depending on MinXSS flight model. Defaults to 1. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plot of histgograms saved to disk in current directory
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS software package
;
; EXAMPLE:
;
;
; MODIFICATION HISTORY:
;   2016/06/04: James Paul Mason: Wrote script.
;-
PRO minxss_plot_rssi_comparison, fm = fm

; Defaults
IF ~keyword_set(fm) THEN fm = 1

; Restore data 
restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0c/minxss1_l0c_all_mission_length.sav'
cssweRssiCsv = read_csv('/Users/' + getenv('username') + '/Dropbox/CubeSat/csswe flight data/CSSWE RSSI Beacon.csv', RECORD_START = 1)
cssweRssi = float(cssweRssiCsv.Field1)

; Generate Japanese-only beacon data
japaneseFiles = file_search('/Users/' + getenv('username') + '/Dropbox/isis_rundirs/', '*ja0caw*')
hkJapan = !NULL
FOR fileLoop = 0, n_elements(japaneseFiles) - 1 DO BEGIN
  minxss_read_packets, japaneseFiles[fileLoop], hk = hkTemp, /VERBOSE
  hkJapan = [hkJapan, hkTemp]
ENDFOR

; Change RSSI to negative for MinXSS
minxssRssi = -hk.radio_rssi 
japanRssi = -hkJapan.radio_rssi

; Create histograms
minxssHist = histogram(minxssRssi, LOCATIONS = minxssRssiBins)
japanHist = histogram(japanRssi, LOCATIONS = japanRssiBins)
cssweHist = histogram(cssweRssi, LOCATIONS = cssweRssiBins)

; Compute medians
minxssMedian = median(minxssRssi)
japanMedian = median(japanRssi)
cssweMedian = median(cssweRssi)

; Create plot
w = window(DIMENSIONS = [1000, 1000]) 
p1 = barplot(minxssRssiBins, minxssHist, /CURRENT, LAYOUT = [1, 3, 1], $
             TITLE = 'MinXSS RF Noise - All: Median = ' + JPMPrintNumber(minxssMedian, /NO_DECIMAL), $
             XTITLE = 'RSSI [dB]', XRANGE = [-120, -40], $
             YTITLE = '#')
p2 = barplot(japanRssiBins, japanHist, /CURRENT, LAYOUT = [1, 3, 2], $
             TITLE = 'MinXSS RF Noise - Japan: Median = ' + JPMPrintNumber(japanMedian, /NO_DECIMAL), $
             XTITLE = 'RSSI [dB]', XRANGE = [-120, -40], $
             YTITLE = '#')
p3 = barplot(cssweRssiBins, cssweHist, /CURRENT, LAYOUT = [1, 3, 3], $
             TITLE = 'CSSWE RF Noise: Median = ' + JPMPrintNumber(cssweMedian, /NO_DECIMAL), $ 
             XTITLE = 'RSSI [dB]', XRANGE = [-120, -40], $
             YTITLE = '#')

p1.save, 'MinXSS RSSI Comparison.png'
STOP


END