// $Header:   P:/PVCS/MAX/WINMXMZ/SUMMARY.CPV   1.10   23 May 1996 13:43:20   HENRY  $
//
// summary.cpp - implementation of Maximize summary dialog class
//

#include "stdafx.h"
#include "winmxmz.h"
#include "summary.h"
#include "mxdlgs.h"
#include "messages.h"

#include <statmfc.h>

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CSummary dialog


CSummary::CSummary(int nKBLowFree, CWnd* pParent /*=NULL*/)
	: CDialog(CSummary::IDD, pParent)
{
	//{{AFX_DATA_INIT(CSummary)
	m_csTotalFreeHigh = "";
	m_csTotalFreeLow = "";
	m_csTotalUsedHigh = "";
	//}}AFX_DATA_INIT

	m_nKBLowFree = nKBLowFree;
}

void CSummary::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CSummary)
	DDX_Control(pDX, IDC_LOWLIST, m_lbLowList);
	DDX_Control(pDX, IDC_HIGHLIST, m_lbHighList);
	DDX_Text(pDX, IDC_TOTALFREEHIGH, m_csTotalFreeHigh);
	DDX_Text(pDX, IDC_TOTALFREELOW, m_csTotalFreeLow);
	DDX_Text(pDX, IDC_TOTALUSEDHIGH, m_csTotalUsedHigh);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CSummary, CDialog)
	//{{AFX_MSG_MAP(CSummary)
	ON_BN_CLICKED(IDC_REVERT, OnRevert)
	ON_BN_CLICKED(IDC_HELP, OnHelp)
	ON_WM_CLOSE()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


CString CSummary::GetPString( LPCSTR lpEntry, LPCSTR lpDefault ) {
	return AfxGetApp()->GetProfileString( INIS_SUMMARY, lpEntry, lpDefault );
}

int CSummary::GetPInt( LPCSTR lpEntry, int nDefault ) {
	return AfxGetApp()->GetProfileInt( INIS_SUMMARY, lpEntry, nDefault );
}

// Remove lines n through m (origin:1) from a text file.  File will be
// copied to a temp file in the same directory, then the original
// deleted and temp file renamed.
int
RemoveLineN( const char *pszFile, int n, int n2, char *pszFiller ) {

	char szTemp[ _MAX_PATH ], szDrive[ _MAX_DRIVE ], szDir[ _MAX_DIR + 1 ];
#define MAXLINE	_MAX_DIR
	int nCur;
	FILE *pfIn, *pfOut;
	int nFill, nFill2;

	_splitpath( pszFile, szDrive, szDir, NULL, NULL );
	_makepath( szTemp, szDrive, szDir, "%%rmln@@", ".&!#" );

	pfIn = fopen( pszFile, "rt" );
	if (!pfIn) {
		return -1;
	}
	pfOut = fopen( szTemp, "wt" );
	if (!pfOut) {
		fclose( pfIn );
		return -1;
	}

	// Both files are open.  Now copy all but line n
	nCur = 1;
	while (fgets( szDir, MAXLINE, pfIn )) {

		// If truncated, make sure it's null terminated (it won't have a
		// trailing NL, but it won't GPF either)
		szDir[ MAXLINE ] = '\0';

		if (nCur >= n && nCur <= n2) {

			// If a filler was supplied, replace the line
			if (pszFiller && *pszFiller) {

				for (nFill = nFill2 = 0;
					 szDir[ nFill ] && szDir[ nFill ] != '\n';
					 nFill++) {

					szDir[ nFill ] = pszFiller[ nFill2 ];

					// Repeat on last character
					if (pszFiller[ nFill2 + 1 ]) nFill2++;

				} // For all characters in output line

			} // Filler supplied
			else {
				nCur++;
				continue;
			} // Leave it out

		} // Removing these lines

		nCur++;

		fputs( szDir, pfOut );

	} // not EOF

	fclose( pfIn );
	fclose( pfOut );

	// Now delete and rename
	_unlink( pszFile );
	if (rename( szTemp, pszFile ) != 0) {
		return -1;
	} // Rename (or unlink) failed

	return nCur;

} // RemoveLineN()

/////////////////////////////////////////////////////////////////////////////
// CSummary message handlers


// Format a number with thousands separator
void FmtNum( char cThousand, long l, char *pszBuff ) {

	char szBuff[ 64 ];
	int nDig, nIn;

	wsprintf( szBuff, "%ld", l );

	// Separators to add will be (ndigits - 1) / 3
	// Blast in separator at every (n + 1) % 4 == 0 place
	// xx
	// xxx
	// x,xxx
	// xxx,xxx
	// x,xxx,xxx

	// Start counting from the left (high order digit) down, origin:1
	nDig = strlen( szBuff );
	for (nIn = 0, nDig += (nDig - 1) / 3; nDig > 0; nDig--) {
		if (nIn && nDig % 4 == 0) {
			*pszBuff++ = cThousand;
		} // Add separator
		*pszBuff++ = szBuff[ nIn++ ];
	} // For all digits

	*pszBuff = '\0'; // Terminate it

} // FmtNum()

