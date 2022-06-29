// $Header:   P:/PVCS/MAX/DOSMAX32/DOSMAX32.CPV   1.3   26 Feb 1996 12:50:16   BOB  $
//
//  MODULE:   dosmax32.cpp
//
// Purpose:  Implements the class factory code as well as CShellExt::QI,
//	     CShellExt::AddRef and CShellExt::Release code.

#include "priv.h"
#include "resource.h"

extern "C" {
///#include <tlhelp32.h>

#define W32SUT_32
#include <w32sut.h>
}

//
// Initialize GUIDs (should be done only and at-least once per DLL/EXE)
//
#pragma data_seg(".text")
#define INITGUID
#include <initguid.h>
#include <shlguid.h>
#include "dosmax32.h"
#pragma data_seg()

//
// Global variables
//
UINT	  g_cRefThisDll = 0;	// Reference count of this DLL.
HINSTANCE g_hmodThisDll = NULL; // Handle to this DLL itself.
char UT16DLLPath[MAX_PATH];
const char	UT16DLL[]  = "DOSMAX16.DLL",
			UT16Proc[] = "UT16Proc";
BOOL g_UTReg = FALSE;			// Whether or not we UTRegister()ed
BOOL fDebug = FALSE;			// Whether or not we're in a debuggin' mood
UT32PROC ppfn16Proc;			// Handle from UTRegister()
char szAppName[] = "DOSMAX";
char szQMAXPath[MAX_PATH];		// Path to QMAX files ending with backslash
///MODULEENTRY32 me32;


// Display Last Error
void DispLastError (int LastErr)
{
	char * pTemp;
	char szTemp[128];

	switch (LastErr)
	{
		case ERROR_NOT_ENOUGH_MEMORY:
			pTemp = "Not enough memory";
			break;

		case ERROR_FILE_NOT_FOUND:
			pTemp = "File not found";
			break;

		case ERROR_PATH_NOT_FOUND:
			pTemp = "Path not found";
			break;

		case ERROR_BAD_FORMAT:
			pTemp = "Bad format";
			break;

		case ERROR_INVALID_FUNCTION:
			pTemp = "Invalid function";
			break;

		case ERROR_SERVICE_EXISTS:
			pTemp = "Service exists";
			break;

		default:
			wsprintf(szTemp, "Unknown error:  %ld", LastErr);
			pTemp = &szTemp[0];
			break;

	} // End SWITCH

	MessageBox(0, pTemp, "DOSMAX -- UTRegister() Error", MB_OK);

} // DispLastError()


// Attempt to UTRegister()
BOOL LCL_UTRegister(void)
{
	char szTemp[128];

	if (g_UTReg == FALSE)
	if (FALSE == (g_UTReg = UTRegister(g_hmodThisDll, // Handle to this DLL
							 UT16DLLPath,	// 16-bit DLL to load
							 NULL,			// No initialization function
							 UT16Proc,		// Function to call
							 &ppfn16Proc,	// Return value from UTRegister
							 NULL,			// No callback needed
							 NULL)))		// No init routine, no shared memory
	if (fDebug)
	{
		wsprintf (szTemp, "UTRegister() Failed:  UT16DDLLPath = <%s>.  DOSMAX feature not available.",
							UT16DLLPath);
		MessageBox (0, szTemp, szAppName, MB_OK);
		DebugBreak();
	}
	return g_UTReg;
} // End LCL_UTRegister()


