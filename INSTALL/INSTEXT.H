/*' $Header:   P:/PVCS/MAX/INSTALL/INSTEXT.H_V   1.6   27 Feb 1996 12:05:58   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INSTEXT.H								      *
 *									      *
 * Text strings for INSTALL.EXE 					      *
 *									      *
 ******************************************************************************/

/*ÚÄ 8	Mar 1992 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿*/
/*³see modification remarks in all other files (transferred to GERMAN) ³*/
/*ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/

#ifndef INSTEXT_INCLUDED
#define INSTEXT_INCLUDED

#include "commdef.h"            /* Common (shared) definitions */
#include "dialog.h"             /* Dialog box defines/functions */
#include "libtext.h"            /* Color definitions */
#include "libcolor.h"           /* Color definitions */

#ifdef OWNER
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL
  #define GLINIT
#else
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL extern
#endif /*  OWNER  */

/*
 *------------------------------------------------------------------
 *	Shared
 *------------------------------------------------------------------
 */

GLOBAL char *TitleMessage
#ifdef GLINIT
#ifdef LANG_GR
= " Meldung "           /* Action title for dialog boxes */
#else
= " Message "           /* Action title for dialog boxes */
#endif
#endif
;

GLOBAL char *TitleAction
#ifdef GLINIT
#ifdef LANG_GR
= " Aktion "            /* Action title for dialog boxes */
#else
= " Action "            /* Action title for dialog boxes */
#endif
#endif
;

GLOBAL char *TitleError
#ifdef GLINIT
#ifdef LANG_GR
= " Fehler "             /* Error title for dialog boxes */
#else
= " Error "             /* Error title for dialog boxes */
#endif
#endif
;

GLOBAL char *TitleWarning
#ifdef GLINIT
#ifdef LANG_GR
= " Achtung "           /* Warning title for dialog boxes */
#else
= " Warning "           /* Warning title for dialog boxes */
#endif
#endif
;

GLOBAL char *TitleCopyright
#ifdef GLINIT
#ifdef LANG_GR
= " Copyright "         /* Copyright title for dialog boxes */
#else
= " Copyright "         /* Copyright title for dialog boxes */
#endif
#endif
;

GLOBAL char *TitleFileDir
#ifdef GLINIT
#ifdef LANG_GR
= " Datei-Verzeichnis "    /* Title for dest path dialog box */
#else
= " File Directory "    /* Title for dest path dialog box */
#endif
#endif
;

GLOBAL char *pszStripmgrOut	/* File we pass to STRIPMGR /E */
#ifdef GLINIT
 = STRIPMGR ".OUT"
#endif
;

GLOBAL char *MsgFileRwErr	/* flerw_error */
#ifdef GLINIT
#ifdef LANG_GR
= "Fehler aufgetaucht beim Lesen/Schreiben von %s.\n"
   "zurck zum DOS.\n\n";
#else
= "An error occurred while reading/writing %s.\n"
   "Exiting to DOS.\n\n";
#endif
#endif
;

GLOBAL char *MsgMallocErr
#ifdef GLINIT
#ifdef LANG_GR
 =	 /* malloc_error */
	"kann Speicher nicht erreichen fr %s.\n"
	"zurck zum DOS.\n\n"
#else
 =	 /* malloc_error */
	"Unable to allocate memory for %s.\n"
	"Exiting to DOS.\n\n"
#endif
#endif
;

GLOBAL char *MsgKingston
#ifdef GLINIT
#ifdef LANG_GR
 =	 /* Kingston Message */
    "DEBUG=EPM   ; Fr die Kingston Datacard\n"
#else
 =	 /* Kingston Message */
    "DEBUG=EPM   ; For the Kingston Datacard\n"
#endif
#endif
;



GLOBAL char *MsgFilePosErr
#ifdef GLINIT
#ifdef LANG_GR
 =	 /* flepos_error */
	"Datei-Suchfehler aufgetaucht in %s.\n"
	"zurck zum DOS.\n\n"
#else
 =	 /* flepos_error */
	"A file seek error occurred in %s.\n"
	"Exiting to DOS.\n\n"
#endif
#endif
;

#if !MOVEM
GLOBAL char *MsgGetMovem
#ifdef GLINIT
=
#ifdef LANG_GR
	"MOVE'EM Untersttzung nicht verfgbar. Setzen Sie sich mit dem\n"
	"Qualitas Kundendienst (Telefonnummer siehe Handbuch) in Verbindung\n"
	"um die MOVE'EM Module zu erhalten.\n"
#else
	"Move'EM support code not available.  Please contact Qualitas tech\n"
	"support or BBS (see documentation for phone number) to obtain the\n"
	"Move'EM support code modules.\n"
#endif
#endif
;
#endif // not MOVEM

GLOBAL char *MsgScanningFile
#ifdef GLINIT
=
#ifdef LANG_GR
	"durchsuche Datei %s\n"
#else
	"Scanning file %s\n"
#endif
#endif
;

GLOBAL char *ProIgnoreFlex
#ifdef GLINIT
=
#ifdef LANG_GR
	"IgnoreFlexFrame   ; "PROGNAME" ==> Wird von Maximize entfernt\n";
#else
	"IgnoreFlexFrame   ; "PROGNAME" ==> To be deleted by Maximize\n";
#endif
#endif
;

/*
 *	This enum must match the HelpInfo array below.
 */

