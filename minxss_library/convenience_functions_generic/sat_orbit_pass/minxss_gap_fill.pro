;
; minxss_gap_fill.pro
;
; Write script to look for gaps in the minxss2_10c_all_mission_length.sav
; Fill gaps in HK, SCI, and ADCS data. Does not fill gaps in LOG
; Looks at scripts_to_run_automatically folder
; Deletes the second script that has '*playback2_last_24_hours.prc' in its name
; Creates a new script with the same time stamp but with the new name '*gap_fill_hk_adcs_sci.prc'
;
; INPUT
; 
;   /plots  Option to plot HK, SCI, and ADCS data to visually see the gaps in data
;
; OUTPUT
;   SCRIPT FILE in scripts_to_run_automatically directory
;
; HISTORY
;   12/16/2018  Bennet Schwab  Original code based on minxss_doy_playback.pro
;

pro minxss_gap_fill,init=init,plots=plots

;If running scripts at Fairbanks this should be = 1, if Boulder this should be = 0, no option yet for Parker
isFairbanks = 1

;
; Get TLE path
;     default is to use directory $TLE_dir
;
;  slash for Mac = '/', PC = '\'
;  File Copy for Mac = 'cp', PC = 'copy'
if !version.os_family eq 'Windows' then begin
    slash = '\'
    file_copy = 'copy '
    file_delete = 'del /F '
endif else begin
    slash = '/'
    file_copy = 'cp '
    file_delete = 'rm -f '
endelse

;
; Get path for TLE / pass time data (as created by plan_satellite_pass.pro)
;
path_name = getenv('minxss_data')
if strlen(path_name) gt 0 then begin
  if ((strpos(path_name,slash,/reverse_search)+1) lt strlen(path_name)) then path_name += slash
endif

;path to mission length file
path_name += 'fm2'+slash+'level0c'+slash

file = path_name+'minxss2_l0c_all_mission_length.sav'

;restore mission length file
restore,file

; TODO - need to find the HK and SCI overwrite times
;only look back as far as the sd_offset will not be written over (~1030016 seconds per sd rollover)
adcsoverwrite = where(adcs4.time gt adcs4[-1].time - 1000000.0)

;create arrays to hold the differences between sd_write_offsets
diffarr = make_array(N_ELEMENTS(hk.time)-1,1,value=0.)
scidiffarr = make_array(N_ELEMENTS(sci.time)-1,1,value=0.)
adcsdiffarr = make_array(N_ELEMENTS(adcs4[adcsoverwrite].time)-1,1,value=0.)

;find differences between sd_hk_write_offsets
for i = 0, N_ELEMENTS(hk.time)-2 do begin
  diffarr[i] = hk[i+1].sd_hk_write_offset-hk[i].sd_hk_write_offset
endfor
;find differences between sd_sci_write_offsets
for i = 0, N_ELEMENTS(sci.time)-2 do begin
  scidiffarr[i] = sci[i+1].sd_sci_write_offset-sci[i].sd_sci_write_offset
endfor
;find differences between sd_adcs_write_offsets only for the past time period where sd offsets are not overwritten
for i = 0, N_ELEMENTS(adcs4[adcsoverwrite].time)-2 do begin
  adcsdiffarr[i] = adcs4[adcsoverwrite[i+1]].sd_adcs_write_offset-adcs4[adcsoverwrite[i]].sd_adcs_write_offset
endfor

; sort the difference arrays by greatest value, saving the values and locations
largest_diff_hk = diffarr[reverse(sort(diffarr))]
;weed out the small number of early mission "bad data points"
gooddata = where(largest_diff_hk lt 200000)
location_diff_hk = reverse(sort(diffarr))

largest_diff_sci = scidiffarr[reverse(sort(scidiffarr))]
location_diff_sci = reverse(sort(scidiffarr))

largest_diff_adcs = adcsdiffarr[reverse(sort(adcsdiffarr))]
location_diff_adcs = reverse(sort(adcsdiffarr))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;PLOTS if keyword /plots is set
;
;
;cutoffs for plotting
war = where(diffarr gt 1000 and diffarr lt 200000)
sciwar = where(scidiffarr gt 5000)
adcswar = where(adcsdiffarr gt 5000)

;if keyword /plots is set, plot hk
if keyword_set(plots) then begin
  hkplt = plot(hk.time,hk.sd_hk_write_offset,symbol='x',title='SD_HK_WRITE_OFFSET vs HK.TIME',xtitle='HK.TIME',ytitle='HK.SD_HK_WRITE_OFFSET')
endif
;then overplot the largest differences in data
for i = 0, N_ELEMENTS(war)-1 do begin
  
  hkpt1 = [hk[war[i]].time,hk[war[i]+1].time]
  hkpt2 = [hk[war[i]].sd_hk_write_offset,hk[war[i]+1].sd_hk_write_offset]
  
  if keyword_set(plots) then begin
    fill = plot(hkpt1,hkpt2,/overplot,symbol='x',color='tomato')
  endif
endfor

