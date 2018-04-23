;
; NAME:
;   playback_all_data_template.prc
;
; PURPOSE:
;   Playback all data with Tlm file for each packet type
;
;	EDIT THIS TEMPLATE BEFORE RUNNING
;	1)  change the start, end, and step values for each packet type
;	2)  save the file as playback_all_data_YYYYDOY_HHMM.prc
;
;	Playback rate is 1 packet / 0.5 sec or about 2 packets / sec
;
;	Ground Playback
;   The contact Tx timeout maximum is 7200 sec (2 hour), so about 20,000 packets.
;	You probably will need to decimate the packets during playback (e.g. HkStep)
;	or have limited range for the playback (e.g. HkStart and HkStop).
;
;	Flight Playback
;	Typical flight passes will be about 10 minutues, so average playback time could be 6 minutues
;	Normally one needs to reduce playback time to about 2 min less than pass time.
;
;  COMMANDS TESTED
;   None
;
; ISSUES:
;
;
; MODIFICATION HISTORY
;   3/18/2015  T. Woods,  Original Code
;

declare cmdCnt dn16
declare cmdTry dn16l
declare cmdSucceed dn16l

;  restart new Tlm file
echo ..... Starting Playback Script .....
echo Start new Tlm file by using the  tlmOutFile rollover  button.
echo Note the new Tlm file for the Playback data.

PLAYBACK_SETUP:
; Set Contact (Tx) timeout (Ground = 7200 sec, Flight = 600 sec)
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_contact_tx_timeout Timeout 600
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1

; Reset Contact Counter
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	reset_counters Group 4
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1

HK_PLAYBACK:
;  The Start-Stop are sector numbers. The Step is for packet decimation.
;  There are 2 HK packets per sector.  The HK rate is 3 sec.
;  So Step of 100 is every 100th sector (600 sec).
;  There are expected to be 7,200 HK Sectors every 12 hours.
;  For HK to be ~1/2 of the data volume, then STEP = 20 for 1-min cadence.
;
echo Configuring for HK playback
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_hk_playback_range HkStart %hkstart% HkStop %hkstop% HkStep %hkstep%
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
wait 1000

LOG_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 6 LOG packets per sector.  A Step of 1 should be used to get all LOG packets.
;  There is a random number of LOG Sectors every 12 hours.
;
echo Configuring for LOG playback
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_log_playback_range LogStart %logstart% LogStop %logstop% LogStep %logstep%
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
wait 1000

SCI_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 SCI packets per sector.  SCI rate is 10 sec.
;  One SCI Record (full spectrum) can take 1 to 14 packets, depending on compression.
;  A Step of 30 is every 30th SCI Record (300 sec).
;  There are expected to be maximum of 60,480 SCI Packets every 12 hours if uncompressed.
;  There are expected about 4,320 SCI Packets every 12 hours for compression during quiet sun period.
;  A STEP value of 3 will have 30-sec science data cadence.
echo Configuring for SCI playback
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_science_playback_range SciStart %scistart% SciStop %scistop% SciStep %scistep%
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
wait 1000

ADCS_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 ADCS packets per sector.  So Step of 300 is every 300th sector (300 sec).
;  One ADCS Record has 4 packets.  ADCS Record rate is 1 sec.
;  There are expected to be 86,400 ADCS Sectors every 12 hours.
;  ADCS playback is probably in its own pass due to its large volume.
;  One can turn off ADCS playback by setting Step to 0.
;  For normal playback, one can use STEP = 240 for 2-min cadence
echo Configuring for ADCS playback
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_adcs_playback_range AdcsStart %adcsstart% AdcsStop %adcsstop% AdcsStep %adcsstep%
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
wait 1000

DIAG_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 DIAG packets per sector.  The DIAG rate is 1 sec when active.
;  The DIAG is not used except for debugging monitors so normally set STEP to 0.
echo Configuring for DIAG playback
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_diag_playback_range DiagStart %diagstart% DiagStop %diagstop% DiagStep %diagstep%
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
wait 1000

XIMG_PLAYBACK:
;  The Start-Stop are sectors numbers. The Step is for packet decimation.
;  There are 2 XIMG packets per sector.  A step of 1 should be used if doing XACT Image.
;  The XIMG is not used except for debugging XACT so normally set STEP to 0.
echo Configuring for XIMG playback
set cmdCnt = MINXSSCmdAcceptCnt + 1
while MINXSSCmdAcceptCnt < $cmdCnt
	set cmdTry = cmdTry + 1
	set_ximg_playback_range XimgStart %ximgstart% XimgStop %ximgstop% XimgStep %ximgstep%
	wait 3529
endwhile
set cmdSucceed = cmdSucceed + 1
wait 1000

START_PLAYBACK:
; Initiate Playback operation
echo WARNING: commands will be difficult to send during playback!
echo Type GO when ready to start Playback...
pause

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