;
; NAME:
;   set_ephemeris
;
; PURPOSE:
;   Set the ephemeris necessary for ADCS to do fine pointing
;
;	*****  CRITICAL - you have to edit the ephemeris values appropriate for this pass
;	*****	The ephemeris values are in lines 50-61 and should be calculated with time during pass 
;	*****   Ideally, this ephemeris time should be within 120 sec of current ADCS time when script is run
;
; ISSUES:
;   Is there a recommend fine reference point telemetry item?
;
; MODIFICATION HISTORY
;   2015/03/24: James Paul Mason: Initial script
;	2015/08/11: Tom Woods: updates for calling hello_minxss and having FINISH section
;	2016/01/18: Tom Woods: provided comments that give instructions on how to calculate the ephemeris values
;	2016/05/24: Tom Woods: fast version of commission_set_ephemeris without any Pauses or setup commands
;	2016/05/28: Tom Woods: updated for 5/29/16 02:48:00 UT ephemeris
;

declare cmdCnt dn16
declare cmdTry dn16l
declare cmdSucceed dn16l
declare xactCmdCnt dn16
declare cmdTryExit dn16l
declare cmdTryNumber dn16l

;  Assumes 4.3 sec command tries (twice per beacon)
;  Exit after 12 minutes ==> 720 sec / 4.3 = 167 tries
set cmdTryExit = 167
set cmdTry = 1
set cmdTryNumber = 1

; variables for setting ephemeris for ADCS
declare ephYear dn16
declare ephMonth dn16
declare ephDay dn16
declare ephHour dn16
declare ephMinute dn16
declare ephSecond dn16
declare ephPosX double64
declare ephPosY double64
declare ephPosZ double64
declare ephVelX double64
declare ephVelY double64
declare ephVelZ double64

; Set Ephemeris UTC time, Position in km, and Velocity in km/sec in J2000 format
;	On MinXSS Processing Mac computer do the following to get the Ephemeris Values
;		; YEAR is format like 2016, but ephYear format below is YEAR - 2000  
;	IDL> minxss_satellite_pass, /verbose    ; this will update the latest TLE (takes several seconds)   
;	IDL> time = ymd2jd( YEAR, MONTH, DAY + HOUR/24.D0 + MINUTE/(24.*60.D0) + SECOND/(24.*3600.D0) )
;	IDL> spacecraft_location, time, location, sunlight, eci_pv=pv
;	IDL> print, 'Position X-Y-Z (km)     = ', pv[0:2]
;	IDL> print, 'Velocity X-Y-Z (km/sec) = ', pv[3:5]
; Then you can sanity check those numbers by entering them into the ECEF row of https://www.oc.nps.edu/oc2902w/coord/llhxyz.htm
; And you should get a latitude/longitude/height corresponding to Boulder and the expected altitude of your spacecraft. 
;
;	*****  Lines 50-61 MUST be edited as Time During Pass when you will click GO button *****
set ephYear = <TephYear>
set ephMonth = <TephMonth>
set ephDay = <TephDay>
set ephHour = <TephHour>
set ephMinute = <TephMinute>
set ephSecond = <TephSecond>
set ephPosX =  <TephPosX>
set ephPosY = <TephPosY>
set ephPosZ = <TephPosZ>
set ephVelX = <TephVelX>
set ephVelY = <TephVelY>
set ephVelZ = <TephVelZ>

SET_EPHEMERIS:

;	Load ephemeris and wait until Refs Valid = 1 = YES = TRUE
LOAD_EPHEMERIS:
set xactCmdCnt = MINXSSXactCmdAccept + 1
while MINXSSXactCmdAccept < $xactCmdCnt
	set cmdTry = cmdTry + 1
	adcs_InitPosVelUtcGreg Year $ephYear Mon $ephMonth Day $ephDay Hour $ephHour Min $ephMinute Sec $ephSecond millisec 0 PosX $ephPosX PosY $ephPosY PosZ $ephPosZ VelX $ephVelX VelY $ephVelY VelZ $ephVelZ
		if cmdTry > cmdTryExit   
		goto DONE_ERROR
	endif
	wait 4200
endwhile
set cmdSucceed = cmdSucceed + 1

echo Ephemeris has been successfully loaded.

DONE_ERROR:
echo ERROR finishing the script during the pass !!!
print cmdTryNumber

FINISH:

echo COMPLETED set_ephemeris script

print cmdTry
print cmdSucceed
