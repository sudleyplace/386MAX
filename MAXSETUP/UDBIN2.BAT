@echo off
REM $Header:   P:/PVCS/MAX/MAXSETUP/UDBIN2.BAV   1.1   25 Sep 1995 14:05:02   BOB  $
REM
REM Copy binary batch file for maxsetup
REM

xc /vn /va ret\w16\setup.exe x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    ret\w16\setup.exe x:\apps\386max

:end
