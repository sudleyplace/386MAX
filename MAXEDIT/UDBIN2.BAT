@echo off
REM $Header:   P:/PVCS/MAX/MAXEDIT/UDBIN2.BAV   1.2   28 Sep 1995 11:54:46   BOB  $
REM
REM Copy binary batch file for maxedit
REM

xc /vn /va RET\W16\MAXEDIT.EXE	x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    RET\W16\MAXEDIT.EXE	x:\apps\386max

:end
