// $Header:   P:/PVCS/MAX/MAXHELP/HELPAFX.H_V   1.0   01 Nov 1995 14:46:06   HENRY  $
//
// HELPAFX.H - Constants used in AFX projects
//
// Copyright (C) 1995 Qualitas, Inc.
// GNU General Public License version 3.
//
// Reverse engineered AFXHELP.HM source file.  Used to generate
// application-specific references to AFX standard definitions
// for MFC applications.

// Non-Client HitTest help IDs
#define IDHT_NOWHERE                      0x0000
#define IDHT_CAPTION                      0x0002
#define IDHT_SIZE                         0x0004
#define IDHT_HSCROLL                      0x0006
#define IDHT_VSCROLL                      0x0007
#define IDHT_MINBUTTON                    0x0008
#define IDHT_MAXBUTTON                    0x0009
#define IDHT_LEFT                         0x000A // alias: IDHT_SIZE
#define IDHT_RIGHT                        0x000B // alias: IDHT_SIZE
#define IDHT_TOP                          0x000C // alias: IDHT_SIZE
#define IDHT_TOPLEFT                      0x000D // alias: IDHT_SIZE
#define IDHT_TOPRIGHT                     0x000E // alias: IDHT_SIZE
#define IDHT_BOTTOM                       0x000F // alias: IDHT_SIZE
#define IDHT_BOTTOMLEFT                   0x0010 // alias: IDHT_SIZE
#define IDHT_BOTTOMRIGHT                  0x0011 // alias: IDHT_SIZE
#define IDHT_BORDER                       0x0012 // alias: IDHT_SIZE

// WM_SYSCOMMAND help IDs
#define ID_SC_SIZE                         0xEF00
#define ID_SC_MOVE                         0xEF01
#define ID_SC_MINIMIZE                     0xEF02
#define ID_SC_MAXIMIZE                     0xEF03
#define ID_SC_NEXTWINDOW                   0xEF04
#define ID_SC_PREVWINDOW                   0xEF05
#define ID_SC_CLOSE                        0xEF06
#define ID_SC_RESTORE                      0xEF12
#define ID_SC_TASKLIST                     0xEF13

// File MRU and aliases
#define ID_FILE_MRU_FILE1                  0xE110
#define ID_FILE_MRU_FILE2                  0xE111 // alias: ID_FILE_MRU_FILE1
#define ID_FILE_MRU_FILE3                  0xE112 // alias: ID_FILE_MRU_FILE1
#define ID_FILE_MRU_FILE4                  0xE113 // alias: ID_FILE_MRU_FILE1

// Window menu list
#define ID_WINDOW_ALL                      0xEF1F

// Commands (HID_*)
#define ID_FILE_NEW                        0xE100
#define ID_FILE_OPEN                       0xE101
#define ID_FILE_CLOSE                      0xE102
#define ID_FILE_SAVE                       0xE103
#define ID_FILE_SAVE_AS                    0xE104
#define ID_FILE_PAGE_SETUP                 0xE105
#define ID_FILE_PRINT_SETUP                0xE106
#define ID_FILE_PRINT                      0xE107
#define ID_FILE_PRINT_PREVIEW              0xE108
#define ID_FILE_UPDATE                     0xE109
#define ID_FILE_SAVE_COPY_AS               0xE10A
#define ID_EDIT_CLEAR                      0xE120
#define ID_EDIT_CLEAR_ALL                  0xE121
#define ID_EDIT_COPY                       0xE122
#define ID_EDIT_CUT                        0xE123
#define ID_EDIT_FIND                       0xE124
#define ID_EDIT_PASTE                      0xE125
#define ID_EDIT_PASTE_LINK                 0xE126
#define ID_EDIT_PASTE_SPECIAL              0xE127
#define ID_EDIT_REPEAT                     0xE128
#define ID_EDIT_REPLACE                    0xE129
#define ID_EDIT_SELECT_ALL                 0xE12A
#define ID_EDIT_UNDO                       0xE12B
#define ID_EDIT_REDO                       0xE12C
#define ID_WINDOW_NEW                      0xE130
#define ID_WINDOW_ARRANGE                  0xE131
#define ID_WINDOW_CASCADE                  0xE132
#define ID_WINDOW_TILE_HORZ                0xE133
#define ID_WINDOW_TILE_VERT                0xE134
#define ID_WINDOW_SPLIT                    0xE135
#define ID_APP_ABOUT                       0xE140
#define ID_APP_EXIT                        0xE141
#define ID_HELP_INDEX                      0xE142
#define ID_HELP_USING                      0xE143
#define ID_CONTEXT_HELP                    0xE144
#define ID_NEXT_PANE                       0xE150
#define ID_PREV_PANE                       0xE151
#define ID_OLE_INSERT_NEW                  0xE200
#define ID_OLE_EDIT_LINKS                  0xE201
#define ID_OLE_EDIT_CONVERT                0xE202
#define ID_OLE_EDIT_CHANGE_ICON            0xE203
#define ID_VIEW_TOOLBAR                    0xE800
#define ID_VIEW_STATUS_BAR                 0xE801
#define ID_RECORD_FIRST                    0xE900
#define ID_RECORD_LAST                     0xE901
#define ID_RECORD_NEXT                     0xE902
#define ID_RECORD_PREV                     0xE903

