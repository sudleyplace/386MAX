//  $Header:   P:/PVCS/MAX/SETUP/SETDDE.CPV   1.4   20 Jan 1997 08:36:50   PETERJ  $
//------------------------------------------------------------------
// SS_DDE.CPP
// DDE Functions for SysSaver
// April 8, 1996
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3
//------------------------------------------------------------------
// Uses the DDE execute facility in ProgMan.  Each call to
// an API here causes a DDE conversation to be set up, the execute
// request made and the conversation terminated.
//------------------------------------------------------------------
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <ddeml.h>

#include <setglob.h>

// local functions
static BOOL SendExecCmd(LPSTR lpszCmd);
HDDEDATA CALLBACK DDECallback(UINT, UINT, HCONV, HSZ, HSZ, HDDEDATA, DWORD, DWORD);

DWORD dwDDEInst = 0;

//------------------------------------------------------------------
// Installs a program into a program group.
// returns: 0 = success, -1 = can't initDDE, 1 = Can't create group.
//------------------------------------------------------------------
int AddItemIconToGroup( LPSTR szCmdLine, LPSTR szTitle, LPSTR szIcon, 
                        int nIconIndex, LPSTR szGroupName, BOOL bClose )
    {
    int nRet = 0;

        // turn it on.
    if( InitDDE() )
        {
        if( pmCreateGroup( szGroupName, szC_Null ))
            {
            SYield(0);

            pmShowGroup( szGroupName, 1 );
            SYield(0);

            pmDeleteItem( szTitle );
            SYield(0);

            pmAddItemIcon( szCmdLine, szTitle, szIcon, nIconIndex, 0 );
            SYield(0);

            if( bClose )
                {
                pmShowGroup( szGroupName, SW_SHOWMINIMIZED );
                SYield(0);
                }
            }
        else
            {
            nRet = 1;
            }

            // turn it off.
        EndDDE();
        }
    else
        {
        nRet = (-1);
        }

    return nRet;
    }

//------------------------------------------------------------------
// Installs a program into a program group.
// returns: 0 = success, -1 = can't initDDE, 1 = Can't create group.
//------------------------------------------------------------------
int AddItemToGroup( LPSTR szCmdLine, LPSTR szTitle, LPSTR szGroupName, BOOL bClose )
    {
    int nRet = 0;

        // turn it on.
    if( InitDDE() )
        {
        if( pmCreateGroup( szGroupName, szC_Null ))
            {
            SYield(0);

            pmShowGroup( szGroupName, 1 );
            SYield(0);

            pmDeleteItem( szTitle );
            SYield(0);

            pmAddItem( szCmdLine, szTitle, szC_Null, 0 );
            SYield(0);

            if( bClose )
                {
                pmShowGroup( szGroupName, SW_SHOWMINIMIZED );
                SYield(0);
                }
            }
        else
            {
            nRet = 1;
            }

            // turn it off.
        EndDDE();
        }
    else
        {
        nRet = (-1);
        }

    return nRet;
    }

//------------------------------------------------------------------
// Delete an item from a program group.
//------------------------------------------------------------------
void DeleteItemFromGroup( LPSTR szTitle, LPSTR szGroupName, BOOL bClose )
    {
        // turn it on.
    if( InitDDE() )
        {
        if( pmShowGroup( szGroupName, 1 ))
            {
            SYield(0);

            pmShowGroup( szGroupName, 1 );
            SYield(0);

            pmDeleteItem( szTitle );
            SYield(0);

            pmDeleteItem( szTitle );
            SYield(0);

            if( bClose )
                {
                pmShowGroup( szGroupName, SW_SHOWMINIMIZED );
                SYield(0);
                }
            }

            // turn it off.
        EndDDE();
        }
    }

