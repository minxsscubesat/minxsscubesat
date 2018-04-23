;+
; NAME:
;   minxss_plot_thermal_orbit_predicts_grouped
;
; PURPOSE:
;   Dissertation plot.
;   Create plot showing the model predictions for a single orbit scenario. 
;
; INPUTS:
;   orbitName [string]: Which orbit to plot. Options are: 
;                       'Iss' -- puts cold on left and hot on right
;                       'SunSync' -- no hot or cold cases since beta doesn't change
;                       Option must be specified as above. 
;
; OPTIONAL INPUTS:
;   dataPathModel [string]: The path to the model data. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Rev8/'
;                           since James is the only one likely to use this code.
;   plotPath [string]:      The path you want the plots saved to. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Rev8/'
;                           since James is the only one likely to use this code.                     
;   
; KEYWORD PARAMETERS:
;   WORST_HOT:        Set this to use end-of-life optical properties in the hot case
;   OVERPLOT_ACTUALS: Set this to include overplots of actual on-orbit temperature measurements. Will change the time range of the plots and uses time periods
;                     identified by Chloe Downs during her summer REU. 
;
; OUTPUTS:
;   Plot as described in purpose in the plotPath as well as dissertation directory for James
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss code package
;
; EXAMPLE:
;   None
;
; MODIFICATION HISTORY:
;   2016-04-05: James Paul Mason: Wrote script.
;   2016-11-27: James Paul Mason: Added OVERPLOT_ACTUALS keyword 
;   2017-03-14: James Paul Mason: Fixed typo of overplotting actual battery temperature rather than actual CDH temperature
;-
PRO minxss_plot_thermal_orbit_predicts_grouped, orbitName = orbitName, $
                                                dataPathModel = dataPathModel, plotPath = plotPath, $
                                                WORST_HOT = WORST_HOT, OVERPLOT_ACTUALS = OVERPLOT_ACTUALS

; Defaults
IF ~keyword_set(dataPathModel) THEN datalocModel = '/Users/' + getenv('username') + '/Dropbox/Research/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Rev8/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/' + getenv('username') + '/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Rev8/' ELSE saveloc = temporary(plotPath)
savelocDissertation = '/Users/' + getenv('username') + '/Dropbox/Research/Woods_LASP/Papers/20160501 Dissertation/PhD_Dissertation/LaTeX/Images/'
savelocPaper = '/Users/' + getenv('username') + '/Dropbox/Research/Postdoc_LASP/Papers/20170430 CubeSat Thermal/Figures/'

orbitName = 'Iss'
IF orbitName EQ 'Iss' THEN dataFilename = 'ISS ' ELSE $
IF orbitName EQ 'SunSync' THEN dataFilename = 'Sun Sync ' ELSE $
message, /INFO, 'You did not use a propper input orbitName.'

; Update the model files -- convert the TD output txt to IDL saveset
minxss_plot_thermal_orbit_convert_model_txt_to_sav

; Setup
fontSize = 26
margin = 0.15
color1a = 'red'
color1b = 'firebrick'
color2a = 'saddle brown'
color2b = 'brown'
color3a = 'blue'
color3b = 'dark blue'
color4a = 'orange'
color4b = 'orange red'
color5a = 'forest green'
color5b = 'dark green'
color6a = 'yellow green'
color6b = 'green'
color7a = 'lime green'
color7b = 'sea green'
color8a = 'dark sea green'
color8b = 'olive drab'
color9a = 'purple'
color9b = 'indigo'
color10a = 'cornflower'
color10b = 'navy'
color11a = 'dark orange'
color11b = 'goldenrod'

; Restore data
restore, datalocModel + dataFilename + 'Cold Model Predicts.sav'

;
; Crap ton of plots
;

; Page 1 of plots - spacecraft TCs
coldOrHot = 'Cold' ; Do cold case plot first
coldDone = 0
layoutColumn = 1
xrange = [0, 24]
IF keyword_set(OVERPLOT_ACTUALS) THEN BEGIN
  xrange = [0, 3]
ENDIF

