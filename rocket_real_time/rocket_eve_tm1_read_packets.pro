;+
; NAME:
;   rocket_eve_tm1_read_packets
;
; PURPOSE:
;   Stripped down code with similar purpose as rocket_eve_tm2_read_packets, designed to return the data via a struct rather than a common buffer.
;   Designed to work in conjunction with rocket_eve_tm1_real_time_display.pro to parse Dewesoft packets to be passed back for displaying.
;
; INPUTS:
;   socketData [bytarr]: Data retrieved from an IP socket.
;   analogMonitorsStructure: Initialized struct in rocket_eve_tm1_real_time_display that will hold the parsed data
;   offsets: Array of indicies where the channel stream offsets are located in a Dewesoft packet. Determining these offsets is handled
;            in rocket_eve_tm1_real_time_display
;   packetsize: Array of channel data sizes in Dewesoft packet corresponding to its given offset 
;   monitorsRefreshText: Struct for the refresh text at the bottom of the analog display windows in rocket_eve_tm1_real_time_display
;   monitorsSerialRefreshText: Same as above but for serial data
;   stale_a: Int counter for invalid analog data
;   stale_s: Same as above but for serial data
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;
; COMMON BLOCKS:
;
; OUTPUTS:
;   Returns analogMonitorsStructure with updated telemetry
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires JPMsystime.
;
; PROCEDURE:
;   TASK 1: Process Analog Telemetry 
;   TASK 2: Process ESP Serial Data
;   TASK 3: Process MEGSP Serial Data
;
; EXAMPLE:
;   rocket_eve_tm1_read_packets, socketData, analogMonitorsStructure, offsets, packetsize, monitorsRefreshText, monitorsSerialRefreshText, stale_a, stale_s, sdoor_state
;-

FUNCTION rocket_eve_tm1_read_packets, socketData, analogMonitorsStructure, offsets, packetsize, monitorsRefreshText, monitorsSerialRefreshText, stale_a, stale_s, sdoor_state, sdoor_history

;common rocket_eve_tm1_read_packets,sdoor_history

; Conversion factors for each individual monitor. Found in DataView
; ===========36.336============
;conv_factor=[5./1023,5./1023,5./1023*2,0.01,5./1023,5./1023,5./1023,5./1023,5./1023,5./1023,$
;             5./1023,5./1023*10,5./1023,5./1023,$
;             0.05,0.055,5./1023,5./1023,5./1023,5./1023,1,0.00918]
;megsp_temp=0,megsa_htr=0,xrs_5v=0,csol_5v=1,slr_pressure=0,cryo_cold=0,megsb_htr=0,xrs_temp=0,megsa_ccd_temp=0,megsb_ccd_temp=1,cryo_hot=1,exprt_28v=1,vac_valve_pos=1,hvs_pressure=1,exprt_15v=1,fpga_5v=1,tv_12v=1,megsa_ff_led=1,megsb_ff_led=1,exprt_bus_cur=0,sdoor_pos=1,exprt_main_28v=0,esp_fpga_time=1,esp_rec_counter=1
;esp1=1,esp2=1,esp3=1,esp4=1
;esp5=1,esp6=1,esp7=1,esp8=1
;esp9=1,megsp_fpga_time=1,megsp1=1,megsp2=1
; Byte offsets for each individual monitor. Also found in DataView

; TODO: for flight - add a 0 for shutter door o/c
;shift=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,21.7]

; ===========36.352============
;conv_factor=[5./1023, 5./1023, 5./1023*2, 5./1023, 5./1023, 5./1023, 5./1023, 5./1023, 5./1023,$
;             5./1023, 5./1023*10, 5./1023, 5./1023,$
;             0.05, 0.055, 5./1023, 5./1023, 5./1023, 1, .0049, .01205]
;shift=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.09566,22]

