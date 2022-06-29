// $Header:   P:/PVCS/MAX/DOSMAX32/PROPSHET.CPV   1.1   18 Dec 1995 16:15:12   BOB  $
//
//  MODULE:   propshet.cpp
//
//  PURPOSE:   Implements the IShellPropSheetExt member functions necessary to
//             support the property sheet page of this shell extension.  This
//             page is displayed when the user selects "Properties..." after
//             right clicking on a .PIF file
//

#include "priv.h"
#include "dosmax32.h"
#include "resource.h"
#include <dosmax2.h>
extern "C" {
#define W32SUT_32
#include <w32sut.h>
}

extern UINT g_cRefThisDll;			// Reference count of this DLL.
extern HINSTANCE g_hmodThisDll;		// Handle to this DLL itself.
extern UT32PROC ppfn16Proc;			// Handle from UTRegister()
extern BOOL g_UTReg;				// Whether or not we UTRegister()ed

extern char szAppName[];
LPCSTR PIFExt = "DOSMAX";

static BOOL fSave;		// Marks whether or not we should save
static char szClickFile[MAX_PATH], szPIFFile[MAX_PATH];
FARPROC lpfnVXD;


typedef struct
{
	BYTE bFlag;					// DOSMAX_xxx (DEF/ON/OFF) flag
	WORD wMem;					// Requested memory (for now, -1)
} DMPIF;

#define DMPIF_DEF {DOSMAX_DEF, 0xFFFF}	// Default values

static DMPIF strDOSMAXOld = DMPIF_DEF,	// Save area for ReadProperties() value
			 strDOSMAXNew = DMPIF_DEF,	// Save area for PropertySheet() changes
			 strDOSMAXDef = DMPIF_DEF;	// Default value (doesn't change)


typedef struct
{
	char **ppLS;
	WORD wRes;
} LPLS;

PSTR ///pszINIFileName,
	 ///pszINISectName,
	 pszMenuShortcut;

LPLS pLS[] = {///{&pszINIFileName,			IDS_INIFILENAME},
			  ///{&pszINISectName,			IDS_INISECTNAME},
			  {&pszMenuShortcut,		IDS_MENUSHORTCUT},
			 };


// Universal Thunk call to Open/Get/CloseProperties()
int WINAPI LCLReadProperties (LPCSTR lpszApp,
							  LPCSTR lpszPIF,
							  int hInf,
							  int flOpt1,
							  LPCSTR lpszGroup,
							  LPVOID lpProps,
							  int cbProps,
							  int flOpt2,
							  int flOpt3)
{
	LPVOID xlist[4+1];					// Translation list

	struct 
	{
		LPCSTR  lpszApp;
		LPCSTR  lpszPIF;
		int		hInf;
		int		flOpt1;				// Used by OpenProperties()
		LPCSTR	lpszGroup;
		LPVOID	lpProps;
		int		cbProps;
		int		flOpt2;				// Used by GetProperties()
		int		flOpt3;				// Used by CloseProperties()
	} stepdownargs;

	if (g_UTReg == FALSE)			// If we didn't register, we can't attend any classes
		return FALSE;				// Go to your room

	// Put arguments into buffer
	stepdownargs.lpszApp = lpszApp;
	stepdownargs.lpszPIF = lpszPIF;
	stepdownargs.hInf	 = hInf;
	stepdownargs.flOpt1	 = flOpt1;
	stepdownargs.lpszGroup = lpszGroup;
	stepdownargs.lpProps = lpProps;
	stepdownargs.cbProps = cbProps;
	stepdownargs.flOpt2  = flOpt2;
	stepdownargs.flOpt3  = flOpt3;

	// Build translation list for flat pointers that need to be
	// translated to segment:offset form.
	xlist[0] = &stepdownargs.lpszApp;
	xlist[1] = &stepdownargs.lpszPIF;
	xlist[2] = &stepdownargs.lpszGroup;
	xlist[3] = &stepdownargs.lpProps;
	xlist[4] = NULL;				// End of the translation list

	return (*ppfn16Proc) (&stepdownargs, ORD_ReadProperties, &xlist[0]); // Call the original routine
} // End LCLReadProperties()


