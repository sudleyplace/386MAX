@echo off
Set NMAKE=NMAKE
if "%windir%" == "" Set NMAKE=NMAKER
%NMAKE% /nologo /f makefile FULLRE=1 BETA=0 PCTSR=0 %1 %2 %3 %4 %5 %6 %7 %8 %9
Set NMAKE=
