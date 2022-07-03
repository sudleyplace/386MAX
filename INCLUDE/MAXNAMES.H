// $Header:   P:/PVCS/MAX/INCLUDE/MAXNAMES.H_V   1.1   04 Nov 1995 22:14:24   HENRY  $
//
// MAXPNAMES.H -- Max 8 product names
//
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3
//
// This file contains definitions for the MAX 8 product.
// Try to use constants from this file for source files and resource
// scripts.  Note that if you use #define'd stuff in string resources,
// you'll need to use RCPPP as the regular resource compiler preprocessor
// will heave big time.
//
// If any .EXE or .DLL names are changed here, MAXNAMES.MAK will also
// need to be changed.

#ifndef MAXNAMES_INCLUDED

#define MAXNAMES_INCLUDED

// Short product name and various lengths of abbreviations
#define MAX8PRODUCT			"Qualitas Max 8"
#define	MAX_ABBR_MC			"Max 8"
#define MAX_ABBR8			"QMAX"
#define MAX_ABBR4			"QMAX"
#define MAX_ABBR3			"QMX"
#define MAX_ABBR2			"QM"

// Help file name
#define	MAXHELP				"MAXHELP"
#define	MAXHELP_HLP			MAXHELP ".HLP"

//----------------------------------------------

#define	QDISPATCH_ABBR_MC	MAX_ABBR_MC
#define	QDISPATCH_ABBR8		MAX_ABBR8
#define	QDISPATCH_ABBR4		MAX_ABBR4
#define	QDISPATCH_ABBR3		MAX_ABBR3
#define	QDISPATCH_ABBR2		MAX_ABBR2


// Component names
#define QDADDRESS			"QDADDRES"
#define	QDADDRESS_MC		"QDAddres"
#define QDADDRESS_EXE		QDADDRESS ".EXE"
#define	QDADDRESS_CAPTION	QDISPATCH " Address Book"
#define	QDADDRESS_ICAPTION	"Address Book"
#define QDADDRESS_WCLASS    QDADDRESS_MC "WClass"

// Custom control module and window class names
#define QDCTRL				"QDCTRL"
#define QDCTRL_MC			"QDCtrl"
#define QDCTRL_DLL			QDCTRL ".DLL"
#define QDCTRLSHEET_WCLASS	"QDispCtrlSheetWClass"
#define QDCTRLTAB_WCLASS	"QDispCtrlTabWClass"

// File extensions
#define QMETAFILE			"QDM"
#define QMETAFILE_EXT		"." QMETAFILE
#define	QMETAFILE_LC		"qdm"
#define	DIRECTOR_ABBR3		"QDD"
#define DIRECTOR_EXT		"." DIRECTOR_ABBR3
#define SENDMOD_EXT			".DLL"
#define	QDCSCRIPT			"QDC"
#define QDCSCRIPT_EXT		"." QDCSCRIPT


// Help file name (used by all helpful components)
#define	QDHELP				QDISPATCH_ABBR8
#define	QDHELP_HLP			QDHELP ".HLP"		// Used for registered users
#define	QDPGMGR_HLP			QDPGMGR ".HLP"		// Used for unregistered QDPgMgr users

// Tutorial Help file name 
#define	QDTUTORIAL			"QDTUTOR"
#define QDTUTORIAL_CAPTION	        QDISPATCH_ABBR_MC " Tutorial"
#define	QDTUTORIAL_HLP			QDTUTORIAL ".HLP"

// and the setup help
#define QDSETUP_HLP			QDISPATCH_ABBR2 "SETUP.HLP"

// Constants used in About Box definitions
#define ABOUT_About "About "
#define ABOUT_Version "Version "
#define ABOUT_ThisProductIsLicensedTo "This product is licensed to: "
#define ABOUT_SerialNumber "Serial Number: "