// Universal Thunk call to Open/Set/CloseProperties()
int WINAPI LCLWriteProperties(LPCSTR lpszApp,
							  LPCSTR lpszPIF,
							  int hInf,
							  int flOpt1,
							  LPCSTR lpszGroup,
							  const VOID FAR *lpProps,
							  int cbProps,
							  int flOpt2,
							  int flOpt3)
{
	LPVOID xlist[4+1];					// Translation list

	struct 
	{
		LPCSTR  lpszApp;
		LPCSTR  lpszPIF;
		int		hInf;
		int		flOpt1;				// Used by OpenProperties()
		LPCSTR	lpszGroup;
		const	VOID FAR *lpProps;
		int		cbProps;
		int		flOpt2;				// Used by SetProperties()
		int		flOpt3;				// Used by CloseProperties()
	} stepdownargs;

	if (g_UTReg == FALSE)			// If we didn't register, we can't attend any classes
		return FALSE;				// Go to your room

	// Put arguments into buffer
	stepdownargs.lpszApp = lpszApp;
	stepdownargs.lpszPIF = lpszPIF;
	stepdownargs.hInf	 = hInf;
	stepdownargs.flOpt1	 = flOpt1;
	stepdownargs.lpszGroup = lpszGroup;
	stepdownargs.lpProps = lpProps;
	stepdownargs.cbProps = cbProps;
	stepdownargs.flOpt2  = flOpt2;
	stepdownargs.flOpt3  = flOpt3;

	// Build translation list for flat pointers that need to be
	// translated to segment:offset form.
	xlist[0] = &stepdownargs.lpszApp;
	xlist[1] = &stepdownargs.lpszPIF;
	xlist[2] = &stepdownargs.lpszGroup;
	xlist[3] = &stepdownargs.lpProps;
	xlist[4] = NULL;				// End of the translation list

	return (*ppfn16Proc) (&stepdownargs, ORD_WriteProperties, &xlist[0]); // Call the original routine
} // End LCLWriteProperties()


// Universal Thunk call to OpenProperties()
int WINAPI LCLOpenProperties(LPCSTR lpszApp,
							 LPCSTR lpszPIF,
							 int hInf,
							 int flOpt)
{
	LPVOID xlist[2+1];					// Translation list

	struct 
	{
		LPCSTR  lpszApp;
		LPCSTR  lpszPIF;
		int		hInf;
		int		flOpt;
	} stepdownargs;

	if (g_UTReg == FALSE)			// If we didn't register, we can't attend any classes
		return FALSE;				// quit quietly

	// Put arguments into buffer
	stepdownargs.lpszApp = lpszApp;
	stepdownargs.lpszPIF = lpszPIF;
	stepdownargs.hInf	 = hInf;
	stepdownargs.flOpt	 = flOpt;

	// Build translation list for flat pointers that need to be
	// translated to segment:offset form.
	xlist[0] = &stepdownargs.lpszApp;
	xlist[1] = &stepdownargs.lpszPIF;
	xlist[2] = NULL;				// End of the translation list

	///DebugBreak();
	return (*ppfn16Proc) (&stepdownargs, ORD_OpenProperties, &xlist[0]); // Call the original routine
} // End LCLOpenProperties()


// Universal Thunk call to GetProperties()
int WINAPI LCLGetProperties(int		hProps,
							LPCSTR	lpszGroup,
							LPVOID	lpProps,
							int 	cbProps,
							int		flOpt)
{
	LPVOID xlist[2+1];					// Translation list

	struct 
	{
		int		hProps;
		LPCSTR  lpszGroup;
		LPVOID  lpProps;
		int		cbProps;
		int		flOpt;
	} stepdownargs;

	if (g_UTReg == FALSE)			// If we didn't register, we can't attend any classes
		return FALSE;				// quit quietly

	// Put arguments into buffer
	stepdownargs.hProps		= hProps;
	stepdownargs.lpszGroup	= lpszGroup;
	stepdownargs.lpProps	= lpProps;
	stepdownargs.cbProps	= cbProps;
	stepdownargs.flOpt		= flOpt;

	// Build translation list for flat pointers that need to be
	// translated to segment:offset form.
	xlist[0] = &stepdownargs.lpszGroup;
	xlist[1] = &stepdownargs.lpProps;
	xlist[2] = NULL;				// End of the translation list

	///DebugBreak();
	return (*ppfn16Proc) (&stepdownargs, ORD_GetProperties, &xlist[0]); // Call the original routine
} // End LCLGetProperties()


