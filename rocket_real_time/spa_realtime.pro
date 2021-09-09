pro spa_realtime
  dirX55=file_search("/Volumes/Users/rocket/Dropbox/minxss_dropbox/rocket_eve/36.353/NUC Software/Hydra_2021_XRS_X55/Rundirs/2021_*")
  dirX55=dirX55[-1]
  while 1 do begin
    fileX55=file_search(dirX55+'/tlm*')
    fileX55=fileX55[-1]
    if fileX55 then begin
      dualsps_plot,fileX55,'X55',win=1,xpos=1415, ypos=1400,xsize=1250,ysize=700,inst='X55 Spectrum'
      dualsps_plot,fileX55,'SPS1',win=2,xpos=1415, ypos=350,xsize=1250,ysize=700,inst='XRS-C SPS Quad'
    endif else begin
      print, 'Waiting for X55 data'
    endelse
    wait,5
  endwhile
end