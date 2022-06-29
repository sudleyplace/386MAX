//' $Header:   P:/PVCS/MAX/MAXCTRL/SETUPDDE.C_V   1.5   06 Feb 1996 10:43:10   BOB  $
//
// SETUPDDE.C
//    SETUPDDE uses the DDE execute facility in ProgMan.  Each call to
//    an API here causes a DDE conversation to be set up, the execute
//    request made and the conversation terminated.

#include <windows.h>
#include <stdio.h>
#include <ddeml.h>
#include <string.h>


// local functions
static BOOL SendExecCmd(LPSTR lpszCmd);
HDDEDATA CALLBACK DDECallback(UINT, UINT, HCONV, HSZ, HSZ, HDDEDATA, DWORD, DWORD);


DWORD dwDDEInst = 0;


// receive & dispatch Windows messages
void ToolboxYield(int bWait)
{
	MSG msg;

	// process any waiting messages
	while (PeekMessage( &msg, NULL, 0, 0, PM_REMOVE )) {
ProcessMessage:
		bWait = 0;
		TranslateMessage( &msg );
		DispatchMessage( &msg );
	}

	// if "Wait" flag set, go to sleep until a message arrives
	if ((bWait) && (GetMessage(&msg, NULL, 0, 0)))
		goto ProcessMessage;
}


// open a DDE connection
unsigned int InitDDE(void)
{
	// Initialize DDEML
	if (DdeInitialize(&dwDDEInst, DDECallback, CBF_FAIL_ALLSVRXACTIONS, 0l) != DMLERR_NO_ERROR)
		return FALSE;

	return TRUE;
}


// end a DDE connection
void EndDDE(void)
{
	// Done with DDEML
	DdeUninitialize(dwDDEInst);
	dwDDEInst = 0;
}


// query if a group contains an item
BOOL pmQueryGroup( LPSTR lpszGroup, LPSTR lpszItem )
{
	int rval = 0, i, len;
	char szItemName[128], szLocalItem[128];
	LPSTR lpItemNames;
	HDDEDATA hDDEData = 0L;
	HSZ hszServer, hszTopic;
	HCONV hConv;

	hszServer = DdeCreateStringHandle(dwDDEInst, "PROGMAN", CP_WINANSI);
	hszTopic = DdeCreateStringHandle(dwDDEInst, lpszGroup, CP_WINANSI);

	// Connect to PROGMAN
	if ((hConv = DdeConnect(dwDDEInst, hszServer, hszServer, 0L)) != 0L) {

		hDDEData = DdeClientTransaction(0L,0L,hConv,hszTopic,CF_TEXT,XTYP_REQUEST,5000L,NULL);

		if (hDDEData) {

			lpItemNames = DdeAccessData(hDDEData, NULL);
			
			if (lpItemNames)
			for (i = 0; *lpItemNames; i++) {

				// Ensure we don't copy more data than is there as the DDE
				// host can set the selector limit on the returned data to be low
				len = lstrlen (lpItemNames) + 1; // Count in trailing zero
				len = min (len, sizeof (szLocalItem));

				// Copy to local buffer so we can use this in a small model
				_fmemcpy (szLocalItem, lpItemNames, len);
				
				// kludge for Win95 bug
				sscanf(szLocalItem + (*szLocalItem == '"'), "%[^,\r\"]", szItemName );

				// skip first line (group summary)
				if ((i > 0) && (lstrcmpi(szItemName, lpszItem) == 0)) {
					rval = 1;
					break;
				}

				while (*lpItemNames++ != '\n')
					;
			}

			DdeFreeDataHandle(hDDEData);
		}

		// disconnect from PROGMAN
		DdeDisconnect(hConv);
	}

	DdeFreeStringHandle(dwDDEInst, hszServer);
	DdeFreeStringHandle(dwDDEInst, hszTopic);

	return rval;
}


// Create a group
BOOL pmCreateGroup(LPSTR lpszGroup, LPSTR lpszPath)
{
	char szBuf[256];

	if (lpszPath && lstrlen(lpszPath))
		wsprintf(szBuf, "[CreateGroup(%s,%s)]", lpszGroup, lpszPath);
	else
		wsprintf(szBuf,  "[CreateGroup(%s)]", lpszGroup);

	return SendExecCmd(szBuf);
}


// Delete group
BOOL pmDeleteGroup(LPSTR lpszGroup)
{
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszGroup && lstrlen(lpszGroup))
		wsprintf(szBuf, "[DeleteGroup(%s)]", lpszGroup);

	return SendExecCmd(szBuf);
}


// Show a group
BOOL pmShowGroup(LPSTR lpszGroup, WORD wCmd)
{
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszGroup && lstrlen(lpszGroup))
		wsprintf(szBuf, "[ShowGroup(%s,%u)]", lpszGroup, wCmd);

	return SendExecCmd(szBuf);
}


// Add a new item to a group
BOOL pmAddItem(LPSTR lpszCmdLine, LPSTR lpszCaption, int fMinimize)
{
	char szBuf[256];

	if (fMinimize)
		wsprintf(szBuf, "[AddItem(%s,%s,,,,,,,1)]", lpszCmdLine, lpszCaption);
	else
		wsprintf(szBuf, "[AddItem(%s,%s)]", lpszCmdLine, lpszCaption, lpszCmdLine);

	return SendExecCmd(szBuf);
}


// Delete an item from a group
BOOL pmDeleteItem(LPSTR lpszItem)
{
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszItem && lstrlen(lpszItem))
		wsprintf(szBuf, "[DeleteItem(%s)]", lpszItem);

	return SendExecCmd(szBuf);
}


// Delete an item from a group
BOOL pmReplaceItem(LPSTR lpszItem)
{
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszItem && lstrlen(lpszItem))
		wsprintf(szBuf, "[ReplaceItem(%s)]", lpszItem);

	return SendExecCmd(szBuf);
}


// Callback function for DDE messages
HDDEDATA CALLBACK DDECallback(UINT wType, UINT wFmt, HCONV hConv,
      HSZ hsz1, HSZ hsz2, HDDEDATA hDDEData, DWORD dwData1, DWORD dwData2)
{
	return NULL;
}


// Send an execute request to the Program Manager
static BOOL SendExecCmd(LPSTR lpszCmd)
{
	HSZ hszProgman;
	HCONV hConv;
	HDDEDATA hExecData;
	int rval;

	// Initiate a conversation with the PROGMAN service on the PROGMAN topic.
	hszProgman = DdeCreateStringHandle(dwDDEInst, "PROGMAN", CP_WINANSI);
	ToolboxYield(0);

	hConv = DdeConnect(dwDDEInst, hszProgman, hszProgman, NULL);

	// Free the HSZ now
	DdeFreeStringHandle(dwDDEInst, hszProgman);
	ToolboxYield(0);

	if (!hConv)
		return FALSE;

	// Create a data handle for the exec string
	hExecData = DdeCreateDataHandle(dwDDEInst, lpszCmd, lstrlen(lpszCmd)+1, 0, NULL, 0, 0);
	ToolboxYield(0);

	// Send the execute request
	rval = (int)DdeClientTransaction((void FAR *)hExecData, (DWORD)-1, hConv, NULL, 0, XTYP_EXECUTE, 5000, NULL);
	ToolboxYield(0);

	// Done with the conversation now.
	DdeDisconnect(hConv);
	ToolboxYield(0);

	return rval;
}