enum _helpnumber {
	HELP_CPYRGHT = HELPOPTEDITOR + 1,
	/*10*/
	HELP_DESTDRV,
	HELP_BOOTDSK,
	HELP_CONFIGSYS,
	HELP_GETWNDPFNE,
	HELP_DOMAXIMIZE,
	HELP_NOMAXIMIZE,
	HELP_NOWIN,
	HELP_GETMONO,
	HELP_UPDATEDIR,
	HELP_SMARTDRV,
	/*20*/
	HELP_USERINFO,
	HELP_SRCDRV,
	HELP_ABRT,
	HELP_NOSMARTDRV,
	HELP_QI_INTRO,
	HELP_QU_INTRO,
	HELP_DOSDIR,
	HELP_QMT,
	HELP_REFDSK,
	HELP_SWAPDRIVE,
	/*30*/
	HELP_MBMENU,
	HELP_EMSON,
	HELP_EMSOFF,
	HELP_SMARTDRVMB,
	HELP_QMTMB,		// Unused
	HELPCOUNT		/* 35 */
};

/*
*  There is an explicit extern reference to this
*  in help.c.  Make sure if you change one, you change the other
*/
GLOBAL HELPDEF HelpInfo[ HELPCOUNT + 1 ]
#ifdef GLINIT
= {
	{ HELP_INSTALL, "H.Contents",   0, NULL },      /*  0    */
	{ HELP_INSTALL, "H.Index",      0, NULL },      /*  1    */
	{ HELP_INSTALL, "H.U_Help",     0, NULL },      /*  2    */
	{ HELP_INSTALL, "H.Default",    0, NULL },      /*  3    */
	{ HELP_INSTALL, "H.U_Dial",     0, NULL },      /*  4    */
	{ HELP_INSTALL, "H.U_Print",    0, NULL },      /*  5    */
	{ HELP_INSTALL, "H.U_Editor",   0, NULL },      /*  6    */
	{ HELP_INSTALL, "H.U_Browse",   0, NULL },      /*  7    */
	{ HELP_INSTALL, "H.E_Option",   0, NULL },      /*  8    */
	{ HELP_INSTALL, "I_cpyrght",    0, NULL },
	/*10*/
	{ HELP_INSTALL, "I_destdrv",    0, NULL },
	{ HELP_INSTALL, "I_bootdsk",    0, NULL },
	{ HELP_INSTALL, "I_configsys",  0, NULL },
	{ HELP_INSTALL, "I_getwndpfne", 0, NULL },
	{ HELP_INSTALL, "I_maximize",   0, NULL },
	{ HELP_INSTALL, "I_nomaximize", 0, NULL },
	{ HELP_INSTALL, "I_nowin",      0, NULL },
	{ HELP_INSTALL, "I_getmono",    0, NULL },
	{ HELP_INSTALL, "I_updatedir",  0, NULL },
	{ HELP_INSTALL, "I_smartdrv",   0, NULL },
	/*20*/
	{ HELP_INSTALL, "I_userinfo",   0, NULL },
	{ HELP_INSTALL, "I_srcdrv",     0, NULL },
	{ HELP_INSTALL, "I_abrt" ,      0, NULL },
	{ HELP_INSTALL, "I_nosmartdrv", 0, NULL },
	{ HELP_INSTALL_Q, "Q_I_Intro",  0, NULL }, /* HELP_QI_INTRO */
	{ HELP_INSTALL_Q, "Q_U_Intro",  0, NULL }, /* HELP_QU_INTRO */
	{ HELP_INSTALL, "I_getdosdir",  0, NULL }, /* HELP_DOSDIR */
	{ HELP_INSTALL, "I_QMT",        0, NULL }, /* HELP_QMT */
	{ HELP_INSTALL, "I_RefDsk",     0, NULL }, /* HELP_REFDSK */
	{ HELP_INSTALL, "I_swapdrive",  0, NULL }, /* HELP_SWAPDRIVE */
	/*30*/
	{ HELP_INSTALL, "I_MBMenu",     0, NULL }, /* HELP_MBMENU */
	{ HELP_INSTALL, "I_EMSOn",      0, NULL }, /* HELP_EMSON */
	{ HELP_INSTALL, "I_EMSOff",     0, NULL }, /* HELP_EMSOFF */
	{ HELP_INSTALL, "I_smartdrvMB", 0, NULL }, /* HELP_SMARTDRVMB */
	{ HELP_INSTALL, "I_QMTMB",      0, NULL }, /* HELP_QMTMB */ // Unused
	{ HELP_LAST,	 "",            0, NULL }
}
#endif
;

#define INSTALLARGCNT 12

GLOBAL int InstallArgCnt
#ifdef GLINIT
= INSTALLARGCNT;
#endif
;

GLOBAL char *InstallArgFrom[INSTALLARGCNT]
#ifdef GLINIT
 = {
	"#ARG1#",
	"#ARG2#",
	"#ARG3#",
	"#ARG4#",
	"#PROGNAME#",
	"#FLENME#",
	"#FLENMEXT#",
	"#QCACHE#",
	"#QCACHEBUF#",
	"#PRODFILE#",
	/*10*/
	"#DIR#",
	NULL
}
#endif
;

GLOBAL char *InstallArgTo[INSTALLARGCNT]
#ifdef GLINIT
 = {
	"C",            /* 0 - boot drive */
	"ARG2",         /* 1 */
	" D",           /* 2 - original boot drive */
	"C:",           /* 3 - boot w/ colon (:) */
	PROGNAME,	/* 4 */
	"???",          /* 5 - Filled in from OEM_ProdName at runtime */
	"???",          /* 6 - Filled in from OEM_FileName at runtime */
	QCACHE, 	/* 7 */
	QCACHE_BUF,	/* 8 */
	"???",          /* 9 - Filled in from OEM_Prodfile at runtime */
	/*10*/
	MAX_PRODDIR,	/* 10 */
	NULL
}
#endif
;