//------------------------------------------------------------------
// return a buffer full of group names.
//------------------------------------------------------------------
LPSTR GetGroups( )
    {
    DWORD rval;
    DWORD dwMem;
    LPSTR szBuff = NULL;
    HSZ hszProgman;
    HSZ hszProgData;
    HCONV hConv;
	HDDEDATA hProgData=NULL;

    if( InitDDE() )
        {
        hszProgman = DdeCreateStringHandle(dwDDEInst, "PROGMAN", CP_WINANSI);
        SYield(0);

            // say "Howdy do?" to progman.
        hConv = DdeConnect(dwDDEInst, hszProgman, hszProgman, NULL);
        SYield(0);

        DdeFreeStringHandle(dwDDEInst, hszProgman);
        SYield(0);

        hszProgData = DdeCreateStringHandle(dwDDEInst, "GROUPS", CP_WINANSI);
        SYield(0);

        hProgData = DdeClientTransaction( NULL, (DWORD)0, hConv, hszProgData, 
                                        CF_TEXT, XTYP_REQUEST, 5000, NULL );
        SYield(0);

        if( hProgData )
            {
            dwMem = DdeGetData( hProgData, (LPBYTE) NULL, 0L, 0L);
            szBuff = (LPSTR)GetMem( (int)dwMem + 2 );

            rval = DdeGetData( hProgData, (LPBYTE)szBuff, dwMem, 0L);
            SYield(0);

            DdeFreeDataHandle( hProgData);
            SYield(0);
            }

        DdeFreeStringHandle(dwDDEInst, hszProgData);
        SYield(0);

            // Done with the conversation now.
        DdeDisconnect(hConv);
        SYield(0);

        EndDDE();
        }

    return szBuff;
    }

//------------------------------------------------------------------
// Fill a buffer full of group names, return count of items.
//------------------------------------------------------------------
int GetGroupItemList( LPSTR szGroup, LPSTR FAR *szBuff )
    {
    int i=0;
    DWORD rval=0;
    DWORD dwMem;
    LPSTR szT1=NULL;
    LPSTR lpScan;
    HSZ hszProgman;
    HSZ hszProgData;
    HCONV hConv;
	HDDEDATA hProgData=NULL;

    if( InitDDE() )
        {
        hszProgman = DdeCreateStringHandle(dwDDEInst, "PROGMAN", CP_WINANSI);
        SYield(0);

            // say "Hi ya" to progman.
        hConv = DdeConnect(dwDDEInst, hszProgman, hszProgman, NULL);
        SYield(0);

        DdeFreeStringHandle(dwDDEInst, hszProgman);
        SYield(0);

        hszProgData = DdeCreateStringHandle(dwDDEInst, szGroup, CP_WINANSI);
        SYield(0);

        hProgData = DdeClientTransaction( NULL, (DWORD)0, hConv, hszProgData, 
                                        CF_TEXT, XTYP_REQUEST, 5000, NULL );
        SYield(0);

        if( hProgData )
            {
            dwMem = DdeGetData( hProgData, (LPBYTE) NULL, 0L, 0L);
            (*szBuff) = (LPSTR)GetMem( (int)dwMem + 2 );
            szT1 = (LPSTR)GetMem( (int)dwMem + 2 );

            rval = DdeGetData( hProgData, (LPBYTE)(*szBuff), dwMem, 0L);
            SYield(0);
            DdeFreeDataHandle( hProgData);
            SYield(0);
            }

        DdeFreeStringHandle(dwDDEInst, hszProgData);
        SYield(0);

            // Done with the conversation now.
        DdeDisconnect(hConv);
        SYield(0);

        EndDDE();
        }
        
    if(( rval > 0 ) && szT1 )
        {
            // move the data to the strtok buffer.
        _fmemcpy( szT1, (*szBuff), (int)dwMem );
            // this is a null loop to count the entries.
            // the first entry is the group name.
        for( lpScan = _fstrtok( szT1, "\r\n" ), i=0;
             lpScan != NULL ;
             lpScan = _fstrtok( NULL, "\r\n" ), i++ );

            // reduce count by one to allow for the group name line.
        i -= 1;
        }

    if( szT1 )
        {
        _ffree( szT1 );
        }
    return i;
    }


