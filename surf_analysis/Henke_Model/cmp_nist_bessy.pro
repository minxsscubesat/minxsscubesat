;
;	Compare NIST and BESSY Calibrations
;

; 0  Wavelength (Å)	AlCr-8	AlCr-19	AlCr-21	AlMn-3	AlMn-8	
; 6  Wavelength (Å)	AlMn-14	AlNbC-1	AlNbC-5	AlScC-8	AlScC-9	
; 12 Wavelength (Å)	AlScC-16	TiC-4		TiC-26	TiMoAu-3	TiMoAu-10	
; 18 Wavelength (Å)	TiMoSiC-1	TiMoSiC-5	TiPd-15	TiZrAu-6
if (n_elements(ncal) lt 2) then begin
  ncal = read_dat( 'XPS_NIST_QE.dat' )

; print, ncal[22,*]
; stop

  nwv = ncal[0,*]/10.	; get NIST wavelength in nm

print, nwv

  nev = 1239.7 / nwv  ; get NIST wavelength in eV
  ; NIST sensitivity is already in electrons/photon units
endif

eps = 'N'	; if "Y" then save plots as EPS files

!fancy=4
!ytitle = '!6Sens. (elec/ph)'
!xtitle = '!6Wavelength (nm)'
y1=60.
y2=y1/2.
y3=y2/2.
y4=y3/2.
y5=y4/2.
csize=0.9
dy=0.9
choice = 0
ans = ' '

;
;	ask user for which PLOT to do
;
big_loop:
print, '         PLOT CHOICES '
print, '1  Ti-C             6  Al-Sc-C'
print, '2  Ti-Zr-Au         7  Ti-Mo-Au'
print, '3  Al-Cr            8  Ti-Mo-Si-C'
print, '4  Al-Mn            9  Ti-Pd'
print, '5  Al-Nb-C          0  ALL PLOTS'
print, ' '
read, 'Enter 0-9 or -1 to EXIT : ', choice

if (choice eq 1) or (choice eq 0) then goto, do_1
if (choice eq 2) or (choice eq 0) then goto, do_2
if (choice eq 3) or (choice eq 0) then goto, do_3
if (choice eq 4) or (choice eq 0) then goto, do_4
if (choice eq 5) or (choice eq 0) then goto, do_5
if (choice eq 6) or (choice eq 0) then goto, do_6
if (choice eq 7) or (choice eq 0) then goto, do_7
if (choice eq 8) or (choice eq 0) then goto, do_8
if (choice eq 9) or (choice eq 0) then goto, do_9

goto, the_end

;
;	Plot Ti-C results
;
do_1:
if (eps eq 'Y') then eps2_p, 'eos_ti_c.eps'
plot_io, nwv, ncal[14,*], psym=4, title='AXUV-100 Ti-C', $
	yrange=[0.01,100], xrange=[0,20]
oplot, [10,10],[y1,y1],psym=4
xyouts, 11, y1*dy, 'NIST S/N 04',charsize=csize
oplot, nwv, ncal[15,*], psym=5
oplot, [10,10],[y2,y2],psym=5
xyouts, 11, y2*dy, 'NIST S/N 26',charsize=csize

b=read_bessy('bessy_ti_c_04_cal.dat')
oplot, b[0,*], b[1,*],psym=2
oplot, [10,10],[y3,y3],psym=2
xyouts, 11, y3*dy, 'BESSY S/N 04',charsize=csize
b=read_bessy('bessy_ti_c_10_cal.dat')
oplot, b[0,*], b[1,*],psym=1
oplot, [10,10],[y4,y4],psym=1
xyouts, 11, y4*dy, 'BESSY S/N 10',charsize=csize
b=read_bessy('bessy_ti_c_14_cal.dat')
oplot, b[0,*], b[1,*],psym=1,thick=2
oplot, [10,10],[y5,y5],psym=1,thick=2
xyouts, 11, y5*dy, 'BESSY S/N 14',charsize=csize
if (eps eq 'Y') then send2

if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

;
;	Plot Ti-Zr-Au results
;
do_2:
if (eps eq 'Y') then eps2_p, 'eos_ti_zr_au.eps'
plot_io, nwv, ncal[22,*], psym=4, title='AXUV-100 Ti-Zr-Au', $
	yrange=[0.01,100], xrange=[0,20]
