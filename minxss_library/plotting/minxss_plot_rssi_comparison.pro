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
;   None
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
;   2016-06-04: James Paul Mason: Wrote script.
;   2018-08-20: James Paul Mason: Replaced MinXSS-1 over Japan with MinXSS-2.
;-
PRO minxss_plot_rssi_comparison

; Restore data 
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'
hk1 = hk
restore, getenv('minxss_data') + '/fm2/level0c/minxss2_l0c_all_mission_length.sav'
hk2 = hk
cssweRssiCsv = read_csv('/Users/jmason86/Dropbox/Research/CubeSat/CSSWE Flight Data/CSSWE RSSI Beacon.csv', RECORD_START = 1)
cssweRssi = float(cssweRssiCsv.Field1)

; Change RSSI to negative for MinXSS
minxss1Rssi = -hk1.radio_rssi 
minxss2Rssi = -hk2.radio_rssi

; Filter out bad data
minxss2Rssi = minxss2Rssi[where(minxss2Rssi NE 0)]

; Create histograms
minxss1Hist = histogram(minxss1Rssi, LOCATIONS = minxss1RssiBins)
minxss2Hist = histogram(minxss2Rssi, LOCATIONS = minxss2RssiBins)
cssweHist = histogram(cssweRssi, LOCATIONS = cssweRssiBins)

; Compute medians
minxss1Median = median(minxss1Rssi)
minxss2Median = median(minxss2Rssi)
cssweMedian = median(cssweRssi)

; Create plot
w = window(DIMENSIONS = [1000, 1000]) 
p1 = barplot(minxss1RssiBins, minxss1Hist, /CURRENT, LAYOUT = [1, 3, 1], $
             TITLE = 'MinXSS-1 RF Noise: Median = ' + JPMPrintNumber(minxss1Median, /NO_DECIMAL), $
             XTITLE = 'RSSI [dB]', XRANGE = [-120, -40], $
             YTITLE = '#')
p2 = barplot(minxss2RssiBins, minxss2Hist, /CURRENT, LAYOUT = [1, 3, 2], $
             TITLE = 'MinXSS-2 RF Noise: Median = ' + JPMPrintNumber(minxss2Median, /NO_DECIMAL), $
             XTITLE = 'RSSI [dB]', XRANGE = p1.xrange, $
             YTITLE = '#')
p3 = barplot(cssweRssiBins, cssweHist, /CURRENT, LAYOUT = [1, 3, 3], $
             TITLE = 'CSSWE RF Noise: Median = ' + JPMPrintNumber(cssweMedian, /NO_DECIMAL), $ 
             XTITLE = 'RSSI [dB]', XRANGE = p1.xrange, $
             YTITLE = '#')

p1.save, 'MinXSS RSSI Comparison.png'
STOP

END