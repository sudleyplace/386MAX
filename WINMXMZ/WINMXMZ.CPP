// $Header:   P:/PVCS/MAX/WINMXMZ/WINMXMZ.CPV   1.10   23 May 1996 13:43:30   HENRY  $
//
// WINMXMZ.CPP - Windows-based kickoff for Maximize
//
// Copyright (C) 1995-96 Qualitas, Inc.  All rights reserved.
//

#include "stdafx.h"

#include <string.h>
#include <io.h>
#include <dos.h>
#include <direct.h>
#include <malloc.h>

#include <maxnames.h>
#include <commfunc.h>
#include <mbparse.h>
#include <statutil.h>
#include <splash.h>
#include <bluescr.h>

#include "winmxmz.h"
#include "progdde.h"
#include "mxdlgs.h"
#include "summary.h"
#include "resource.h"

#define	WINMXMZ
#include "messages.h"

#include <mxhelpid.h>

#include <ctl3d.h>

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CWinmxmzApp

BEGIN_MESSAGE_MAP(CWinmxmzApp, CWinApp)
	//{{AFX_MSG_MAP(CWinmxmzApp)
	ON_COMMAND(ID_HELP, OnHelp)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CWinmxmzApp construction

CWinmxmzApp::CWinmxmzApp()
{
	// TODO: add construction code here,
	// Place all significant initialization in InitInstance

        // don't erase ourself yet.
    m_hwndDlg = NULL;
	m_CWndSummary = NULL;
    m_idDlg = 0;
    m_bWin95 = FALSE;
}

/////////////////////////////////////////////////////////////////////////////
// The one and only CWinmxmzApp object

CWinmxmzApp NEAR theApp;

// Useful globals
CString csMaxDir;		// 386MAX directory with trailing BS
char *pszSect = NULL;	// Selected MultiConfig section
#define	MAXBUFF 256

// Callback used when displaying bluescreen
CWnd FAR * CALLBACK CBSummWnd( void )
{
	return THEAPP->m_CWndSummary;
}

/////////////////////////////////////////////////////////////////////////////
// CWinmxmzApp initialization

// Snoop for various settings by reading MAXIMIZE.CFG, etc.
// This is done after getting defaults from MAXIMIZE.INI.
// We'll let Maximize remove any statements from MAXIMIZE.CFG.
void
ParseCfg( CCustomOpts& opts ) {

	// First, let's read MAXIMIZE.CFG
	CString csMaxCfg( csMaxDir );
	csMaxCfg += MAXIMIZE_CFG;
	FILE *pfCfg = fopen( (LPCSTR)csMaxCfg, "rt" );
	char szBuff[ MAXBUFF + 1 ], *psz;

	if (pfCfg) {

		while (fgets( szBuff, MAXBUFF, pfCfg )) {

			szBuff[ MAXBUFF ] = '\0';

			// Clobber any trailing comments
			psz = strchr( szBuff, ';' );
			if (psz) {
				*psz = '\0';
			}

			// We're only interested in NOROMSRCH, NOVGASWAP, and NOEXTRADOS
			psz = strtok( szBuff, " \t\r\n=" );
			if (psz) {
				if (!_stricmp( psz, "NOROMSRCH" )) {
					opts.m_bROMSrch = FALSE;
				} // Got NOROMSRCH
				else if (!_stricmp( psz, "NOVGASWAP" )) {
					opts.m_bVGASwap = FALSE;
				} // Got NOVGASWAP
				else if (!_stricmp( psz, "NOEXTRADOS" )) {
					opts.m_bExtraDOS = FALSE;
				} // Got NOEXTRADOS
			} // Got a token

		} // Not EOF

		fclose( pfCfg );

	} // Opened OK

} // ParseCfg()

// Class for parsing CONFIG.SYS
class CConfigParse {

public:
	// Initialize with section to parse
	CConfigParse( LPCSTR lpSect );

	~CConfigParse( void );

	// Parse CONFIG.SYS.  Returns 1 if found, else 0.
	int Parse( void );

	CString m_csDevLine; // DEVICE= line
	char m_cBoot;		// Boot drive
	BYTE m_Owner;		// Active owner

