@echo off
echo Sets environment variables for FREEMAX build

REM Force to empty to ensure we use the ones from the MAKEFILE
Set INCLUDE=
Set LIB=
Set H=
Set I=
Set BINDIR=

REM Now set stuff we need
Set COPYCMD=/Y
Set MAXROOT=R:\MAX\
Set MBLDOUT=x:\apps\release\freemax.out
Set MBLDREQ=x:\apps\release\freemax\buildreq\
Set BLDOUT=%MBLDOUT%
Set BLDREQ=%MBLDREQ%
Set LNKCMD=
Set PATH=%MAXROOT%TOOLS;X:\APPS\PVCS;Y:\PUBLIC
Set USER=BOB
Set MSVC16=M:\
Set MSVC32=N:\

chdrv %MAXROOT%
if not "%1" == "" cd %1
