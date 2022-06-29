@echo off
REM $Header:   P:/PVCS/MAX/386DISK/UDBIN2.BAV   1.1   01 Feb 1996 10:46:04   BOB  $
REM
REM Copy binary batch file for 386disk
REM

xc /vn /va	ret\386disk.sys x:\apps\386max
xc /vn /va	ret\386disk.ssf x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a 	ret\386disk.sys x:\apps\386max
xc /n/a 	ret\386disk.ssf x:\apps\386max

:end
