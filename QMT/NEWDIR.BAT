@echo off
if "%1" == "" goto ERR
if "%2" == "" %0 %1 RET
if "%TWTEXT%" == "" goto ERR2
if exist P:\MAX\QMT\%1.DOC goto ERR3

REM Ensure we're creating the directory where the user wants it.
echo Create subdirectory %1.%TWTEXT% under
cd
echo Press Ctrl-Break if not . . .
pause

REM Create and change to local directory.
if not exist %1.%TWTEXT%\*.*			md %1.%TWTEXT%
						cd %1.%TWTEXT%

REM Create and change to P:\TWT directory.
if not exist P:\TWT\QMT\%1.%TWTEXT%\*.* 	md P:\TWT\QMT\%1.%TWTEXT%
						cd P:\TWT\QMT\%1.%TWTEXT%

REM Create local OEM and common subdirectories.
if not exist %2\*.*				md %2

REM Call NMAKE to copy .OBJ and other files to local disk.
nmaker /nologo /f p:\max\qmt\makefile %3 %4 %5 %6 %7 %8 %9 NEWDIR=Y FULLRE=1

REM Remove Archive bit from batch and PVCS files so FF/A lists only
REM  those files which have changed.
x:\apps\misc\fmode/n *.bat
x:\apps\misc\fmode/n pvcs.*

REM Copy executable files to P:\TWT\%1 for TWT purposes.
x:\apps\misc\xc/r   %2\ramexam.exe   p:
x:\apps\misc\xc/r   %2\ramexam.ssf   p:
x:\apps\misc\xc/r   %2\ramexam.map   p:

goto :END

:ERR
echo Syntax:  NEWDIR dirname [oem [flags]]
echo	where dirname is the name (without extension) of the
echo	directory to be created locally as well as in P:\TWT
echo	using the extension found in TWTEXT (e.g., BOB).
echo	OEM is an optional subdirectory name (default = BET)
echo	to be created on the local drive and flags are passed
echo	to NMAKE.  FLAGS are optional flags to be passed to NMAKE.

goto :END

:ERR2
echo Please define a Set statement for TWTEXT of up to three
echo characters to be used as a directory extension in P:\TWT.

goto :END

:ERR3
echo The specified directory name has already been used, based
echo upon the fact that there's a file P:\MAX\QMT\%1.DOC.

:END
