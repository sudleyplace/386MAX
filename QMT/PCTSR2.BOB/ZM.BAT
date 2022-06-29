@echo off
REM Run this batch file to create a version of RAMExam for Micron Technologies

if exist MIC\ramexam.exe del MIC\ramexam.exe
call mkrm
call qm
pkzip -f micron *.*
