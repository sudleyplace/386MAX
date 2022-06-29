@echo off
Set NMAKE=NMAKE
if "%windir%" == "" Set NMAKE=NMAKER
%NMAKE% /nologo /f makefile FULLRE=1 BETA=1 PCTSR=1 LIGHTS=1 %1 %2 %3 %4 %5 %6 %7 %8 %9
Set NMAKE=
