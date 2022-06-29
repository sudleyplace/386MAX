@echo off
REM $Header:   P:/PVCS/MAX/VXD/UDBIN2.BAV   1.1   25 Sep 1995 11:03:00   BUILD  $
REM
REM Copy binary batch file for vxd
REM

xc /vn /va BCF\386MAX.VXD x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    BCF\386MAX.VXD x:\apps\386max

:end
