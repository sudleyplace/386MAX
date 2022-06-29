//
//  Header File for TLOCK322.h
//
//
#ifndef _THISHEADERFILE
	#define _THISHEADERFILE
#ifdef _DLL_
	#define TLOCK_API __declspec( dllexport )
#else
	#define TLOCK_API __declspec( dllimport )
#endif
// TSF File Read Errors
#define TLOCK_ERROR_WRONGVERSION	-5
#define TLOCK_ERROR_NOACCESSYET		-4
#define TLOCK_ERROR_FILEREAD		-3
#define TLOCK_ERROR_BADPASSWORD		-2
#define TLOCK_ERROR_FILENOTFOUND	-1
#define TLOCK_ERROR_SUCCESS			1 


#ifdef __cplusplus
extern "C"{
#endif

TLOCK_API long	_stdcall getUserNumMinutesUsed(LPCTSTR strPassword);
TLOCK_API int	_stdcall getUserNumExecutions(LPCTSTR strPassword);
TLOCK_API int	_stdcall getUserNumDaysLeft(LPCTSTR strPassword);
TLOCK_API long	_stdcall getUserState(LPCTSTR strPassword);
TLOCK_API int	_stdcall verifyTimeLock32(LPCTSTR lpszFileName, LPCTSTR strPassword, LPTSTR strResult);
TLOCK_API BOOL	_stdcall getUserName32(LPTSTR strResult);
TLOCK_API BOOL	_stdcall getRegNum32(LPTSTR strResult);
TLOCK_API long	_stdcall showMainDialogEx(LPCTSTR strPassword, HINSTANCE hInst, WORD wBMPID, LPCTSTR szMsg);
TLOCK_API long	_stdcall showMainDialog(LPCTSTR strPassword);
TLOCK_API BOOL	_stdcall trialEnvironmentOpen();
TLOCK_API BOOL	_stdcall trialEnvironmentClose();
TLOCK_API long	_stdcall invokeTimeLock32(	LPCTSTR lpszFileName, LPCTSTR strPassword, 
											HINSTANCE hInst, WORD wBMPID, LPCTSTR szMsg,
											LPTSTR strResult);

#ifdef __cplusplus
}
#endif

#endif