// Universal Thunk call to SetProperties()
int WINAPI LCLSetProperties(int hProps,
							LPCSTR lpszGroup,
							const VOID FAR *lpProps,
							int cbProps,
							int flOpt)
{
	LPVOID xlist[2+1];					// Translation list

	struct 
	{
		int		hProps;
		LPCSTR  lpszGroup;
		const VOID FAR * lpProps;
		int		cbProps;
		int		flOpt;
	} stepdownargs;

	if (g_UTReg == FALSE)			// If we didn't register, we can't attend any classes
		return FALSE;				// quit quietly

	// Put arguments into buffer
	stepdownargs.hProps		= hProps;
	stepdownargs.lpszGroup	= lpszGroup;
	stepdownargs.lpProps	= lpProps;
	stepdownargs.cbProps	= cbProps;
	stepdownargs.flOpt		= flOpt;

	// Build translation list for flat pointers that need to be
	// translated to segment:offset form.
	xlist[0] = &stepdownargs.lpszGroup;
	xlist[1] = &stepdownargs.lpProps;
	xlist[2] = NULL;				// End of the translation list

	///DebugBreak();
	return (*ppfn16Proc) (&stepdownargs, ORD_SetProperties, &xlist[0]); // Call the original routine
} // End LCLSetProperties()


// Universal Thunk call to CloseProperties()
int WINAPI LCLCloseProperties(int hProps, int flOpt)
{
	int stepdownargs[2];
	
	if (g_UTReg == FALSE)			// If we didn't register, we can't attend any classes
		return FALSE;				// quit quietly

	// Put arguments into buffer
	stepdownargs[0] = hProps;
	stepdownargs[1] = flOpt;

	///DebugBreak();
	return (*ppfn16Proc) (&stepdownargs, ORD_CloseProperties, NULL); // Call the original routine
} // End LCLCloseProperties()


// Universal Thunk call to GetDOSMAXInfo()
int WINAPI LCLGetDOSMAXInfo(void)
{
	if (g_UTReg == FALSE)			// If we didn't register, we can't attend any classes
		return FALSE;				// quit quietly

	return (*ppfn16Proc) (NULL, ORD_GetDOSMAXInfo, NULL); // Call the original routine
} // End LCLGetDOSMAXInfo()


// Convert to PIF name
void MakePIF (char *InpFile, char *OutFile)
{
	char szDrive[_MAX_DRIVE],
		 szDir  [_MAX_DIR],
		 szPath [_MAX_PATH];
	_splitpath (InpFile, szDrive, szDir, szPath, NULL);
	_makepath  (OutFile, szDrive, szDir, szPath, ".PIF");

} // End MakePIF()

//  FUNCTION: PIFPageDlgProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE: Callback dialog procedure for the property page
//
//  PARAMETERS:
//    hDlg      - Dialog box window handle
//    uMessage  - current message
//    wParam    - depends on message
//    lParam    - depends on message
//
//  RETURN VALUE:
//
//    Depends on message.  In general, return TRUE if we process it.
//
//  COMMENTS:
//

