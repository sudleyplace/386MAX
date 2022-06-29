@echo off
REM $Header:   P:/PVCS/MAX/CYASETUP/UDBIN2.BAV   1.1   02 Aug 1996 09:32:22   PETERJ  $
REM
REM Copy binary batch file for cyasetup
REM

xc /vn /va w16\d\setup.exe x:\apps\386max\cyasetup.exe

delay 10
if errorlevel 1 goto end

xc /n/a w16\d\setup.exe x:\apps\386max\cyasetup.exe

:end