	// Callback function used in parsing
	int CBfn( CONFIGLINE _far *lpCfg );

protected:
	int m_nMenuFree; // If non-zero, call config_free when cleaning up.

};

// Implementation of CConfigParse class
CConfigParse::CConfigParse( LPCSTR lpSect ) {

	m_csDevLine = "";
	m_cBoot = ::get_bootdrive();

	m_nMenuFree = ::menu_parse( m_cBoot, 1 );

	::set_current( (LPSTR)lpSect );

	m_Owner = ActiveOwner;

} // CConfigParse::CConfigParse()

// Global pointer needed to call member function
// Note that this will never work for multiple instances.  The mbparse
// callback should be changed to take a DWORD of data for the callback.
static CConfigParse *pParse;

// C callback stub
int _cdecl _far
CConfigParse_CBfn( CONFIGLINE _far *lpCfg ) {
	return pParse->CBfn( lpCfg );
} // CConfigParse_CBfn()

int
CConfigParse::Parse( void ) {

	// Note that parsing frees up menu data
	m_nMenuFree = 0;

	pParse = this;
	return !::config_parse( m_cBoot, m_Owner, "/dev/nul", 0,
					CConfigParse_CBfn );

} // CConfigParse::Parse()

int
CConfigParse::CBfn( CONFIGLINE _far *lpCfg ) {

	char szBuff[ 256 ], szName[ _MAX_FNAME + _MAX_EXT ], szExt[ _MAX_EXT ];
	char *pszTok;

	// Called with data for each line.
	// FIXME allow a list of possible drivers to be specified.
	// Return
	if (lpCfg->ID == ID_DEVICE) {

		lstrcpy( szBuff, lpCfg->line );

		// Skip DEVICE*
		pszTok = strtok( szBuff, " \t=\r\n" );

		// Skip any switches
		while ((pszTok = strtok( NULL, " \t=\r\n" )) && *pszTok == '/') ;

		// If anything left it's our boy
		if (pszTok) {

			_splitpath( pszTok, NULL, NULL, szName, szExt );
			strcat( szName, szExt );

			// Now check for the device we're looking for
			// FIXME use a list passed to our constructor
			// To make things easier we'll start with the path, e.g.
			// c:\386max\386max.sys pro=c:\386max\386max.pro
			if (!_stricmp( szName, MGRNAME_SYS ) ||
				!_stricmp( szName, ALTMGRNAME_SYS )) {
				m_csDevLine = (lpCfg->line + (int)(pszTok - szBuff));
			} // Found it

		} // Got path

	} // Got a device

	return 0; // Don't do any relocation

} // CConfigParse::CBfn()


CConfigParse::~CConfigParse( void ) {
	if (m_nMenuFree) {
		::config_free();
	} // Need to free menu data
} // CConfigParse::~CConfigParse()

// Parse CONFIG.SYS to find 386MAX.PRO and save profile name.
void
ParseCfgSys( CString& csPro ) {

	// Innocent until proven guilty...
	csPro = "";

	// Troll for DEVICE=386max.sys or DEVICE=bluemax.sys
	CConfigParse cfgp( pszSect ? pszSect : "common" );

	// If found, parse line for pro= (ignore other statements)
	if (cfgp.Parse()) {

		cfgp.m_csDevLine.MakeLower();

		LPSTR lpszPro = (LPSTR)strstr( cfgp.m_csDevLine, "pro=" );

		if (lpszPro) {

			lpszPro = strtok( lpszPro + 4, " \t\r\n" );

			if (lpszPro) {
				csPro = lpszPro;
			} // Got argument

		} // Found pro= statement

	} // Got line

} // ParseCfgSys()

