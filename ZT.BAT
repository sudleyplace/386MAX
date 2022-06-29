@echo off
REM Run this batch file to create a version of RAMExam for Tandon Corp.

if exist TAN\ramexam.exe del TAN\ramexam.exe
call mkrt
call qt
pkzip -f tandon *.*
