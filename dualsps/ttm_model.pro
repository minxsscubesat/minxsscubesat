;
;	ttm_model.pro
;
;	Simulation of TTM control algorithm for LASP TTM-SPS Generation 3
;
;	INPUT:
;		Quad_Data	SPS Quad Data in relative units (* 900 = arc-sec)
;						Data[0] = seconds,  Data[1] = Quad value from -1 to 1
;		/gain		Option to specify the gain (default is 0.1)
;		/pzt_factor	Option to specify the PZT Volts / arcsec (default 0.4848 V/asec)
;		/dac_max	Option to specify the DAC maximum value (default is for 12-bit DAC)
;		/volt_max	Option to specify the PZT maximum value (default is 30 V)
;		/pid_param	Option to specify the PID parameters (Kp, Ki, Kd)
;						Default is PID is simple mode with Kp=1.0, Ki=0.0, Kd=0.0
;		/mean_run	Option to specify the running mean number (default is 1)
;		/time_step	Option to specify time step for TTM control (default is 0.012 sec)
;		/auto_tune	Option to auto tune the PID parameters
;		/verbose	Option to print model messages
;		/debug		Option to debug the code / stop during execution
;
;	OUTPUT:
;		Plot of predicted control angle
;
;	HISTORY:
;		6/12/21		T. Woods,  Model for TTM Gen 3, FSW version 3.08
;
pro ttm_model, quad_data, gain=gain, pzt_factor=pzt_factor, dac_max=dac_max, volt_max=volt_max, $
						pid_param=pid_param, mean_run=mean_run, time_step=time_step, $
						auto_tune=auto_tune, verbose=verbose, debug=debug

;
;	Check Input Values
;
if n_params() lt 1 then begin
	print, 'USAGE: ttm_model, quad_data, gain=gain, pzt_factor=pzt_factor, dac_max=dac_max, $ '
	print, '                          volt_max=volt_max, pid_param=pid_param, mean_run=mean_run, $'
	print, '                          time_step=time_step, verbose=verbose, debug=debug'
	return
endif

;	GAIN is unitless and default is 0.1
if not keyword_set(gain) then gain = 0.1
	if (gain lt 0.001) then gain = 0.001
	if (gain gt 100.) then gain = 100.

;	PZT_FACTOR has units of Volts / arc-sec and default of 0.4848 V/asec for PI S-330.2 and CDM telescope
if not keyword_set(pzt_factor) then pzt_factor = 0.4848
	if (pzt_factor lt 0.01) then pzt_factor = 0.01
	if (pzt_factor gt 10.) then pzt_factor = 10.

;	DAC_MAX has units of DN and default is 2.^12
if not keyword_set(dac_max) then dac_max = 2.^12
	if (dac_max lt 2.^8) then dac_max = 2.^8
	if (dac_max gt 2.^24) then dac_max = 2.^24

;	VOLT_MAX has units of Volts and default is 30 V
if not keyword_set(volt_max) then volt_max = 30.
	if (volt_max lt 2.) then volt_max = 2.
	if (volt_max gt 120.) then volt_max = 120.

;	PID_PARAM are unitless and default is Kp=1.0, Ki=0.0, Kd=0.0 (PID is simple P control)
if not keyword_set(pid_param) then pid_param = [1.0, 0.0, 0.0]
	if (pid_param[0] lt 0.01) then pid_param[0] = 0.01
	if (pid_param[0] gt 100.) then pid_param[0] = 100.
	if (pid_param[1] lt 0.0) then pid_param[1] = 0.0
	if (pid_param[1] gt 100.) then pid_param[1] = 100.
	if (pid_param[2] lt 0.0) then pid_param[2] = 0.0
	if (pid_param[2] gt 100.) then pid_param[2] = 100.

;	MEAN_RUN is unitless and default is 1 (no running mean)
if not keyword_set(mean_run) then mean_run = 1 else mean_run = long(mean_run)
	if (mean_run lt 1) then mean_run = 1L
	if (mean_run gt 101L) then mean_run = 101L

;	TIME_STEP has units of seconds and default is 0.012 sec (will be faster for EM/FM)
if not keyword_set(time_step) then time_step = 0.012
	if (time_step lt 0.001) then time_step = 0.001
	if (time_step gt 0.1) then time_step = 0.1

;  no special checks for AUTO_TUNE

if keyword_set(debug) then verbose = 1
if keyword_set(verbose) then begin
	; print the Control Parameters
	; ... TO DO ...
endif

;
;	Start model run with the Quad_Data
;		1.  Configure PID control algorithm
;		2.  Convert Quad_Data into arc-sec units
;		3.  Running Mean is performed before calling PID control algorithm
;		4.  LOOP: Call PID control algorithm (pid_compute) for each data point
;

;	1.  Configure PID control algorithm
pid_sum = 0.0

;	2.  Convert Quad_Data into arc-sec units and with right time step
sod = reform(quad_data[0,*])
num_total = long((sod[-1] - sod[0]) / time_step) + 1L
time = findgen(num_total) * time_step + sod[0]
angle_factor = 15. * 60.	; convert Quad value to arc-sec
data = interpol(reform(quad_data[1,*]), sod, time) * angle_factor

;	3.  Running Mean is performed before calling PID control algorithm
if (mean_run gt 1) then begin
	sm_data = smooth( data, mean_run, /edge_trun )
	; shift smoothed data forward by mean_run/2 points
	k_last = mean_run/2L
	sm_data = shift( sm_data, k_last )
	for k=0,k_last-1 do sm_data[k] = sm_data[k_last]
endif else sm_data = data  ; no running mean

;	4.  LOOP: Call PID control algorithm (pid_compute) for each data point

;
;	Plot the model run results
;

if keyword_set(debug) then stop, 'DEBUG at end of ttm_model ...'
return
end
