;+
; NAME:
;   daxss_make_spectra_movie
;
; PURPOSE:
;   Make a movie of the DAXSS-55 spectra from the 2021-09-09 rocket flight
;
; INPUTS:
;   None (but need the data file)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   No direct return, but movie written to disk
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to the data file
;
; EXAMPLE:
;   Just run it!
;-
PRO daxss_make_spectra_movie

; Defaults
dataloc = getenv('HOME') + '/Dropbox/minxss_dropbox/rocket_eve/36.353/TM_Data/Flight/TM1/'
saveloc = getenv('HOME') + '/Dropbox/minxss_dropbox/rocket_eve/36.353/Results/'
fps = 20
dims = [1500, 1000]
fontsize = 16

; Load data
restore, dataloc + 'dualsps_xrs_xdata_x55_messages_old.sav'

; Generate a placeholder energy array for now
en = jpmrange(0, 15, inc=0.0146)
en = en[0:1023]

; Prepare movie
movie_object = IDLffVideoWrite(saveloc + 'DAXSS Rocket Spectra.mp4')
vid_stream = movie_object.AddVideoStream(dims[0], dims[1], fps)
w = window(dimensions=dims, FONT_SIZE=fontSize, /BUFFER)
p1 = plot(en, x55[0].x55_spectra, thick=2, font_size=fontSize, /CURRENT, $
          title='DAXSS Rocket Spectra on 2021-09-09 B8 Flare', $
          xtitle='energy [keV]', xrange=[0.5, 5], /xlog, $
          ytitle='intensity [counts/sec]', /ylog)
          
; Loop through each frame of movie
FOR i = 0, n_elements(x55) - 1 DO BEGIN
  p1.setdata, en, x55[i].x55_spectra
  timeInMovie = movie_object.Put(vid_stream, p1.CopyWindow())
  print, strtrim(i, 2) + ' of ' + strtrim(n_elements(x55), 2)
ENDFOR
movie_object.Cleanup
STOP
END