oplot, [10,10],[y1,y1],psym=4
xyouts, 11, y1*dy, 'NIST S/N 06',charsize=csize

b=read_bessy('bessy_ti_zr_au_06_cal.dat')
oplot, b[0,*], b[1,*],psym=2
oplot, [10,10],[y2,y2],psym=2
xyouts, 11, y2*dy, 'BESSY S/N 06',charsize=csize
b=read_bessy('bessy_ti_zr_au_04_cal.dat')
oplot, b[0,*], b[1,*],psym=1
oplot, [10,10],[y3,y3],psym=1
xyouts, 11, y3*dy, 'BESSY S/N 04',charsize=csize
b=read_bessy('bessy_ti_zr_au_07_cal.dat')
oplot, b[0,*], b[1,*],psym=1,thick=2
oplot, [10,10],[y4,y4],psym=1,thick=2
xyouts, 11, y4*dy, 'BESSY S/N 07',charsize=csize
if (eps eq 'Y') then send2

if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

;
;	Plot Al-Cr results
;
do_3:
if (eps eq 'Y') then eps2_p, 'eos_al_cr.eps'
plot_io, nwv, ncal[1,*], psym=4, title='AXUV-100 Al-Cr', $
	yrange=[0.01,100], xrange=[0,50]
oplot, [10,10]*2,[y1,y1],psym=4
xyouts, 22, y1*dy, 'NIST S/N 08',charsize=csize
oplot, nwv, ncal[2,*], psym=5
oplot, [10,10]*2,[y2,y2],psym=5
xyouts, 22, y2*dy, 'NIST S/N 19',charsize=csize
oplot, nwv, ncal[3,*], psym=6
oplot, [10,10]*2,[y3,y3],psym=6
xyouts, 22, y3*dy, 'NIST S/N 21',charsize=csize

b=read_bessy('bessy_al_cr_06_cal.dat')
oplot, b[0,*], b[1,*],psym=1
oplot, [10,10]*2,[y4,y4],psym=1
xyouts, 22, y4*dy, 'BESSY S/N 06',charsize=csize
b=read_bessy('bessy_al_cr_07_cal.dat')
oplot, b[0,*], b[1,*],psym=1,thick=2
oplot, [10,10]*2,[y5,y5],psym=1,thick=2
xyouts, 22, y5*dy, 'BESSY S/N 07',charsize=csize
if (eps eq 'Y') then send2

if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

;
;	Plot Al-Mn results
;
do_4:
if (eps eq 'Y') then eps2_p, 'eos_al_mn.eps'
plot_io, nwv, ncal[4,*], psym=4, title='AXUV-100 Al-Mn', $
	yrange=[0.01,100], xrange=[0,50]
oplot, [10,10]*2,[y1,y1],psym=4
xyouts, 22, y1*dy, 'NIST S/N 03',charsize=csize
oplot, nwv, ncal[5,*], psym=5
oplot, [10,10]*2,[y2,y2],psym=5
xyouts, 22, y2*dy, 'NIST S/N 08',charsize=csize
oplot, nwv, ncal[7,*], psym=6
oplot, [10,10]*2,[y3,y3],psym=6
xyouts, 22, y3*dy, 'NIST S/N 14',charsize=csize

b=read_bessy('bessy_al_mn_06_cal.dat')
oplot, b[0,*], b[1,*],psym=1
oplot, [10,10]*2,[y4,y4],psym=1
xyouts, 22, y4*dy, 'BESSY S/N 06',charsize=csize
if (eps eq 'Y') then send2

if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

;
;	Plot Al-Nb-C results
;
do_5:
if (eps eq 'Y') then eps2_p, 'eos_al_nb_c.eps'
plot_io, nwv, ncal[8,*], psym=4, title='AXUV-100 Al-Nb-C', $
	yrange=[0.01,100], xrange=[0,50]
oplot, [10,10]*2,[y1,y1],psym=4
xyouts, 22, y1*dy, 'NIST S/N 01',charsize=csize
oplot, nwv, ncal[9,*], psym=5
oplot, [10,10]*2,[y2,y2],psym=5
xyouts, 22, y2*dy, 'NIST S/N 05',charsize=csize

