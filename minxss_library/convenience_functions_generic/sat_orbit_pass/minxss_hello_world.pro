;
; minxss_hello_world
; 
; Simple procedure to print Hello World into file in TLE_dir/ to verify CRON job is working.
; 
; 
pro minxss_hello_world

;
; Get TLE path
;     default is to use directory $TLE_dir
;
;  slash for Mac = '/', PC = '\'
;  File Copy for Mac = 'cp', PC = 'copy'
if !version.os_family eq 'Windows' then begin
    slash = '\'
    file_copy = 'copy '
    file_delete = 'del /F '
endif else begin
    slash = '/'
    file_copy = 'cp '
    file_delete = 'rm -f '
endelse

;
; Get path for TLE / pass time data (as created by plan_satellite_pass.pro)
;
path_name = getenv('TLE_dir')
if strlen(path_name) gt 0 then begin
  if ((strpos(path_name,slash,/reverse_search)+1) lt strlen(path_name)) then path_name += slash
endif
; else path_name is empty string
print, '*** TLE path = ', path_name

openw, 1, path_name+'minxss_hello_world.txt'
printf,1,'Hello World from MinXSS !'
close,1

return
end
