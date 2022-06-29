@echo off
REM $Header:   P:/PVCS/MAX/SETUP32/UDBIN2.BAV   1.1   16 Sep 1996 08:57:16   PETERJ  $
REM
REM Copy binary batch file for setup32
REM

xc /vn /va w16\d\PRJ.lib p:\max\lib

delay 10
if errorlevel 1 goto end

xc /n/a w16\d\PRJ.lib p:\max\lib

:end
