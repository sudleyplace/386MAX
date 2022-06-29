@echo off
REM This is a batch file to run automatically all
REM   possible combinations of arguments to TEST24.
REM When running this batch file, ensure that no SWAT screens
REM   occur as well as no beeps (which TEST24 uses to signal
REM   an error).

x:\apps\386max\memlimit noswap,0
REM Re-enable ECHO so we can see the command line arguments.
echo on

test24
if errorlevel 1 pause

test24/v=0
if errorlevel 1 pause
test24/v=1
if errorlevel 1 pause
test24/v=2
if errorlevel 1 pause
test24/v=3
if errorlevel 1 pause
test24/v=4
if errorlevel 1 pause
test24/v=5
if errorlevel 1 pause

test24/p=0
if errorlevel 1 pause
test24/p=1
if errorlevel 1 pause
test24/p=2
if errorlevel 1 pause
test24/p=3
if errorlevel 1 pause
test24/p=4
if errorlevel 1 pause
test24/p=5
if errorlevel 1 pause

test24/p=0/v=0
if errorlevel 1 pause
test24/p=0/v=1
if errorlevel 1 pause
test24/p=0/v=2
if errorlevel 1 pause
test24/p=0/v=3
if errorlevel 1 pause
test24/p=0/v=4
if errorlevel 1 pause
test24/p=0/v=5
if errorlevel 1 pause

test24/p=1/v=0
if errorlevel 1 pause
test24/p=1/v=1
if errorlevel 1 pause
test24/p=1/v=2
if errorlevel 1 pause
test24/p=1/v=3
if errorlevel 1 pause
test24/p=1/v=4
if errorlevel 1 pause
test24/p=1/v=5
if errorlevel 1 pause

test24/p=2/v=0
if errorlevel 1 pause
test24/p=2/v=1
if errorlevel 1 pause
test24/p=2/v=2
if errorlevel 1 pause
test24/p=2/v=3
if errorlevel 1 pause
test24/p=2/v=4
if errorlevel 1 pause
test24/p=2/v=5
if errorlevel 1 pause

test24/p=3/v=0
if errorlevel 1 pause
test24/p=3/v=1
if errorlevel 1 pause
test24/p=3/v=2
if errorlevel 1 pause
test24/p=3/v=3
if errorlevel 1 pause
test24/p=3/v=4
if errorlevel 1 pause
test24/p=3/v=5
if errorlevel 1 pause

test24/p=4/v=0
if errorlevel 1 pause
test24/p=4/v=1
if errorlevel 1 pause
test24/p=4/v=2
if errorlevel 1 pause
test24/p=4/v=3
if errorlevel 1 pause
test24/p=4/v=4
if errorlevel 1 pause
test24/p=4/v=5
if errorlevel 1 pause

test24/p=5/v=0
if errorlevel 1 pause
test24/p=5/v=1
if errorlevel 1 pause
test24/p=5/v=2
if errorlevel 1 pause
test24/p=5/v=3
if errorlevel 1 pause
test24/p=5/v=4
if errorlevel 1 pause
test24/p=5/v=5
if errorlevel 1 pause

x:\apps\386max\memlimit swapfree
