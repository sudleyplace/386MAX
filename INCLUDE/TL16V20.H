//
//  Header File tl16v20.h
//
//

#define TLOCK_API __export __far __pascal

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

long TLOCK_API getUserNumMinutesUsed(LPCTSTR strPassword);
int TLOCK_API getUserNumExecutions(LPCTSTR strPassword);
int TLOCK_API getUserNumDaysLeft(LPCTSTR strPassword);
long TLOCK_API getUserState(LPCTSTR strPassword);
int TLOCK_API verifyTimeLock16(LPCTSTR lpszFileName, LPCTSTR strPassword, LPTSTR strResult);
int TLOCK_API getUserName(LPCTSTR strPassword, LPTSTR strResult);
int TLOCK_API getRegNum(LPCTSTR strPassword, LPTSTR strResult);
long TLOCK_API showMainDialog16(HWND hwndParent, LPCTSTR strKey, BOOL b3dCtrls);
long TLOCK_API showMainDialog16Ex(HWND hwndParent, LPCTSTR strKey,
								 HINSTANCE hInst, WORD wBMPID, LPCTSTR szMsg,
								 BOOL b3dCtrls);
int TLOCK_API trialEnvironmentOpen16(LPCTSTR lpszFileName, LPCTSTR strPassword);
int TLOCK_API trialEnvironmentClose16(LPCTSTR lpszFileName, LPCTSTR strPassword);
long TLOCK_API invokeTimeLock16(HWND hwndParent, LPCTSTR lpszFileName, LPCTSTR lpszPassword, 
								  HINSTANCE hInst, WORD wBMPID, LPCTSTR szMsg,
								  LPTSTR strResult, BOOL b3dCtrls);

#ifdef __cplusplus
}
#endif