b=read_bessy('bessy_al_nb_c_03_cal.dat')
oplot, b[0,*], b[1,*],psym=2
oplot, [10,10]*2,[y3,y3],psym=2
xyouts, 22, y3*dy, 'BESSY S/N 03',charsize=csize
if (eps eq 'Y') then send2

if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

;
;	Plot Al-Sc-C results
;
do_6:
if (eps eq 'Y') then eps2_p, 'eos_al_sc_c.eps'
plot_io, nwv, ncal[10,*], psym=4, title='AXUV-100 Al-Sc-C', $
	yrange=[0.01,100], xrange=[0,50]
oplot, [10,10]*3,[y1,y1],psym=4
xyouts, 32, y1*dy, 'NIST S/N 08',charsize=csize
oplot, nwv, ncal[11,*], psym=5
oplot, [10,10]*3,[y2,y2],psym=5
xyouts, 32, y2*dy, 'NIST S/N 09',charsize=csize
oplot, nwv, ncal[13,*], psym=6
oplot, [10,10]*3,[y3,y3],psym=6
xyouts, 32, y3*dy, 'NIST S/N 16',charsize=csize

b=read_bessy('bessy_al_sc_c_17_cal.dat')
oplot, b[0,*], b[1,*],psym=1
oplot, [10,10]*3,[y4,y4],psym=1
xyouts, 32, y4*dy, 'BESSY S/N 17',charsize=csize
b=read_bessy('bessy_al_sc_c_24_cal.dat')
oplot, b[0,*], b[1,*],psym=1,thick=2
oplot, [10,10]*3,[y5,y5],psym=1,thick=2
xyouts, 32, y5*dy, 'BESSY S/N 24',charsize=csize
if (eps eq 'Y') then send2

if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

;
;	Plot Ti-Mo-Au results
;
do_7:
if (eps eq 'Y') then eps2_p, 'eos_ti_mo_au.eps'
plot_io, nwv, ncal[16,*], psym=4, title='AXUV-100 Ti-Mo-Au', $
	yrange=[0.01,100], xrange=[0,20]
oplot, [10,10],[y1,y1],psym=4
xyouts, 11, y1*dy, 'NIST S/N 03',charsize=csize
oplot, nwv, ncal[17,*], psym=5
oplot, [10,10],[y2,y2],psym=5
xyouts, 11, y2*dy, 'NIST S/N 10',charsize=csize
if (eps eq 'Y') then send2

if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

;
;	Plot Ti-Mo-Si-C results
;
do_8:
if (eps eq 'Y') then eps2_p, 'eos_ti_mo_si_c.eps'
plot_io, nwv, ncal[19,*], psym=4, title='AXUV-100 Ti-Mo-Si-C', $
	yrange=[0.01,100], xrange=[0,20]
oplot, [10,10],[y1,y1],psym=4
xyouts, 11, y1*dy, 'NIST S/N 01',charsize=csize
oplot, nwv, ncal[20,*], psym=5
oplot, [10,10],[y2,y2],psym=5
xyouts, 11, y2*dy, 'NIST S/N 05',charsize=csize
if (eps eq 'Y') then send2

if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

;
;	Plot Ti-Pd results
;
do_9:
if (eps eq 'Y') then eps2_p, 'eos_ti_pd.eps'
plot_io, nwv, ncal[21,*], psym=4, title='AXUV-100 Ti-Pd', $
	yrange=[0.01,100], xrange=[0,20]
oplot, [10,10],[y1,y1],psym=4
xyouts, 11, y1*dy, 'NIST S/N 15',charsize=csize

b=read_bessy('bessy_ti_pd_17_cal.dat')
oplot, b[0,*], b[1,*],psym=2
oplot, [10,10],[y2,y2],psym=2
xyouts, 11, y2*dy, 'BESSY S/N 17',charsize=csize
if (eps eq 'Y') then send2

; if (choice eq 0) then read, 'Next ? ', ans
if (choice ne 0) then goto, big_loop

goto, big_loop

the_end:
print, 'Exit...'
end