GLOBAL int QuickHelpNum 	/* Help number for Quick help window */
#ifdef GLINIT
= 0
#endif
;

#ifdef LANG_GR
#define ABORTESCSTART 8
#else
#define ABORTESCSTART 6
#endif
GLOBAL char *MsgAbortEsc
#ifdef GLINIT
#ifdef LANG_GR
= "Abbruch ESC"
#else
= "Abort Esc"
#endif
#endif
;	/* Label for MainButtons[0] */

GLOBAL char **DosHelpText;

/* The first two elements must be USE (INCLUDE) and RAM (EXCLUDE) */
/* in that order.  Other elements which should not intersect with */
/* a RAM= on the MDA may be added. */
GLOBAL char *UseRam[2]
#ifdef GLINIT
= { USE, RAM }
#endif
;

GLOBAL char *MsgHelpSystemErr
#ifdef GLINIT
#ifdef LANG_GR
 = "Fehler im Hilfe-System\n"
#else
 = "Help system error\n"
#endif
#endif
;

/*
 *------------------------------------------------------------------
 *	install.c (main)
 *------------------------------------------------------------------
 */

#ifdef MAIN_C

extern char PrintName[];	/* In VERSDATA.ASM - Formerly static ProgramName */

#ifdef LANG_GR
static char *MsgWrtReg = "schreibe Registrierungs-Daten\n";
static char *MsgCopyProg = "kopiere Programm-Dateien\n";
static char *MsgDisableRerun = "Bitte Steuerprogramme auáer %s unwirksam machen, dann "PROGNAME" neu starten!\n";
static char *MsgRebootRerun = "Bitte System neu starten, dann "PROGNAME" aufrufen!\n";
static char *MsgBadDosVer = "Dieses Produkt erfordert DOS Version 3.0 oder h”her.\nZurck zum DOS.\n";
static char *MsgNoReinstall = "Die Option /R darf nicht benutzt werden, wenn "PROGNAME" von der\nInstallationsdiskette ausgefhrt wird.\n";
static char *MsgDiskCacheTest = "bewerte Disk Cache\n";
#if REDUIT
static char *MsgNeedDisk = "Option /M ist nur bei Aufruf von der Vertriebsdiskette m”glich.\n";
#endif
#else
static char *MsgWrtReg = "Writing Registration data\n";
static char *MsgCopyProg = "Copying Program files\n";
static char *MsgDisableRerun = "Please disable control programs other than %s and rerun " PROGNAME "\n";
static char *MsgRebootRerun = "Please reboot your system, then rerun "PROGNAME"\n";
static char *MsgBadDosVer = "This product requires DOS Version 3.0 or later.\nExiting to DOS.\n";
static char *MsgNoReinstall = "The /R option may not be used when running "PROGNAME" from the\ndistribution diskette.\n";
#if REDUIT
static char *MsgNeedDisk = "The /M option must be run from the distribution diskette.\n";
#endif
static char *MsgDiskCacheTest = "Evaluating disk cache\n";
#endif

extern char HelpString[];	/* In VERSDATA.ASM */

/* Diagnostic messages displayed during startup_init */
#ifdef LANG_GR
static char *GetSVGAMsg =  "\rprfe Monitor-Typ";
static char *PostSVGAMsg = "\r                 \r";
#else
static char *GetSVGAMsg =  "\rTesting display type";
static char *PostSVGAMsg = "\r                    \r";
#endif

static char *DeleteList[] =   // Delete after copying
{"ctl3dv2.dll",
"goahead.drv",
NULL};

#endif
/*MAIN_C*/

/*
 *------------------------------------------------------------------
 *	scrn.c
 *------------------------------------------------------------------
 */

#ifdef SCRN_C

/*
 *	Notes on dialog boxes:
 *
 *	buttons color	title
 *	------- -----	-----
 *	y/n	any	action
 *	ok	cyan	message
 *	ok	red	error
 *	y/n	red	warning
 */

#ifdef LANG_GR
#define SMALL_DIALOG  40	/* Width for small dialog box */
#define MEDIUM_DIALOG 60	/* Width for medium dialog box */
#else
#define SMALL_DIALOG  36	/* Width for small dialog box */
#define MEDIUM_DIALOG 55	/* Width for medium dialog box */
#endif
#define LARGE_DIALOG  72	/* Width for large dialog box */

static DIALOGTEXT InstallText[3]
= {	{ 2, "S.", HELP_INSTALL_S, SMALL_DIALOG },
	{ 2, "M.", HELP_INSTALL_M, MEDIUM_DIALOG },
	{ 2, "L.", HELP_INSTALL_L, LARGE_DIALOG } };


DIALOGPARM NormalDialog = {	/* Style of normal dialog box */
	MEDIUM_DIALOG,		/*	Outer width of dialog box */
	NorDlgColors,		/*	Attribute list */
	MessageButtons, 	/*	Button list */
	sizeof(MessageButtons)/sizeof(MessageButtons[0]),
	0,			/*	Color for edit field */
	SHADOW_SINGLE,		/*	Shadow control for edit field */
	InstallText		/*	Help type if text comes from help file */
};