///// Find current module
///// Returns TRUE if found, FALSE if not
///BOOL FindCurMod (void)
///{
///	HANDLE hSnapshot;
///	BOOL fOK, fRet = FALSE;
///	char szTemp[128];
///	HMODULE hModCur, hModKrnl;
///	typedef HANDLE (WINAPI *CREATETOOLHELP32SNAPSHOT)(DWORD, DWORD);
///	typedef BOOL   (WINAPI *MODULE32)(HANDLE, LPMODULEENTRY32);
///
///	CREATETOOLHELP32SNAPSHOT lpfnCreateToolhelp32Snapshot;
///	MODULE32 lpfnModule32First, lpfnModule32Next;
///
///	hModCur = GetModuleHandle(NULL);
///
///	DebugBreak();
///	hModKrnl = GetModuleHandle ("KERNEL32.DLL");
///	if (!hModKrnl)
///		return fRet;
///
///	lpfnCreateToolhelp32Snapshot = (CREATETOOLHELP32SNAPSHOT) GetProcAddress (hModKrnl, "CreateToolhelp32Snapshot");
///	lpfnModule32First = (MODULE32) GetProcAddress (hModKrnl, "Module32First");
///	lpfnModule32Next  = (MODULE32) GetProcAddress (hModKrnl, "Module32Next");
///
///	// create a process module snapshot and walk through the list, adding
///	// each module to the Modules listbox
///	hSnapshot = (*lpfnCreateToolhelp32Snapshot)( TH32CS_SNAPMODULE, NULL );	// NULL = current process
///	if ( !hSnapshot )
///		return fRet;
///    
///	me32.dwSize = sizeof(me32);     // Gotta initialize dwSize!
///	for ( fOK = (*lpfnModule32First)( hSnapshot, &me32 );
///		  fOK;
///		  fOK = (*lpfnModule32Next)( hSnapshot, &me32 ) )
///	{
///		if (hMdCur == me32.hModule)	// If it's our boy
///		{
///			fRet = TRUE;
///			break;
///		}
///		///wsprintf( szTemp, "Base:%08X\nRef:%02u\nPath: %s\nName: %s\nCURMOD: %08X",
///		///            me32.hModule, me32.ProccntUsage, me32.szExePath, me32.szModule, hModCur);
///		///MessageBox (0, szTemp, "Module Names", MB_OK);
///	}
///    
///	CloseHandle( hSnapshot );   // Done with this snapshot.  Free it
///	return fRet;
///
///} // End FindCurMod()


// Determine whether or not a given file exists
BOOL FileExist (char *file)
{
	HFILE hFile;
	char szTemp[MAX_PATH];
	char szUFF[ 128];

	hFile = _lopen (file, OF_READ);
	if (hFile)
		_lclose (hFile);
	else
	{
		LoadString (g_hmodThisDll, IDS_UNABLEFF,  szUFF,  sizeof (szUFF ));
		wsprintf (szTemp, szUFF, file);

		MessageBox (0, szTemp, szAppName, MB_OK);
		return FALSE;
	}
	return TRUE;

} // End FileExist


// Wait for an exec to finish
BOOL WaitForExec (char *pFileName, char *pCmdLine)
{
	STARTUPINFO psi;
	PROCESS_INFORMATION pi;
	char szNewFileCmd[255];

	// It appears that CreateProcess() ignores the filename and
	// use the command line as if it were for an MS-DOS process
	// if the file is a Win16 app.
	wsprintf (szNewFileCmd, "%s %s", pFileName, pCmdLine);
	
	psi.cb = sizeof (psi);
	psi.lpReserved = 0;
	psi.lpDesktop = 0;
	psi.lpTitle = 0;
	psi.dwX = 0;
	psi.dwY = 0;
	psi.dwXSize = 0;
	psi.dwYSize = 0;
	psi.dwXCountChars = 0;
	psi.dwYCountChars = 0;
	psi.dwFillAttribute = 0;
	psi.dwFlags = 0;
	psi.wShowWindow = 0;
	psi.cbReserved2 = 0;
	psi.lpReserved2 = 0;
	psi.hStdInput = 0;
	psi.hStdOutput = 0;
	psi.hStdError = 0;

	CreateProcess ( NULL,			// File to execute
					szNewFileCmd,	// Its command line
					NULL,			// No process security attrs
					NULL,			// No thread ...
					FALSE,			// No handles to inherit
					///HIGH_PRIORITY_CLASS, // Create flags
					NULL,			// No create flags
					NULL,			// Use caller's environment
					NULL,			// Use caller's current directory
					&psi,			// Process startup info struc
					&pi);


	if (WaitForSingleObject(pi.hProcess, 2000) == WAIT_TIMEOUT)
	{
		LoadString (g_hmodThisDll, IDS_UNABLEREG,  szNewFileCmd,  sizeof (szNewFileCmd));
		MessageBox(0, szNewFileCmd, szAppName, MB_OK);
		return FALSE;
	}

	return TRUE;

} // End WaitForExec ()


