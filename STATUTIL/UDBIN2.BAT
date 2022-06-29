@echo off
REM $Header:   P:/PVCS/MAX/STATUTIL/UDBIN2.BAV   1.0   02 Apr 1996 16:54:02   HENRY  $
REM
REM Copy binary batch file for statutil
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
