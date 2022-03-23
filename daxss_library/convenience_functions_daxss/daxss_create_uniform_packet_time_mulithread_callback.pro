;+
; NAME:
;   daxss_create_uniform_packet_time_mulithread_callback
;
; PURPOSE:
;   Callback procedure for the multi-threading in daxss_create_uniform_packet_times.
;   Since each thread is in parallel, a procedure is needed to respond when the thread completes
;   its task. For this particular implementation, all that needs to be done is to set a flag (userdata)
;   indicating that the thread has completed processing.
;
; INPUTS:
;   status [?]:   Part of IDL_IDL_Bridge
;   error [?]:    Part of IDL_IDL_Bridge
;   node [?]:     Part of IDL_IDL_Bridge
;   userdata [?]: Part of IDL_IDL_Bridge
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   None
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss code package
;
; EXAMPLE:
;   None -- this code should only be called internally by daxss_create_uniform_packet_times
;
; MODIFICATION HISTORY:
;   2016/06/27: James Paul Mason: Wrote script.
;-
PRO daxss_create_uniform_packet_time_mulithread_callback, status, error, node, userdata
STOP
node->setProperty, userData = 2

END
