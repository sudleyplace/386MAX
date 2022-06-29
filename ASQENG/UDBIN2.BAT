@echo off
REM $Header:   P:/PVCS/MAX/ASQENG/UDBIN2.BAV   1.0   15 Aug 1995 13:43:20   HENRY  $
REM
REM Copy binary batch file for asqeng
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
