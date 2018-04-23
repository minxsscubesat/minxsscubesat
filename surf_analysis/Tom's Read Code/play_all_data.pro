;
;	play 36.258 data
;
ans = ' '
doSave = 0		; set to non-zero to also save the data as IDL saveset

afile = '36286_tm2_Flt_100_460_raw_amegs.dat'
bfile = '36286_tm2_Flt_100_460_raw_bmegs.dat'
efile = '36286_tm1_Flt_-200_585_esp.dat'
txfile = '36286_tm1_Flt_-200_585_xps.dat'
pfile = '36286_tm1_Flt_-200_585_pmegs.dat'
alogfile = '36286_tm1_Flt_-200_585_analogs.dat'

doMEGS = 0
if (doMEGS ne 0) then begin
  read, 'Ready for MEGS-A movie ? ', ans
  movie_raw_megs, afile, 'A', 2

  read, 'Ready for MEGS-B movie ? ', ans
  movie_raw_megs, bfile, 'B', 2
endif

read, 'Ready for ESP plot ? ', ans
plot_esp, efile, esp
write_jpeg_tv, 'esp_36286.jpg'

read, 'Ready for MEGS-P plot ? ', ans
plot_megsp, pfile, pmegs
write_jpeg_tv, 'pmegs_36286.jpg'

read, 'Ready for TIMED SEE XPS plots ? ', ans
plot_xps, txfile, xps, xrange=[0,600], /jpeg

read, 'Ready for Analog plots ? ', ans
plot_analogs, alogfile, analog

if (doSave ne 0) then begin
  esave = strmid(efile,0,strlen(efile)-4)+'.sav'
  print, 'Saving ESP data in ', esave
  save, esp, file=esave

  psave = strmid(pfile,0,strlen(pfile)-4)+'.sav'
  print, 'Saving MEGS-P data in ', psave
  save, pmegs, file=psave

  txsave = strmid(txfile,0,strlen(txfile)-4)+'.sav'
  print, 'Saving XPS data in ', txsave
  save, xps, file=txsave

  alogsave = strmid(alogfile,0,strlen(alogfile)-4)+'.sav'
  print, 'Saving Analog data in ', alogsave
  save, analog, file=alogsave
endif

end
