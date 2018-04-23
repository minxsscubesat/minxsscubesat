;+
; NAME:
; rxrs_centerpoint
;
; PURPOSE:
; Identify centerpoint average intensity for scan across FOV
;
; CATEGORY:
; SURF calibration procedure
;
; CALLING SEQUENCE:
; rxrs_centerpoint, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata]
;
; INPUTS:
; channel   Options are  'A1', 'A2', 'B1', 'B2' PLUS added 'X123', 'X123_Fast', 'SPS', 'PS1' - 'PS6'
; filename  Hydra Dump file of Rocket XRS MCU data
; surffile  Optional input to read SURFER log file
; itime   Optional input to specify the integration time: default is 1.0 sec
; /debug    Option to print DEBUG messages
; /rocket   Option to use rocket XRS procedures instead of MinXSS XRS procedures
; /etu    Option to use ETU XRS procedures instead of MinXSS XRS procedures
; /quadx    Option to use Quad X data instead of finding edges
; /quady    Option to use Quad Y data instead of finding edges
; /quad45   Option to use Quad 45 degrees data instead of finding edges
; /fitlimit Option to specify range of fit from Maximum: default is 0.2 to 0.8 of Max
;
; OUTPUTS:
; PLOT    Showing scan data and print to screen of centering results
;       Center results include both edge finding and peak value
;
; data    Hydra Telemetry data
; surfdata  SURFER PC log data
;
; COMMON BLOCKS:
; None
;
; PROCEDURE:
;
; 1.  Check input parameters
; 2.  Plot the data using plotxrs.pro
; 3.  User selects time range of interest
; 4.  Re-plot and display center results (edges and peak)
;
; MODIFICATION HISTORY:
; 2018-03-28: James Paul Mason: Initial script based on Tom's rxrs_center.pro
;+

pro rxrs_centerpoint, channel, filename, surffile, itime=itime, debug=debug, $
  rocket=rocket, etu=etu, fitlimit=fitlimit, $
  data=data, surfdata=surfdata, plotdata=plotdata, $
  quad45=quad45, quadx=quadx, quady=quady
;
; 1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  rxrs_center, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata]'
  return
endif

ch = strupcase(channel)
if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') and $
  (ch ne 'X123') and (ch ne 'X123_FAST') and (ch ne 'SPS') and $
  (ch ne 'PS1') and (ch ne 'PS2') and (ch ne 'PS3') and $
  (ch ne 'PS4') and (ch ne 'PS5') and (ch ne 'PS6') then begin
  print, 'ERROR rxrs_center: Invalid Channel name.  Expected A1, A2, B1, B2, X123, SPS, or PS1-PS6.'
  return
endif

if (n_params() lt 2) then begin
  filename = ''
endif

if (n_params() lt 3) then begin
  doSURF = 0
  surffile=' '
endif else begin
  doSURF = 1
endelse

if keyword_set(itime) then integtime = float(itime) else integtime = 1.0
if (integtime lt 1.0) then integtime = 1.0

if keyword_set(quad45) or keyword_set(quadx) or keyword_set(quady) then doQuad = 1 else doQuad = 0

;
; 2.  Plot the data using:
;     MinXSS-like (2018) files [2018 default]: plot_rxrs_hydra.pro
;     /rocket option for Rocket Hydra files:  plotxrs.pro
;     /etu option for ETU XRS files:  plot_xrs_gse.pro
;
if keyword_set(rocket) then begin
  ; Use ROCKET interface
  if keyword_set(debug) then begin
    if (doSURF ne 0) then begin
      plotxrs, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, /debug
    endif else begin
      plotxrs, ch, filename, itime=integtime, data=data, /debug
    endelse
  endif else begin
    if (doSURF ne 0) then begin
      plotxrs, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata
    endif else begin
      plotxrs, ch, filename, itime=integtime, data=data
    endelse
  endelse
endif else if keyword_set(etu) then begin
  ; Use ETU XRS interface
  if keyword_set(debug) then begin
    if (doSURF ne 0) then begin
      plot_xrs_gse, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, /debug
    endif else begin
      plot_xrs_gse, ch, filename, itime=integtime, data=data, /debug
    endelse
  endif else begin
    if (doSURF ne 0) then begin
      plot_xrs_gse, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata
    endif else begin
      plot_xrs_gse, ch, filename, itime=integtime, data=data
    endelse
  endelse
endif else begin
  ; Use default MinXSS (rocket 2018) XRS interface
  if (doSURF ne 0) then begin
    plot_rxrs_hydra, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, $
      debug=debug, quad45=quad45
  endif else begin
    plot_rxrs_hydra, ch, filename, itime=integtime, data=data, debug=debug, quad45=quad45
  endelse
endelse

;
; 3.  User selects time range of interest
;
tbase = long(data[0].time/1000.) * 1000L
ans = 'Y'
read, 'Do you need to restrict the scan time ? (Y or N) ', ans
ans = strupcase(strmid(ans,0,1))
if (ans eq 'Y') then begin
  ans2=' '
  read, 'Move cursor to LEFT side of the FOV scan and hit RETURN key...', ans2
  cursor, x1, y1, /nowait
  read, 'Move cursor to RIGHT side of the FOV scan and hit RETURN key...', ans2
  cursor, x2, y2, /nowait
  ;  get scan data
  wfov = where( (data.time ge (x1+tbase)) and (data.time le (x2+tbase)), numfov )
  if (numfov lt 2) then begin
    print, 'ERROR rxrs_center: user did not select valid time range'
    return
  endif
  fovdata = data[wfov]
endif else begin
  fovdata = data
endelse

; Compute average (mean and median) of the restricted time range
print, 'Median intensity [intensity / mA] = ' + strtrim(median(fovdata.cnt), 2)
print, 'Mean intensity = [intensity / mA] = ' + strtrim(mean(fovdata.cnt), 2)
print, 'Median intensity [intensity] = ' + strtrim(median(fovdata.rawcnt), 2)
print, 'Mean intensity = [intensity] = ' + strtrim(mean(fovdata.rawcnt), 2)

END