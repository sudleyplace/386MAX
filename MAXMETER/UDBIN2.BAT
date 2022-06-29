@echo off
REM $Header:   P:/PVCS/MAX/MAXMETER/UDBIN2.BAV   1.2   25 Sep 1995 14:55:10   BOB  $
REM
REM Copy binary batch file for maxmeter
REM

xc /vn /va ret\w16\MAXMETER.EXE x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    ret\w16\MAXMETER.EXE x:\apps\386max

:end
