;+
; NAME:
;   minxss_plot_sd_offsets
;
; PURPOSE:
;   Make plots to help figure out what happened to the SD offsets for MinXSS-2. Was there an SD card anomaly?
;
; INPUTS:
;   None, but calls MinXSS l0c mission length saveset
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Various plots
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS-2 l0c mission length data
;
; EXAMPLE:
;   Just run it!
;-
PRO minxss_plot_sd_offsets, fm=fm

; Defaults
IF fm EQ !NULL THEN fm = 2
fontSize = 16

restore, getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level0c/minxss' + strtrim(fm, 2) + '_l0c_all_mission_length.sav'

; Get rid of flatsat data
hk = hk[where(hk.time_jd LT jpmiso2jd('2019-01-08T00:00:00Z'))]

; Make stack plot
w = window(DIMENSION = [1000, 1400], FONT_SIZE = fontSize)
p1 = plot(hk.time_jd, hk.sd_hk_write_offset, THICK = 2, LAYOUT = [1, 3, 1], /CURRENT, $
          TITLE = 'MinXSS-2 SD Card Anomaly?', $
          XTICKUNITS = ['Day', 'Month', 'Year'], $
          YTITLE = 'HK Write Offset', $
          FONT_SIZE = fontSize)
p2 = plot(hk.time_jd, hk.sd_adcs_write_offset, THICK = 2, LAYOUT = [1, 3, 2], /CURRENT, $
          XTICKUNITS = ['Day', 'Month', 'Year'], $
          YTITLE = 'ADCS Write Offset', $
          FONT_SIZE = fontSize)
p3 = plot(hk.time_jd, hk.sd_sci_write_offset, THICK = 2, LAYOUT = [1, 3, 3], /CURRENT, $
          XTICKUNITS = ['Day', 'Month', 'Year'], $
          YTITLE = 'Science Write Offset', $
          FONT_SIZE = fontSize)
STOP
END