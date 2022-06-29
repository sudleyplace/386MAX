@echo off
:NEXT
if "%2" == "" goto PE
autokeyb E %1[cr]
shift
goto NEXT

:PE
c:\bin\pe /q /pc:\bin\pe2.pro %1
