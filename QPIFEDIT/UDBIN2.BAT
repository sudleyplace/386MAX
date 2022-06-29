@echo off
REM $Header:   P:/PVCS/MAX/QPIFEDIT/UDBIN2.BAV   1.1   02 Oct 1995 14:15:58   BOB  $
REM
REM Copy binary batch file for qpifedit
REM

xc /vn /va RET\QPIFEDIT.EXE x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    RET\QPIFEDIT.EXE x:\apps\386max

:end
