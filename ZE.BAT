@echo off
REM Run this batch file to create a version of RAMExam for Evaluations

if exist ret\ramexam.exe del ret\ramexam.exe
call mkev
copy ret\ramexam.exe .
call qe
pkzip -f eval807 *.*