// Names for WIN.INI (used for QDISPTCH.DRV)
#define WINI_NAME		QDISPATCH
#define WINI_DRVNAME		QDISPATCH_ABBR8		// [drvname,port]
#define WINI_DRVPORT		QDISPATCH_ABBR3
#define WINI_DRVPORTCOLON	WINI_DRVPORT ":"	// Dispatch=drvname,port:,15,45
#define WINI_LASTDEVICE		"LastDevice"		// Under [drvname,port] section

// .INI file name, section names, and entry names.
#define INI_NAME			QDISPATCH_ABBR8 ".INI"
#define INI_CONFIG			"Config"
#define 	INI_CONFIG_DBFILES		"DB Files"
#define 	INI_CONFIG_DISPACH_PATH		"Dispatch Path"
#define 	INI_CONFIG_LIBRARY		"Library"
#define		INI_CONFIG_QDMFILES		QMETAFILE " Files"
#define		INI_CONFIG_SERVICES		"Services"
#define 	INI_CONFIG_SHAREDIR		"Share Dir"
#define		INI_CONFIG_COVERPAGE 	"Cover Page"
#define 	INI_CONFIG_COVERDIR		"Cover Dir"
#define		INI_CONFIG_USECOVER		"Use Cover"
#define		INI_CONFIG_TRAYDELETEOPT "Tray Delete Opt"
#define 	INI_CONFIG_TRAYDELETEDELAY "Tray Delete Delay"
#define		INI_CONFIG_TRAYDIR		"Tray Dir"
#define		INI_CONFIG_LOADCENTRAL	"Load Central"
#define		INI_CONFIG_LOADSERVER	"Load Server"
#define	INI_EMAIL					"E-mail"
#define		INI_EMAIL_TEXTCONV		"Text Conversion"
#define	INI_QDSERV					QDISPSRV_MC
#define		INI_QDSERV_SOUNDS		"Sounds"
#define INI_USER					"User"
#define		INI_USER_USERID			"UserID"
#define		INI_USER_FIRSTNAME		"FirstName"
#define		INI_USER_LASTNAME		"LastName"
#define		INI_USER_ORG			"Org"
#define		INI_USER_SERIALNUMBER	"SerialNumber"
#define INI_LOGINDATA				"Login Data Types"
#define		INI_LOGINDATA_NCOLS		"Number Columns"
#define		INI_LOGINDATA_COLUMN	"Column"	// Column0, etc.
#define		INI_LOGINDATA_PASSWORD	0x0001		// Bit set in ColumnN flags
// Machine definitions must correspond to Machine_str in GLOBALS.TXT
// and DEFSTR in CDBCONST.H.  There's also a connection to Comm_str,
// defined in QDCOMM.TXT, and in QDCOMM.CPP.
#define	INI_MACHINE					"Machine"
#define		INI_MACHINE_COMPORT		"ComPort"
#define		INI_MACHINE_BPS			"BPS"
#define		INI_MACHINE_PARITY		"Parity"
#define		INI_MACHINE_DATABITS	"DataBits"
#define		INI_MACHINE_STOPBITS	"StopBits"
#define		INI_MACHINE_MODEMNAME	"ModemName"
#define		INI_MACHINE_MODEMINIT	"ModemInit"
#define		INI_MACHINE_MODEMDIAL	"ModemDial"
#define		INI_MACHINE_MODEMCLOSE	"ModemClose"

