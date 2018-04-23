;+
; NAME:
;   minxss_plot_pretty_first_light
;
; PURPOSE:
;   Create a pretty version of MinXSS first light spectum. 
;
; INPUTS:
;   
;
; OPTIONAL INPUTS:
;
;
; KEYWORD PARAMETERS:
;
;
; OUTPUTS:
;
;
; OPTIONAL OUTPUTS:
;
;
; RESTRICTIONS:
;   Assuming FM-1 only for now
;
; EXAMPLE:
;
;
; MODIFICATION HISTORY:
;   2016/06/01: James Paul Mason: Wrote script.
;-
PRO minxss_plot_pretty_first_light

; Restore data
restore, getenv('minxss_data') + '/fm1/first_light/minxss_firstlight_vars.sav'


; Pull out variables I care about 
minxss_firstlight = minxss_firstlight / area_minxss / energywidths_36290

; Convert to angstrom
wavelengthAngstrom = JPMkev2Angstrom(energyMeans_36290)

; Create plot
b = barplot(energyMeans_36290, minxss_firstLight, THICK = 5, FILL_COLOR = 'dodger blue', MARGIN = 0.1, AXIS_STYLE = 'none', DIMENSIONS = [900, 800], $
            TITLE = 'MinXSS-1 First Light', FONT_SIZE = 18, $
            /YLOG, YRANGE = [1e1, 1e8], $
            XRANGE = [0, 3])
title = b.title 
title.position = [0.37730704867271808, 0.102, 0.62269295132728186, 0.102]
b1 = barplot(energyMeans_36290, minxss_firstLight, COLOR = 'dodger blue', FILL_COLOR = 'dodger blue', THICK = 2, /OVERPLOT)
ax1 = axis('X', LOCATION = 'bottom', TARGET = [b], TITLE = 'Energy [keV]', TICKFONT_SIZE = 16)
ax2 = axis('Y', LOCATION = 'left', TARGET = [b], TITLE = 'Intensity [counts sec$^{-1}$ cm$^{-2}$ keV$^{-1}$]', TICKFONT_SIZE = 16)
ax3 = axis('Y', LOCATION = 'right', TARGET = [b], SHOWTEXT = 0, TICKFONT_SIZE = 16)
p = plot(wavelengthAngstrom, minxss_firstLight, /CURRENT, MARGIN = 0.1, linestyle = 'none', AXIS_STYLE = 'none', $
         XRANGE = [28, 4.132])
ax2 = axis('X', LOCATION = 'top', TARGET = [p], TITLE = 'Wavelength [Å]', TICKFONT_SIZE = 16)
t = text(0.5, 0.3, 'GOES XRS: B1.5', COLOR = 'white', ALIGNMENT = 0.5, FONT_SIZE = 14, FONT_STYLE = 'bold') 

b.save, 'MinXSS-1 First Light.png'
END