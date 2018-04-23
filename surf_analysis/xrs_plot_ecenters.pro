PRO xrs_plot_ecenters

RESTORE, FILENAME = '408c.sav'
   d408X = plotdata[*,0]
   d408Y = plotdata[*,1]
   d408MAX = MAX(d408Y)
   
RESTORE, FILENAME = '380c.sav'
   d380X = plotdata[*,0]
   d380Y = plotdata[*,1]
   d380MAX = MAX(d380Y)


;RESTORE, FILENAME = '361c.sav'


RESTORE, FILENAME = '331c.sav'
   d331X = plotdata[*,0]
   d331Y = plotdata[*,1]
   d331MAX = MAX(d331Y)

;RESTORE, FILENAME = 285c.sav



PLOT, d380X, d380Y/d380MAX, $
   TITLE = 'B2 Y-Center vs. Energy', XTITLE='Y (Inches)',$
   YTITLE = 'Relative Intensity', $
   XR=[-0.6,0.6],$
   /NODATA
   OPLOT, d380X, d380Y/d380MAX, color=fsc_color("orange")
      XYOUTS, 0.3, 0.8, '380 MeV', color=fsc_color("orange")
   OPLOT, d408X, d408Y/d408MAX, color=fsc_color("blue")
         XYOUTS, 0.3, 0.9, '408 MeV', color=fsc_color("blue")
   OPLOT, d331X, d331Y/d331MAX, color=fsc_color("red")
         XYOUTS, 0.3, 0.7, '331 MeV', color=fsc_color("red")
         
write_jpeg_tv,'B2YEplot.jpg'

END