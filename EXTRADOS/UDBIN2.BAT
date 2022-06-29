@echo off
REM $Header:   P:/PVCS/MAX/EXTRADOS/UDBIN2.BAV   1.1   29 Sep 1995 19:11:18   BOB  $
REM
REM Copy binary batch file for extrados
REM

xc /vn /va RET\EXTRADOS.MAX x:\apps\386max
xc /vn /va RET\EXTRADOS.SSF x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    RET\EXTRADOS.MAX x:\apps\386max
xc /n/a    RET\EXTRADOS.SSF x:\apps\386max

:end