;if keyword /plots is set, plot sci
if keyword_set(plots) then begin
  sciplt = plot(sci.time,sci.sd_sci_write_offset,symbol='x',title='SD_SCI_WRITE_OFFSET vs SCI.TIME',xtitle='SCI.TIME',ytitle='SCI.SD_SCI_WRITE_OFFSET')
endif
;then overplot the largest differences in data
for i = 0, N_ELEMENTS(sciwar)-1 do begin

  scipt1 = [sci[sciwar[i]].time,sci[sciwar[i]+1].time]
  scipt2 = [sci[sciwar[i]].sd_sci_write_offset,sci[sciwar[i]+1].sd_sci_write_offset]
  
  if keyword_set(plots) then begin
    scifill = plot(scipt1,scipt2,/overplot,symbol='x',color='tomato')
  endif
endfor

;if keyword /plots is set, plot adcs
if keyword_set(plots) then begin
  adcsplt = plot(adcs4.time,adcs4.sd_adcs_write_offset,symbol='x',title='SD_ADCS_WRITE_OFFSET vs ADCS4.TIME',xtitle='ADCS4.TIME',ytitle='ADCS4.SD_ADCS_WRITE_OFFSET')
endif
;then overplot the largest differences in data
for i = 0, N_ELEMENTS(adcswar)-1 do begin

  scipt1 = [adcs4[adcswar[i]+adcsoverwrite[0]].time,adcs4[adcswar[i]+1+adcsoverwrite[0]].time]
  scipt2 = [adcs4[adcswar[i]+adcsoverwrite[0]].sd_adcs_write_offset,adcs4[adcswar[i]+1+adcsoverwrite[0]].sd_adcs_write_offset]

  if keyword_set(plots) then begin
    adcsfill = plot(scipt1,scipt2,/overplot,symbol='x',color='tomato')
  endif
endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;LOADS the template script
;

hydra_dir = getenv('Hydra')
if strlen(hydra_dir) gt 0 then begin
  if ((strpos(hydra_dir,slash,/reverse_search)+1) lt strlen(hydra_dir)) then hydra_dir += slash
endif

;path to scripts_to_run_automatically folder
if isFairbanks eq 1 then passdir = hydra_dir+'MinXSS'+slash+'HYDRA_FM-2_Fairbanks'+slash+'Scripts'+slash+'scripts_to_run_automatically'+slash
if isFairbanks eq 0 then passdir = hydra_dir+'MinXSS'+slash+'HYDRA_FM-2_Boulder'+slash+'Scripts'+slash+'scripts_to_run_automatically'+slash

;disect the name to rip only the date and time stamp
if keyword_set(init) then begin
  passfiles = file_search(passdir+'*playback2_last_24_hours.prc')
  nfiles = N_ELEMENTS(passfiles)/2-1
endif else begin
  passfiles = file_search(passdir+'*gap*.prc')
  nfiles = N_ELEMENTS(passfiles)-1
endelse
filedir = strsplit(passfiles[1],slash,/extract)
;oldname = filedir[8]
oldname = filedir[WHERE(STRMATCH(filedir, '2*', /FOLD_CASE) EQ 1)]
splitname = strsplit(oldname,'_',/extract)
date = strtrim(string(splitname[0]))+'_'+strtrim(string(splitname[1]))

;create an array of all the dates and times with 'playback_last_24_hours'
dates = make_array(N_ELEMENTS(passfiles),1,value='')
for i = 0,N_ELEMENTS(passfiles)-1 do begin
  filedirs = strsplit(passfiles[i],slash,/extract)
  ;oldnames = filedirs[8]
  oldnames = filedirs[WHERE(STRMATCH(filedirs, '2*', /FOLD_CASE) EQ 1)]
  splitnames = strsplit(oldnames,'_',/extract)
  dates[i] = strtrim(string(splitnames[0]))+'_'+strtrim(string(splitnames[1]))
endfor

;path to the template script playback_custom_template.prc
custom_template = hydra_dir+'MinXSS'+slash+'HYDRA_FM-2_Fairbanks'+slash+'Scripts'+slash+'scripts_auto_template'+slash+'playback_custom_template.prc'
flare_template = hydra_dir+'MinXSS'+slash+'HYDRA_FM-2_Fairbanks'+slash+'Scripts'+slash+'scripts_auto_template'+slash+'playback_flare.prc'