// Parse .PRO file for USE= above F000 and for VGASWAP.
// Also check for BCF= or AUTOBCF and if found, disable ROMSrch.
// opts.m_csMaxPro should already be set.
void
ParsePro( CCustomOpts& opts ) {

	FILE *pfPro;
	char szBuff[ MAXBUFF + 1 ];

	// Innocent until proven guilty...
	opts.m_bHasVGASwap = FALSE;
	opts.m_bHasUseHigh = FALSE;
	opts.m_bROMSrchEna = TRUE;

	// Now parse profile if found.  If no path, tough.
	// FIXME assert boot drive as drive letter, but it's not quite
	// that simple, and assert boot root as directory.
	if (!opts.m_csMaxPro.IsEmpty() &&
		(pfPro = fopen( opts.m_csMaxPro, "rt" ))) {

		// If no multiconfig, we're seeking common
		int nSectFound = 1; // Always start with common
		char *pszFindSect = "common";

		if (pszSect) {
			pszFindSect = pszSect;
		}

		while (fgets( szBuff, MAXBUFF, pfPro )) {

			// Terminate it
			szBuff[ MAXBUFF ] = '\0';

			// Check for section
			if (szBuff[ 0 ] == '[') {

				char *pszTrail = strchr( &szBuff[ 1 ], ']' );

				if (pszTrail) {
					*pszTrail = '\0';
				} // Got trailing ] to clobber

				// Check for common or the specified section
				nSectFound = (!_stricmp( &szBuff[ 1 ], "common" ) ||
					!_stricmp( &szBuff[ 1 ], pszFindSect ));

			} // Got section name
			else if (nSectFound) {

				// Troll for VGASWAP, USE=, BCF=, etc.
				static char szTokList[] = " \t=,-\r\n";
				char *pszComment = strchr( szBuff, ';' );
				if (pszComment) {
					*pszComment = '\0';
				} // Clobber comments

				char *pszTok = strtok( szBuff, szTokList );
				if (!pszTok) {
					continue;
				} // Empty line

				if (!_stricmp( pszTok, "VGASWAP" )) {
					opts.m_bHasVGASwap = TRUE;
				} // Found VGASWAP
				else if (!_stricmp( pszTok, "USE" ) &&
						 (pszTok = strtok( NULL, szTokList ))) {

					WORD wStart = 0;

					sscanf( pszTok, "%x", &wStart );

					if (wStart >= 0xf000) {
						opts.m_bHasUseHigh = TRUE;
					} // Found one above f000

				} // Found a USE= statement
				else if (!_stricmp( pszTok, "BCF" ) ||
						 !_stricmp( pszTok, "AUTOBCF" )) {
					opts.m_bROMSrchEna = FALSE;
				} // Got BCF= or AUTOBCF

			} // Not ignoring

		} // Not EOF

		fclose( pfPro );

	} // Got a profile name

} // ParsePro()


