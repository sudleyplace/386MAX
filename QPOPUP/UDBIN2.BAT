@echo off
REM ' $Header:   P:/PVCS/MAX/QPOPUP/UDBIN2.BAV   1.1   06 Nov 1995 19:31:14   BOB  $
REM
REM Copy binary batch file for qpopup
REM

xc /vn /va RET\QPOPUP.EXE x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    RET\QPOPUP.EXE x:\apps\386max

:end