// QDAddress INI section entries
#define INI_QDADDRESS "QDAddress"
#define		INI_QDADDRESS_ACTION "Action"
	// Executed action: time,hwnd,act,type,key (e.g., 123...456,23456,Edit,Device,PD1)
	// QDAddres executes this action when it receives a QDADDRESS_ACTION_MSG messages.
	// time = time_t value from time() function when entry was written.
	//		QDAddres only acts on relatively recent actions (controlled by
	//		INI_QDADRESS_ACTION_TIMEOUT specification).
	// hwnd = HWND of Send Dialog initiating transaction.
	// act = Action: N=New or Edit
	// type = Individual, Organization, Group, or Device
	// key = Database key (only for Edit action; may be omitted)
	// When messages begins processing an QDADDRESS_ACTIONTAKEN_MSG
	// is sent back to QDSEND so it knows processing has started.
	// When processing is complete another QDADDRESS_ACTIONTAKEN_MSG
	// is sent with a non-zero WPARAM indicating action is complete.
	// The WPARAM contains the HWND of QDADDRESS application so that
	// subsequent messages (such as QDADDRESS_GROUP_MSG can be sent 
	// to the QDADDRESS).
	// FIXME You need not remind me what a big KLUDGE this is... it
	// should be redone for a subsequent release.
#define			INI_QDADDRESS_ACT_NEW "New"
#define			INI_QDADDRESS_ACT_EDIT "Edit"
#define			INI_QDADDRESS_TYPE_IND "Ind"
#define			INI_QDADDRESS_TYPE_ORG "Org"
#define			INI_QDADDRESS_TYPE_GRP "Grp"
#define			INI_QDADDRESS_TYPE_DEV "Dev"

#define 	INI_QDADDRESS_ACTION_TIMEOUT "Action Timeout"
	// Maximum age of INI_QDADDRESS_ACTION entry that will be processed

// Send dialog
#define INI_QDSEND	QDSEND_MC

// Components that need their own data in the ini file should just use
// their name for a section name, e.g. QDISPSRV, etc.

// INI names used in QDPREFS
#define QDPREFS_INI			QDPREFS_MC						// INI section 
#define 	QDPREFS_X		"X Position"					// MRU position (in QDPREFS_INI section)
#define 	QDPREFS_Y		"Y Position"
#define QDPREFS_INI_INFO_USR	QDPREFS_INI " User Info"	// User Information section

#define	QDSTATUS_INI		QDSTATUS_MC						// INI section 
#define 	QDSTATUS_X		"X Position"					// MRU position (in QDSTATUS_INI section)
#define 	QDSTATUS_Y		"Y Position"

// Registration database name
#define REG_NAME			QDISPATCH_ABBR8 ".REG"

// Service Names
#define SVC_MSMAIL                      "MSMail"
#define SVC_CCMAIL                      "CCMail"
#define SVC_GWMAIL                      "GWMail"
#define SVC_MHSMAIL                     "MHSMail"
#define SVC_NOTES                       "Notes"
#define SVC_WINFAX                      "WinFax"
#define SVC_LANFAX                      "LanFax"
#define SVC_BFAX                        "BitWare"
#define SVC_FAXWORKS                    "FaxWorks"
#define SVC_AOL                         "AOL"
#define SVC_TCP                         "TCPIP"
#define SVC_NOVELL                      "Novell"

// Miscellaneous objects
#define	DEFAULTINI			"default.ini"	// network config ini
#define	REGISTERINI			"register.ini"	// user disk id
#define	DISPATCHER			"Dispatcher"		// A standalone script
#define DIRECTOR			"Dispatch Director" // A director script
#define GLOBAL_SYMBOLS		"GLOBALS.TXT"		// VB type definitions
#define DBFIELD_CFG			"QDBFIELD.CFG"		// Field definitions
#define SCRIPTLANG			"Dispatch Basic"	// Name of the script language
#define INITQDB_TXT			"INITQDB.TXT"		// Used by BLDQDB
#define INITNET_TXT			"INITNET.TXT"		// Used by BLDQDB
#define QDCOMM_TXT			QDCOMM ".TXT"		// Used by QDCOMM

#define QDEVAP                          "evap"          // directory evaporator
#define QDEVAP_CAPTION                  UNINSTAL_CAPTION " directory remover"  
#define QDEVAP_COM                      QDEVAP ".com"   
#define QDEVAP_PIF                      QDEVAP ".pif"   

#endif

