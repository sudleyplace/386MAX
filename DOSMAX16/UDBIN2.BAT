@echo off
REM $Header:   P:/PVCS/MAX/DOSMAX16/UDBIN2.BAV   1.0   25 Oct 1995 12:59:04   BOB  $
REM
REM Copy binary batch file for dosmax16
REM

xc /vn /va w16\d\PRJ.exe x:\apps\386max
xc /vn /va w16\d\PRJ.dll x:\apps\386max
xc /vn /va w16\d\PRJ.lib p:\max\lib

delay 10
if errorlevel 1 goto end

xc /n/a w16\d\PRJ.exe x:\apps\386max
xc /n/a w16\d\PRJ.dll x:\apps\386max
xc /n/a w16\d\PRJ.lib p:\max\lib

:end
