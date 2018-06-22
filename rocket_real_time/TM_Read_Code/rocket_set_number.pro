;
;  rocket_set_number
;
;	Set rocket default number and launch time
;
pro rocket_set_number, rnum

common rocket_common, rocket_number, launch_time, rocket_data_dir

if n_params() lt 1 then rnum = 0.0

rocket_number = rnum
if rnum eq 36.240 then begin
  launch_time = 16.*3600. + 58.*60. + 0.72
endif else if rnum eq 36.258 then begin
  launch_time = 18.*3600. + 32.*60. + 2.
endif else if rnum eq 36.275 then begin
  launch_time = 17.*3600. + 50.*60. + 0.
endif else if rnum eq 36.286 then begin
  launch_time = 19.*3600. + 30.*60. + 1.
endif else if rnum eq 36.290 then begin
  launch_time = 18.*3600. + 0.*60. + 0.
endif else if rnum eq 36.300 then begin
  launch_time = 19.*3600. + 15.*60. + 0.
endif else if rnum eq 36.318 then begin
  launch_time = 19.*3600. + 0.*60. + 0.
endif else if rnum eq 36.336 then begin
  launch_time = 19.*3600. + 0.*60. + 0.
endif else begin
  print, 'WARNING: invalid rocket number, so assuming 36.336'
  rocket_number = 36.336
  launch_time = 19.*3600. + 0.*60. + 0.
endelse

rocket_data_dir = getenv('rocket_dir')
if (strlen(rocket_data_dir) lt 1) then rocket_data_dir = 'Users/Shared/Projects/Rocket_Folder'
rocket_data_dir += '/Data_' + strtrim(long(rocket_number*1000.),2) + '/WSMR/'

return
end