// Set up batch files to reboot into Maximize.
// This is needed only if MAX is not the current memory manager.
// We'll pass Maximize.exe the /R option if all goes well here.
int
SetAutoWMX( LPCSTR lpMaxDir, char *pszMaximize, char *pszOptions ) {

		/***
		 *	User requested to reboot and run MAXIMIZE.
		 *	We need to save the AUTOEXEC.BAT as
		 *	AUTO_WMX.$$$, create a new autoexec.bat which then
		 *	chains to AUTO_WMX.BAT, which itself does the following:
		 *	1. Copies the original AUTOEXEC.BAT back in
		 *	   place.
		 *	2. Displays a brief "Come out of your
		 *	   shell" message.
		 *	3. Processes AUTOEXEC.BAT using BATPROC.
		 *	4. Starts MAXIMIZE with the selected parameters.
		 *     Note the /R should have no effect the second
		 *     time around because we'll either have MAX
		 *     present or we'll be in real mode.
		 ***/

		char szDestpath[ _MAX_PATH ];
		FILE *autotemp, *pfTemp2;

		// Copy AUTOEXEC.BAT to AUTO_WMX.$$$
		wsprintf( szDestpath, "%s" TEMPAUTO_TMP, lpMaxDir );
		if (!CopyFile( StartupBat, szDestpath )) return -1;

		// Copy CONFIG.SYS to AUTO_WMX.CFG
		wsprintf( szDestpath, "%s" TEMPAUTO_CFG, lpMaxDir );
		if (!CopyFile( ConfigSys, szDestpath )) return -1;

		// Create AUTO_WMX.BAT which restores original
		// AUTOEXEC and starts MAXIMIZE.
		wsprintf( szDestpath, "%s" TEMPAUTO_BAT, lpMaxDir );
		autotemp = fopen( szDestpath, "w" );
		if (!autotemp) return -1;

		wsprintf( szDestpath, "%s" TEMPAUTO_TMP, lpMaxDir );
		//truename( szDestpath );
		fprintf( autotemp, MsgAutotemp, szDestpath );

		strcpy( szDestpath, StartupBat );
		//truename( szDestpath );
		fprintf( autotemp, "%s\n", szDestpath );

		wsprintf( szDestpath, "%s" TEMPAUTO_CFG, lpMaxDir );
		//truename( szDestpath );
		fprintf( autotemp, "copy %s %s\n", szDestpath, ConfigSys );
		wsprintf( szDestpath, "%sBATPROC", lpMaxDir );
		//truename( szDestpath );
		fprintf( autotemp, "%s %s * 386LOAD Maximize.trm\n",
				szDestpath, StartupBat );

		fprintf( autotemp, "%s %s\n", pszMaximize, pszOptions );
		fclose( autotemp );

		// Create new AUTOEXEC.BAT which starts c:\386max\autoinst.bat
		autotemp = fopen( StartupBat, "w" );
		if (!autotemp) return -1;

		wsprintf( szDestpath, "%s" TEMPAUTO_BAT, lpMaxDir );
		//truename( szDestpath );
		fprintf( autotemp, "%s\n", szDestpath );
		fclose( autotemp );

		// If MultiConfig write first four lines of CONFIG.SYS
		if (pszSect) {

			char szBuff[ 512 ];

			wsprintf( szDestpath, "%sCFG_SYS.$$$", lpMaxDir );
			pfTemp2 = fopen( szDestpath, "w" );

			if (pfTemp2) {

				fprintf( pfTemp2, "[menu]\nMenuItem=%s\nMenuDefault=%s,0\n[common]\n", pszSect, pszSect );

				if (autotemp = fopen( ConfigSys, "r" )) {

					while (fgets( szBuff, sizeof( szBuff ) - 1, autotemp )) {

						szBuff[ sizeof( szBuff ) - 1 ] = '\0';

						fputs( szBuff, pfTemp2 );

					} // not EOF

					fclose( autotemp );

				} // Opened CONFIG.SYS for input

				fclose( pfTemp2 );

				// Now copy the new file to config.sys
				CopyFile( szDestpath, ConfigSys );

			} // Opened output

		} // Write CONFIG.SYS

		// Now create a _mximize.bat that uses maximize /r to test
		// for whether we're in real mode.
		wsprintf( szDestpath, "%s_MXIMIZE.BAT", lpMaxDir );
		autotemp = fopen( szDestpath, "w" );
		if (autotemp) {

			fprintf( autotemp, "@echo off\necho off\n" );
			fprintf( autotemp, "%Fsmaximize.exe /r\n", lpMaxDir );
			fprintf( autotemp, "if not errorlevel 5 goto end\n"
							   "copy %Fs" TEMPAUTO_CFG " %s\n",
							   	lpMaxDir, ConfigSys );
			fprintf( autotemp, "copy %Fs" TEMPAUTO_TMP " %s\n",
								lpMaxDir, StartupBat );
			fprintf( autotemp, ":end\n" );
			fprintf( autotemp, "%s %s\n", pszMaximize, pszOptions );

			fclose( autotemp );

			// Now set up the new command line
			char *pszComspec = getenv( "COMSPEC" );
			if (!pszComspec) pszComspec = "command.com";

			strcpy( pszMaximize, pszComspec );

			wsprintf( pszOptions, "/c %s", szDestpath );

		} // Created OK

		return 0; // Success

} // SetAutoWMX()

