// $Header:   P:/PVCS/MAX/MAXSETUP/CLEAN.C_V   1.1   13 Dec 1995 11:51:36   PETERJ  $
//
// clean.c - a program to run copyfile.bat and then to remove
// copyfile.bat and the directory it is in. Used in MAX 8.01 install
// to get around the windows file sharing violation.
// created by Peter Johnson (PETERJ) 12/4/95
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3
//
// pass in:
// name of batch file with path.
// name of QMAX directory
// name of Windows directory
// run the file, then delete the file and the directory.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <process.h>

    // Executes another program, overlaying current space
extern int MyExecv( char __far *lpCmd, char __far *lpCmdTail );

char *cw = "clean.com  Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3";
        
char *szSetup = "setup.exe /C";
char *szWin = "win.com";


int main( int argc, char **argv )
    {
    int len;
    char szOutCmd[ _MAX_PATH * 2 + 21 ];
    char szDrive[ _MAX_PATH + 1 ];
    char szPath[  _MAX_PATH + 1 ];

    len = strlen( argv[1] );
    if ( len < 8 )
        {
        _unlink( "clean.exe" );
        return 0;
        }
   
        // get the path from the filename.
    _splitpath( argv[1], szDrive, szPath, NULL, NULL );
    _makepath( szOutCmd, szDrive, szPath, NULL, NULL );

    len = strlen( szOutCmd );
    if ( szOutCmd[ len-1 ] == '\\' )
        {
        szOutCmd[ len-1 ] = '\0';
        }

        // run the batch file.
    system( argv[1] );
        // delete the batch file.
    _unlink( argv[1] );
        // remove the directory.
    _rmdir( szOutCmd );
        
        // delete this file (clean.exe)
    _unlink( "clean.exe" );

    return 0;
    }
    