// Dialogs (AFX_HIDD_*)
#define IDD_AFX_FILEOPEN                   0x7004
#define IDD_AFX_FILESAVE                   0x7005
#define IDD_AFX_FONT                       0x7006
#define IDD_AFX_COLOR                      0x7007
#define IDD_AFX_PRINT                      0x7008
#define IDD_AFX_PRINTSETUP                 0x7009
#define IDD_AFX_FIND                       0x700A
#define IDD_AFX_REPLACE                    0x700B
#define IDD_AFX_NEWTYPEDLG                 0x7801
#define IDD_AFX_PRINTDLG                   0x7802
#define IDD_AFX_PREVIEW_TOOLBAR            0x7803
#define IDD_AFX_INSERTOBJECT               0x7804
#define IDD_AFX_CHANGEICON                 0x7805
#define IDD_AFX_CONVERT                    0x7806
#define IDD_AFX_PASTESPECIAL               0x7807
#define IDD_AFX_EDITLINKS                  0x7808
#define IDD_AFX_FILEBROWSE                 0x7809
#define IDD_AFX_BUSY                       0x780A

// Prompts/Errors (AFX_HIDP_*)
#define IDP_AFX_INVALID_FILENAME           0xF100
#define IDP_AFX_FAILED_TO_OPEN_DOC         0xF101
#define IDP_AFX_FAILED_TO_SAVE_DOC         0xF102
#define IDP_AFX_ASK_TO_SAVE                0xF103
#define IDP_AFX_FAILED_TO_CREATE_DOC       0xF104
#define IDP_AFX_FILE_TOO_LARGE             0xF105
#define IDP_AFX_FAILED_TO_START_PRINT      0xF106
#define IDP_AFX_FAILED_TO_LAUNCH_HELP      0xF107
#define IDP_AFX_INTERNAL_FAILURE           0xF108
#define IDP_AFX_COMMAND_FAILURE            0xF109
#define IDP_AFX_FAILED_MEMORY_ALLOC        0xF10A
#define IDP_AFX_VB2APICALLED               0xF10B
#define IDP_AFX_PARSE_INT                  0xF110
#define IDP_AFX_PARSE_REAL                 0xF111
#define IDP_AFX_PARSE_INT_RANGE            0xF112
#define IDP_AFX_PARSE_REAL_RANGE           0xF113
#define IDP_AFX_PARSE_STRING_SIZE          0xF114
#define IDP_AFX_PARSE_RADIO_BUTTON         0xF115
#define IDP_AFX_FAILED_INVALID_FORMAT      0xF120
#define IDP_AFX_FAILED_INVALID_PATH        0xF121
#define IDP_AFX_FAILED_DISK_FULL           0xF122
#define IDP_AFX_FAILED_ACCESS_READ         0xF123
#define IDP_AFX_FAILED_ACCESS_WRITE        0xF124
#define IDP_AFX_FAILED_IO_ERROR_READ       0xF125
#define IDP_AFX_FAILED_IO_ERROR_WRITE      0xF126
#define IDP_AFX_STATIC_OBJECT              0xF180
#define IDP_AFX_FAILED_TO_CONNECT          0xF181
#define IDP_AFX_SERVER_BUSY                0xF182
#define IDP_AFX_BAD_VERB                   0xF183
#define IDP_AFX_FAILED_TO_NOTIFY           0xF185
#define IDP_AFX_FAILED_TO_LAUNCH           0xF186
#define IDP_AFX_ASK_TO_UPDATE              0xF187
#define IDP_AFX_FAILED_TO_UPDATE           0xF188
#define IDP_AFX_FAILED_TO_REGISTER         0xF189
#define IDP_AFX_FAILED_TO_AUTO_REGISTER    0xF18A
#define IDP_AFX_FAILED_TO_CONVERT          0xF18B

// Frame Controls (AFX_HIDW_*)
#define IDW_AFX_TOOLBAR                    0xE800
#define IDW_AFX_STATUS_BAR                 0xE801
#define IDW_AFX_PREVIEW_BAR                0xE802
#define IDW_AFX_RESIZE_BAR                 0xE803

/////////////////////////////////////////////////////////////////////////////
