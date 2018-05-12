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
;   hkCsol [stucture]: An anonymous structure that contains the hk of interest in engineering units (e.g., temperatures in ºC].
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
;-
FUNCTION rocket_csol_extract_hk, csolRow2000, $
                                 VERBOSE = VERBOSE, DEBUG = DEBUG

; Input check
IF n_elements(csolRow2000) NE 439 THEN BEGIN
  message, /INFO, JPMsystime() + ' Expected to get only the 439 words from CSOL row 2000 but input contained ' + JPMPrintNumber(n_elements(csolRow2000), /NO_DECIMALS) + ' words.'
  return, -1
ENDIF

; Set up structure 
csolHk = {hkThermDet0: 0.0, hkThermDet1: 0.0, hkThermFPGA: 0.0, $
          hkCurrent5V: 0.0, hkVoltage5V: 0.0, $
          setTECEnable: 0, setFFLEnable: 0, $ ; Treat as booleans
          sdStartFrameAddress: 0L, sdCurrentFrameAddress: 0}

; Extract telemetry points, convert to engineering units, and store in structure
; Note: Each word (element of the csolRow2000 array) is 16 bits (i.e., 2 bytes)
; TODO: Do I need to do ishft() on csolRow2000[] ? 
csolHk.hkThermDet0 = (csolRow2000[10] + 0.5) * 10000. / (4095.5 - csolRow2000[10]) ; [ºC] TODO: Is this really ºC?
csolHk.hkThermDet1 = csolRow2000[11] ; TODO: Need conversion equation for this thermistor
csolHk.hkThermFPGA = (csolRow2000[12] + 0.5) * 10000. / (4095.5 - csolRow2000[12]) ; [ºC] TODO Is this really ºC? Same kind of thermistor as ThermDet0
csolHk.hkCurrent5V = 2500. * csolRow2000[13] / 8192. ; [mA]
csolHk.hkVoltage5V = 10. * csolRow2000[14] / 4096. ; [V]
csolHk.setTECEnable = csolRow2000[18] ; [bool] 1 = on, 0 = off
csolhk.setFFLEnable = csolRow2000[19] ; [bool] 1 = on, 0 = off
csolhk.sdStartFrameAddress = csolRow2000[21] ; First frame address of the data recording for the current power cycle
csolhk.sdCurrentFrameAddress = csolRow2000[22] ; Current frame address for data recording

return, csolhk

END