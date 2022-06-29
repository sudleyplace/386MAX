@echo off
REM $Header:   P:/PVCS/MAX/MAXIMIZE/UDBIN2.BAV   1.3   09 Oct 1995 14:32:52   BOB  $
REM
REM Copy binary batch file for maximize
REM

xc /vn /va REB\MAX.EXE	x:\apps\386max\maximize.*
xc /vn /va REB\MAX.SSF	x:\apps\386max\maximize.*

delay 10
if errorlevel 1 goto end

xc /n/a    REB\MAX.EXE	x:\apps\386max\maximize.*
xc /n/a    REB\MAX.SSF	x:\apps\386max\maximize.*

:end
