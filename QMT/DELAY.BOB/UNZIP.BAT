@echo off
if "%1" == "" goto REFRESH

pkunzip delay %1 %2 %3 %4 %5 %6 %7 %8 %9

goto END

:REFRESH
pkunzip -f delay
:END
