/* qpopup.h - Copyright (C) 1993-5 Qualitas, Inc.  All Rights Reserved. */

#define STR_APPNAME	"QPOPUP"        // Application name
#define STR_PROFILE	"QMAX.INI"      // Profile filename


// Resource identitifiers

#define IDD_MODESW		100	// Mode switch dialog
#define IDT_MSG 		101
#define IDT_NAME		102
#define IDT_MODE		103
#define IDB_IGNORE		110	// Ignore this time
#define IDB_ALWAYS		111	// Always ignore
#define IDB_TERMINATE		112	// Terminate the VM button
#define IDB_MODESWHELP		113	// Give me more help button

#define IDD_MODESWHELP		200	// Mode switch help dialog
#define IDE_HELP		201	// Help text edit control
#define ID_HELPTEXT		202	// Help text RCDATA resource

#define ID_WARNTEXT		203	// 'WARN' text RCDATA resource
#define ID_FAILTEXT		204	// 'FAIL' text RCDATA resource

#define IDD_TERMINATE		300	// Terminate VM warning dialog

#define IDD_REFUSE		400	// 'Refuse to run in the future' dialog
#define IDT_REFUSE_FILENAME	401	// Filename static text

#define IDD_INSUF		500	// Insufficient Windows mode dialog
#define IDB_EXPERT		501	// Don't remind me again checkbox

#define IDD_CFGWARN		600	// 386LOAD.CFG warning dialog
#define IDT_CFG_FILENAME	601	// Filename static text
#define IDE_CFG_HELPTEXT	602	// Help text edit control
#define IDB_CFG_FUTURE		603	// Don't warm me again

// String resources

#define IDS_ERR_REGISTER_CLASS	1
#define IDS_ERR_CREATE_WINDOW	2
#define IDS_ERR_NOT_BUILT	3
#define IDS_ERR_INSTANCE	4

#define IDS_386MAX_WARN 	10	// "386MAX Warning"
#define IDS_386MAX_VXDWARN	11	// "DOSMAX is not available ..."

