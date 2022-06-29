//' $Header:   P:/PVCS/MAX/STATUTIL/SEH.C_V   1.0   25 Sep 1996 11:25:28   BOB  $

//*******************************************************
//	Structured Exception Handle Routines
//
//	This module is compiled as a _WIN32 app only
//*******************************************************

#define STRICT
#pragma pack (1)
#include <windows.h>
#include <dbgbrk.pro>


#ifdef _WIN32
#ifdef DEBUG
//****************************************************************************
//	DispFault ()
//
//	Display information about a fault
//****************************************************************************

DWORD DispFault (PEXCEPTION_POINTERS pEP, LPSTR lpszAppName, BOOL bDebug)

{
	char szTemp[1204];
	int iLen = 0;
	
#define EC(a)									\
	case a: 									\
		wsprintf (szTemp + iLen,				\
				  "Exception code:  %s\r\n",    \
				  #a);							\
		break;
	
	switch (pEP->ExceptionRecord->ExceptionCode)
	{
		EC (EXCEPTION_ACCESS_VIOLATION)
		EC (EXCEPTION_ARRAY_BOUNDS_EXCEEDED)
		EC (EXCEPTION_BREAKPOINT)
		EC (EXCEPTION_DATATYPE_MISALIGNMENT)
		EC (EXCEPTION_FLT_DENORMAL_OPERAND)
		EC (EXCEPTION_FLT_DIVIDE_BY_ZERO)
		EC (EXCEPTION_FLT_INEXACT_RESULT)	
		EC (EXCEPTION_FLT_INVALID_OPERATION)
		EC (EXCEPTION_FLT_OVERFLOW) 
		EC (EXCEPTION_FLT_STACK_CHECK)	
		EC (EXCEPTION_FLT_UNDERFLOW)
		EC (EXCEPTION_ILLEGAL_INSTRUCTION)	
		EC (EXCEPTION_IN_PAGE_ERROR)
		EC (EXCEPTION_INT_DIVIDE_BY_ZERO)	
		EC (EXCEPTION_INT_OVERFLOW) 
		EC (EXCEPTION_INVALID_DISPOSITION)	
		EC (EXCEPTION_NONCONTINUABLE_EXCEPTION) 
		EC (EXCEPTION_PRIV_INSTRUCTION) 
		EC (EXCEPTION_SINGLE_STEP)	
		EC (EXCEPTION_STACK_OVERFLOW)
		
		default:
			wsprintf (szTemp + iLen,
					  "Exception code:  %08lX\r\n",
					  pEP->ExceptionRecord->ExceptionCode);
	
	} // End SWITCH
	
	iLen = lstrlen (szTemp);
	wsprintf (szTemp + iLen, "Flags: %08lX\r\n", pEP->ExceptionRecord->ExceptionFlags);
	
	iLen = lstrlen (szTemp);
	wsprintf (szTemp + iLen, "Address: %08lX\r\n", pEP->ExceptionRecord->ExceptionAddress);
	
	iLen = lstrlen (szTemp);
	wsprintf (szTemp + iLen, "# parameters: %08lX\r\n", pEP->ExceptionRecord->NumberParameters);
	
	if (bDebug)
	{
		lstrcat (szTemp, "\r\n\r\nDo you wish to Close (Yes) or Debug (No)?\r\n");

		if (IDYES == MessageBox (GetFocus (), szTemp, lpszAppName, MB_ICONSTOP | MB_YESNO))
			return (DWORD) EXCEPTION_EXECUTE_HANDLER;

		DbgBrk ();
		
		return (DWORD) EXCEPTION_CONTINUE_EXECUTION;
	} else
	{
		MessageBox (GetFocus (), szTemp, lpszAppName, MB_ICONSTOP);

		return (DWORD) EXCEPTION_EXECUTE_HANDLER;
	} // End IF

} // End DispFault ()
#endif
#endif


//***************************************************************************
//	End of File: SEH.C
//***************************************************************************
