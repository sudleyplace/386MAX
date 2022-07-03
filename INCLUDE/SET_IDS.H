// $Header:   P:/PVCS/MAX/INCLUDE/SET_IDS.H_V   1.1   20 Jan 1997 08:41:06   PETERJ  $
//------------------------------------------------------------------
// SET_IDS.H
// Identifiers for Qualitas Setup
// Version 1.0
// 7 June, 1996
// Copyright (C) 1996 Qualitas, Inc.  GNU General Public License version 3
//------------------------------------------------------------------

#define SU_OK                             0
#define SU_CANCEL                         1

#define SETICON                         500
#define SETICON1                        501
#define SETCLEAN                        502

#define IDD_ABOUT                       100
#define IDD_MODELESS                    101
#define IDD_DIRECTORY                   102

#define IDC_VERSION                     1000
#define IDC_COPY                        1001
#define IDC_STATUS1                     1002
#define IDC_STATUS2                     1003
#define IDC_METER                       1004
#define IDC_INSTDIR                     1005

    // reserved window messages
#define IDM_EXIT                        ( WM_USER + 1 )
#define IDM_ABOUT                       ( WM_USER + 2 )
#define IDM_HELP                        ( WM_USER + 3 )
#define IDM_HELPCONTENTS                ( WM_USER + 4 )
#define IDM_INTRO                       ( WM_USER + 5 )
    
    // should match last element of reserved windows messages above.
#define IDM_RESERVED                    ( WM_USER + 5 )

