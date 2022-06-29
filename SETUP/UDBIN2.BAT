@echo off
REM $Header:   P:/PVCS/MAX/SETUP/UDBIN2.BAV   1.1   02 Aug 1996 09:28:08   PETERJ  $
REM
REM Copy binary batch file for syssaver
REM

xc /vn /va w16\d\PRJ.lib p:\max\lib

delay 10
if errorlevel 1 goto end

xc /n/a w16\d\PRJ.lib p:\max\lib

:end
