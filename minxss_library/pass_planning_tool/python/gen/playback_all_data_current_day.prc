;
; NAME:
;   playback_all_data_current_day.prc
;
; PURPOSE:
;   Playback all data with Tlm file for each packet type
;
;	This Script plays back the past 24-hours of data using current SD-Card Write Offsets
;	Playback rate is 1 packet / 0.5 sec or about 2 packets / sec
;
;	Flight Playback
;	Typical flight passes will be about 10 minutes, so average playback time could be 6 minutes.
;	Normally one needs to reduce playback time to about 2 min less than pass time.
;	*** This script intends to downlink data for 5 minutes ***
; 
;  COMMANDS TESTED
;   None
;
; ISSUES:
;   Note that type_db.xml in ISIS root directory needs the addition of:
;		<typeSN name="sn32l" size="32" endian="LITTLE" />
;
; MODIFICATION HISTORY
;   12/28/2015  T. Woods,  Original Code
;	

declare cmdCnt dn16
declare cmdTry dn16l
declare cmdSucceed dn16l
declare startSector sn32l
declare stopSector sn32l

;  restart new Tlm file  (no skip this so there is no Pause)
echo ..... Starting Playback Script .....
; echo Start new Tlm file by using the  tlmOutFile rollover  button.
; echo Note the new Tlm file for the Playback data.
; echo Type GO if ready to continue...
; pause

PLAYBACK_SETUP:
; Set Contact (Tx) timeout (Ground = 7200 sec, Flight = 600 sec)
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_contact_tx_timeout Timeout 600
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1

; wait 1000
; Reset Contact Counter
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	reset_counters Group 4
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1

HK_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 HK packets per sector.  The HK rate is 3 sec.
;  So Step of 100 is every 100th sector (600 sec).
;  There are expected to be 14,400 HK Sectors every 24 hours.
;  For HK to be 35% of the data volume, then STEP = 200 for 10-min cadence.
;
echo Configuring for HK playback 
set cmdCnt = MINXSSCmdAcceptCnt + 1
set stopSector = MINXSSSdHkWriteOffset
set startSector = stopSector - 14400
if startSector < 0
	echo WARNING: Rollover of HK Buffer, not all HK data are being downlinked.
	set startSector = 0
endif
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_hk_playback_range HkStart $startSector HkStop $stopSector HkStep 200
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
;wait 1000

LOG_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 6 LOG packets per sector.  A Step of 1 should be used to get all LOG packets.
;  There is a random number of LOG Sectors every 24 hours.
;  Assume a LOG message every 5 minutes, so that is 300 sectors in 24-hour period.
;
echo Configuring for LOG playback 
set cmdCnt = MINXSSCmdAcceptCnt + 1
set stopSector = MINXSSSdLogMsgWriteOffset
set startSector = stopSector - 300
if startSector < 0
	echo WARNING: Rollover of LOG Buffer, not all LOG data are being downlinked.
	set startSector = 0
endif
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_log_playback_range LogStart $startSector LogStop $stopSector LogStep 1
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
;wait 1000

SCI_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 SCI packets per sector.  SCI rate is 10 sec.
;  One SCI Record (full spectrum) can take 1 to 14 packets, depending on compression.
;  A Step of 30 is every 30th SCI Record (300 sec).
;  There are expected to be maximum of 60,480 SCI Sectors every 24 hours if uncompressed.
;  There are expected about 8,640 SCI Packets every 24 hours for compression during quiet sun period.
;  A STEP value of 60 will have 10-min science data cadence so SCI will be 35% of downlink.
;
echo Configuring for SCI playback 
set cmdCnt = MINXSSCmdAcceptCnt + 1
set stopSector = MINXSSSdSciWriteOffset
set startSector = stopSector - 60480
if startSector < 0
	echo WARNING: Rollover of SCI Buffer, not all SCI data are being downlinked.
	set startSector = 0
endif
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_science_playback_range SciStart $startSector SciStop $stopSector SciStep 60 
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
;wait 1000

ADCS_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 ADCS packets per sector.  So Step of 300 is every 300th sector (300 sec).
;  One ADCS Record has 4 packets.  ADCS Record rate is 1 sec.
;  There are expected to be 172,800 ADCS Sectors every 24 hours.
;  ADCS playback is probably in its own pass due to its large volume.
;  One can turn off ADCS playback by setting Step to 0.
;  For normal playback, one can use STEP = 1199 for 20-min cadence for 18% of downlink
;  STEP has to be ODD number so that different ADCS packets are downlink
;		(ADCS 1+2 in one sector, and ADCS 3+4 in next sector)
;
echo Configuring for ADCS playback 
set cmdCnt = MINXSSCmdAcceptCnt + 1
set stopSector = MINXSSSdAdcWriteOffset
set startSector = stopSector - 172800
if startSector < 0
	echo WARNING: Rollover of ADCS Buffer, not all ADCS data are being downlinked.
	set startSector = 0
endif
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_adcs_playback_range AdcsStart $startSector AdcsStop $stopSector AdcsStep 1199
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
;wait 1000

DIAG_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 DIAG packets per sector.  The DIAG rate is 1 sec when active.
;  The DIAG is not used except for debugging monitors so normally set STEP to 0.
;echo Configuring for DIAG playback 
;set cmdCnt = MINXSSCmdAcceptCnt + 1
;while MINXSSCmdAcceptCnt < $cmdCnt
;	set cmdTry = cmdTry + 1
;	set_diag_playback_range DiagStart 3000 DiagStop 3000 DiagStep 0
;	wait 3529
;endwhile
;set cmdSucceed = cmdSucceed + 1
;wait 1000

XIMG_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 XIMG packets per sector.  A step of 1 should be used if doing XACT Image.
;  The XIMG is not used except for debugging XACT so normally set STEP to 0.
;echo Configuring for XIMG playback 
;set cmdCnt = MINXSSCmdAcceptCnt + 1
;while MINXSSCmdAcceptCnt < $cmdCnt
;	set cmdTry = cmdTry + 1
;	set_ximg_playback_range XimgStart 200000 XimgStop 200000 XimgStep 0
;	wait 3529
;endwhile
;set cmdSucceed = cmdSucceed + 1
;wait 1000

START_PLAYBACK:
; Initiate Playback operation
;	Change so playback runs without User input to start playback
echo WARNING: commands will be difficult to send during playback!
;echo Type GO when ready to start Playback...
;pause

set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	initiate_playback_op
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1

echo PLAYBACK has started.  It will take several minutes to complete.
echo Once completed, you can start new Tlm file by using the  tlmOutFile rollover  button.
echo End of playback_all_data Script

print cmdTry
print cmdSucceed