// DLL entry point
extern "C" int APIENTRY
DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
{
    if (dwReason == DLL_PROCESS_ATTACH)
    {
		char szINIFileName[255],			// The name of our .INI file ("QMAX.INI")
			 szINICFGSect [255],			// The name of the config section ("CONFIG")
			 szINIMAXPath [255],			// The name of the QMAX path ("Qualitas MAX Path")
			 szSetEWVName [255],			// The name of the Set Expected Windows Version program ("SETEWV")
			 szSetEWVDPFE [255],			// The entrire Drive, Path, Filename, and Extension to SETEWV
			 szCurModule  [255],			// d:\path\filename.ext of curent module
			 szCurFileName[255],			// filename of above
			 szCmdLine[255],				// Command line of program to exec
			 szOrigVer[6];					// Original version #
		int len;

   		// Extension DLL one-time initialization

		g_hmodThisDll = hInstance;

		// Because of a bug in the Universal Thunk processing, we need to
		// set the Exepected Windows Version of the current task to 3.10
		// so our 16-bit DLL can load.

		// Load strings we need
		LoadString (g_hmodThisDll, IDS_INIFILENAME, szINIFileName, sizeof (szINIFileName));
 		LoadString (g_hmodThisDll, IDS_INICFGSECT,  szINICFGSect,  sizeof (szINICFGSect ));
		LoadString (g_hmodThisDll, IDS_INIMAXPATH,  szINIMAXPath,  sizeof (szINIMAXPath ));
		LoadString (g_hmodThisDll, IDS_SETEWVNAME,  szSetEWVName,  sizeof (szSetEWVName ));

		// Read debug switch from QMAX.INI
		fDebug = GetPrivateProfileInt (szINICFGSect, "debug", 0, szINIFileName);

		// Get the QMAX.INI path
		GetPrivateProfileString (szINICFGSect, szINIMAXPath, "", szQMAXPath, sizeof (szQMAXPath), szINIFileName);
 		len = lstrlen (szQMAXPath);			// Append a trailing backslash
		if (len && szQMAXPath[len - 1] != '\\') // ...unless there's already
			lstrcat (szQMAXPath, "\\");		// ...one there
		
		// Setup the UT16 DLL path
		wsprintf (UT16DLLPath, "%s%s", szQMAXPath, UT16DLL);

		// Ensure the file exists
		if (!FileExist (UT16DLLPath))
			return FALSE;

		// Find the current module
		GetModuleFileName (NULL, szCurModule, sizeof (szCurModule));
		_splitpath (szCurModule, NULL, NULL, szCurFileName, NULL);
		
		// Save the current expected version #
		lstrcpy (szOrigVer, "0400");		// *FIXME*

		// Get the path name to the SETEWV.EXE program
		wsprintf (szSetEWVDPFE, "%s%s", szQMAXPath, 	// Start with QMAX path
										szSetEWVName);	// Append the executable name
		// Ensure the file exists
		if (!FileExist (szSetEWVDPFE))
			return FALSE;

		// Set the version # to 0x030A
		lstrcpy (szCmdLine, szCurFileName);		// Start with the current file name
		lstrcat (szCmdLine, " ");				// Append separator
		len = lstrlen (szCmdLine);				// Save so we can restore orig ver later
		lstrcat (szCmdLine, "030A");			// Append the new version #

		// Exec the SETEWV program and wait for it to complete
		if (FALSE == WaitForExec (szSetEWVDPFE, szCmdLine))	// Set the current process' Expected Winodws Version #
			return FALSE;						// Quit if it failed
		
		LCL_UTRegister();						// Attempt to UTRegister()

		// Restore the current process' Expected Windows Version #
		lstrcpy (&szCmdLine[len], szOrigVer);	// Append the orignial version #

		// Exec the SETEWV program and wait for it to complete
		if (FALSE == WaitForExec (szSetEWVDPFE, szCmdLine))
			return FALSE;						// Quit if it failed
   }
    else if (dwReason == DLL_PROCESS_DETACH)
    {
		if (g_UTReg)
			UTUnRegister (g_hmodThisDll);		// Say goodbye
    }

    return TRUE;	// ok
}

