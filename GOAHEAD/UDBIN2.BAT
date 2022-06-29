@echo off
REM $Header:   P:/PVCS/MAX/GOAHEAD/UDBIN2.BAV   1.1   29 Sep 1995 19:30:04   BOB  $
REM
REM Copy binary batch file for goahead
REM

xc /vn /va RET\GOAHEAD.DRV x:\apps\386max
xc /vn /va RET\GOAHEAD.EXE x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    RET\GOAHEAD.DRV x:\apps\386max
xc /n/a    RET\GOAHEAD.EXE x:\apps\386max

:end