BOOL CALLBACK PIFPageDlgProc(HWND hDlg,
                             UINT uMessage,
                             WPARAM wParam,
                             LPARAM lParam)
{
    LPPROPSHEETPAGE psp=(LPPROPSHEETPAGE)GetWindowLong(hDlg, DWL_USER);
    ///static int iDOSMAXOld, iDOSMAXNew;
    int  iID, i, len;
    LPCSHELLEXT lpcs;
	char *pLocMem; 	// Pointer to local memory
	WORD wAlloc, wLen, wHead;
	///static int iPIF;		// .PIF file property handle
	///static BOOL fSave;		// Marks whether or not we should save
	///static char szClickFile[MAX_PATH], szPIFFile[MAX_PATH];

	char szTemp [MAX_PATH];
	char pszHelpText[1024];

	// Note that the following array assumes that DOSMAX_OFF=0, DOSMAX_ON=1, DOSMAX_DEF=2
	// as per the enum statement in DOSMAX.H.
	static int DOSMAX2IDC[] = {IDC_OFF, IDC_ON, IDC_DEFAULT};

	// Note that the following array assumes that IDC_DEFAULT, IDC_ON, and IDC_OFF are
	// consecutive and that IDC_DEFAULT is the smallest.
	static int IDC2DOSMAX[] = {DOSMAX_DEF, DOSMAX_ON, DOSMAX_OFF};

    switch (uMessage)
    {
        //
        // When the shell creates a dialog box for a property sheet page,
        // it passes the pointer to the PROPSHEETPAGE data structure as
        // lParam. The dialog procedures of extensions typically store it
        // in the DWL_USER of the dialog box window.
        //
        case WM_INITDIALOG:
            SetWindowLong(hDlg, DWL_USER, lParam);

            psp = (LPPROPSHEETPAGE)lParam;

            lpcs = (LPCSHELLEXT)psp->lParam;

			// Allocate local memory for the strings
			wAlloc = 1*1024;			// Amount to allocate (it's arbitrary)
			pLocMem = (char *) LocalAlloc(LMEM_FIXED, wAlloc);	// Allocate it

			// Load the strings into local memory
			for (wHead = 0; wHead < sizeof(pLS)/sizeof(LPLS); wHead++)
			{
				*pLS[wHead].ppLS = pLocMem;				// Save as next location
				wLen = LoadString(g_hmodThisDll, pLS[wHead].wRes, pLocMem, wAlloc); // Count in the trailing zero
				if (wLen == 0)							// If it doesn't exist
				{
					wsprintf(szTemp, "String #%d missing.", pLS[wHead].wRes);
					MessageBox(hDlg, szTemp, szAppName, MB_OK);
				} // End IF
				pLocMem += wLen + 1;					// Skip over the string
				wAlloc -= wLen + 1;						// Reduce the amount remaining
			} // End FOR

			fSave = FALSE;							// No save as yet
			
			// Read in matching (if any) entry from .PIF file
            if (*(lpcs->m_szPropSheetFileUserClickedOn))
			{
				///// Copy the filename and change the extension to .PIF
				///lstrcpy (szClickFile, lpcs->m_szPropSheetFileUserClickedOn);
				///MakePIF (szClickFile, szPIFFile);

				///iDOSMAXOld = DOSMAX_DEF;	// *FIXME*
				// Open, get. and close the properties
				///LCLReadProperties (	szClickFile,	// Name of program
				///					szPIFFile,		// ...     .PIF to create
				///					0,				// Information handle
				///					0,				// Open normally
				///					PIFExt,			// PIF extension name
				///					&iDOSMAXOld,	// Address of value
				///					1,				// Length of value in bytes
				///					0,				// Read given property
				///					0);				// Save any cached data

				///iPIF = LCLOpenProperties (
				///					lpcs->m_szPropSheetFileUserClickedOn, // Name of program
				///					szTemp,			// ...     .PIF to create
				///					0,				// Information handle
				///					0);				// Open normally
				
				///if (iPIF != FALSE)					// If it worked, ...
				///{
				///	if (0 == LCLGetProperties (
				///						iPIF,		// Properties handle
				///						PIFExt,		// PIF extension name
				///						&iIndex,	// Address of value
				///						1,			// Length of value in bytes
				///						0))			// Read given property
				///	{	// If the given property group doesn't exist, create it
				///		LCLSetProperties (iPIF,		// Properties handle
				///						  PIFExt,	// PIF extension name
				///						  &iIndex,	// Address of value
				///						  1,		// Length of value in bytes
				///						  0);		// Write directly to file
				///	}
				///	LCLCloseProperties (iPIF, 0);	// Close it up
				///} // End IF
			} // End IF
			else
			{
				strDOSMAXOld = strDOSMAXDef;	// Initialize as default
				szClickFile[0] = szPIFFile[0] = '\0'; // No such files
			}

			strDOSMAXNew = strDOSMAXOld;		// Set for later use

            ///    iIndex = (UINT)GetPrivateProfileInt(pszINISectName,
            ///                                        lpcs->m_szPropSheetFileUserClickedOn,
            ///                                        DOSMAX_DEF,
            ///                                        &pszINIFileName[0]);

			// Select the proper radio button
            SendDlgItemMessage(hDlg, DOSMAX2IDC[strDOSMAXOld.bFlag], BM_SETCHECK, TRUE, 0L);
			///SetProp(hDlg, "ID", GetDlgItem(hDlg, DOSMAX2IDC[iDOSMAXOld]));

			// Load in the help text strings
			len = 0;
			for (i=0; i < 13; i++)
			{
				LoadString( g_hmodThisDll,
							i+IDS_HELPTEXT1,
							&pszHelpText[len],
							sizeof (pszHelpText) - len);
				len += lstrlen( &pszHelpText[len] );
			}
 
 			// Because AppStudio can't handle large amounts of static text,
			// we have to display it dynamically here.
			SetDlgItemText(hDlg, IDC_HELPTEXT, pszHelpText);

			return FALSE;
            ///break;

        case WM_DESTROY:
			///DebugBreak();
			// If a previous Apply occurred and the changed data
			// is different from the original data
            //update the DOSMAX information in the .PIF file

			if (fSave)
			{
				// Copy the filename and change the extension to .PIF
				///MakePIF(lpcs->m_szPropSheetFileUserClickedOn, szTemp);
				
				// As a kludge to synchonizing access to the .PIF file with
				// SHELL32.DLL, we go to sleep for a moment hoping that the
				// shell finishes so we can open/set/close.
				///	Sleep (1000);

				
				
				// Open, set, and close the properties
				LCLWriteProperties (szClickFile, // Name of program
									szPIFFile,	// ...     .PIF to create
									0,		// Information handle
									0,		// Open normally
									PIFExt,	// PIF extension name
									&strDOSMAXNew, // Address of value
									sizeof (strDOSMAXNew),// Length of value in bytes
									0,		// Write directly to file
									0);		// Save any cached data
			}
			
            ///RemoveProp(hDlg, "ID");
            break;

        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case IDC_DEFAULT:
                case IDC_ON:
                case IDC_OFF:
                    ///SetProp(hDlg, "ID", (HANDLE)lParam);
                    iID = LOWORD(wParam) - IDC_DEFAULT;	// Convert to origin-IDC_DEFAULT
					// If this is a change, set the apply button
					if (strDOSMAXNew.bFlag != IDC2DOSMAX[iID])
				        SendMessage( GetParent( hDlg ), PSM_CHANGED, (WPARAM) hDlg, 0L );
					strDOSMAXNew.bFlag = IDC2DOSMAX[iID];	// Convert to origin-DOSMAX_xxx
					///LCLSetProperties (	iPIF,		// Properties handle
					///					PIFExt,		// PIF extension name
					///					&iDOSMAXNew, // Address of value
					//					1,			// Length of value in bytes
					///					SETPROPS_CACHE);// Write to the cache only
                    break;

                default:
                    break;
            }
            break;

        case WM_NOTIFY:
            switch (((NMHDR FAR *)lParam)->code)
            {
				case PSN_SETACTIVE:
					return 0;
                    ///break;

				case PSN_RESET:
					////DebugBreak();
					// The user chickened out -- mark as not to be saved
					fSave = FALSE;
					///LCLCloseProperties (iPIF, CLOSEPROPS_DISCARD);

					break;

					///iPIF = LCLOpenProperties (
					///					lpcs->m_szPropSheetFileUserClickedOn, // Name of program
					///					szTemp,		// ...     .PIF to create
					///					0,			// Information handle
					///					0);			// Open normally
					///
					///if (iPIF != FALSE)				// If it worked, ...
					///{
					///	LCLSetProperties (
					///					iPIF,		// Properties handle
					///					PIFExt,		// PIF extension name
					///					&iID,		// Address of value
					///					1,			// Length of value in bytes
					///					0);			// Write directly to file
					///
					///	LCLCloseProperties (iPIF, 0);	// Close it up
					///} // End IF
					
					// Write out entry to QMAX.INI file
                    ///wsprintf(szTemp, "%i", IDC2DOSMAX[iID]);
					///WritePrivateProfileString(pszINISectName,
                    ///                          lpcs->m_szPropSheetFileUserClickedOn,
                    ///                          szTemp,
                    ///                          &pszINIFileName[0]);
					///break;

                case PSN_APPLY:
					///DebugBreak();
                    //User has clicked the OK or Apply button so we'll
					// Mark that the information should be saved if it's
					// different from the original value

                    ///lpcs = (LPCSHELLEXT)psp->lParam;
                    ///iID  = GetDlgCtrlID((HWND)GetProp(hDlg, "ID"));
                    ///iID -= IDC_DEFAULT;		// Convert to origin-IDC_DEFAULT
					///iDOSMAXNew = IDC2DOSMAX[iID];	// Convert to origin-DOSMAX_xxx

					if (strDOSMAXOld.bFlag != strDOSMAXNew.bFlag)	// If it changed, ...
					{
						fSave = TRUE;
                    	///LCLCloseProperties (iPIF, 0);	// Write it out
					}
					else
					{
						fSave = FALSE;
                    	///LCLCloseProperties (iPIF, CLOSEPROPS_DISCARD); // Discard
					}
					return PSNRET_NOERROR;
					///break;

                default:
                    break;
            }
            break;

        default:
            return FALSE;
    }
    return TRUE;
}