//------------------------------------------------------------------
// Delete a program group.
//------------------------------------------------------------------
void DeleteGroup( LPSTR szGroupName )
    {
        // turn it on.
    if( InitDDE() )
        {
        pmDeleteGroup( szGroupName );
        SYield(0);
            // turn it off.
        EndDDE();
        }
    }

//------------------------------------------------------------------
// open a DDE connection
//------------------------------------------------------------------
unsigned int InitDDE(void)
    {
        // Initialize DDEML
	if (DdeInitialize(&dwDDEInst, DDECallback, CBF_FAIL_ALLSVRXACTIONS, 0l) != DMLERR_NO_ERROR)
        {
		return FALSE;
        }
	return TRUE;
    }

//------------------------------------------------------------------
// end a DDE connection
//------------------------------------------------------------------
void EndDDE(void)
    {
        // Done with DDEML
	DdeUninitialize(dwDDEInst);
	dwDDEInst = 0;
    }

//------------------------------------------------------------------
// query if a group contains an item
//------------------------------------------------------------------
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
	if ((hConv = DdeConnect(dwDDEInst, hszServer, hszServer, 0L)) != 0L) 
        {
		hDDEData = DdeClientTransaction(0L,0L,hConv,hszTopic,CF_TEXT,XTYP_REQUEST,5000L,NULL);

		if (hDDEData) 
            {
			lpItemNames = (LPSTR)DdeAccessData(hDDEData, NULL);
			if (lpItemNames)
                {
                for (i = 0; *lpItemNames; i++) 
                    {
                        
                        // Ensure we don't copy more data than is there as the DDE
                        // host can set the selector limit on the returned data to be low
                    len = lstrlen (lpItemNames) + 1; // Count in trailing zero
                    len = min (len, sizeof (szLocalItem));

                        // Copy to local buffer so we can use this in a small model
                    _fmemcpy (szLocalItem, lpItemNames, len);
                    
                        // kludge for Win95 bug
                    sscanf(szLocalItem + (*szLocalItem == '"'), "%[^,\r\"]", szItemName );
            
                        // skip first line (group summary)
                    if ((i > 0) && (lstrcmpi(szItemName, lpszItem) == 0)) 
                        {
                        rval = 1;
                        break;
                        }

                    while (*lpItemNames++ != '\n');
                    }
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

//------------------------------------------------------------------
// Create a group
//------------------------------------------------------------------
BOOL pmCreateGroup(LPSTR lpszGroup, LPSTR lpszPath)
    {
	char szBuf[256];

	if (lpszPath && lstrlen(lpszPath))
        {
		wsprintf(szBuf, "[CreateGroup(%s,%s)]", lpszGroup, lpszPath);
        }
	else
        {
		wsprintf(szBuf,  "[CreateGroup(%s)]", lpszGroup);
        }
	return SendExecCmd(szBuf);
    }

//------------------------------------------------------------------
// Delete group
//------------------------------------------------------------------
BOOL pmDeleteGroup(LPSTR lpszGroup)
    {
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszGroup && lstrlen(lpszGroup))
        {
		wsprintf(szBuf, "[DeleteGroup(%s)]", lpszGroup);
        }
	return SendExecCmd(szBuf);
    }

//------------------------------------------------------------------
// Show a group
//------------------------------------------------------------------
BOOL pmShowGroup(LPSTR lpszGroup, WORD wCmd)
    {
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszGroup && lstrlen(lpszGroup))
        {
		wsprintf(szBuf, "[ShowGroup(%s,%u)]", lpszGroup, wCmd);
        }
	return SendExecCmd(szBuf);
    }

//------------------------------------------------------------------
// Add a new item to a group
//------------------------------------------------------------------
BOOL pmAddItem(LPSTR lpszCmdLine, LPSTR lpszCaption, LPSTR lpszIcon, int fMinimize)
    {
	char szBuf[256];

	if (fMinimize)
        {
        wsprintf(szBuf, "[AddItem(%s,%s,%s,,,,,,1)]", lpszCmdLine, lpszCaption, lpszIcon );
        }
    else
        {
		wsprintf(szBuf, "[AddItem(%s,%s,%s)]", lpszCmdLine, lpszCaption, lpszIcon );
        }

	return SendExecCmd(szBuf);
    }

//------------------------------------------------------------------
// Add a new item to a group, specifying icon and index.
//------------------------------------------------------------------
BOOL pmAddItemIcon(LPSTR lpszCmdLine, LPSTR lpszCaption, LPSTR lpszIcon, 
                                        int nIconIndex, int fMinimize)
    {
	char szBuf[256];

	if (fMinimize)
        {
        wsprintf(szBuf, "[AddItem(%s,%s,%s,%d,,,,,1)]", lpszCmdLine, 
                         lpszCaption, lpszIcon, nIconIndex );
        }
    else
        {
		wsprintf(szBuf, "[AddItem(%s,%s,%s,%d)]", lpszCmdLine, 
                         lpszCaption, lpszIcon, nIconIndex );
        }

	return SendExecCmd(szBuf);
    }

//------------------------------------------------------------------
// Delete an item from a group
//------------------------------------------------------------------
BOOL pmDeleteItem(LPSTR lpszItem)
    {
	char szBuf[256];
	szBuf[0] = '\0';
	if (lpszItem && lstrlen(lpszItem))
        {
		wsprintf(szBuf, "[DeleteItem(%s)]", lpszItem);
        }
	return SendExecCmd(szBuf);
    }

//------------------------------------------------------------------
// Replace an item from a group
//------------------------------------------------------------------
BOOL pmReplaceItem(LPSTR lpszItem)
    {
	char szBuf[256];

	szBuf[0] = '\0';
	if (lpszItem && lstrlen(lpszItem))
        {
		wsprintf(szBuf, "[ReplaceItem(%s)]", lpszItem);
        }
	return SendExecCmd(szBuf);
    }

//------------------------------------------------------------------
// Callback function for DDE messages
//------------------------------------------------------------------
HDDEDATA CALLBACK DDECallback(UINT wType, UINT wFmt, HCONV hConv,
      HSZ hsz1, HSZ hsz2, HDDEDATA hDDEData, DWORD dwData1, DWORD dwData2)
    {
	return NULL;
    }

//------------------------------------------------------------------
// Send an execute request to the Program Manager
//------------------------------------------------------------------
static BOOL SendExecCmd(LPSTR lpszCmd)
    {
	HSZ hszProgman;
	HCONV hConv;
	HDDEDATA hExecData;
	int rval;
    
        // Initiate a conversation with the PROGMAN service on the PROGMAN topic.
    hszProgman = DdeCreateStringHandle(dwDDEInst, "PROGMAN", CP_WINANSI);
	SYield(0);

	hConv = DdeConnect(dwDDEInst, hszProgman, hszProgman, NULL);

    DdeFreeStringHandle(dwDDEInst, hszProgman);
    SYield(0);

	if ( !hConv )
        {
        return FALSE;
        }

        // Create a data handle for the exec string
	hExecData = DdeCreateDataHandle(dwDDEInst, ( LPBYTE )lpszCmd, lstrlen(lpszCmd)+1, 0, NULL, CF_TEXT, 0);
	SYield(0);

        // Send the execute request
	rval = (int)DdeClientTransaction((LPBYTE)hExecData, (DWORD)-1, hConv, NULL, 0, XTYP_EXECUTE, 5000, NULL);
	SYield(0);

        // Done with the conversation now.
	DdeDisconnect(hConv);
	SYield(0);

	return rval;
    }