for i = 0,nfiles do begin
  
  if largest_diff_hk[gooddata[i]] ge 1000 then begin  
    ;read the CUSTOM PLAYBACK template script
    finfo = file_info(custom_template)
    openr,lun,custom_template,/get_lun
    scriptbytes = bytarr(finfo.size)
    readu, lun, scriptbytes
    close, lun
    free_lun, lun
    filledscript = string(scriptbytes)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;
    ;EDITS the template script
    ;
  
    ;Edit the start/stop values for HK, SCI, and ADCS. Also change the stop value of the LOG to be same as the start value
    newscript = strjoin(strsplit(filledscript,'HKstartSector = 32333',/regex,/extract,/preserve_null),'HKstartSector = '+strtrim(string(hk[location_diff_hk[gooddata[i]]].sd_hk_write_offset),1))
    newscript = strjoin(strsplit(newscript,'HKstopSector = 32333',/regex,/extract,/preserve_null),'HKstopSector = '+strtrim(string(hk[location_diff_hk[gooddata[i]]+1].sd_hk_write_offset),1))
    newscript = strjoin(strsplit(newscript,'SCIstartSector = 1334691',/regex,/extract,/preserve_null),'SCIstartSector = '+strtrim(string(sci[location_diff_sci[i]].sd_sci_write_offset),1))
    newscript = strjoin(strsplit(newscript,'SCIstopSector = 1335594',/regex,/extract,/preserve_null),'SCIstopSector = '+strtrim(string(sci[location_diff_sci[i]+1].sd_sci_write_offset),1))
    newscript = strjoin(strsplit(newscript,'ADCSstartSector = 655283',/regex,/extract,/preserve_null),'ADCSstartSector = '+strtrim(string(adcs4[location_diff_adcs[i]+adcsoverwrite[0]].sd_adcs_write_offset),1))
    newscript = strjoin(strsplit(newscript,'ADCSstopSector = 660580',/regex,/extract,/preserve_null),'ADCSstopSector = '+strtrim(string(adcs4[location_diff_adcs[i]+1+adcsoverwrite[0]].sd_adcs_write_offset),1))
    newscript = strjoin(strsplit(newscript,'LOGstopSector = 4353',/regex,/extract,/preserve_null),'LOGstopSector = 4346')
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;
    ;SAVES new script
    ;
    
    ;new name of the script will have same date and time stamp but also the gap fill name
    if keyword_set(init) then begin
      newname = dates[2*i]+'_gap_fill_hk_adcs_sci.prc'
      origfile = passfiles[2*i]
    endif else begin
      newname = dates[i]+'_gap_fill_hk_adcs_sci.prc'
      origfile = passfiles[i]
    endelse
    
   ;UNCOMMENT BELOW TO SAVE GAP_FILL FILES
    newfilename = passdir+newname
    openw, lun, newfilename, /get_lun
    printf, lun, newscript
    close, lun
    free_lun, lun
    
    ;UNCOMMENT BELOW TO DELETE THE FILE BEING REPLACED
    ;  CAUTION: CANNOT UNDO ONCE DELETED!!!
    if newfilename ne origfile then begin
      openr, lun, origfile, /delete, /get_lun
      close, lun
    endif



  endif else begin
    ;read the CUSTOM PLAYBACK template script
    finfo = file_info(custom_template)
    openr,lun,custom_template,/get_lun
    scriptbytes = bytarr(finfo.size)
    readu, lun, scriptbytes
    close, lun
    free_lun, lun
    filledscript = string(scriptbytes)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;
    ;EDITS the template script
    ;
  
    ;Edit the start/stop values for SCI and ADCS. HK and LOG will not playback!
    newscript = strjoin(strsplit(filledscript,'SCIstartSector = 1334691',/regex,/extract,/preserve_null),'SCIstartSector = '+strtrim(string(sci[location_diff_sci[i]].sd_sci_write_offset),1))
    newscript = strjoin(strsplit(newscript,'SCIstopSector = 1335594',/regex,/extract,/preserve_null),'SCIstopSector = '+strtrim(string(sci[location_diff_sci[i]+1].sd_sci_write_offset),1))
    newscript = strjoin(strsplit(newscript,'ADCSstartSector = 655283',/regex,/extract,/preserve_null),'ADCSstartSector = '+strtrim(string(adcs4[location_diff_adcs[i]+adcsoverwrite[0]].sd_adcs_write_offset),1))
    newscript = strjoin(strsplit(newscript,'ADCSstopSector = 660580',/regex,/extract,/preserve_null),'ADCSstopSector = '+strtrim(string(adcs4[location_diff_adcs[i]+1+adcsoverwrite[0]].sd_adcs_write_offset),1))
    newscript = strjoin(strsplit(newscript,'LOGstopSector = 4353',/regex,/extract,/preserve_null),'LOGstopSector = 4346')
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;
    ;SAVES new script
    ;
    
    ;new name of the script will have same date and time stamp but also the gap fill name
    if keyword_set(init) then begin
      newname = dates[2*i]+'_gap_fill_adcs_sci.prc'
      origfile = passfiles[2*i]
    endif else begin
      newname = dates[i]+'_gap_fill_adcs_sci.prc'
      origfile = passfiles[i]
    endelse
    
   ;UNCOMMENT BELOW TO SAVE GAP_FILL FILES
    newfilename = passdir+newname
    openw, lun, newfilename, /get_lun
    printf, lun, newscript
    close, lun
    free_lun, lun
    
    ;UNCOMMENT BELOW TO DELETE THE FILE BEING REPLACED
    ;  CAUTION: CANNOT UNDO ONCE DELETED!!!
    if newfilename ne origfile then begin
      openr, lun, origfile, /delete, /get_lun
      close, lun
    endif
  
  endelse
endfor

end