w = window(DIMENSIONS = [1836., 2376.], /BUFFER) ; Corresponds to 8.5" x 11" * 4 with resolution of 72 dpi (can't change res)
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'

  leftTitle = text(0.25, 1, 'Cold Case', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  rightTitle = text(0.75, 1, 'Hot Case', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  xTitle = text(0, 0.5, 'Temperature [ºC]', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize, ORIENTATION = 90)

  ; -X Middle TC
  p1 = plot(timeModelHours, tcMinusXMiddleModel, '4--', COLOR = color1b, FONT_SIZE = fontSize, /CURRENT, LAYOUT = [2, 4, layoutColumn], MARGIN = margin, $
            TITLE = '-X Middle TC', $
            XRANGE = xrange)

  ; +Y Top TC
  p1 = plot(timeModelHours, tcMinusYBottomModel, COLOR = color2b, '4--', /CURRENT, LAYOUT = [2, 4, layoutColumn + 2], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = '-Y Bottom TC', $
            XRANGE = xrange)

  ; +X Bottom TC
  p1 = plot(timeModelHours, tcPlusXBottomModel, COLOR = color3b, '4--', /CURRENT, LAYOUT = [2, 4, layoutColumn + 4], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = '+X Bottom TC', $
            XRANGE = xrange)
  
  ; -Z TC
  p1 = plot(timeModelHours, tcMinusZModel, COLOR = color4b, '4--', /CURRENT, LAYOUT = [2, 4, layoutColumn + 6], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = '-Z TC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange)
  
  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    layoutColumn = 2

    ; Read the hot case data
    IF keyword_set(WORST_HOT) THEN restore, datalocModel + dataFilename + 'Hot Worst Case Model Predicts.sav' ELSE $
                                   restore, datalocModel + dataFilename + 'Hot Model Predicts.sav'

  ENDIF
ENDWHILE ; First page of plots
IF keyword_set(WORST_HOT) THEN BEGIN
  p1.save, saveloc + 'ISS Orbit WorstCase External TCs.png'
  p1.save, savelocDissertation + 'IssOrbitWorstCaseExternalTcs.png'
ENDIF ELSE BEGIN
  p1.save, saveloc + 'ISS Orbit External TCs.png'
  p1.save, savelocDissertation + 'IssOrbitExternalTcs.png'
ENDELSE

; Read the cold case model data
restore, datalocModel + dataFilename + 'Cold Model Predicts.sav'

; Page 2 of plots - passive boards
coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
layoutColumn = 1
xrange = [0, 24]

w = window(DIMENSIONS = [1836., 2376.], /BUFFER) ; Corresponds to 8.5" x 11" * 4 with resolution of 72 dpi (can't change res)
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'

  leftTitle = text(0.25, 1, 'Cold Case', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  rightTitle = text(0.75, 1, 'Hot Case', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  xTitle = text(0, 0.5, 'Temperature [ºC]', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize, ORIENTATION = 90)
  
  ; Motherboard
  p1 = plot(timeModelHours, tlmMotherboardModel, '4--', COLOR = color5b, FONT_SIZE = fontSize, /CURRENT, LAYOUT = [2, 4, layoutColumn], MARGIN = margin, $
            TITLE = 'Motherboard', $
            XRANGE = xrange, $ 
            NAME = 'Model')
  
  ; CDH
  p2 = plot(timeModelHours, tlmCdhModel, COLOR = color6b, '4--', /CURRENT, LAYOUT = [2, 4, layoutColumn + 2], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = 'CDH Board', $
            XRANGE = xrange)
  
  ; +X Solar Array
  p3 = plot(timeModelHours, tlmSaPlusXModel, COLOR = color7b, '4--', /CURRENT, LAYOUT = [2, 4, layoutColumn + 4], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = '+X Solar Array', $
            XRANGE = xrange)
  
  ; X123 electronics
  p4 = plot(timeModelHours, tlmX123BoardModel, COLOR = color8b, '4--', /CURRENT, LAYOUT = [2, 4, layoutColumn + 6], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = 'X123 Electronics', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange)

  ;
  ; Optionally overplot the actual on-orbit measurements
  ;

  IF keyword_set(OVERPLOT_ACTUALS) THEN BEGIN

    ; Restore MinXSS-1 data
    restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

    ; Restrict data to time ranges for cold and hot cases as determined by Chloe Downs during summer REU
    ; Cold time range: [2016-06-15 10:57:03, 2016-06-15 14:00:16], which had a beta of 1º
    ; Hot time range: [2016-05-28 23:30:00, 2016-05-29 02:30:00], which had a beta of 73º
    IF coldOrHot EQ 'Cold' THEN BEGIN
      hk = hk[where(hk.time_jd GE JPMiso2jd('2016-06-15T10:57:03Z') AND hk.time_jd LE JPMiso2jd('2016-06-15T14:00:16Z'))]
    ENDIF ELSE BEGIN
      hk = hk[where(hk.time_jd GE JPMiso2jd('2016-05-28T23:30:00Z') AND hk.time_jd LE JPMiso2jd('2016-05-29T02:30:00Z'))]
    ENDELSE

    ; Convert orbit time to hours since window start
    timeActualHours = (hk.time_jd - hk[0].time_jd) * 24.

    ; Shift model values to be in sync with actuals (as best as possible, anyway)
    shiftValue = -12

    ; Compute Motherboard means
    windowModelIndices = where(timeModelHours GE 0 AND timeModelHours LE 3)
    tlmMotherboardModelShifted = shift(tlmMotherboardModel, shiftValue)
    meanTlmMotherboardModel = mean(tlmMotherboardModelShifted[windowModelIndices])
    meanMotherboardActual = mean(hk.mb_temp2)

    ; Compute CDH means
    tlmCdhModelShifted = shift(tlmCdhModel, shiftValue)
    meanTlmCdhModel = mean(tlmCdhModelShifted[windowModelIndices])
    meanCdhActual = mean(hk.cdh_temp)

    ; Compute +X SA means
    tlmSaPlusXModelShifted = shift(tlmSaPlusXModel, shiftValue)
    meanTlmSaPlusXModel = mean(tlmSaPlusXModelShifted[windowModelIndices])
    meanSaPlusXActual = mean(hk.eps_sa2_temp)

    ; Compute X123 Electronics means
    tlmX123BoardModelShifted = shift(tlmX123BoardModel, shiftValue)
    meanTlmX123BoardModel = mean(tlmX123BoardModelShifted[windowModelIndices])
    meanX123BoardActual = mean(hk.x123_brd_temp)

    ; Motherboard overplot
    IF coldOrHot EQ 'Cold' THEN BEGIN
      t1aPosition = [0.25, 24]
      t1Position = [0.25, 18]
    ENDIF ELSE BEGIN
      t1aPosition = [0.25, 32]
      t1Position = [0.25, 29]
    ENDELSE
    p1a = plot(timeActualHours, hk.mb_temp2, '4', COLOR = color5a, OVERPLOT = p1, $
               NAME = 'Measurement')
    p1.SetData, timeModelHours, shift(tlmMotherboardModel, -12)
    p1.xrange = [0, 3]
    p1.title = 'Motherboard: $\Delta$Mean = ' + JPMPrintNumber(abs(meanMotherboardActual - meanTlmMotherboardModel)) + ' ºC'
    t1a = text(t1aPosition[0], t1aPosition[1], 'Mean = ' + JPMPrintNumber(meanMotherboardActual) + ' ºC', COLOR = color5a, TARGET = p1, /DATA, FONT_SIZE = fontSize - 2)
    t1 = text(t1Position[0], t1Position[1], 'Mean = ' + JPMPrintNumber(meanTlmMotherboardModel) + ' ºC', COLOR = color5b, TARGET = p1, /DATA, FONT_SIZE = fontSize - 2)
    l1 = legend(TARGET = [p1, p1a], POSITION = [0.55, 0.55], FONT_SIZE = fontSize)
    
    ; CDH overplot
    IF coldOrHot EQ 'Cold' THEN BEGIN
      t2aPosition = [0.25, 24]
      t2Position = [0.25, 19]
    ENDIF ELSE BEGIN
      t2aPosition = [0.25, 40]
      t2Position = [0.25, 35]
    ENDELSE
    p2a = plot(timeActualHours, hk.cdh_temp, '4', COLOR = color6a,  OVERPLOT = p2)
    p2.SetData, timeModelHours, shift(tlmCdhModel, -12)
    p2.xrange = [0, 3]
    p2.title = 'CDH Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanCdhActual - meanTlmCdhModel)) + ' ºC'
    t2a = text(t2aPosition[0], t2aPosition[1], 'Mean = ' + JPMPrintNumber(meanCdhActual) + ' ºC', COLOR = color6a, TARGET = p2, /DATA, FONT_SIZE = fontSize - 2)
    t2 = text(t2Position[0], t2Position[1], 'Mean = ' + JPMPrintNumber(meanTlmCdhModel) + ' ºC', COLOR = color6b, TARGET = p2, /DATA, FONT_SIZE = fontSize - 2)
    
    ; +X Solar Panel overplot
    IF coldOrHot EQ 'Cold' THEN BEGIN
      t3aPosition = [0.25, 100]
      t3Position = [0.25, 80]
      yRange = [-40, 120]
    ENDIF ELSE BEGIN
      t3aPosition = [0.25, 90]
      t3Position = [0.25, 82]
      yRange = [40, 100]
    ENDELSE
    p3a = plot(timeActualHours, hk.eps_sa2_temp, '4', COLOR = color7a, OVERPLOT = p3)
    p3.SetData, timeModelHours, shift(tlmSaPlusXModel, -12)
    p3.xrange = [0, 3]
    p3.yrange = yRange
    p3.title = '+X Solar Array: $\Delta$Mean = ' + JPMPrintNumber(abs(meanSaPlusXActual - meanTlmSaPlusXModel)) + ' ºC'
    t3a = text(t3aPosition[0], t3aPosition[1], 'Mean = ' + JPMPrintNumber(meanSaPlusXActual) + ' ºC', COLOR = color7a, TARGET = p3, /DATA, FONT_SIZE = fontSize - 2)
    t3 = text(t3Position[0], t3Position[1], 'Mean = ' + JPMPrintNumber(meanTlmSaPlusXModel) + ' ºC', COLOR = color7b, TARGET = p3, /DATA, FONT_SIZE = fontSize - 2)

    ; X123 Electronics overplot
    IF coldOrHot EQ 'Cold' THEN BEGIN
      t3aPosition = [0.25, 29]
      t3Position = [0.25, 25]
      yRange = [5, 35]
    ENDIF ELSE BEGIN
      t3aPosition = [0.25, 37]
      t3Position = [0.25, 34]
      yRange = [20, 40]
    ENDELSE
    p4a = plot(timeActualHours, hk.x123_brd_temp, '4', COLOR = color8a, OVERPLOT = p4)
    p4.SetData, timeModelHours, shift(tlmX123BoardModel, -12)
    p4.xrange = [0, 3]
    p4.yrange = yRange
    p4.title = 'X123 Electronics: $\Delta$Mean = ' + JPMPrintNumber(abs(meanX123BoardActual - meanTlmX123BoardModel)) + ' ºC'
    t4a = text(t3aPosition[0], t3aPosition[1], 'Mean = ' + JPMPrintNumber(meanX123BoardActual) + ' ºC', COLOR = color8a, TARGET = p4, /DATA, FONT_SIZE = fontSize - 2)
    t4 = text(t3Position[0], t3Position[1], 'Mean = ' + JPMPrintNumber(meanTlmX123BoardModel) + ' ºC', COLOR = color8b, TARGET = p4, /DATA, FONT_SIZE = fontSize - 2)
    
  ENDIF
  
  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    layoutColumn = 2

    ; Read the hot case model data
    IF keyword_set(WORST_HOT) THEN restore, datalocModel + dataFilename + 'Hot Worst Case Model Predicts.sav' ELSE $
                                   restore, datalocModel + dataFilename + 'Hot Model Predicts.sav'

  ENDIF
ENDWHILE ; Second page of plots
IF keyword_set(WORST_HOT) THEN BEGIN
  p1.save, saveloc + 'ISS Orbit Worst Case Passive Boards.png'
  p1.save, savelocDissertation + 'IssOrbitWorstCasePassiveBoards.png'
ENDIF ELSE IF keyword_set(OVERPLOT_ACTUALS) THEN BEGIN
  p1.save, saveloc + 'ISS Orbit Predicts vs Actuals Passive Boards.png'
  p1.save, savelocPaper + 'IssOrbitPredictsVsActualsPassiveBoards.png'
ENDIF ELSE BEGIN
  p1.save, saveloc + 'ISS Orbit Passive Boards.png'
  p1.save, savelocDissertation + 'IssOrbitPassiveBoards.png'
ENDELSE

; Read the cold case model data
restore, datalocModel + dataFilename + 'Cold Model Predicts.sav'

; Page 3 of plots - active boards
coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
layoutColumn = 1
xrange = [0, 24]

w = window(DIMENSIONS = [1836., 1782.], /BUFFER) ; Corresponds to 8.5" x 11" * 3 with resolution of 72 dpi (can't change res)
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'

  leftTitle = text(0.25, 1, 'Cold Case ISS', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  rightTitle = text(0.75, 1, 'Hot Case ISS', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  xTitle = text(0, 0.5, 'Temperature [ºC]', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize, ORIENTATION = 90)

  ; EPS
  p1 = plot(timeModelHours, tlmEpsModel, '4--', COLOR = color9b, FONT_SIZE = fontSize, /CURRENT, LAYOUT = [2, 3, layoutColumn], MARGIN = margin, $
            TITLE = 'EPS Board', $
            XRANGE = xrange, $ 
            NAME = 'Model')

  ; Batteries
  p2 = plot(timeModelHours, tlmBatteryModel, COLOR = color10b, '4--', /CURRENT, LAYOUT = [2, 3, layoutColumn + 2], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = 'Batteries', $
            XRANGE = xrange)

  ; COMM
  p3 = plot(timeModelHours, tlmCommModel, COLOR = color11b, '4--', /CURRENT, LAYOUT = [2, 3, layoutColumn + 4], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = 'COMM Board', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange)
 
  ;
  ; Optionally overplot the actual on-orbit measurements 
  ;
  
  IF keyword_set(OVERPLOT_ACTUALS) THEN BEGIN
    
    ; Restore MinXSS-1 data
    restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'
    
    ; Restrict data to time ranges for cold and hot cases as determined by Chloe Downs during summer REU
    ; Cold time range: [2016-06-15 10:57:03, 2016-06-15 14:00:16], which had a beta of 1º
    ; Hot time range: [2016-05-28 23:30:00, 2016-05-29 02:30:00], which had a beta of 73º    
    IF coldOrHot EQ 'Cold' THEN BEGIN
      hk = hk[where(hk.time_jd GE JPMiso2jd('2016-06-15T10:57:03Z') AND hk.time_jd LE JPMiso2jd('2016-06-15T14:00:16Z'))]
    ENDIF ELSE BEGIN
      hk = hk[where(hk.time_jd GE JPMiso2jd('2016-05-28T23:30:00Z') AND hk.time_jd LE JPMiso2jd('2016-05-29T02:30:00Z'))]
    ENDELSE
    
    ; Convert orbit time to hours since window start
    timeActualHours = (hk.time_jd - hk[0].time_jd) * 24.
    
    ; Shift model values to be in sync with actuals (as best as possible, anyway)
    shiftValue = -12
    
    ; Compute EPS means 
    windowModelIndices = where(timeModelHours GE 0 AND timeModelHours LE 3)
    tlmEpsModelShifted = shift(tlmEpsModel, shiftValue)
    meanTlmEpsModel = mean(tlmEpsModelShifted[windowModelIndices])
    meanEpsActual = mean(hk.eps_temp1)
    
    ; Compute battery means
    tlmBatteryModelShifted = shift(tlmBatteryModel, shiftValue)
    meanTlmBatteryModel = mean(tlmBatteryModelShifted[windowModelIndices])
    meanBatteryActual = mean(hk.eps_batt_temp1)
    
    ; Compute COMM means
    tlmCommModelShifted = shift(tlmCommModel, shiftValue)
    meanTlmCommModel = mean(tlmCommModelShifted[windowModelIndices])
    meanCommActual = mean(hk.comm_temp)
    
    ; EPS overplot
    IF coldOrHot EQ 'Cold' THEN BEGIN
      t1aPosition = [0.25, 7.0]
      t1Position = [0.25, 3.0]
    ENDIF ELSE BEGIN
      t1aPosition = [0.25, 43.0]
      t1Position = [0.25, 42.0]
    ENDELSE
    p1a = plot(timeActualHours, hk.eps_temp1, '4', COLOR = color9a, OVERPLOT = p1, $
               NAME = 'Measurement')
    p1.SetData, timeModelHours, shift(tlmEpsModel, -12)
    p1.xrange = [0, 3]
    p1.title = 'EPS Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanEpsActual - meanTlmEpsModel)) + ' ºC'
    t1a = text(t1aPosition[0], t1aPosition[1], 'Mean = ' + JPMPrintNumber(meanEpsActual) + ' ºC', COLOR = color9a, TARGET = p1, /DATA, FONT_SIZE = fontSize - 2)
    t1 = text(t1Position[0], t1Position[1], 'Mean = ' + JPMPrintNumber(meanTlmEpsModel) + ' ºC', COLOR = color9b, TARGET = p1, /DATA, FONT_SIZE = fontSize - 2)
    l1 = legend(TARGET = [p1, p1a], POSITION = [0.55, 0.55], FONT_SIZE = fontSize)
    
    ; Batteries overplot
    IF coldOrHot EQ 'Cold' THEN BEGIN
      t2aPosition = [0.25, 10]
      t2Position = [0.25, 9]
    ENDIF ELSE BEGIN
      t2aPosition = [0.25, 26]
      t2Position = [0.25, 24]
    ENDELSE
    p2a = plot(timeActualHours, hk.eps_batt_temp1, '4', COLOR = color10a,  OVERPLOT = p2)
    p2.SetData, timeModelHours, shift(tlmBatteryModel, -12)
    p2.xrange = [0, 3]
    p2.title = 'Batteries: $\Delta$Mean = ' + JPMPrintNumber(abs(meanBatteryActual - meanTlmBatteryModel)) + ' ºC'
    t2a = text(t2aPosition[0], t2aPosition[1], 'Mean = ' + JPMPrintNumber(meanBatteryActual) + ' ºC', COLOR = color10a, TARGET = p2, /DATA, FONT_SIZE = fontSize - 2)
    t2 = text(t2Position[0], t2Position[1], 'Mean = ' + JPMPrintNumber(meanTlmBatteryModel) + ' ºC', COLOR = color10b, TARGET = p2, /DATA, FONT_SIZE = fontSize - 2)
    
    ; COMM overplot
    IF coldOrHot EQ 'Cold' THEN BEGIN
      t3aPosition = [0.25, 18.0]
      t3Position = [0.25, 16.0]
      yRange = [0, 20]
    ENDIF ELSE BEGIN
      t3aPosition = [0.25, 35]
      t3Position = [0.25, 33]
      yRange = [20, 40]
    ENDELSE
    p3a = plot(timeActualHours, hk.comm_temp, '4', COLOR = color11a, OVERPLOT = p3)
    p3.SetData, timeModelHours, shift(tlmCommModel, -12)
    p3.xrange = [0, 3]
    p3.title = 'COMM Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanCommActual - meanTlmCommModel)) + ' ºC'
    p3.yrange = yRange
    t13a = text(t3aPosition[0], t3aPosition[1], 'Mean = ' + JPMPrintNumber(meanCommActual) + ' ºC', COLOR = color11a, TARGET = p3, /DATA, FONT_SIZE = fontSize - 2)
    t3 = text(t3Position[0], t3Position[1], 'Mean = ' + JPMPrintNumber(meanTlmCommModel) + ' ºC', COLOR = color11b, TARGET = p3, /DATA, FONT_SIZE = fontSize - 2)
    
  ENDIF
  
  
  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    layoutColumn = 2

    ; Read the hot case model data
    IF keyword_set(WORST_HOT) THEN restore, datalocModel + dataFilename + 'Hot Worst Case Model Predicts.sav' ELSE $
                                   restore, datalocModel + dataFilename + 'Hot Model Predicts.sav'

  ENDIF
ENDWHILE ; Third page of plots
IF keyword_set(WORST_HOT) THEN BEGIN
  p1.save, saveloc + 'ISS Orbit Worst Case Active Boards.png'
  p1.save, savelocDissertation + 'IssOrbitWorstCaseActiveBoards.png'
ENDIF ELSE IF keyword_set(OVERPLOT_ACTUALS) THEN BEGIN
  p1.save, saveloc + 'ISS Orbit Predicts vs Actuals Active Boards.png'
  p1.save, savelocPaper + 'IssOrbitPredictsVsActualsActiveBoards.png'
ENDIF ELSE BEGIN 
  p1.save, saveloc + 'ISS Orbit Active Boards.png'
  p1.save, savelocDissertation + 'IssOrbitActiveBoards.png'
ENDELSE

END