@echo off
REM $Header:   P:/PVCS/MAX/MAXCTRL/UDBIN2.BAV   1.1   25 Sep 1995 15:09:54   BOB  $
REM
REM Copy binary batch file for maxctrl
REM

xc /vn /va ret\w16\TOOLBOX.EXE x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    ret\w16\TOOLBOX.EXE x:\apps\386max

:end