//---------------------------------------------------------------------------
// DllCanUnloadNow
//--------------------------------------------------------------------------

STDAPI DllCanUnloadNow(void)
{
    return (g_cRefThisDll == 0 ? S_OK : S_FALSE);
}

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID *ppvOut)
{
    *ppvOut = NULL;

    if (IsEqualIID(rclsid, CLSID_ShellExtension))
    {
		CShellExtClassFactory *pcf = new CShellExtClassFactory;

		return pcf->QueryInterface(riid, ppvOut);
    }

    return CLASS_E_CLASSNOTAVAILABLE;
}

CShellExtClassFactory::CShellExtClassFactory()
{
    m_cRef = 0L;

    g_cRefThisDll++;
}

CShellExtClassFactory::~CShellExtClassFactory()
{
    g_cRefThisDll--;
}

STDMETHODIMP CShellExtClassFactory::QueryInterface(REFIID riid,
						   LPVOID FAR *ppv)
{
    *ppv = NULL;

    // Any interface on this object is the object pointer

    if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_IClassFactory))
    {
		*ppv = (LPCLASSFACTORY)this;

		AddRef();

		return NOERROR;
    }

    return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) CShellExtClassFactory::AddRef()
{
    return ++m_cRef;
}

STDMETHODIMP_(ULONG) CShellExtClassFactory::Release()
{
    if (--m_cRef)
		return m_cRef;

    delete this;

    return 0L;
}

STDMETHODIMP CShellExtClassFactory::CreateInstance(LPUNKNOWN pUnkOuter,
						      REFIID riid,
						      LPVOID *ppvObj)
{
    *ppvObj = NULL;

    // Shell extensions typically don't support aggregation (inheritance)

    if (pUnkOuter)
		return CLASS_E_NOAGGREGATION;

    // Create the main shell extension object.	The shell will then call
    // QueryInterface with IID_IShellExtInit--this is how shell extensions are
    // initialized.

    LPCSHELLEXT pShellExt = new CShellExt();  //Create the CShellExt object

    if (NULL == pShellExt)
		return E_OUTOFMEMORY;

    return pShellExt->QueryInterface(riid, ppvObj);
}


STDMETHODIMP CShellExtClassFactory::LockServer(BOOL fLock)
{
    return NOERROR;
}

// *********************** CShellExt *************************
CShellExt::CShellExt()
{
    m_cRef = 0L;
    m_pDataObj = NULL;

    g_cRefThisDll++;
}

CShellExt::~CShellExt()
{
    if (m_pDataObj)
		m_pDataObj->Release();

    g_cRefThisDll--;
}

STDMETHODIMP CShellExt::QueryInterface(REFIID riid, LPVOID FAR *ppv)
{
    *ppv = NULL;

    if (IsEqualIID(riid, IID_IShellExtInit) || IsEqualIID(riid, IID_IUnknown))
    {
		*ppv = (LPSHELLEXTINIT)this;
    }
    ///else if (IsEqualIID(riid, IID_IContextMenu))
    ///{
	///	*ppv = (LPCONTEXTMENU)this;
    ///}
    ///else if (IsEqualIID(riid, IID_IExtractIcon))
    ///{
	///*ppv = (LPEXTRACTICON)this;
    ///}
    ///else if (IsEqualIID(riid, IID_IPersistFile))
    ///{
	///*ppv = (LPPERSISTFILE)this;
    ///}
    else if (IsEqualIID(riid, IID_IShellPropSheetExt))
    {
		*ppv = (LPSHELLPROPSHEETEXT)this;
    }
    ///else if (IsEqualIID(riid, IID_IShellCopyHook))
    ///{
	///*ppv = (LPCOPYHOOK)this;
    ///}

    if (*ppv)
    {
		AddRef();

		return NOERROR;
    }

	return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) CShellExt::AddRef()
{
    return ++m_cRef;
}

STDMETHODIMP_(ULONG) CShellExt::Release()
{
    if (--m_cRef)
	return m_cRef;

    delete this;

    return 0L;
}
