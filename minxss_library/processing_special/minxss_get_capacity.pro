PRO minxss_get_capacity,save_files,fm=fm
colors=['tomato','dodger blue','green','purple','orange','pink','gray']
time=[]
time_jd=[]
discharge=[]
temp1=[]
temp2=[]
volt=[]
cdh_temp=[]
eclipse_state=[]
if not keyword_set(fm) then fm='fm2'
for i=0,N_elements(save_files)-1 do begin
  restore,'/Users/minxss/Dropbox/minxss_dropbox/data/'+strtrim(fm,2)+'/level0c/'+save_files[i]
  time_jd=[time_jd,hk.TIME_JD]
  discharge=[discharge,hk.EPS_BATT_DISCHARGE]
  temp1=[temp1,hk.EPS_BATT_TEMP1]
  temp2=[temp2,hk.EPS_BATT_TEMP2]
  volt=[volt,hk.EPS_FG_VOLT]
  cdh_temp=[cdh_temp,hk.CDH_TEMP]
  eclipse_state=[eclipse_state,hk.ECLIPSE_STATE]
  time=[time,hk.TIME]
endfor
cdh_temp=cdh_temp+273.15
cont=1
count=0
r=label_date(date_format='%N-%D-%Z %H:%I%S')
while cont eq 1 do begin
  zoom_cont=1
  window,0
  plot,time_jd,volt,xtickformat='label_date'
  oplot,time_jd,eclipse_state
  new_dis=''
  read,new_dis,Prompt='Select a discharge time? (y or n)'
  if new_dis eq 'y' then begin
    while zoom_cont eq 1 do begin
      cursor, x1, y1
      WHILE (!MOUSE.button NE 4) DO BEGIN
        CURSOR, x2, y2
      endwhile
      plot,time_jd[where(time_jd ge x1 and time_jd le x2)], volt[where(time_jd ge x1 and time_jd le x2)],yrange=[min(volt[where(time_jd ge x1 and time_jd le x2)])-.1,max(volt[where(time_jd ge x1 and time_jd le x2)])+.1],xtickformat='label_date'
      oplot,time_jd[where(time_jd ge x1 and time_jd le x2)], eclipse_state[where(time_jd ge x1 and time_jd le x2)]*8
      zoom_prmt=''
      read,zoom_prmt,Prompt='Zoom? (y or n)'
      if zoom_prmt eq 'n' then zoom_cont=0
    endwhile
    amp_hours=int_tabulated(time[where(time_jd ge x1 and time_jd le x2)],discharge[where(time_jd ge x1 and time_jd le x2)])/1000/60/60
    avg_temp=mean([mean(temp1[where(time_jd ge x1 and time_jd le x2)]),mean(temp2[where(time_jd ge x1 and time_jd le x2)])])
    ;total_temp=int_tabulated(time[where(time ge x1 and time le x2)],cdh_temp[where(time ge x1 and time le x2)])/60/60
    ;stop
    print,'Temperature: '+strtrim(avg_temp,2)+' Amp*Hours: '+strtrim(amp_hours,2)
    if count eq 0 then begin
      p2=plot((time[where(time_jd ge x1 and time_jd le x2)]-min(time[where(time_jd ge x1 and time_jd le x2)]))/60/60,volt[where(time_jd ge x1 and time_jd le x2)],title='MinXSS-2 Battery Discharge Test',xtitle='Discharge Duration (hrs)',ytitle='FG Battery Voltage (V)',color=colors[count],name=strtrim(string(avg_temp,format='(f10.2)'),2)+'!Z(00B0)C')
      t1=text(.1,.1,strtrim(string(amp_hours,format='(f10.8)'),2)+' A-hrs',color=colors[count],target=p2)
    endif else begin
      p3=plot((time[where(time_jd ge x1 and time_jd le x2)]-min(time[where(time_jd ge x1 and time_jd le x2)]))/60/60,volt[where(time_jd ge x1 and time_jd le x2)],/over,color=colors[count],name=strtrim(string(avg_temp,format='(f10.2)'),2)+'!Z(00B0)C')
      t1=text(.1,.1,strtrim(string(amp_hours,format='(f10.8)'),2)+' A-hrs',color=colors[count],target=p2)
    endelse
  endif else begin
    cont=0
  endelse
  count++
endwhile
leg=legend(target=names)
END