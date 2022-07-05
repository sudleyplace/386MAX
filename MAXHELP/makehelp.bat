@echo off
REM $Header:   P:/PVCS/MAX/MAXHELP/MAKEHELP.SRV   1.1   04 Nov 1995 22:15:10   HENRY  $
REM Makehelp.src - C preprocessor input for MAKEHELP.BAT
REM Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.

REM -- Ensure help output directory exists
vdir -c hlp

REM -- First make map file from App Studio generated resource.h files.
REM -- Note that MFC applications get some extra standard identifiers
REM -- supplied by helpafx.h.  We DO NOT use afxhelp.hm any longer.

xc /r hlp\maxhelp.hmc hlp\max.hm

call makehlp2 ..\winmxmz\resource.h WMX 0x010
call makehlp2 helpafx.h             WMX 0x010

REM -- Extract sections we need from MAXHELP.HPJ
%MAXROOT%tools\getsect maxhelp.hpj windows	 >hlp\maxhelp.win
%MAXROOT%tools\getsect maxhelp.hpj config	 >hlp\maxhelp.cfg
%MAXROOT%tools\getsect maxhelp.hpj map		 >hlp\maxhelp.hm

REM -- Make help for entire product
call %MAXROOT%tools\hcp _MAXHELP.hpj

echo.
