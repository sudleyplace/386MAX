@echo off
REM $Header:   P:/PVCS/MAX/RAMBASIC/UDBIN2.BAV   1.1   01 Feb 1996 11:38:00   BOB  $
REM
REM Copy binary batch file for rambasic
REM

xc /vn /va	ret\rambasic.com x:\apps\386max
xc /vn /va	ret\rambasic.ssf x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a 	ret\rambasic.com x:\apps\386max
xc /n/a 	ret\rambasic.ssf x:\apps\386max

:end
