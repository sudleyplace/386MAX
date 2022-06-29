@echo off
REM $Header:   P:/PVCS/MAX/386LOAD/UDBIN2.BAV   1.1   10 Nov 1995 22:51:04   BOB  $
REM
REM Copy binary batch file for 386load
REM

xc /vn /va BET\386LOAD.COM	x:\apps\386max
xc /vn /va BET\386LOAD.SYS	x:\apps\386max
xc /vn /va BET\DRVLOAD.SSF	x:\apps\386max
xc /vn /va BET\TSRLOAD.SSF	x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    BET\386LOAD.COM	x:\apps\386max
xc /n/a    BET\386LOAD.SYS	x:\apps\386max
xc /n/a    BET\DRVLOAD.SSF	x:\apps\386max
xc /n/a    BET\TSRLOAD.SSF	x:\apps\386max

:end
