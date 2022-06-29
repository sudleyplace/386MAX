@echo off
REM $Header:   P:/PVCS/MAX/MEMLIMIT/UDBIN2.BAV   1.1   01 Feb 1996 11:02:40   BOB  $
REM
REM Copy binary batch file for memlimit
REM

xc /vn /va	ret\memlimit.exe x:\apps\386max
xc /vn /va	ret\memlimit.ssf x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a 	ret\memlimit.exe x:\apps\386max
xc /n/a 	ret\memlimit.ssf x:\apps\386max

:end