BOOL CSummary::OnInitDialog()
{
	char szTemp[ 256 ], szEntry[ 64 ], szNum[ 64 ], *psz;
	WORD wHighTotal;
	int nHighRegs, n, nReg, nHigh, nLow, nAddTab;
	unsigned long dwSize;
	long lTotal;
	CString cs;

	CDialog::OnInitDialog();

	THEAPP->m_hwndDlg = m_hWnd;

	// Center ourselves
	CenterDialog( this );

	// Set up for string formatting
	char szThousand[ 16 ];

	// Get local thousands separator (, or .)
	::GetProfileString( INIS_INTL, INI_THOUSANDSEP, ",",
				szThousand, sizeof( szThousand ) - 1 );

	// Set tab stops for	>99,999 	xxx,xxx		7
	// 						>9,999		 xx,xxx		6
	// 						>999		  x,xxx		5
	//						>99			    xxx		3
	//						>9				 xx		2
	//						<10				  x		1
	// We'll _assume_ that all numerals are of equal width...

	// First get dialog base units
	DWORD dwBase = ::GetDialogBaseUnits();
	// x * LOWORD( dwBase ) / 4 = size in pixels

	// FIXME calculate this
#define TABBASE	64
#define	TNUMWIDTH 4
#define	TCOMMAWID 2
	int nTabList[ 6 ] = {	TABBASE,
							TABBASE+TNUMWIDTH,
							TABBASE+TNUMWIDTH*2,
							TABBASE+TNUMWIDTH*3+TCOMMAWID,
							TABBASE+TNUMWIDTH*4+TCOMMAWID, 
							TABBASE+TNUMWIDTH*5+TCOMMAWID };

	// How many tabs needed for each numeric length
	static int nTabs[ 10 ] = { 6, 5, 4, 4, 3, 2, 1, 1, 1, 1 };

	m_lbHighList.SetTabStops( 6, nTabList );
	m_lbLowList.SetTabStops( 6, nTabList );

	// Remove line from startup batch file
	cs = GetPString( INI_REMOVELINE, "0," );

	// Save for diagnostics
	AfxGetApp()->WriteProfileString( INIS_LASTACT, INI_REMOVELINE, cs );

	psz = strtok( (LPSTR)(LPCSTR)cs, " \t,\r\n" );
	if (psz) {

		n = atoi( psz );
		psz = strtok( NULL, " \t,\r\n" );

		if (n && psz) {

			// Remove the line from the file, using filler.
			// We can't just remove it because that will confuse the
			// batch file processor.
			RemoveLineN( psz, n, n, "REM winmaxim~" );

			// Now clobber the instruction in the INI file
			AfxGetApp()->WriteProfileString( INIS_SUMMARY, INI_REMOVELINE, "0," );

		} // Line number is valid and there's a filename

	} // Got line number token

	// Remove lines from start of CONFIG.SYS
	cs = GetPString( INI_REMOVEMENU, "0," );

	// Save for diagnostics
	AfxGetApp()->WriteProfileString( INIS_LASTACT, INI_REMOVELINE, cs );

	psz = strtok( (LPSTR)(LPCSTR)cs, " \t,\r\n" );
	if (psz) {

		n = atoi( psz );
		psz = strtok( NULL, " \t,\r\n" );

		if (n && psz) {

			// Remove first n lines completely
			RemoveLineN( psz, 1, n, NULL );

			// Clobber the INI file entry
			AfxGetApp()->WriteProfileString( INIS_SUMMARY, INI_REMOVEMENU, "0," );

		} // Got a valid number of lines and a filename

	} // Got number of lines token

	// Get values from MAXIMIZE.INI

	nHighRegs = GetPInt( INI_NHIGHREGS, 0 );

	// Calculate total high DOS
	wHighTotal = 0;
	for (n = 0; n < nHighRegs; n++) {

		sprintf( szTemp, INI_REGTEMPLATE, n );
		nReg = GetPInt( szTemp, 0 );
		wHighTotal += (WORD)nReg;

	} // For all high DOS regions

	wsprintf( szTemp, FMT_MOVED, (n = GetPInt( INI_HIGHPARAS, 0 )) / 64 );
	m_csTotalUsedHigh = szTemp;

	wsprintf( szTemp, FMT_REMAIN, (wHighTotal - n) / 64 );
	m_csTotalFreeHigh = szTemp;

	sprintf( szTemp, FMT_FREE, m_nKBLowFree );
	m_csTotalFreeLow = szTemp;

	nHigh = GetPInt( INI_NHIGH, 0 );
	nLow = GetPInt( INI_NLOW, 0 );

	m_lbHighList.AddString( DLGMSG_NAMEBYTES );
	m_lbHighList.AddString( "" );

	// Now add high programs to m_csHighList
	lTotal = 0L;
	for (n = 0; n <= nHigh; n++) {

		if (n == nHigh) {

			m_lbHighList.AddString( "" );
			strcpy( szTemp, DLGMSG_TOTAL );
			FmtNum( szThousand[ 0 ], lTotal, szNum );

		} // Use total
		else {

			sprintf( szEntry, INI_HIGHSEGTEMPLATE, n );
			cs = GetPString( szEntry, "" );
			if (cs.IsEmpty()) continue;

			// This is supposed to be a no-no...
			psz = strtok( (LPSTR)(LPCSTR)cs, ", \t\r\n" );
			if (!psz) continue; // No size

			dwSize = atol( psz );
			if (!dwSize) continue; // Bad value

			// Continue getting tokens and adding
			psz = strtok( NULL, " \t\r\n" );
			if (!psz) continue; // No program name

			wsprintf( szTemp, " %s", psz );

			while (psz = strtok( NULL, " \t\r\n" )) {

				strcat( szTemp, " " );
				strcat( szTemp, psz );

			} // while still getting tokens

			// Format size with thousands separator
			FmtNum( szThousand[ 0 ], dwSize, szNum );

			lTotal += dwSize;

		} // Format individual value

		// Add the correct number of tabs
		nAddTab = nTabs[ strlen( szNum ) - 1 ];

		// Now paste size onto end
		psz = szTemp + strlen( szTemp );
		strncpy( psz, "\t\t\t\t\t\t\t", nAddTab );
		sprintf( &psz[ nAddTab ], "%s", szNum );

		m_lbHighList.AddString( szTemp );

	} // for all high programs

	if (nLow > 0) {

		m_lbLowList.AddString( DLGMSG_NAMEBYTES );
		m_lbLowList.AddString( "" );

	}
	else {

		m_lbLowList.AddString( "" );
		m_lbLowList.AddString( DLGMSG_NOLOW1 );
		m_lbLowList.AddString( DLGMSG_NOLOW2 );
		m_lbLowList.AddString( DLGMSG_NOLOW3 );
#ifdef DLGMSG_NOLOW4
		m_lbLowList.AddString( DLGMSG_NOLOW4 );
#endif

	}

	// Add low programs to m_lbLowDos
	lTotal = 0L;
	for (n = 0; n <= nLow; n++) {

		if (n == nLow) {

			m_lbLowList.AddString( "" );

			strcpy( szTemp, DLGMSG_TOTAL );
			FmtNum( szThousand[ 0 ], lTotal, szNum );

		} // Format total
		else {

			sprintf( szEntry, "Loseg%d", n );
			cs = GetPString( szEntry, "" );
			if (cs.IsEmpty()) continue;

			// This is supposed to be a no-no...
			psz = strtok( (LPSTR)(LPCSTR)cs, ", \t\r\n" );
			if (!psz) continue; // No size

			dwSize = atol( psz );
			if (!dwSize) continue; // Bad value

			// Continue getting tokens and adding
			psz = strtok( NULL, " \t\r\n" );
			if (!psz) continue; // No program name

			wsprintf( szTemp, " %s", psz );

			while (psz = strtok( NULL, " \t\r\n" )) {

				strcat( szTemp, " " );
				strcat( szTemp, psz );

			} // while still getting tokens

			// Format size with thousands separator
			FmtNum( szThousand[ 0 ], dwSize, szNum );

			lTotal += dwSize;

		} // Format individual value

		// Add the correct number of tabs
		nAddTab = nTabs[ strlen( szNum ) - 1 ];

		// Now paste size onto end
		psz = szTemp + strlen( szTemp );
		strncpy( psz, "\t\t\t\t\t\t\t", nAddTab );
		sprintf( &psz[ nAddTab ], "%s", szNum );

		m_lbLowList.AddString( szTemp );

	} // for all low programs

	// Set ourselves up for forced switching from blue screen
	THEAPP->m_CWndSummary = this;

	// Finally, update the dialog with variables
	UpdateData( FALSE );

	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CSummary::OnRevert()
{
	EndDialog( IDC_REVERT );
}

void CSummary::OnHelp()
{
	THEAPP->WinHelp( HID_BASE_RESOURCE+IDD );
}

void CSummary::OnOK()
{
	// Void the switching pointer
	THEAPP->m_CWndSummary = NULL;

	// Shut down help
	THEAPP->WinHelp( 0L, HELP_QUIT );

	CDialog::OnOK();
}

void CSummary::OnClose()
{
	// Void the switching pointer
	THEAPP->m_CWndSummary = NULL;

	CDialog::OnClose();
}