DIALOGPARM NormLargeDialog = {	/* Style of normal large dialog box */
	LARGE_DIALOG,		/*	Outer width of dialog box */
	NorDlgColors,		/*	Attribute list */
	MessageButtons, 	/*	Button list */
	sizeof(MessageButtons)/sizeof(MessageButtons[0]),
	0,			/*	Color for edit field */
	SHADOW_SINGLE,		/*	Shadow control for edit field */
	InstallText		/*	Help type if text comes from help file */
};

DIALOGPARM ErrorDialog = {	/* Style of warning message dialog box */
	SMALL_DIALOG,		/*	Outer width of dialog box */
	ErrDlgColors,		/*	Attribute list */
	MessageButtons, 	/*	Button list */
	sizeof(MessageButtons)/sizeof(MessageButtons[0]),
	0,			/*	Color for edit field */
	0,			/*	Shadow control for edit field */
	InstallText		/*	Help type if text comes from help file */
};

DIALOGPARM WarningDialog = {	/* Style of warning message dialog box */
	LARGE_DIALOG,		/*	Outer width of dialog box */
	ErrDlgColors,		/*	Attribute list */
	YesNoButtons,		/*	Button list */
	sizeof(YesNoButtons)/sizeof(YesNoButtons[0]),
	0,			/*	Color for edit field */
	0,			/*	Shadow control for edit field */
	InstallText		/*	Help type if text comes from help file */
};

DIALOGPARM BadUpdDialog = {	/* Style of Bad Update message dialog box */
	LARGE_DIALOG,		/*	Outer width of dialog box */
	ErrDlgColors,		/*	Attribute list */
	UpdateButtons,		/*	Button list */
	sizeof(UpdateButtons)/sizeof(UpdateButtons[0]),
	0,			/*	Color for edit field */
	0,			/*	Shadow control for edit field */
	InstallText		/*	Help type if text comes from help file */
};

DIALOGEDIT DriveEdit = {	/* Field to edit drive letters */
	{ -5, 17, 1, 1 },	/* Edit window */
	NULL,			/* Where to get/put editable string */
	0			/* Length of edit field - Don't forget the null terminator */
};

DIALOGEDIT RegisterEdit = {
	{  7, 16, 1, 46 },	/* Name field */
	NULL,			/* Where to get/put editable string */
	0			/* Length of edit field - Don't forget the null terminator */
};

DIALOGEDIT CompanyEdit = {
	{  9, 16, 1, 46 },	/* Name field */
	NULL,			/* Where to get/put editable string */
	0			/* Length of edit field - Don't forget the null terminator */
};

DIALOGEDIT SerialEdit = {
	{ -5, 28, 1, 16 },	/* Serial number field */
	NULL,			/* Where to get/put editable string */
	0			/* Length of edit field - Don't forget the null terminator */
};

DIALOGEDIT PathEdit = { 	/* Field to path spec */
	{ -5, 2, 1, 50 },	/* Edit window */
	NULL,			/* Where to get/put editable string */
	0			/* Length of edit field - Don't forget the null terminator */
};

DIALOGEDIT Path2Edit = {	/* Field to path spec */
	{ -5, 2, 1, 65 },	/* Edit window */
	NULL,			/* Where to get/put editable string */
	0			/* Length of edit field - Don't forget the null terminator */
};

extern char *MsgLogoText[];	/* In VERSDATA.ASM */
extern char ProgramName[];	/* In VERSDATA.ASM */


/* static char *MsgMoveEm =	"M.MoveEm"; */
static char *MsgNoInstall =	"M.NoInstall";
static char *MsgSrcDrv =	"M.SrcDrv";
static char *MsgSrcWarn =	"S.SrcWarn";
static char *MsgCopyright =	"L.Copyright";
static char *MsgUserinfo =	"L.Userinfo";
static char *MsgBlankWarn =	"S.BlankWarn";
static char *MsgBadNumber =	"S.BadNumber";
static char *MsgDestDir =	"M.DestDir";
static char *MsgDropOut =	"S.Dropout";
static char *MsgMaximize =	"M.Maximize";
static char *MsgMaxBack =	"M.MaxBack";
static char *MsgNoMaximize =	"M.NoMaximize";
static char *MsgConfigSysN =	"L.ConfigSysN";
static char *MsgNoWinSupp =	"M.NoWinSupp";
static char *MsgExecWinErr =	"M.ExecWinErr";
static char *MsgNoWin = 	"M.NoWin";
static char *MsgWinPath =	"M.WinPath";
static char *MsgBadWinSubdir =	"M.BadWinSubdir";
static char *MsgSVGAWarn=	"M.SVGAWarn";
static char *MsgGetMono =	"M.GetMono";
static char *MsgBootDisk =	"S.BootDisk";
static char *MsgInsertBoot =	"S.InsertBoot";
static char *MsgBadDrive =	"S.BadDrive";
static char *MsgUpdateDir =	"M.UpdateDir";
static char *MsgSmartDrv =	"M.SmartDrv";
static char *MsgNoSmartDrv =	"M.NoSmartDrv";
static char *MsgFromWin =	"S.FromWIN";
static char *MsgDosPath =	"M.DOSPath";
static char *MsgDosHelp =	"M.DOSHelp";
static char *MsgBadDosDir =	"M.BadDOSSubdir";
static char *MsgNoCache =	"M.NoCache";
static char *MsgMMMaximize =	"L.MMMaximize";
static char *MsgRefDsk =	"L.RefDsk";
static char *MsgBootSwap =	"M.BootSwap";
static char *MsgQMT =		"M.QMT";
static char *MsgConfirm =	"L.Confirm";
static char *MsgEnableEMS =	"L.EnableEMS";
static char *MsgDisableEMS =	"L.DisableEMS";

