@echo off
REM $Header:   P:/PVCS/MAX/ROMSRCH/UDBIN2.BAV   1.1   28 Sep 1995 10:45:54   BOB  $
REM
REM Copy binary batch file for romsrch
REM

xc /vn /va RET\ROMSRCH.COM x:\apps\386max
xc /vn /va RET\ROMSRCH.SSF x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    RET\ROMSRCH.COM x:\apps\386max
xc /n/a    RET\ROMSRCH.SSF x:\apps\386max

:end