// Determine whether or not a file is a Windows Executable

BOOL IsWinEXE (char *szFile)
{
	HFILE hFile;
	typedef struct
	{
		WORD Sign,			// 00:  Signature
			 R512,			// 02:	Image size/512 remainder
			 Q512,			// 04:  Image size/512 quotient (rounded up)
			 nRel,			// 06:  # relocation table items
			 hSiz,			// 08:  Size of header in paras
			 min,			// 0A:  Minimum # paras needed beyond image
			 max,			// 0C:  Maximum ...
			 ss,			// 0E:  Initial SS in paras
			 sp,		   	// 10:  ...     SP
			 chk,			// 12:  Checksum
			 ip,			// 14:  Initial IP
			 cs,			// 16:  ...     CS
			 iRel,			// 18:  Offset to 1st relocation table item
			 ovrl;			// 1A:  Overlay #
		BYTE rsvd[0x3C-0x1C]; // 1C:  (Reserved)
		DWORD lOff;			// 3C:  Offset to 'NE' header
	} EXEHDR;
	EXEHDR exehdr;
	WORD NEsign;
	char szEXT[_MAX_EXT];

	#define NESIGN 'EN'
	#define PESIGN 'EP'

	_splitpath (szFile, NULL, NULL, NULL, szEXT);

	if (lstrcmpi (szEXT, ".EXE") == 0)
	{
		hFile = _lopen (szFile, OF_READ);
		if (hFile != HFILE_ERROR)
		{
			(void) _lread (hFile, (void *) &exehdr, sizeof (exehdr));
			if ((exehdr.Sign == 'MZ' || exehdr.Sign == 'ZM')	// If it's an EXE signature
				&& exehdr.iRel == 0x40)	// If the offset is normal for a .EXE file, ...
			{
				_llseek (hFile, exehdr.lOff, 0);
				_lread (hFile, (void *) &NEsign, sizeof (NEsign));
				if (NEsign == NESIGN || NEsign == PESIGN)
				{
					_lclose (hFile);
					return TRUE;
				}
			} // End IF

			_lclose (hFile);
		} // End IF
	} // End IF
	
	return FALSE;

} // IsWinEXE()


