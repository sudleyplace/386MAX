// SETUPDDE.C
//    SETUPDDE uses the DDE execute facility in ProgMan.  Each call to
//    an API here causes a DDE conversation to be set up, the execute
//    request made and the conversation terminated.

#include "setup.h"
#include <stdio.h>
#include <ddeml.h>
#include <string.h>


// local functions
static BOOL SendExecCmd(LPSTR lpszCmd);
HDDEDATA CALLBACK DDECallback(UINT, UINT, HCONV, HSZ, HSZ, HDDEDATA, DWORD, DWORD);


DWORD dwDDEInst = 0;

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
BOOL FAR PASCAL pmQueryGroup( LPSTR lpszGroup, LPSTR lpszItem )
{
	int rval = 0, i;
	char szItemName[128];
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

			for (i = 0; ((lpItemNames != 0L) && (*lpItemNames)); i++) {

				// kludge for Win95 bug
				sscanf(((*lpItemNames == '"') ? lpItemNames+1 : lpItemNames), "%[^,\r\"]", szItemName );

				// skip first line (group summary)
				if ((i > 0) && ((lstrcmpi(szItemName, lpszItem) == 0) || (lstrcmpi( "*", lpszItem) == 0))) {
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


// Create / Activate a group
BOOL FAR PASCAL pmCreateGroup(LPSTR lpszGroup, LPSTR lpszPath)
{
	char szBuf[256];

	if (lpszPath && lstrlen(lpszPath))
		wsprintf(szBuf, "[CreateGroup(%s,%s)]", lpszGroup, lpszPath);
	else
		wsprintf(szBuf,  "[CreateGroup(%s)]", lpszGroup);

	return SendExecCmd(szBuf);
}


// Delete group
BOOL FAR PASCAL pmDeleteGroup(LPSTR lpszGroup)
{
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszGroup && lstrlen(lpszGroup))
		wsprintf(szBuf, "[DeleteGroup(%s)]", lpszGroup);

	return SendExecCmd(szBuf);
}


// Show a group
BOOL FAR PASCAL pmShowGroup(LPSTR lpszGroup, WORD wCmd)
{
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszGroup && lstrlen(lpszGroup))
		wsprintf(szBuf, "[ShowGroup(%s,%u)]", lpszGroup, wCmd);

	return SendExecCmd(szBuf);
}


// Add a new item to a group
BOOL FAR PASCAL pmAddItem(LPSTR lpszCmdLine, LPSTR lpszCaption, LPSTR lpszIcon, int fMinimize)
{
	char szBuf[256];

	if (fMinimize)
		wsprintf(szBuf, "[AddItem(%s,%s,%s,,,,,,1)]", lpszCmdLine, lpszCaption, lpszIcon);
	else
		wsprintf(szBuf, "[AddItem(%s,%s,%s)]", lpszCmdLine, lpszCaption, lpszIcon);

	return SendExecCmd(szBuf);
}


// Delete an item from a group
BOOL FAR PASCAL pmDeleteItem(LPSTR lpszItem)
{
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszItem && lstrlen(lpszItem))
		wsprintf(szBuf, "[DeleteItem(%s)]", lpszItem);

	return SendExecCmd(szBuf);
}


// Replace an item in a group
BOOL FAR PASCAL pmReplaceItem(LPSTR lpszItem)
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

	SetupYield(0);

	// Initiate a conversation with the PROGMAN service on the PROGMAN topic.
	hszProgman = DdeCreateStringHandle(dwDDEInst, "PROGMAN", CP_WINANSI);

	hConv = DdeConnect(dwDDEInst, hszProgman, hszProgman, NULL);

	// Free the HSZ now
	DdeFreeStringHandle(dwDDEInst, hszProgman);
	SetupYield(0);

	if (!hConv)
		return FALSE;

	// Create a data handle for the exec string
	hExecData = DdeCreateDataHandle(dwDDEInst, lpszCmd, lstrlen(lpszCmd)+1, 0, NULL, 0, 0);
	SetupYield(0);

	// Send the execute request
	rval = (int)DdeClientTransaction((void FAR *)hExecData, (DWORD)-1, hConv, NULL, 0, XTYP_EXECUTE, 5000, NULL);
	SetupYield(0);

	// Done with the conversation now.
	DdeDisconnect(hConv);
	SetupYield(0);

	return rval;
}

