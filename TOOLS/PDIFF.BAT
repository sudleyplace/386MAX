@echo off
if "%1" == "" goto ERR
if "%2" == "" goto NET

vdiff -b %1 %2 %3 %4 %5 %6 %7 %8 %9>e
goto COM

:NET
vdiff -b -r %1 %2 %3 %4 %5 %6 %7 %8 %9>e

:COM
call p e

goto EXIT

:ERR
echo Syntax:  PDIFF filename.ext

:EXIT