//
//  FUNCTION: CShellExt::AddPages(LPFNADDPROPSHEETPAGE, LPARAM)
//
//  PURPOSE: Called by the shell just before the property sheet is displayed.
//
//  PARAMETERS:
//    lpfnAddPage -  Pointer to the Shell's AddPage function
//    lParam      -  Passed as second parameter to lpfnAddPage
//
//  RETURN VALUE:
//
//    NOERROR in all cases.  If for some reason our pages don't get added,
//    the Shell still needs to bring up the Properties... sheet.
//
//  COMMENTS:
//

STDMETHODIMP CShellExt::AddPages(LPFNADDPROPSHEETPAGE lpfnAddPage, LPARAM lParam)
{
    PROPSHEETPAGE psp;
    HPROPSHEETPAGE hpage;
	char pszPSPTitle[255];

    FORMATETC fmte = {CF_HDROP,
                      (DVTARGETDEVICE FAR *)NULL,
                      DVASPECT_CONTENT,
                      -1,
                      TYMED_HGLOBAL
                     };
    STGMEDIUM medium;
    HRESULT hres = 0;

    if (m_pDataObj)  //Paranoid check, m_pDataObj should have something by now...
       hres = m_pDataObj->GetData(&fmte, &medium);

    if (SUCCEEDED(hres))
    {
        //Find out how many files the user has selected...
        UINT cbFiles = 0;
        LPCSHELLEXT lpcsext = this;

        if (medium.hGlobal)
            cbFiles = DragQueryFile((HDROP)medium.hGlobal, (UINT)-1, 0, 0);

        if (cbFiles < 2)
        {
            //OK, the user has only selected a single file, so let's go ahead
            //and add the property sheet.  Note that it doesn't HAVE to be this
            //way, but for simplicity and educational reasons, I'll only add
            //the property sheet if a single .PIF file is selected.

            //Get the name of the file the user has clicked on
            if (cbFiles)
               DragQueryFile((HDROP)medium.hGlobal,
                             0,
                             m_szPropSheetFileUserClickedOn,
                             sizeof(m_szPropSheetFileUserClickedOn));

			// If this is a Windows .EXE, we don't create a PSP
			if (IsWinEXE (m_szPropSheetFileUserClickedOn) == TRUE)
				return NOERROR;

			if (g_UTReg == FALSE)			// If we didn't register, we can't attend any classes
				return NOERROR;

			// If there's no 386MAX.VxD or if DOSMAX=OFF, there are no property pages
			if (LCLGetDOSMAXInfo() != TRUE)
				return NOERROR;
				
            // Create a property sheet page object from a dialog box.
            //
            // We store a pointer to our class in the psp.lParam, so we
            // can access our class members from within the PIFPageDlgProc
            //
            // If the page needs more instance data, you can append
            // arbitrary size of data at the end of this structure,
            // and pass it to the CreatePropSheetPage. In such a case,
            // the size of entire data structure (including page specific
            // data) must be stored in the dwSize field.   Note that in
            // general you should NOT need to do this, as you can simply
            // store a pointer to data in the lParam member.
            //

			// Copy the filename and change the extension to .PIF
			lstrcpy (szClickFile, m_szPropSheetFileUserClickedOn);
			MakePIF (szClickFile, szPIFFile);

			// Open, get. and close the properties
			LCLReadProperties (	szClickFile,	// Name of program
								szPIFFile,		// ...     .PIF to create
								0,				// Information handle
								0,				// Open normally
								PIFExt,			// PIF extension name
								&strDOSMAXOld,	// Address of value
								sizeof(strDOSMAXOld), // Length of value in bytes
								0,				// Read given property
								0);				// Save any cached data
			
			LoadString (g_hmodThisDll, IDS_PSPTITLE, pszPSPTitle, sizeof (pszPSPTitle));

            psp.dwSize      = sizeof(psp);      // no extra data.
            psp.dwFlags     = PSP_USEREFPARENT | PSP_USETITLE;
            psp.hInstance   = g_hmodThisDll;
            psp.pszTemplate = MAKEINTRESOURCE(IDD_PIFPAGE);
            psp.hIcon       = 0;
            psp.pszTitle    = pszPSPTitle;
            psp.pfnDlgProc  = PIFPageDlgProc;
            psp.pcRefParent = &g_cRefThisDll;
            psp.lParam      = (LPARAM)lpcsext;

            hpage = CreatePropertySheetPage(&psp);

            if (hpage)
            {
                if (!lpfnAddPage(hpage, lParam))
                    DestroyPropertySheetPage(hpage);
            }
        }
    }

    return NOERROR;
}

//
//  FUNCTION: CShellExt::ReplacePage(UINT, LPFNADDPROPSHEETPAGE, LPARAM)
//
//  PURPOSE: Called by the shell only for Control Panel property sheet
//           extensions
//
//  PARAMETERS:
//    uPageID         -  ID of page to be replaced
//    lpfnReplaceWith -  Pointer to the Shell's Replace function
//    lParam          -  Passed as second parameter to lpfnReplaceWith
//
//  RETURN VALUE:
//
//    E_FAIL, since we don't support this function.  It should never be
//    called.

//  COMMENTS:
//

STDMETHODIMP CShellExt::ReplacePage(UINT uPageID,
                                    LPFNADDPROPSHEETPAGE lpfnReplaceWith,
                                    LPARAM lParam)
{
    return E_FAIL;
}
