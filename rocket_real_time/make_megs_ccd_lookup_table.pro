;+
; NAME:
;   make_megs_ccd_lookup_table
;
; PURPOSE:
;   The MEGS CCDs come down from rocket telemetry in an alternating pattern: pixel 0 is top left, pixel 1 is bottom right, etc. 
;   This program makes a lookup table for converting pixel to row, column. That means its 2 million rows by 3 columns. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   megsCcdLookupTable.sav, a 3 x 2 million element array. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires JPMProgressBar
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2015-04-19: James Paul Mason: Wrote script.
;-
PRO make_megs_ccd_lookup_table


imageArray = fltarr(2048L, 1024L)
imageSize = 1024L * 2048L

evens = range(0, imageSize * 2 - 1, inc = 2)
odds = reverse(evens + 1)
evens = evens[0:imageSize/2 - 1]
odds = odds[-imageSize/2:-1]
evensOdds = [evens, odds]

k = 0L
FOR i = 0, 1024L - 1 DO BEGIN
  FOR j = 0, 2048L - 1 DO BEGIN
    imageArray[j, i] = evensOdds[k]
    k++
  ENDFOR
ENDFOR

; To return the two indices of the pixel, do array_indices(imageArray, where(imageArray EQ pixel))

; Make a look up table
megsCcdLookupTable = fltarr(3, imageSize)
megsCcdLookupTable[0, *] = evensOdds
FOR pixelIndex = 0, imageSize - 1 DO BEGIN
  megsCcdLookupTable[1:2, pixelIndex] = array_indices(imageArray, where(imageArray EQ evensOdds[pixelIndex]))
  IF pixelIndex mod 10000 EQ 0 THEN progressBar = JPMProgressBar(100. * (pixelIndex + 1)/imageSize, progressBar = progressBar)
ENDFOR

; Sort it
megsCcdLookupTable = colsort(megsCcdLookupTable, 0)

save, megsCcdLookupTable, FILENAME = 'megsCcdLookupTable', /COMPRESS
END