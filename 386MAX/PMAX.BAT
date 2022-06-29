@echo off
REM Edit QMAX*.ASM and QMAX*.INC files
REM   To edit a .ASM file only, use   %0 xxx   where xxx
REM	is the three-letter file ID (e.g. VCP for QMAX_VCP.ASM).
REM   To edit a .INC file only, use   %0 . xxx	where xxx
REM	is the three-letter file ID (e.g. VCP for QMAX_VCP.INC).
REM   To edit both the .ASM and .INC files, use   %0 xxx yyy
REM	where xxx and yyy are the three-letter fiel IDs.

if "%2" == "" goto ASM
if "%1" == "." goto INC

Set PMAXASM=
if not exist qmax%1.asm Set PMAXASM=%MAXDIR%
Set PMAXINC=
if not exist qmax%2.inc Set PMAXINC=%MAXDIR%

call p %PMAXASM%qmax%1.asm %PMAXINC%qmax%2.inc

goto END

:INC
Set PMAXINC=
if not exist qmax%2.inc Set PMAXINC=%MAXDIR%

call p %PMAXINC%qmax%2.inc

goto END

:ASM
Set PMAXASM=
if not exist qmax%1.asm Set PMAXASM=%MAXDIR%
call p %PMAXASM%qmax%1.asm

:END
