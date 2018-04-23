echo off
tasklist /fi "imagename eq auto_pass_automation.exe" |find ":" > nul
if errorlevel 1 echo LASP Pass automation already running!
if NOT errorlevel 1 echo Starting LASP CubeSat pass automation!
if NOT errorlevel 1 start "auto_pass_automation" "auto_pass_automation.exe"
