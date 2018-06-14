;+
; NAME:
;   rocket_csol_extract_hk
;
; PURPOSE:
;   Extract housekeeping telemetry points (hk) of interest and return it. 
;   That hk lives in a "fake" row 2000 of the image frame. This code expects to be given just that 2000th row.
;
; INPUTS:
;   csolRow2000 [uintarr]: The data in the 2000th row of the CSOL image frame that contains the metadata and hk. 
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set to print out additional information about how the processing is proceeding.
;   DEBUG:   Set to print out additional information useful for debugging.
;
; OUTPUTS:
;   hkCsol [stucture]: An anonymous structure that contains the hk of interest in engineering units (e.g., temperatures in ºC).
;                      May also contain the metadata.
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires JPMsystime, JPMPrintNumber
;
; EXAMPLE:
;   csolHk = rocket_csol_extract_hk(csolPacketData) ; provided csolPacketData corresponds to just row 2000
;
; MODIFICATION HISTORY:
;   2018-05-11: James Paul Mason: Wrote script.
;   2018-05-29: James Paul Mason: Field updates to get CSOL image and housekeeping working.
;   2018-06-11: Don Woodraska, Tom Woods, Alan Sims added inttime, rowperiod and rowperint
;-
FUNCTION rocket_csol_extract_hk, csolRow2000, $
                                 VERBOSE = VERBOSE, DEBUG = DEBUG

; Input check
IF n_elements(csolRow2000) LE 35 THEN BEGIN ; Filler starts at element 36
  message, /INFO, JPMsystime() + ' Expected to get only the >35 words from CSOL row 2000 but input contained ' + JPMPrintNumber(n_elements(csolRow2000), /NO_DECIMALS) + ' words.'
  return, !NULL
ENDIF

; Set up structure 
csolHk = {thermDet0: 0.0, thermDet1: 0.0, thermFPGA: 0.0, $
          current5V: 0.0, voltage5V: 0.0, $
          tecEnable: 0, fflEnable: 0, $ ; Treat as booleans
          sdStartFrameAddress: 0L, sdCurrentFrameAddress: 0, $
          rowPeriod: 0u, $
          rowPerInt: 0u, $
          intTime: 0.0}

; Extract telemetry points, convert to engineering units, and store in structure
csolHk.thermDet0 = rocket_csol_convert_temperatures(csolRow2000[10], /COEFF_SET_0) ; [ºC]
csolHk.thermDet1 = rocket_csol_convert_temperatures(csolRow2000[11], /COEFF_SET_1) ; [ºC]
csolHk.thermFPGA = rocket_csol_convert_temperatures(csolRow2000[12], /COEFF_SET_0) ; [ºC]
csolHk.current5V = 2500. * csolRow2000[13] / 8192. ; [mA]
csolHk.voltage5V = 10. * csolRow2000[14] / 4096. ; [V]
csolhk.rowPeriod = csolRow2000[16]
csolhk.rowPerInt = csolRow2000[17]
csolHk.tecEnable = csolRow2000[18] ; [bool] 1 = on, 0 = off
csolhk.fflEnable = csolRow2000[19] ; [bool] 1 = on, 0 = off
csolhk.sdStartFrameAddress = csolRow2000[21] ; First frame address of the data recording for the current power cycle
csolhk.sdCurrentFrameAddress = csolRow2000[22] ; Current frame address for data recording

;derived integration time
csolhk.intTime = (csolhk.rowPeriod + 1.) * (csolhk.rowPerInt + 1.) / (1.e6) ; integration time in seconds

return, csolhk

END