#ifdef LANG_GR

static char *MsgGetReg = "ermittle Registrierungs-Daten\n";
static char *MsgGetDest = "ermittle Programm-Verzeichnis\n";
static char *MsgGetBoot = "ermittle Start-Laufwerk\n";
static char *MsgGetWinInfo = "hole Windows-Information\n";
static char *MsgWrtDosHelp = "schreibe DOS-Hilfedatei\n";
static char *MsgCopyADF = "kopiere .ADF-Dateien\n";
static char *MsgReboot = "starte System...\n";
static char *MsgWrtFile = "schreibe %s-Datei\n";
static char *MsgCreateBackup = "lege Sicherungsdateien an\n";

#else

static char *MsgGetReg = "Getting Registration data\n";
static char *MsgGetDest = "Getting Program directory\n";
static char *MsgGetBoot = "Getting Boot drive\n";
static char *MsgGetWinInfo = "Getting Windows information\n";
static char *MsgWrtDosHelp = "Writing DOS help file\n";
static char *MsgCopyADF = "Copying .ADF files\n";
static char *MsgReboot = "Rebooting system...\n";
static char *MsgWrtFile = "Writing %s file\n";
static char *MsgCreateBackup = "Creating file backups\n";

#endif

static char *CfgNoVS_Force =
#ifdef LANG_GR
/*VGASW*/ " ;  " PROGNAME " ==> vom Benutzer angegebener Adapter paát nicht\n";
#else
/*VGASW*/ " ;  " PROGNAME " ==> User designated adapter as unsuitable\n";
#endif

static char *CfgNoVS_Adap =
#ifdef LANG_GR
	  " ;  " PROGNAME " ==> hat %s %s entdeckt\n";
#else
	  " ;  " PROGNAME " ==> %s %s detected\n";
#endif

static char *CfgNoExtraDOS =
#ifdef LANG_GR
	  " ;  " PROGNAME " ==> Windows 3.0 nicht untersttzt\n";
#else
	  " ;  " PROGNAME " ==> Windows 3.0 not supported\n";
#endif

static char *ProMono =		 /* pro_mono */
#ifdef LANG_GR
	"   ; "PROGNAME" ==> stelle RAM im MDA-Bereich her\n";
#else
	"   ; "PROGNAME" ==> Recover RAM in MDA region\n";
#endif

static char *ProNoWin3x =
#ifdef LANG_GR
	"   ; "PROGNAME" ==> installiere keine Windows 3-Untersttzung\n";
#else
	"   ; "PROGNAME" ==> Do not install Windows 3 support code\n";
#endif

static char *ProNoWin30 =
#ifdef LANG_GR
	"   ; "PROGNAME" ==> Windows 3.0 Untersttzung nicht erforderlich\n";
#else
	"   ; "PROGNAME" ==> Windows 3.0 support code not needed\n";
#endif

#if REDUIT

static char *ProBcf =		 /* pro_bcf */
#ifdef LANG_GR
 AUTOBCF"   ; "PROGNAME" ==> BIOS-Komprimierung mit @%04x.BCF\n";
#else
 AUTOBCF"   ; "PROGNAME" ==> Compress the BIOS using @%04x.BCF\n";
#endif

#endif

static char *ProNoEMS =
#ifdef LANG_GR
 "EMS=0   ; "PROGNAME" ==> Schalte EMS Services aus\n";
#else
 "EMS=0   ; "PROGNAME" ==> Disable EMS services\n";
#endif

static char *ProAutoBcf =
#ifdef LANG_GR
 AUTOBCF" /t ; "PROGNAME" ==> BIOS-Komprimierung\n";
#else
 AUTOBCF" /t ; "PROGNAME" ==> Compress the BIOS\n";
#endif

char *MsgAutotemp =
#ifdef LANG_GR
	  "echo off\n"
	  "echo ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ %s " PROGNAME " ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\n"
	  "echo Verlassen Sie bitte ein evtl. Men bzw. jede andere\n"
	  "echo Oberfl„che, sodaá wir MAXIMIZE fortsetzen k”nnen.\n"
	  "echo ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\n"
	  "copy %s ";
#else
	  "echo off\n"
	  "echo ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ %s " PROGNAME " ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\n"
	  "echo Please exit any menu or shell programs as soon as\n"
	  "echo they appear so that we may proceed with MAXIMIZE.\n"
	  "echo ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ\n"
	  "copy %s ";
#endif
//	   copy c:\386max\autoinst.$$$ c:\autoexec.bat
//	   c:\386max\batproc autoexec.bat * 386load
//	   c:\386max\maximize /c


#define NUMREFDISKBUTTONS 3
static BUTTON RefDiskButtons[ NUMREFDISKBUTTONS ] = {
#ifdef LANG_GR
   { { -1, 15 }, 11, "Hilfe F1",     { KEY_F1,      0,   0,  0        }, KEY_F1,     FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 26 }, 12, "Fertig <ÄÙ",   { KEY_ENTER,  'f', 'F', KEY_ALTF }, KEY_ENTER,  TRUE,  TRUE,  7, 3, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 40 }, 12, "Abbruch ESC",  { KEY_ESCAPE, 'a', 'A', KEY_ALTA }, KEY_ESCAPE, FALSE, TRUE,  8, 3, FG_BLUE | BG_GRAY, FALSE },