; ===========36.352============
  default = 5./1023
  conv_factor=[ default, default, 2*default, default, default, default, default, default, default,$
                default, 10*default, default, default,$
                0.05, 0.055, default, default, default, 1, .0049, .01205]
  shift=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.09566,22]
             
  channel_num=23                ;We should have 24 offsets in a valid Dewesoft packet. One for each pulled channel

  serial_num=14                 ;Number of serial data points in our monitor structure

  ;If we have a valid Dewesoft packet then parse the packet for each channel
  if (channel_num eq n_elements(offsets)-1) then begin
    ;Change the refresh string and reset our invalid counter now that we found a valid packet
     monitorsRefreshText.String = 'Last full refresh: ' + JPMsystime()
     stale_a=0
   
     ;
     ;TASK 1: Process Analog Monitors
     ;
   
     ;Loop over only the analog monitors in our struct
     for i=0,n_tags(analogMonitorsStructure)-(1+serial_num) do begin
      ;This is the data for an individual channel
        var=tag_names(analogMonitorsStructure)
        packetdata=socketdata[offsets[i]+4:offsets[i]+packetsize[i]*2+4-3]
        ;As analog values are just the same tlm point repeated in the channel data 
        ;we can grap the first word and say thats our data 
        tlm=byte2uint(packetdata[n_elements(packetdata)-2:n_elements(packetdata)-1])*conv_factor[i]+shift[i]
        ;Store it to our struct
        analogMonitorsStructure.(i)=tlm 
     endfor
   
     ;Shutter door logic
     
     sdoor_history=shift(sdoor_history,1)
     sdoor_history[0]=analogMonitorsStructure.sdoor_pos
   
     ;check if most values of sdoor_history are above the open threshold or above the closed theshold
     sdoor_state = "Closed"
     if median(sdoor_history) gt 500. then begin
        sdoor_state = "Open"
     endif
   
     ;Process esp channel data which comes next
     sync_esp_ind=-1            ;Where we found the ESP sync word in the dewesoft channel
     esp_ref=0                  ;ESP refresh variable. This gets set to 1 if we find ESP data in the channel and are able to pull out all the monitors
   
     ;Grab the second to last channel data in the Dewesoft packet which is esp
     packetdata_esp=socketdata[offsets[n_elements(offsets)-3]+4:offsets[n_elements(offsets)-3]+packetsize[n_elements(offsets)-3]*2-1]
   
     ;
     ;TASK 2: Process ESP Serial Data
     ;
   
     ;Loop through this channel data to find the correct sync words (0x037E, 0x0045 which translates to 126,3,69,0 in the channel stream)
     ;Note: There actually four more sync bytes but it is enough to check for the first four
     ;Sync bytes for ESP and MEGS-P goes 0x037E and then E S P for ESP or M G P for MEGS-P in ascii
     for j=0,n_elements(packetdata_esp)-5 do begin
        ;If we find the sync words update the index of where ESP data starts in the channel data
        if((packetdata_esp[j] eq 126) and (packetdata_esp[j+1] eq 3) and (packetdata_esp[j+2] eq 69) and (packetdata_esp[j+3] eq 0)) then sync_esp_ind=j
     endfor
  
     ;Check to see at that index if the channel stream is long enough to contain the ESP serial monitors
     if ((sync_esp_ind+55 lt n_elements(packetdata_esp)) and sync_esp_ind ne -1) then begin
      ;Pull the ESP monitors out of the stream
        analogMonitorsStructure.esp_fpga_time=byte2ulong([packetdata_esp[sync_esp_ind+14],packetdata_esp[sync_esp_ind+12],packetdata_esp[sync_esp_ind+10],packetdata_esp[sync_esp_ind+8]])
        analogMonitorsStructure.esp_rec_counter=byte2uint([packetdata_esp[sync_esp_ind+18],packetdata_esp[sync_esp_ind+16]])
        analogMonitorsStructure.esp1=byte2uint([packetdata_esp[sync_esp_ind+22],packetdata_esp[sync_esp_ind+20]])
        analogMonitorsStructure.esp2=byte2uint([packetdata_esp[sync_esp_ind+26],packetdata_esp[sync_esp_ind+24]])
        analogMonitorsStructure.esp3=byte2uint([packetdata_esp[sync_esp_ind+30],packetdata_esp[sync_esp_ind+28]])
        analogMonitorsStructure.esp4=byte2uint([packetdata_esp[sync_esp_ind+34],packetdata_esp[sync_esp_ind+32]])
        analogMonitorsStructure.esp5=byte2uint([packetdata_esp[sync_esp_ind+38],packetdata_esp[sync_esp_ind+36]])
        analogMonitorsStructure.esp6=byte2uint([packetdata_esp[sync_esp_ind+42],packetdata_esp[sync_esp_ind+40]])
        analogMonitorsStructure.esp7=byte2uint([packetdata_esp[sync_esp_ind+46],packetdata_esp[sync_esp_ind+44]])
        analogMonitorsStructure.esp8=byte2uint([packetdata_esp[sync_esp_ind+50],packetdata_esp[sync_esp_ind+48]])
        analogMonitorsStructure.esp9=byte2uint([packetdata_esp[sync_esp_ind+54],packetdata_esp[sync_esp_ind+52]])
        esp_ref=1               ;We have now refreshed the ESP monitors
     endif
   
     ;
     ;TASK 3: Process MEGSP Serial Data
     ;
   
     ;Process megs-p channel which comes next
     sync_megsp_ind=-1          ;Where we found the MEGS-P sync word in the dewesoft channel
     megs_ref=0;MEGSP refresh variable. This gets set to 1 if we find MEGSP data in the channel and are able to pull out all the monitors
   
     ;Grab the last channel data in the Dewesoft packet which is megsp 
     packetdata_megsp=socketdata[offsets[n_elements(offsets)-2]+4:offsets[n_elements(offsets)-2]+packetsize[n_elements(offsets)-2]*2-1]
   
     ;Loop through this channel data to find the correct sync words (0x037E, 0x004D which translates to 126,3,77,0 in the channel stream)
     ;Note: There actually four more sync bytes but it is enough to check for the first four
     for j=0,n_elements(packetdata_megsp)-5 do begin
        ;If we find the sync words update the index of where MEGS-P data starts in the channel data
        if((packetdata_megsp[j] eq 126) and (packetdata_megsp[j+1] eq 3) and (packetdata_megsp[j+2] eq 77) and (packetdata_megsp[j+3] eq 0)) then sync_megsp_ind=j
     endfor
     if ((sync_megsp_ind+23 lt n_elements(packetdata_megsp) and sync_megsp_ind ne -1)) then begin
        ;Pull the MEGSP monitors out of the stream
        analogMonitorsStructure.megsp_fpga_time=byte2ulong([packetdata_megsp[sync_megsp_ind+14],packetdata_megsp[sync_megsp_ind+12],packetdata_megsp[sync_megsp_ind+10],packetdata_megsp[sync_megsp_ind+8]])
        analogMonitorsStructure.megsp1=byte2uint([packetdata_megsp[sync_megsp_ind+18],packetdata_megsp[sync_megsp_ind+16]])
        analogMonitorsStructure.megsp2=byte2uint([packetdata_megsp[sync_megsp_ind+22],packetdata_megsp[sync_megsp_ind+20]])
        megs_ref=1              ;We have now refreshed the MEGSP monitors
     endif
   
     ;Only if we have refreshed ESP and MEGSP data can we update the full refresh string for the serial monitors window
     if ((megs_ref ne 0) and (esp_ref ne 0)) then begin
        monitorsSerialRefreshText.String = 'Last full refresh: ' + JPMsystime()
        stale_s=0               ;reset the invalid serial data counter
     endif else stale_s=stale_s+1 ;If we didn't get one of the serial monitors to refresh then increment the invalid serial packet counter
     
     return,analogMonitorsStructure ;Return our updated struct
   
  endif else begin
    ;If we didn't see all the valid offsets than increment our invalid packets counters
     stale_a=stale_a+1
     stale_s=stale_s+1
     sdoor_state = 'UNKNOWN'
  endelse
 ;If we didn't see a valid packet then just pass back the struct we were passed (which will just be the last valid packet data)
  return,analogMonitorsStructure
END