BOOL CWinmxmzApp::InitInstance()
{
    DWORD dwVer;
	// Standard initialization
	// If you are not using these features and wish to reduce the size
	//  of your final executable, you should remove from the following
	//  the specific initialization routines you do not need.

    m_pszProfileName = MAXIMIZE_INI;

    m_pszHelpFilePath = MAXHELP_HLP;	// MAXHELP.HLP

	// Enable 3D controls
	Ctl3dRegister( AfxGetInstanceHandle());
	Ctl3dAutoSubclass( AfxGetInstanceHandle());

	SetDialogBkColor();        // Set dialog background color to gray

	// Display splash screen
	CSplashDlg splash;

	DWORD dwStartSplash = ::GetTickCount();
	DWORD dwNow;

            // find out if we're in Win95.
        dwVer = GetVersion();
        if ( ( LOBYTE( LOWORD( dwVer )) > 3 ) ||
             ( ( LOBYTE( LOWORD( dwVer )) > 2) && 
               ( HIBYTE( LOWORD( dwVer )) > 15) ) ) {
            m_bWin95 = TRUE;
        }
        else {
            m_bWin95 = FALSE;
        }

	WORD wHigh, wLSeg;
	BOOL bQMax = qmaxpres( &wHigh, &wLSeg );

	// Get directory we're loaded from to locate Max components.

	LPSTR lpsz = csMaxDir.GetBuffer( _MAX_PATH );
	::GetModuleFileName( m_hInstance, lpsz, _MAX_PATH );
	csMaxDir.ReleaseBuffer();

	// Split path into various components.
	char szDrive[ _MAX_DRIVE ], szDir[_MAX_DIR ];
	_splitpath( (LPCSTR)csMaxDir, szDrive, szDir, NULL, NULL );

	// Now reassemble the drive and directory (with trailing backslash)
	csMaxDir = szDrive;
	csMaxDir += szDir;

	// Use our directory as a default, but try to get directory name from
	// QDSPATCH.INI
	//m_csDir = GetProfileString( INI_CONFIG, INI_CONFIG_DBFILES,
	//					(LPCSTR)csDispatchDir );

	// Make sure there's no trailing backslash
	//if ((m_csDir.GetLength() > 3) && (m_csDir.Right( 1 ) == "\\")) {
	//	m_csDir = m_csDir.Left( m_csDir.GetLength() - 1 );
	//} // Strip trailing backslash

	// Put up our dialogs
	// From here on out we're running a simple state machine
	// or finite-state automaton.
	// Some states are optional, and may repeat the previous
	// direction.
	enum {
		START_STATE=0,
		MBOOT_STATE,
		MODE_STATE,
		OPTION_STATE,
		REBOOT_STATE,
		END_STATE,
		CANCEL_STATE
	};
	int nState = START_STATE;
	int nDirection = 1;
	int nRes;
	CWelcome welcome;
	CSelectMode mode;
	CCustomOpts opts( NULL, m_bWin95 ? IDD_CUSTOPTS95 : IDD_CUSTOPTS );
	CEndPhase1 end1;
	CExit confexit;
	CString addbat;

	// Don't try to evade a faked current section
	char *pszConfig = getenv( "CONFIG" );
	if (pszConfig) {
		pszSect = _fstrdup( pszConfig );
	} // CONFIG defined in environment

	// Set defaults from MAXIMIZE.INI
	CString csProfile( csMaxDir );
	csProfile += MAXIMIZE_INI;

	m_pszProfileName = csProfile;

	mode.m_bCustom = GetProfileInt( INIS_DEFAULTS, INI_CUSTOM, FALSE );

	opts.m_bWin95 = m_bWin95;
	if (m_bWin95) {
		opts.m_bDOSStart = GetProfileInt( INIS_DEFAULTS, INI_DOSSTART, FALSE );
	} // Get additional option for Win95

	opts.m_bROMSrch = GetProfileInt( INIS_DEFAULTS, INI_ROMSRCH, TRUE );
	opts.m_bVGASwap = GetProfileInt( INIS_DEFAULTS, INI_VGASWAP, TRUE );
	opts.m_bExtraDOS = GetProfileInt( INIS_DEFAULTS, INI_EXTRADOS, TRUE );

	// Now try to find a DEVICE=386max.sys or DEVICE=bluemax.sys line
	// and get m_csMaxPro
	ParseCfgSys( opts.m_csMaxPro );

	// Check Maximize.CFG and 386MAX.PRO specifically for NO* statements
	// and USE= statements at or above F000
	ParseCfg( opts );

	// If the current section does _not_ have 386MAX.SYS and we're
	// not going to ask about Multiconfig, bail out now...
	if (!pszSect && opts.m_csMaxPro.IsEmpty()) {
		AfxMessageBox( ERRMSG_NOMAX );
		return TRUE;
	} // Max not found

	// Parse profile for m_bHasVGASwap, m_bHasUseHigh
	ParsePro( opts );

	// If ROMSrch has already been run for this section, turn it off.
	if (opts.m_bHasUseHigh || !opts.m_bROMSrchEna) {
		opts.m_bROMSrch = FALSE;
	} // ROMsrch-recovered areas already present

	// Create and save path to DOSSTART.BAT
	if (m_bWin95) {

		char szDir[ _MAX_DIR ], szPath[ _MAX_PATH ];

		GetWindowsDirectory( szDir, sizeof( szDir ) );

		// Drive component in directory c:\win95 will _not_ be discarded
		// as the docs so erroneously indicate.
		_makepath( szPath, "", szDir, "DOSStart", ".bat" );

		addbat = szPath;

	} // Save path to DOSSTART.BAT

	// Wait a bit
	do {
		dwNow = ::GetTickCount();
		// FIXME figure out how to yield
	} while (dwNow - dwStartSplash < 1600);

	// Dump the splash screen
	splash.DestroyWindow();

	// Note that only one _or_ the other of /I or /summary is allowed...
	int nFromToolbox = !_stricmp( m_lpCmdLine, "/I" );

	if (!_strnicmp( m_lpCmdLine, "/summary", 8 ))
	{
		// If invoked with /summary get summary data from MAXIMIZE.INI
		// This also removes the line that forces a Windows start at
		// the end of autoexec.
		CBlue blue( NULL, ::CBSummWnd );
		CSummary summ( atoi( &m_lpCmdLine[ 8 ] ) );
		int nRes = summ.DoModal();

		blue.DestroyWindow();

		// If we're to revert, exit Windows and run Premaxim then reboot
		if (nRes == IDC_REVERT) {

			char szMaximize[ _MAX_PATH ];

			// Build path to maximize
			wsprintf( szMaximize, "%s" MAXIMIZE_EXE, (LPCSTR)csMaxDir );

			// If this fails, bitch about it
			if (!::ExitWindowsExec( szMaximize, "/X /P" )) {
				AfxMessageBox( ERRMSG_CANTPREMAXIM );
			} // Failed to run maximize /X /P

		} // Take me home, daddy...

		return TRUE;
	}

	while (nState < END_STATE) {

		switch (nState) {

			case START_STATE:
				nDirection = 1;
				if (!nFromToolbox && welcome.DoModal() != IDOK) {
					nState = CANCEL_STATE;
				}
				break;

			case MBOOT_STATE:
				// If started from Toolbox, only allow Maximize
				// on current section.
				if (pszSect && !nFromToolbox) {

					CSelectMBoot selectmb( NULL, pszSect );

					nDirection = 1;
					_ffree( pszSect );

					switch (selectmb.DoModal()) {

						case IDOK:
							pszSect = _fstrdup( (LPCSTR)selectmb.m_csSelected );
							// Now re-read profile (possibly a different
							// profile or a different section in the same
							// profile)
							ParseCfgSys( opts.m_csMaxPro );
							opts.m_bROMSrch = GetProfileInt( INIS_DEFAULTS,
										INI_ROMSRCH, FALSE );
							if (opts.m_csMaxPro.IsEmpty()) {
								AfxMessageBox( ERRMSG_MAX_MCFG );
								nDirection = 0;
							} // Bitch about it
							else {

								ParsePro( opts );

								// If ROMSrch has already been run for this
								// section, turn it off.
								if (opts.m_bHasUseHigh) {
									opts.m_bROMSrch = FALSE;
								} // ROMsrch-recovered areas already present

							} // Parse MAX profile for this section

							break;

						case IDCANCEL:
							// No confirmation needed yet
							nState = CANCEL_STATE;
							break;

					} // switch ( selectmb )

				} // Multiconfig present
				break;

			case MODE_STATE:
				if (!nFromToolbox)
				  switch (mode.DoModal()) {

					case IDC_BACK:
						nDirection = -1;
						break;

					case IDC_EXPRESS:
						// If going from custom to express, should we
						// revert to basic express assumptions or leave
						// everything as is?

						// I guess we should revert...
						if (!opts.m_bHasUseHigh && opts.m_bROMSrchEna) {
							opts.m_bROMSrch = TRUE;
						}

						if (!opts.m_bHasVGASwap) {
							opts.m_bVGASwap = TRUE;
						}

						opts.m_bExtraDOS = TRUE;

						// Fall through to custom case

					case IDC_CUSTOM:
						nDirection = 1;
						break;

					case IDCANCEL:
						nDirection = 0;
						if (confexit.DoModal() == IDOK) {
							nState = CANCEL_STATE;
						} // Got confirmation
						break;

				  } // switch ()
				break;

			case OPTION_STATE:
				// If DOSSTART.BAT doesn't exist, disable the option
				if (m_bWin95) {

					opts.m_bDOSStartEna = !_access( addbat, 00 );

				} // Win95, make sure DOSSTART.BAT exists

				if (mode.m_bCustom) switch (opts.DoModal()) {

					case IDC_BACK:
						nDirection = -1;
						break;

					case IDOK:
						nDirection = 1;
						break;

					case IDCANCEL:
						nDirection = 0;
						if (confexit.DoModal() == IDOK) {
							nState = CANCEL_STATE;
						} // Got confirmation
						break;

				} // m_bCustom
				break;

			case REBOOT_STATE:
				nRes = end1.DoModal();
				if (nRes == IDOK) {

					char szMaximize[ _MAX_PATH ];
					char szOptions[ 128 ];

					// Save options in MAXIMIZE.INI.  Note that if we bail
					// out before getting this far, none of the option
					// changes we've made here will be saved.
					WriteProfileInt( INIS_DEFAULTS, INI_CUSTOM, mode.m_bCustom );
					WriteProfileInt( INIS_DEFAULTS, INI_ROMSRCH, opts.m_bROMSrch );
					WriteProfileInt( INIS_DEFAULTS, INI_VGASWAP, opts.m_bVGASwap );
					WriteProfileInt( INIS_DEFAULTS, INI_EXTRADOS, opts.m_bExtraDOS );

					if (m_bWin95) {
						WriteProfileInt( INIS_DEFAULTS, INI_DOSSTART, opts.m_bDOSStart );
					}

					// Save special commands
					WriteProfileInt( INIS_REMOVE, INI_USEHIGH, opts.m_bDisROMSrch );
					WriteProfileInt( INIS_REMOVE, INI_VGASWAP, opts.m_bDisVGASwap );

					// Build path to maximize
					wsprintf( szMaximize, "%s" MAXIMIZE_EXE, (LPCSTR)csMaxDir );

					// Build options
					sprintf( szOptions, "/X /V %s",
									mode.m_bCustom ? "/U" : "/E" );

					if (pszSect) {
						sprintf( &szOptions[ strlen( szOptions ) ], " /A %s",
							pszSect );
					} // MultiConfig section selected

					// FIXME we need a scheme that'll work for DOS and Windows.
					// We're close to running out of command line space
					// in some configurations though it's _highly_ unlikely.
					if (m_bWin95 && opts.m_bDOSStart && !addbat.IsEmpty()) {
						strcat( szOptions, " /O " );
						strcat( szOptions, addbat );
					} // Process DOSSTART.BAT too

					// Save startup name in MAXIMIZE.INI.  This is used to
					// save some code in MAXIMIZE.EXE.
					WriteProfileString( INIS_CURRENTSECT, INI_STARTUPBAT, StartupBat );

					// If Max isn't present, set up batch file to boot into
					// Maximize
					if (!bQMax) {
						SetAutoWMX( csMaxDir, szMaximize, szOptions );
					} // MAX is not present

					// Exit and start Maximize.  Note that this may be done
					// via a batch file (szMaximize = "%COMSPEC%" and
					// szOptions = "/c c:\386max\_mximize.bat")
					if (!::ExitWindowsExec( szMaximize, szOptions )) {
						AfxMessageBox( ERRMSG_CANTEXIT );
						nDirection = 0;
					} // Failed, try again

				} // Go ahead and reboot
				else switch (nRes) {

					case IDC_BACK:
						if (!nFromToolbox) {
							nDirection = -1;
						} // Not from Toolbox
						// FIXME Should we turn off nFromToolbox and let 'em
						// go back if they want to?
						else {
							nFromToolbox = 0;
							nDirection = -1;
						} // Let 'em go back
						break;

					case IDCANCEL:
						nDirection = 0;
						if (confexit.DoModal() == IDOK) {
							nState = CANCEL_STATE;
						} // Got confirmation
						break;

				} // Handle other cases
				break;

			default:
				nDirection = 0;
				if (confexit.DoModal() == IDOK) {
					nState = CANCEL_STATE;
				} // Got confirmation
				break;

		} // switch

		nState += nDirection;

	} // Not end of loop

	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////
// application cleanup routine
int CWinmxmzApp::ExitInstance()
{
    CString csTempDir;
    CString csTempDir2;

   	// Shut down help
	WinHelp( 0L, HELP_QUIT );

    Ctl3dUnregister( AfxGetInstanceHandle());

    return 0;
}


// ---------------------------------------------------------------------------
// Set Win95-ish small font for dialog

void CWinmxmzApp::SetSmallFont(CWnd *pDlg)
{
	// Get handle and font of dialog
    HWND hwnd = pDlg->m_hWnd;
    HFONT hfont = (HFONT)pDlg->GetFont()->m_hObject;
    if(!hfont)
    	return;

	// Try to create a normal weight version of the bold font used in dialog    	
	TRY 
	{		
		LOGFONT lf;
		if(!hfont || !::GetObject(hfont, sizeof(lf), &lf))
			return;
		lf.lfWeight = FW_NORMAL;
		m_font.CreateFontIndirect(&lf);
		hfont = (HFONT)m_font.m_hObject;
	} 
	CATCH_ALL(e) 
	{
		return;
	}
	END_CATCH_ALL;

	// Set small font into every control
	for(hwnd = ::GetWindow(hwnd, GW_CHILD); hwnd; hwnd = ::GetWindow(hwnd, GW_HWNDNEXT))
		::SendMessage(hwnd, WM_SETFONT, (WPARAM)hfont, (LPARAM)0);
}

// ---------------------------------------------------------------------------

void CWinmxmzApp::OnHelp()
{
	WinHelp( HID_BASE_RESOURCE+m_idDlg );
}

// ---------------------------------------------------------------------------

void CWinmxmzApp::WinHelp( DWORD dwData, UINT uCmd /*=HELP_CONTEXT*/ )
{
	static bHelp = FALSE;	// Have not been run yet

	if(uCmd == HELP_QUIT)
	{
        if(bHelp)
            {
            bHelp = FALSE;
            if(m_hwndDlg)
                ::WinHelp(m_hwndDlg, MAXHELP_HLP, HELP_QUIT, 0L);
            }
        return;
	}
	
	// Convert CONTENTS and INDEX requests into application-specific context
	if(uCmd == HELP_CONTENTS || uCmd == HELP_INDEX)
	{
            uCmd = HELP_CONTEXT;
            dwData = HID_BASE_RESOURCE+m_idDlg;
	}

	// Convert contexts so they are application-specific	
	if(uCmd == HELP_CONTEXT || uCmd == HELP_CONTEXTPOPUP)
            dwData |= WINMX_HLP_DWORD;

	if(m_hwndDlg)
	{
            bHelp = TRUE;
            TRACE2("WinHelp dwData=0x%08lx, uCmd=0x%04x\n", dwData, uCmd);
            ::WinHelp(m_hwndDlg, MAXHELP_HLP, uCmd, dwData);
	}
}

