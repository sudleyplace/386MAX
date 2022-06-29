@echo off
REM $Header:   P:/PVCS/MAX/MAXHELP/MAKEHLP2.SRV   1.1   04 Nov 1995 22:15:00   HENRY  $
REM Makehelp subroutine source - generate help map file for a single project
REM %1 is the relative path of the RESOURCE.H file to process.
REM %2 is a prefix for symbols
REM %3 is a hex prefix for mappings (0x000, 0x008, 0x010, 0x018, etc.)
REM %4 is an optional modifier added to the extension

REM Nice idea, but not worth it...
rem #include "afxpriv.h"

REM Note the cute shenanigans we have to do here-
REM %3%_EMPTY%10000 is needed to expand %310000 properly
REM unless we use the equates from AFXPRIV.H

set _C=/
set _C=%_C%/

echo. >>hlp\max.hm%4
echo. >>hlp\max.hm%4
echo %_C% Help mappings for %2 %1 >>hlp\max.hm%4
echo. >>hlp\max.hm%4
echo %_C% Commands (ID_* and IDM_*) >>hlp\max.hm%4
makehm ID_,%2_HID_,%3%_EMPTY%10000 IDM_,%2_HIDM_,%3%_EMPTY%10000 %1 >>hlp\max.hm%4
echo. >>hlp\max.hm%4
echo %_C% Prompts (IDP_*) >>hlp\max.hm%4
makehm IDP_,%2_HIDP_,%3%_EMPTY%30000 %1 >>hlp\max.hm%4
echo. >>hlp\max.hm%4
echo %_C% Resources (IDR_*) >>hlp\max.hm%4
makehm IDR_,%2_HIDR_,%3%_EMPTY%20000 %1 >>hlp\max.hm%4
echo. >>hlp\max.hm%4
echo %_C% Dialogs (IDD_*) >>hlp\max.hm%4
makehm IDD_,%2_HIDD_,%3%_EMPTY%20000 %1 >>hlp\max.hm%4
echo. >>hlp\max.hm%4
echo %_C% Controls (IDC_* and IDW_*) >>hlp\max.hm%4
makehm IDC_,%2_HIDC_,%3%_EMPTY%50000 IDW_,%2_HIDW_,%3%_EMPTY%50000 %1 >>hlp\max.hm%4
echo. >>hlp\max.hm%4
echo %_C% Hit-Tests (IDHT_*) >>hlp\max.hm%4
makehm IDHT_,%2_HIDHT_,%3%_EMPTY%40000 %1 >>hlp\max.hm%4