#else
   { { -1, 15 }, 11, "Help F1",         { KEY_F1,         0, 0, 0 }, KEY_F1,            FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 26 }, 12, "OK",         { KEY_ENTER,  'o', 'O', KEY_ALTO     }, KEY_ENTER,   TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 40 }, 12, "Cancel",          { KEY_ESCAPE, 'c', 'C', KEY_ALTC }, KEY_ESCAPE, FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
#endif
};

BUTTON MMMButtons [] = {
#ifdef LANG_GR
   { {0,0}, 12, "Reboot",    {'r','R',KEY_ALTR,0}, 'R', TRUE,  TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 15, "Ende zu DOS",{'d','D',KEY_ALTD,0}, 'D', FALSE, TRUE, 8, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 15, "mehr Info", {'m','M',KEY_ALTM,0}, 'M', FALSE, TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE }
#else
   { {0,0}, 12, "Reboot",    {'r','R',KEY_ALTR,0}, 'R', TRUE,  TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 15, "Exit to DOS",{'d','D',KEY_ALTD,0}, 'D', FALSE, TRUE, 8, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 15, "More Info", {'m','M',KEY_ALTM,0}, 'M', FALSE, TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE }
#endif
};

BUTTON MBButtons [] = {
#ifdef LANG_GR
   { {0,0}, 16, "Alle Abschnitte", {'a','A',KEY_ALTA,0}, RESP_YES, FALSE,  TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 16, "Dieser Abschnitt", {'d','D',KEY_ALTT,0}, RESP_THIS, TRUE, TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 12, "Nein",         {'n','N',KEY_ALTN,0}, 'N', FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE }
#else
   { {0,0}, 16, "All sections", {'a','A',KEY_ALTA,0}, RESP_YES, FALSE,  TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 16, "This section", {'t','T',KEY_ALTT,0}, RESP_THIS, TRUE, TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 12, "No",           {'n','N',KEY_ALTN,0}, 'N', FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE }
#endif
};

#ifdef LANG_GR
#define FILECHGKEY	KEY_ALTL
#define FILECANKEY	KEY_ALTA
#else
#define FILECHGKEY	KEY_ALTV
#define FILECANKEY	KEY_ALTC
#endif
#define NUMFILECHGBUTTONS 2
static BUTTON FileChgButtons[ NUMFILECHGBUTTONS ] = {
#ifdef LANG_GR
   { { -6, 26 }, 12, "Fertig <ÄÙ",   { KEY_ENTER,  'f', 'F', KEY_ALTF }, KEY_ENTER,  TRUE,  TRUE,  7, 3, FG_BLUE | BG_GRAY, TRUE },
   { { -6, 40 }, 12, "Abbruch",  { 'a', 'A', KEY_ALTA, 0 }, FILECANKEY, FALSE, TRUE,  8, 3, FG_BLUE | BG_GRAY, TRUE },
#else
   { {	-6,  26 }, 12, "OK",         { KEY_ENTER,  'o', 'O', KEY_ALTO     }, KEY_ENTER,   TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, TRUE },
   { {	-6,  40 }, 12, "Cancel",          { 'c', 'C', KEY_ALTC, 0 }, FILECANKEY, FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, TRUE },
#endif
};

typedef struct tagChangeStruct {
  int	Active; 	// 1 if to be displayed
  int	Index;		// Origin:0
  char	*DisplayTxt;	// "README file"
  char	*DisplayFile;	// README (with dest_dpfne prepended)
} CHANGESTRUCT;

enum {
	CHG_README = 0
#if !MOVEM
			  , CHG_WINDOWS
#endif // not MOVEM
};

#ifdef LANG_GR
#define CHANGESTO "nderungen fr "
#else
#define CHANGESTO "Changes to "
#endif
static char *ChangesTo = CHANGESTO "%s%s%s%s";
CHANGESTRUCT Changes[] = {
#ifdef LANG_GR
  {1, -1, "README Datei",
#else
  {1, -1, "README file",
#endif
#if MOVEM
				MOV_README}
#else
				MAX_README},
#endif // not MOVEM
};
#define NUMCHANGES	(sizeof(Changes)/sizeof(Changes[0]))
/*	Bottom of file change viewer window */
#ifdef LANG_GR
#define FDIFFBOTTOMTITLE " [TAB \x18 \x19 <ÄÙ ESC] "
#else
#define FDIFFBOTTOMTITLE " [Tab \x18 \x19 Enter Esc] "
#endif
static char FDiffBottomTitle[sizeof( FDIFFBOTTOMTITLE )] = FDIFFBOTTOMTITLE;

#endif /*SCRN_C*/

/*
 *------------------------------------------------------------------
 *	drve.c
 *------------------------------------------------------------------
 */

#ifdef DRVE_C

static char *MsgBadDest =	"S.BadDest";
static char *MsgBadCreatSub =	"S.BadCreatSub";
static char *MsgInsertDest =	"S.InsertDest";
static char *MsgInsertSrc =	"L.InsertSrc";
static char *MsgInvalidDrv =	"S.InvalidDrv";
static char *MsgNoFreeDisk =	"L.NoFreeDisk";
static char *MsgNoFreeDisk2 =	"L.NoFreeDisk2";

#ifdef LANG_GR
static char *MsgArchiveErr =	 "Datendatei %s ist besch„digt (%s in %s; Fehler %d,).\n"
				 "zurck zum DOS.\n\n";
