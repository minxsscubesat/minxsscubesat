;+
; NAME:
;	xrs_filters
;
; PURPOSE:
;	produce the Henke file from individual runs of diode.pro
;

PRO xrs_filters
basedir = '/Users/ajones/Desktop/SURF/SURF_XRS/rocketXRSdec10/MultiEnergy/'
chdir = basedir

nwave = 301
filters = FLTARR(nwave,5)
henke = read_dat( fluxdir + 'RXRS_HENKE_v10.dat' )

Hfiles = [ 'Be520.dat', 'Be510.dat', 'Be58.dat', 'Be60.dat']
FOR i = 1, 4 DO BEGIN ;Read in the individual files
   tmp =read_dat( Hfiles[i] )
   filters(*,0)=tmp(0)
   filters(*,i) = tmp(1)
ENDFOR
   fname='ARJ_filter'
  	datcomments = [ $
  		'5 columns , $
  		'301 rows ', $
  		' ', $
  		'File can be read using "write_dat.pro"', $
  		' ' ]
  	write_dat, data, file=fname+'.dat', comments=datcomments

END