static char *MsgExtFile =	 "extrahiere %s (%lu Byte)\n";
static char *MsgCreateBack =	 "lege Unterverzeichnis: %s zur Sicherung an,\n";
static char *MsgCopyArchive =	 "kopiere Archiv-Datei %s auf Festplatte,\n";
static char *MsgRenErr =	 "Achtung: Kann %s nicht in %s umbenennen; Fehler %d\n";
static char *MsgCfgParseErr =	 "Fehler bei Analyse von CONFIG.SYS aufgetreten\n";
static char *MsgGetCWD =	 "Fehlermelding von getcwd in save_path.";
static char *MsgChDir = 	 "Chdir erfolglos in restore_path.";
static char *MsgCopyBCF =	 "kopiere @%04X.BCF-Datei\n";
#else
static char *MsgArchiveErr =	 "Data file %s is corrupted (%s in %s; error %d).\n"
				 "Exiting to DOS.\n\n";
static char *MsgExtFile =	 "Extracting %s (%lu bytes)\n";
static char *MsgCreateBack =	 "Creating Backup subdirectory %s\n";
static char *MsgCopyArchive =	 "Copying Archive file %s to hard disk\n";
static char *MsgRenErr =	 "Warning: unable to rename %s to %s; error %d\n";
static char *MsgCfgParseErr =	 "An error occurred parsing CONFIG.SYS\n";
static char *MsgGetCWD =	 "Error return from getcwd in save_path.";
static char *MsgChDir = 	 "Chdir failed in restore_path.";
static char *MsgCopyBCF =	 "Copying @%04X.BCF file\n";
#endif

static char *MsgMBMenu = "H.MBMenu";    /* Help dialog for MultiBoot select, */
					/* not the F1 help. */

#endif /*DRVE_C*/

/*
 *------------------------------------------------------------------
 *	misc.c
 *------------------------------------------------------------------
 */

#ifdef MISC_C

#if REDUIT

/* Written into PROFILE.ADD */
static char *MsgBcfFind =	/* bcffnd_txt */
#ifdef LANG_GR
	"Diese Datei wurde von %s "PROGNAME" angelegt.\r\n"
	"Fr Ihr System paát BCF:  %s\r\n"
	"Fgen Sie Ihrem %s-Profil folgenden Eintrag hinzu,\r\n"
	"um die BIOS-Komprimierung zu aktivieren.\r\n"
	AUTOBCF "        ; lade BIOS-Komprimierungs-Datei\r\n";
#else
	"This file created by %s "PROGNAME".\r\n"
	"The matching BCF for your system is:  %s\r\n"
	"Add the following statement to your %s profile\r\n"
	"to activate BIOS Compression.\r\n"
	AUTOBCF "        ; Load BIOS Compression File\r\n";
#endif

/* Written into PROFILE.ADD */
static char *MsgNoBcf = 	/* nobcf_txt */
#ifdef LANG_GR
	PROGNAME " Kein zu Ihrem System passendes BCF auffindbar.\r\n\r\n"
	"Fragen Sie bei Qualitas an, damit wir helfen k”nnen. Geben\r\n"
	"Sie uns dabei folgende Information ber Ihr System:\r\n"
	"Der BIOS-CRC-Wert ist:  %04X\r\n";
#else
	PROGNAME " did not locate a matching BCF for your system.\r\n\r\n"
	"Call Qualitas with the following information to properly identify\r\n"
	"your system.\r\n"
	"The BIOS CRC value is:  %04X\r\n";
#endif

/* Written into PROFILE.ADD */
static char *MsgNoBcfSys =	/* nobcfsys_txt */
#ifdef LANG_GR
	PROGNAME " stellte fest, daá Ihr System kein Mikrokanal-/IBM-PS/2-386\r\n"
	"ist. Deswegen ist hier keine BIOS-Komprimierung verfgbar.\r\n";
#else
	PROGNAME " has determined that your system is not a Micro Channel or IBM PS/2 386.\r\n"
	"Therefore, BIOS compression support is not available for this system.\r\n";
#endif

#endif	/* ifdef REDUIT */

#ifdef LANG_GR
static char *MsgCfgWriteErr = "Fehler bei Schreiben von CONFIG.SYS";
static char *MsgMAXExecFail = "kann MAXIMIZE nicht ausfhren";
static char *MsgProWriteErr = "Fehler bei Schreiben der Profildatei";
static char *MsgRunStripmgr = "fhre " STRIPMGR " aus";
#else
static char *MsgCfgWriteErr = "Error writing CONFIG.SYS";
static char *MsgMAXExecFail = "Unable to execute MAXIMIZE";
static char *MsgProWriteErr = "Error writing profile";
static char *MsgRunStripmgr = "Executing " STRIPMGR;
#endif

static char *MsgStripMgrErr = "S.StripMgrErr";

#endif	/*MISC_C*/

/*
 *------------------------------------------------------------------
 *	files.c
 *------------------------------------------------------------------
 */

#ifdef FILES_C

static char *ProCreate =	 /* pro_create */
#ifdef LANG_GR
	"   ; Dieses Profil wurde von "PROGNAME" automatisch angelegt\n";
#else
	"   ; This profile created automatically by "PROGNAME"\n";
#endif

//static char *ProEms = 	 /* pro_ems */
//	"   ; "PROGNAME" ==> optimale Einstellung fr WINDOWS 3.0\n";
//	"   ; "PROGNAME" ==> Optimal setting for WINDOWS 3.0\n";

static char *ProNoDPMI =
#ifdef LANG_GR
  NODPMI"   ; "PROGNAME" ==> installiere keine DPMI-Unterst.; %u kB Extended-Memory.\n";
#else
  NODPMI"   ; "PROGNAME" ==> Do not install DPMI support; %uK extended memory.\n";
#endif

#if MOVEM
//static char *ProMoveExclude =
//#ifdef LANG_GR
//	"   ; "PROGNAME" ==> benutze nicht den Monochrom-Bereich\n";
//#else
//	"   ; "PROGNAME" ==> Do not map over monochrome display area\n";
//#endif

static char *ProMoveUMB =
#ifdef LANG_GR
	"   ; "PROGNAME" ==> schalte UMB-Untersttzung ein (XMS-Treiber erforderlich)\n";
#else
	"   ; "PROGNAME" ==> Enable UMB support (XMS driver required)\n";
#endif

#else

static char *ProSwapfile =
#ifdef LANG_GR
  SWAPFILE"=%s /S=8192   ; "PROGNAME" ==> Lege eine 8192 KB tempor„re DPMI Auslagerungs-Datei an\n";
#else
  SWAPFILE"=%s /S=8192   ; "PROGNAME" ==> Create an 8192 KB temporary DPMI swap file\n";
#endif

static char *ProNoSwapfile =
#ifdef LANG_GR
  "; DPMI Auslagerungs-Datei nicht installiert\n";
#define PRONOSWAP_NCMP 25	// Number of characters to compare
#else
  "; DPMI swap file not installed\n";
#define PRONOSWAP_NCMP 25	// Number of characters to compare
#endif

static char *ProOldMMLine =
#ifdef LANG_GR
  "; Vorheriger Memory Manager Eintrag entfernt von " STRIPMGR ":\n";
#else
  "; Previous memory manager line removed by " STRIPMGR ":\n";
#endif

static char *MsgCheckSwap =
#ifdef LANG_GR
 "bewerte Speicherplatz fr DPMI Auslagerungsdatei\n";
#else
 "Evaluating Available space for DPMI swap file\n";
#endif

#endif // IF MOVEM / ELSE

static char *MsgFileOpenErr =  /* flecreat_error */
#ifdef LANG_GR
	"kann Datei %s nicht ”ffnen.\n"
	"zurck zum DOS.\n\n";
#else
	"Cannot open file %s.\n"
	"Exiting to DOS.\n\n";
#endif

static char *MsgProError = "S.ProError";

static char *MsgFileRdOnly = "S.RdOnly";

static char *MsgPreInst =
#ifdef LANG_GR
	"REM  Diese Datei wurde von " PROGNAME " angelegt\n"
#else
	"REM  This file created by " PROGNAME "\n"
#endif
	"if exist %spremaxim.bat call %spremaxim.bat\n";

/* Tokens we can ignore when placing QCACHE or QMT */
static char *ValidCmdTokens = "||break|cd|chdir|copy|date|del|dir|echo|era"
			      "|erase|md|mkdir|path|pause|prompt|rd|rem|rmdir"
			      "|set|time|truename|ver|verify|";

/* Tokens we know are internal commands (specifically, they can't be */
/* batch commands).  LH and LOADHIGH should have been skipped over. */
static char *ValidCmdTokens2 = "|if|goto|lh|loadhigh|";

#endif	/*FILES_C*/

/*
 *------------------------------------------------------------------
 *	security.c
 *------------------------------------------------------------------
 */

#ifdef SECURITY_C

static char *MsgBadUpdSubdir =	"M.BadUpdSubdir";
static char *MsgUnLocate = "S.UnLocate";

#endif /*SECURITY_C*/

#ifdef INPRINT_C

#ifdef LANG_GR
static char *Printing = "Drucke Seite %d...";
#else
static char *Printing = "Printing page %d...";
#endif

typedef enum {
	PRINTTYPEHELP,
	PRINTTYPEFILE,
	PRINTTYPENONE
} PRINTTITLETYPE;

static char *PRINTTYPETEXT[PRINTTYPENONE] = {
#ifdef LANG_GR
	"HILFE",
	"DATEI"
#else
	"HELP",
	"FILE"
#endif
};

#ifdef LANG_GR
#define PRINTPAGETITLE " von Qualitas"
#else
#define PRINTPAGETITLE " by Qualitas"
#endif
static char PrintPageTitle[ sizeof( PRINTPAGETITLE )]
= PRINTPAGETITLE;

#ifdef LANG_GR
static char *PrintPage = "Seite: %d";
static char *Arrows = "Pfeiltasten";
static char *Enter = "<ÄÙ";
#else
static char *PrintPage = "page: %d";
static char *Arrows = "Arrows";
static char *Enter = "Enter";
#endif

#define NUMPRINTINGBUTTONS 1
static BUTTON PrintingButtons[NUMPRINTINGBUTTONS]
= {
#ifdef LANG_GR
   { { 15, 34 }, 12, "Abbruch ESC",     { KEY_ESCAPE, 'a', 'A', KEY_ALTA     }, KEY_ESCAPE,    TRUE,  TRUE,  8, 3, FG_BLUE  | BG_GRAY, FALSE },
#else
   { { 15, 34 }, 12, "Cancel",     { KEY_ESCAPE, 'c', 'C', KEY_ALTC     }, KEY_ESCAPE,    TRUE,  TRUE,  0, 1, FG_BLUE      | BG_GRAY, FALSE },
#endif
};

#endif /* INPRINT_C */

#endif /*INSTEXT_INCLUDED*/

