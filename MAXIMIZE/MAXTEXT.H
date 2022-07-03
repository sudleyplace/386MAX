/*' $Header:   P:/PVCS/MAX/MAXIMIZE/MAXTEXT.H_V   1.1   26 Oct 1995 21:53:24   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MAXTEXT.H								      *
 *									      *
 * Text strings for maximize						      *
 *									      *
 ******************************************************************************/

/*ÚÄ 5.M„rz 1992 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿*/
/*³see modification remarks in all other files (transferred to GERMAN) ³*/
/*ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/

#ifndef MAXTEXT_INCLUDED
#define MAXTEXT_INCLUDED

#include <commdef.h>		/* Common (shared) definitions */
#include <dialog.h>		/* Dialog box defines/functions */
#include <libcolor.h>		/* Color definitions */
#include <libtext.h>		/* Library text definitions */
#include <max_sys.h>
#include <qualitas.h>		/* Qualitas product definitions */

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

#define ABETA	"áAT"   /* Extension to make AUTOEXEC.BAT unique -- */

#define DONE_KEY   KEY_ENTER	/* Done key for browse */
#define TOGGLE_KEY KEY_F6	/* Toggle key for browse */
#define PREV_KEY   KEY_F7	/* Previous key for browse */
#define NEXT_KEY   KEY_F8	/* Next key for browse */

GLOBAL char *TitleAction
#ifdef GLINIT
#ifdef LANG_GR
= " Aktion "            /* Action title for dialog boxes */
#else
= " Action "            /* Action title for dialog boxes */
#endif
#endif
;

GLOBAL char *TitleIntro
#ifdef GLINIT
#ifdef LANG_GR
= " Einfhrung "      /* Title for intro panels */
#else
= " Introduction "      /* Title for intro panels */
#endif
#endif
;

GLOBAL char *TitleMessage
#ifdef GLINIT
#ifdef LANG_GR
= " Meldung "           /* Title for message panels */
#else
= " Message "           /* Title for message panels */
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

GLOBAL char *TitleError
#ifdef GLINIT
#ifdef LANG_GR
= " Fehler "
#else
= " Error "
#endif
#endif
;

GLOBAL char *TitleWarning
#ifdef GLINIT
#ifdef LANG_GR
= " Achtung "
#else
= " Warning "
#endif
#endif
;


GLOBAL char *MsgWrtFile
#ifdef GLINIT
#ifdef LANG_GR
= "schreibe %s-Datei\n"
#else
= "Writing %s file\n"
#endif
#endif
;

GLOBAL char *MsgLocCfg
#ifdef GLINIT
 = "S.LocCfg"
#endif
;

GLOBAL char *MsgMsgScrn
#ifdef GLINIT
#ifdef LANG_GR
 = "Hinweis-Bildschirm -- Phase %d"
#else
 = "Message Screen -- Phase %d"
#endif
#endif
;

GLOBAL char *MsgErrWwf
#ifdef GLINIT
#ifdef LANG_GR
 = "Fehler beim Schreiben von Dateien festgestellt.\n"
#else
 = "Errors were detected while writing files\n"
#endif
#endif
;

GLOBAL char *MsgExitPgm
#ifdef GLINIT
#ifdef LANG_GR
 = "Das Programm wird beendet.\n"
#else
 = "Exiting program\n"
#endif
#endif
;

GLOBAL char *MsgIgnoreFlex
#ifdef GLINIT
#ifdef LANG_GR
 = "IGNOREFLEXFRAME     ; Wird von MAXIMIZE entfernt\n"
#else
 = "IGNOREFLEXFRAME     ; To be deleted by MAXIMIZE\n"
#endif
#endif
;

#ifdef HARPO
GLOBAL char *MsgRedundant
#ifdef GLINIT
#ifdef LANG_GR
 = "REM Redundante " HARPO " Zeile"
#else
 = "REM Redundant " HARPO " line"
#endif
#endif
;
#endif

/*
 *	This enum must match the HelpInfo array below.
 */

enum _helpnumber {
	HELP_ABORT = HELPOPTEDITOR + 1,
	HELP_BOOTDSK,	/* 10 */
	HELP_INTROMAX,
	HELP_INTROMOV,
	HELP_INTROP2,
	HELP_FILEREQ,
	HELP_REFDSK,
	HELP_REFDSK2,
	HELP_P1HELP,
	HELP_P2HELP,
	HELP_P3HELP,
	HELP_QUICKMAX,	/* 20 */
	HELP_REBOOT,
	HELP_REORDER,
	HELP_QPHASE1,
	HELP_QPHASE2,
	HELP_QPHASE3,
	HELP_PROGSCRN,
	HELP_COMPSCRN,
	HELP_COMPLETE,
	HELP_QINTRO,
	HELP_PROBE,	/* 30 */
	HELP_VGASWAP,
#ifdef STACKER
	HELP_SWAPPEDDRIVE,
#endif			/* ifdef STACKER */
	HELP_MBMENU,
	HELP_ABIOSERR,
	HELP_DELBACKUP,
	HELPCOUNT
};

/*
*  There is an explicit extern reference to this
*  in help.c.  Make sure if you change one, you change the other
*/
GLOBAL HELPDEF HelpInfo[ HELPCOUNT + 1 ]
#ifdef GLINIT
= {
	{ HELP_MAXIMIZE, "H.Contents",  0, NULL },      /*  0    */
	{ HELP_MAXIMIZE, "H.Index",     0, NULL },      /*  1    */
	{ HELP_MAXIMIZE, "H.U_Help",    0, NULL },      /*  2    */
	{ HELP_MAXIMIZE, "H.Default",   0, NULL },      /*  3    */
	{ HELP_MAXIMIZE, "H.U_Dial",    0, NULL },      /*  4    */
	{ HELP_MAXIMIZE, "H.U_Print",   0, NULL },      /*  5    */
	{ HELP_MAXIMIZE, "H.U_Editor",  0, NULL },      /*  6    */
	{ HELP_MAXIMIZE, "H.U_Browse",  0, NULL },      /*  7    */
	{ HELP_MAXIMIZE, "H.E_Option",  0, NULL },      /*  8    */
	{ HELP_MAXIMIZE,  "M_abrt",     0, NULL },      /* HELP_ABORT */
	/*10*/
	{ HELP_MAXIMIZE,  "M_bootdsk",  0, NULL },      /* HELP_BOOTDSK */
	{ HELP_MAXIMIZE,  "M_IntroMax", 0, NULL },      /* HELP_INTROMAX */
	{ HELP_MAXIMIZE,  "M_IntroMov", 0, NULL },      /* HELP_INTROMOV */
	{ HELP_MAXIMIZE,  "M_IntroP2",  0, NULL },      /* HELP_INTROP2 */
	{ HELP_MAXIMIZE,  "M_filereq",  0, NULL },      /* HELP_FILEREQ */
	{ HELP_MAXIMIZE,  "M_refdsk",   0, NULL },      /* HELP_REFDSK */
	{ HELP_MAXIMIZE,  "M_refdsk2",  0, NULL },      /* HELP_REFDSK */
	{ HELP_MAXIMIZE,  "M_p1help",   0, NULL },      /* HELP_P1HELP */
	{ HELP_MAXIMIZE,  "M_p2help",   0, NULL },      /* HELP_P2HELP */
	{ HELP_MAXIMIZE,  "M_p3help",   0, NULL },      /* HELP_P3HELP */
	/*20*/
	{ HELP_MAXIMIZE,  "M_Quick",    0, NULL },      /* HELP_QUICKMAX */
	{ HELP_MAXIMIZE,  "M_reboot",   0, NULL },      /* HELP_REBOOT */
	{ HELP_MAXIMIZE,  "M_Reorder",  0, NULL },      /* HELP_REORDER */
	{ HELP_MAXIMIZE_Q,"Q_Phase1",   0, NULL },      /* HELP_QPHASE1 */
	{ HELP_MAXIMIZE_Q,"Q_Phase2",   0, NULL },      /* HELP_QPHASE2 */
	{ HELP_MAXIMIZE_Q,"Q_Phase3",   0, NULL },      /* HELP_QPHASE3 */
	{ HELP_MX_DATA,   "M_D_Progress",0, NULL },     /* HELP_PROGSCRN */
	{ HELP_MX_DATA,   "M_D_Complete", 0, NULL },    /* HELP_COMPSCRN */
	{ HELP_MAXIMIZE,  "M_Complete", 0, NULL },      /* HELP_COMPLETE */
	{ HELP_MAXIMIZE_Q,"Q_Intro", 0, NULL },         /* HELP_QINTRO */
	/*30*/
	{ HELP_MAXIMIZE,  "M_probe", 0, NULL },         /* HELP_PROBE */
	{ HELP_MAXIMIZE, "M_vgaswap",0, NULL },         /* HELP_VGASWAP */
#ifdef STACKER
	{ HELP_MAXIMIZE, "M_SwappedDrive",0,NULL },     /* HELP_SWAPPEDDRIVE */
#endif			/* ifdef STACKER */
	{ HELP_MAXIMIZE, "M_MBMenu",    0, NULL },      /* HELP_MBMENU */
	{ HELP_MAXIMIZE, "M_ABIOSErr",  0, NULL },      /* HELP_ABIOSERR */
	{ HELP_MAXIMIZE, "M_DelBackup",  0, NULL },     /* HELP_DELBACKUP */
	{ HELP_LAST,	 "",  0, NULL }
}
#endif
;

/* Quick reference panels by pass number */
GLOBAL int QuickRefs[3]
#ifdef GLINIT
 = { HELP_QPHASE1, HELP_QPHASE2, HELP_QPHASE3 }
#endif
;

#define MAXIMIZEARGCNT 8
GLOBAL int MaximizeArgCnt
#ifdef GLINIT
 = MAXIMIZEARGCNT
#endif
;

GLOBAL char *MaximizeArgFrom[MAXIMIZEARGCNT]
#ifdef GLINIT
 = {
	"#ARG1#",
	"#ARG2#",
	"#ARG3#",
	"#ARG4#",
	"#PRODNAME#",
	"#LOADER#",
	"#LOADNAME#",
	NULL
}
#endif
;

/* We've filled in some non-language specific defaults in case */
/* the user prints all help topics... */
GLOBAL char *MaximizeArgTo[MAXIMIZEARGCNT]
#ifdef GLINIT
 = {
	"C",    /* ARG1 - compressed drive */
	"ARG2",
	": D",  /* ARG3 - (same) or : */
	"C:",   /* ARG4 - drive d: */
	PRODNAME,
	LOADER,
	LOADNAME,
	NULL
}
#endif
;

/* Browse colors */
GLOBAL char BrBaseColor;	/* Browse base color */
GLOBAL char BrScrollBar;	/* Browse scroll bar color */

GLOBAL char P1LowCool;		/* Pass1 Low / InActive */
GLOBAL char P1LowHot;		/* Pass1 Low / Active */
GLOBAL char P1HighCool; 	/* Pass1 High / InActive */
GLOBAL char P1HighHot;		/* Pass1 High / Active */

GLOBAL char P2ActColors[2][2];	/* Pass 2 Action colors */
GLOBAL char P2TxtColors[2][2];	/* Pass 2 Text colors */
GLOBAL char P3ActColors[2][2];	/* Pass 3 Action colors */
GLOBAL char P3TxtColors[2][2];	/* Pass 3 Text colors */

GLOBAL char P3GrpLow;		/* Pass 3 Group menu low */
GLOBAL char P3GrpHigh;		/* Pass 3 Group menu high */
GLOBAL char P3GrpAlt;		/* Pass 3 Group menu alternate */

GLOBAL char ProgBarHot; 	/* Hot color for progress bar */

#define SMALL_DIALOG  36	/* Width for small dialog box */

#ifdef LANG_GR
#define MEDIUM_DIALOG 59	/* Width in uihelp\makefile + 3 */
#else
#define MEDIUM_DIALOG 55	/* Width for medium dialog box */
#endif

#define LARGE_DIALOG  72	/* Width for large dialog box */

GLOBAL DIALOGTEXT MaximizeText[3]
#ifdef GLINIT
= {	{ 2, "S.", HELP_MAXIMIZE_S, SMALL_DIALOG },
	{ 2, "M.", HELP_MAXIMIZE_M, MEDIUM_DIALOG },
	{ 2, "L.", HELP_MAXIMIZE_L, LARGE_DIALOG } }
#endif
;

GLOBAL DIALOGPARM NormalDialog
#ifdef GLINIT
 = {	/* Style of normal dialog box */
	MEDIUM_DIALOG,		/*	Outer width of dialog box */
	NorDlgColors,		/*	Attribute list */
	MessageButtons, 	/*	Button list */
	sizeof(MessageButtons)/sizeof(MessageButtons[0]),
	0,			/*	Color for edit field */
	SHADOW_SINGLE,		/*	Shadow control for edit field */
	MaximizeText		/*	Help type if text comes from help file */
}
#endif
;

GLOBAL char *MsgAdapterMem
#ifdef GLINIT
#ifdef LANG_GR
 = "  ; MAXIMIZE ==> schtze RAM auf Adapterkarten"
#else
 = "  ; MAXIMIZE ==> Protect RAM on adapters"
#endif
#endif
;

#ifdef LANG_GR
#define SUBIDCOMMENT_A "     ; MAXIMIZE ==> Verlagere "
#define SUBIDCOMMENT_B " in Region %d mit %lu Byte\n"
#else
#define SUBIDCOMMENT_A "     ; MAXIMIZE ==> Move "
#define SUBIDCOMMENT_B " to region %d for %lu bytes\n"
#endif

#ifdef GLINIT
#define MsgSubIDFComment SUBIDCOMMENT_A "FILES" SUBIDCOMMENT_B
#define MsgSubIDFText	 " Files"
#define MsgSubIDXComment SUBIDCOMMENT_A "FCBs" SUBIDCOMMENT_B
#define MsgSubIDXText	 " FCBs"
#define MsgSubIDBComment SUBIDCOMMENT_A "BUFFERS" SUBIDCOMMENT_B
#define MsgSubIDBText	 " Buffers"
#define MsgSubIDLComment SUBIDCOMMENT_A "LASTDRIVE" SUBIDCOMMENT_B
#define MsgSubIDLText	 " Lastdrive"
#define MsgSubIDSComment SUBIDCOMMENT_A "STACKS" SUBIDCOMMENT_B
#define MsgSubIDSText	 " Stacks"
#define MsgSubIDGComment SUBIDCOMMENT_A "IFS-G" SUBIDCOMMENT_B
#define MsgSubIDGText	 " IFS_G"
#define MsgSubIDHComment SUBIDCOMMENT_A "IFS-H" SUBIDCOMMENT_B
#define MsgSubIDHText	 " IFS_H"
#define MsgSubIDRComment SUBIDCOMMENT_A "IFS-R" SUBIDCOMMENT_B
#define MsgSubIDRText	 " IFS_R"
#define MsgSubIDYComment SUBIDCOMMENT_A "IFS-Y" SUBIDCOMMENT_B
#define MsgSubIDYText	 " IFS_Y"
#ifdef LANG_GR
#define DOS3DATA	"DOS 3 Daten"
#else
#define DOS3DATA	"DOS 3 data"
#endif
#define MsgSubIDVComment SUBIDCOMMENT_A DOS3DATA SUBIDCOMMENT_B
#define MsgSubIDVText	 " " DOS3DATA
#define MsgSubIDQComment SUBIDCOMMENT_A "Temporary Batch Processing Data" SUBIDCOMMENT_B
#define MsgSubIDQText	 " Tempdata"
#define MsgSubIDXBDAComment SUBIDCOMMENT_A "Extended BIOS Data Area" SUBIDCOMMENT_B
#define MsgSubIDXBDAText " XBDA"
#define MsgSubIDHPDAComment SUBIDCOMMENT_A "DPMI Host Private Data Area" SUBIDCOMMENT_B
#define MsgSubIDHPDAText " HPDA"
#define MsgSubIDMSTACKComment SUBIDCOMMENT_A "Stack Overflow Protection" SUBIDCOMMENT_B
#define MsgSubIDMSTACKText " MAX Stack"
#endif

GLOBAL char *MsgComspec
#ifdef GLINIT
 =	 SUBIDCOMMENT_A "COMMAND.COM" SUBIDCOMMENT_B
#endif
;

GLOBAL char *MsgEnvironment
#ifdef GLINIT
#ifdef LANG_GR
 =	 SUBIDCOMMENT_A "Hauptumgebung" SUBIDCOMMENT_B
#else
 =	 SUBIDCOMMENT_A "master environment" SUBIDCOMMENT_B
#endif
#endif
;

/*
 *------------------------------------------------------------------
 *	main.c
 *------------------------------------------------------------------
 */

#ifdef MAIN_C

static char ProgramName[] = " Maximize";

#ifdef LANG_GR
char *MsgPlsDisable = "Bitte alle Steuerprogramme auáer " PRODNAME " unwirksam machen, dann MAXIMIZE neu starten!\n";
#else
char *MsgPlsDisable = "Please disable control programs other than " PRODNAME " and rerun MAXIMIZE\n";
#endif

char *MsgNoInst = "S.NoInst";
char *MsgPhsErr = "S.PhsErr";
char *MsgNoMaxCfgMB = "S.NoMaxCfgMB";

char *MsgErrBat1 =
#ifdef LANG_GR
	"echo off\n"
	"if not \"%1\" == \"\" goto %1\n"
	"echo Aus irgendeinem Grund wurde " PRODNAME " nicht installiert.\n"
	"echo Bitte berprfen Sie die CONFIG.SYS Datei auf evtl. Fehler\n"
	"echo und starten Sie dann MAXIMIZE neu.\n"
	"pause\n"
	"call ";
#else
	"echo off\n"
	"if not \"%1\" == \"\" goto %1\n"
	"echo For some reason, " PRODNAME " did not install.  Please check for\n"
	"echo error messages in CONFIG.SYS and rerun MAXIMIZE\n"
	"pause\n"
	"call ";
#endif

char *MsgErrBat2 =
#ifdef LANG_GR
	"\nautoexec\n"
	":PREMAXIM\n"
	"echo erneuere Dateien...\n"
	"echo on\n"
	"call ";
#else
	"\nautoexec\n"
	":PREMAXIM\n"
	"echo Restoring files...\n"
	"echo on\n"
	"call ";
#endif


#ifdef LANG_GR

char *MsgInvDrv = "es wurde ein unzul„ssiges Laufwerk gew„hlt\n";
char *MsgPgmAbt = "Programm-Abbruch\n";
char *MsgPlsRer = "bitte MAXIMIZE erneut starten\n";
char *MsgCreating = "erzeuge %s\n";
char *CfgBackup = "  ; Steuert L”schung der Qualitas Sicherungsdateien";

#define ABORTESCSTART 8
char *MsgAbortEsc = "Abbruch ESC";        /* Label for MainButtons[0] */

#else

char *MsgInvDrv = "Invalid drive selected\n";
char *MsgPgmAbt = "Program aborting\n";
char *MsgPlsRer = "Please rerun MAXIMIZE\n";
char *MsgCreating = "Creating %s\n";
char *CfgBackup = "  ; Controls deletion of Qualitas backup files";

#define ABORTESCSTART 6
char *MsgAbortEsc = "Abort Esc";        /* Label for MainButtons[0] */

#endif

static char *MsgMBMenu = "H.MBMenu";    /* Help dialog for MultiBoot select, */
					/* not the F1 help. */

extern char HelpString[];	/* In VERSDATA.ASM */

#endif /* MAIN_C */


/*
 *------------------------------------------------------------------
 *	screens.c
 *------------------------------------------------------------------
 */

#ifdef SCREENS_C

extern char Prodname[]; 	/* " 386MAX 6 " in VERSDATA.ASM */

DIALOGPARM ErrorDialog = {	/* Style of warning message dialog box */
	SMALL_DIALOG,		/*	Outer width of dialog box */
	ErrDlgColors,		/*	Attribute list */
	MessageButtons, 	/*	Button list */
	sizeof(MessageButtons)/sizeof(MessageButtons[0]),
	0,			/*	Color for edit field */
	0,			/*	Shadow control for edit field */
	MaximizeText		/*	Help type if text comes from help file */
};

DIALOGPARM WarningDialog = {	/* Style of warning message dialog box */
	LARGE_DIALOG,		/*	Outer width of dialog box */
	ErrDlgColors,		/*	Attribute list */
	YesNoButtons,		/*	Button list */
	sizeof(YesNoButtons)/sizeof(YesNoButtons[0]),
	0,			/*	Color for edit field */
	0,			/*	Shadow control for edit field */
	MaximizeText		/*	Help type if text comes from help file */
};

static DIALOGEDIT DriveEdit = { /* Field to edit drive letters */
	{ -5, 17, 1, 1 },	/* Edit window */
	NULL,			/* Where to get/put editable string */
	0			/* Length of edit field - Don't forget the null terminator */
};

static DIALOGEDIT RegisterEdit[2] = {	/* Field to edit registration info */
      { { -7, 16, 1, 44 },	/* Name field */
	NULL,			/* Where to get/put editable string */
	0 },			/* Length of edit field - Don't forget the null terminator */

      { { -5, 16, 1, 16 },	/* Serial number field */
	NULL,			/* Where to get/put editable string */
	0 }			/* Length of edit field - Don't forget the null terminator */
};

static DIALOGEDIT PathEdit = {		/* Field to path spec */
	{ -5, 2, 1, 51 },	/* Edit window */
	NULL,			/* Where to get/put editable string */
	0			/* Length of edit field - Don't forget the null terminator */
};

static DIALOGEDIT BackupEdit[] = { /* Max and min backup values */
	{ { -8, 50, 1, 7 },	/* Edit window */
	  NULL, 		/* Where to get/put editable string */
	  3 },			/* Length of edit field */
	{ { -6, 50, 1, 7 },	/* Edit window */
	  NULL, 		/* Where to get/put editable string */
	  3 }			/* Length of edit field */
};

extern char *MsgLogoText[];
static char *MsgIntroP1 = "L.IntroP1";
static char *MsgIntroPs2 = "M.IntroPS2";

static char *MsgBootDisk = "S.BootDisk";
static char *MsgBadDrive = "S.BadDrive";
static char *MsgCnfNf = "S.CnfNf";
static char *MsgCnfWp = "S.CnfWp";

static char *MsgReqFile = "M.ReqFile";
static char *MsgRefDsk = "L.RefDsk";
static char *MsgRefDsk2 = "L.RefDsk2";
static char *MsgQuickMax = "M.Quick";
static char *MsgEmsHelp = "L.EMSHelp";
static char *MsgFromWin = "S.FromWIN";
static char *MsgProbe = "M.ROMSrch1";
static char *MsgReboot = "L.Reboot";
static char *MsgVGASwap = "M.VGASwap";
static char *MsgABIOSErr = "L.ABIOSErr";
static char *MsgDelBackup = "L.DelBackup";
static char *MsgInvBack = "S.InvBack";

static BUTTON EmsHelpButtons[4] = {
   { { 0, 0  }, 11, " (C) ",    { 'C', 'c', 0, 0 }, 'C', TRUE, TRUE, 2, 1,  FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 11, " (N) ",    { 'N', 'n', 0, 0 }, 'N', FALSE, TRUE, 2, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 11, " (D) ",    { 'D', 'd', 0, 0 }, 'D', FALSE, TRUE, 2, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 11, " (R) ",    { 'R', 'r', 0, 0 }, 'R', FALSE, TRUE, 2, 1, FG_BLUE | BG_GRAY, FALSE }
};

char *MsgBatNf = "S.BatNf";

#ifdef LANG_GR

char *MsgCopyADF = "kopiere .ADF-Dateien\n";
char *MsgRebootM = "Moment bitte, System startet neu...";
char *MsgInstAbt = "Installation wurde abgebrochen";
char *MsgPressAnyKey = "weiter mit beliebiger Taste...";
char *MsgPressEsc = "mit ESC nehmen Sie den Vorschlag an.";

#else

char *MsgCopyADF = "Copying .ADF files\n";
char *MsgRebootM = "Rebooting the system will take a moment...";
char *MsgInstAbt = "Installation is being aborted";
char *MsgPressAnyKey = "Press any key to continue...";
char *MsgPressEsc = "Press Esc to accept current best fit.";

#endif

static char *MsgConfirmEsc =
#ifdef LANG_GR
		"\n"
		"Sie haben w„hrend der Optimierung ESC bet„tigt.\n"
		"Wollen Sie anhalten und den jetzigen Stand\n"
		"der Anpassung akzeptieren ?\n"
		"\n";
#else
		"\n"
		"Esc has been pressed during optimization.\n"
		"Do you wish to stop now and accept the\n"
		"current best fit?\n"
		"\n";
#endif

#ifdef LANG_GR
static char *MsgConfirmAbort = "\nWollen Sie die Optimierung abbrechen ?\n\n";
char *MsgPressEnter = "weiter mit <ÄÙ\n";
#else
static char *MsgConfirmAbort = "\nDo you wish to cancel optimization?\n\n";
char *MsgPressEnter = "Press Enter to continue.\n";
#endif

static BUTTON OkButtons[ 1 ] = {
#ifdef LANG_GR
   { { -3, 1 }, 12, "Fertig <ÄÙ", { KEY_ENTER, 0, 0, 0 }, KEY_ENTER, FALSE, FALSE, 7, 3,  FG_BLUE | BG_GRAY, TRUE }
#else
   { { -3, 1 }, 12, "OK Enter", { KEY_ENTER, 0, 0, 0 }, KEY_ENTER, FALSE, FALSE, 0, 1,  FG_BLUE | BG_GRAY, TRUE }
#endif
};

#ifdef LANG_GR
static char *MsgMaximizing = " MAXimierung - Phase %d ";
static char *MsgMovingHigh = "verlege %s Byte in HiDOS Speicher";
static char *MsgLeftLow = "behalte %s Byte in LoDOS Speicher";
#else
static char *MsgMaximizing = " Maximizing - Phase %d ";
static char *MsgMovingHigh = "Moving %s bytes into high DOS memory";
static char *MsgLeftLow = "Leaving %s bytes in low DOS memory";
#endif

#ifdef LANG_GR
static char CompleteMsg[] = "fertig.";   // Msg to display at top of screen
#else
static char CompleteMsg[] = "completed.";   // Msg to display at top of screen
#endif

#define NUMREFDISKBUTTONS 3
static BUTTON RefDiskButtons[ NUMREFDISKBUTTONS ] = {
#ifdef LANG_GR
   { { -1, 15 }, 11, "Hilfe F1",      { KEY_F1,      0,   0,  0 },        KEY_F1,     FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 26 }, 12, "Fertig <ÄÙ",    { KEY_ENTER,  'f', 'F', KEY_ALTF }, KEY_ENTER,   TRUE, TRUE,  7, 3, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 40 }, 14, "Abbruch ESC",   { KEY_ESCAPE, 'a', 'A', KEY_ALTA }, KEY_ESCAPE, FALSE, TRUE,  8, 3, FG_BLUE | BG_GRAY, FALSE },
#else
   { { -1, 15 }, 11, "Help F1",         { KEY_F1,         0, 0, 0 }, KEY_F1,            FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 26 }, 12, "OK",         { KEY_ENTER,  'o', 'O', KEY_ALTO     }, KEY_ENTER,   TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 40 }, 12, "Cancel",          { KEY_ESCAPE, 'c', 'C', KEY_ALTC }, KEY_ESCAPE, FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
#endif
};

#define NUMBACKUPBUTTONS 4
static BUTTON BackupButtons[ NUMBACKUPBUTTONS ] = {
#ifdef LANG_GR
   { { -1, 15 }, 11, "Hilfe F1",      { KEY_F1,      0,   0,  0 },        KEY_F1,     FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 4  }, 12, "Ja",         { 'j', 'J', KEY_ALTJ, 0 }, 'J', TRUE,   TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 22 }, 12, "Nein",       { 'n', 'N', KEY_ALTN, 0 }, 'N', FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 40 }, 14, "Abbruch ESC",{ KEY_ESCAPE, 'a', 'A', KEY_ALTA }, KEY_ESCAPE, FALSE, TRUE,  8, 3, FG_BLUE | BG_GRAY, FALSE },
#else
   { { -1, 15 }, 11, "Help F1",         { KEY_F1,         0, 0, 0 }, KEY_F1,            FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 4  }, 12, "Yes",      { 'y', 'Y', KEY_ALTY, 0 }, 'Y', TRUE,   TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 22 }, 12, "No",       { 'n', 'N', KEY_ALTN, 0 }, 'N', FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 40 }, 12, "Cancel",   { KEY_ESCAPE, 'c', 'C', KEY_ALTC }, KEY_ESCAPE, FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
#endif
};

#endif /* SCREENS_C */

#ifdef P1BROWSE_C

/*
 *	Pass 1 (MC) Browse button definitions
 */

static BUTTON P1Buttons[ 2 ] = {
#ifdef LANG_GR
   { { -3, 1  }, 12, "Fertig <ÄÙ",{ DONE_KEY, 0, 0, 0 },   DONE_KEY,   FALSE, FALSE, 7, 3, FG_BLUE | BG_GRAY, FALSE },
   { { -3, 15 }, 11, "Umsch. F6", { TOGGLE_KEY, 0, 0, 0 }, TOGGLE_KEY, FALSE, FALSE, 7, 2, FG_BLUE | BG_GRAY, FALSE },
#else
   { { -3, 1  }, 12, "Done Enter",{ DONE_KEY, 0, 0, 0 },   DONE_KEY,   FALSE, FALSE, 5, 5, FG_BLUE | BG_GRAY, FALSE },
   { { -3, 15 }, 11, "Toggle F6", { TOGGLE_KEY, 0, 0, 0 }, TOGGLE_KEY, FALSE, FALSE, 7, 2, FG_BLUE | BG_GRAY, FALSE },
#endif
};

#ifdef LANG_GR
char *MsgAdapAction = "AKTION";
char *MsgAdapName = "ADAPTER-NAME";
#else
char *MsgAdapAction = "ACTION";
char *MsgAdapName = "ADAPTER NAME";
#endif

char *MsgAstateText[] = {
#ifdef LANG_GR
	"",
	"  MAXIMIZE  ", /* 1 = MAXIMIZE */
	"  STATISCH  ", /* 2 = STATIC */
	"  INAKTIV   ", /* 3 = DISABLED */
	"  EMS=0     ", /* 4 = EMSZERO */
	"  NOFRAME   ", /* 5 = NO FRAME */
	"KEIN SPEICH.", /* 6 = NOMEM */
#else
	"",
	"  MAXIMIZE  ", /* 1 = MAXIMIZE */
	"  STATIC    ", /* 2 = STATIC */
	"  DISABLED  ", /* 3 = DISABLED */
	"  EMS=0     ", /* 4 = EMSZERO */
	"  NOFRAME   ", /* 5 = NO FRAME */
	"  NO MEMORY ", /* 6 = NOMEM */
#endif
	0
};

#ifdef LANG_GR

char *MsgNoEms = "EMS=0 ; kein EMS-Zugriff verfgbar";
char *MsgEmsRes = "EMS=%ld ; reserviere genau %ld KB des EMS-Speichers";
char *MsgNoFrame = "NOFRAME ; kein EMS-Rahmen verfgbar";
char *MsgEmsFrame = "EMS-Seitenrahmen (PageFrame)";
char *MsgOptAdapt = "optimiere MC-Adapter...\n";

#else

char *MsgNoEms = "EMS=0 ; No EMS services available";
char *MsgEmsRes = "EMS=%ld ; Reserve exactly %ld KB of EMS memory";
char *MsgNoFrame = "NOFRAME ; No EMS frame available";
char *MsgEmsFrame = "EMS Page Frame";
char *MsgOptAdapt = "Optimizing MC Adapters...\n";

#endif

char *MsgAdaptIntro = "M.Adapter";

#endif /*P1BROWSE_C*/

#ifdef READCNFG_C

char *MsgNoCfgSys = "S.NoCfgSys";
char *MsgNoMaxCfg = "S.NoMaxCfg";

#ifdef LANG_GR

char *MsgReadCfg = "lese CONFIG.SYS-Datei\n";
char *MsgFileNf = "%s-Datei nicht gefunden\n";

#else

char *MsgReadCfg = "Reading CONFIG.SYS file\n";
char *MsgFileNf = "File %s not found\n";

#endif

#ifdef STACKER
static char *MsgBootSwap = "M.BootSwap";
#endif			/* ifdef STACKER */

#endif /*READCNFG_C*/

#ifdef PARSE_C

#ifdef LANG_GR

char *MsgParsParm = "analysiere %s-Parameter\n";
char *MsgErrOpen = "Fehler beim ™ffnen der %s-Datei\n";
char *MsgErrWriting = "Fehler bei Schreiben der Datei %s\n";
char *MsgParsFile = "analysiere %s-Datei\n";
char *MsgCreatProf = "lege %s-Profil an\n";

#else

char *MsgParsParm = "Parsing %s parameters\n";
char *MsgErrOpen = "Error opening %s file\n";
char *MsgErrWriting = "Error writing file %s\n";
char *MsgParsFile = "Parsing %s file\n";
char *MsgCreatProf = "Creating %s profile\n";

#endif

char *MsgProLim = "S.ProLim";
static char *MsgROMSrch2 = "M.ROMSrch2";


static char ProbeComment[] =
#ifdef LANG_GR
   "; MAXIMIZE ==> " PROBE " fand %04x-%04x unbelegt, jedoch vorhd. RAM-Statement(s) respektiert.\n";
#else
   "; MAXIMIZE ==> " PROBE " found %04x-%04x unused but respected existing RAM statement(s).\n";
#endif

static char ProbeUse[] =
#ifdef LANG_GR
   "USE=%04x-%04x           ; MAXIMIZE ==> " PROBE " entdeckt %2u kB.\n";
#else
   "USE=%04x-%04x           ; MAXIMIZE ==> " PROBE " recovers %2u KB.\n";
#endif

static char VGASwap[] =
#ifdef LANG_GR
   "VGASWAP                 ; MAXIMIZE ==> verlagert Video-ROM.\n";
#else
   "VGASWAP                 ; MAXIMIZE ==> Relocate video ROM.\n";
#endif

static char CfgNoVS_Xlat[] =
#ifdef LANG_GR
   "NOVGASWAP               ; MAXIMIZE ==> nicht-kompatibles Video-BIOS";
#else
   "NOVGASWAP               ; MAXIMIZE ==> Incompatible video BIOS";
#endif

static char CfgNoROMSRCH[] =
   "NOROMSRCH               ; MAXIMIZE ==> ";
static char CfgNoROMSRCH_Hang[] =
/* This comment is somewhat alarming, but the user should never see it */
/* unless that's exactly what happened.  We'll remove the deadman version */
/* of NOROMSRCH when ROMSRCH completes (either successfully or otherwise). */
#ifdef LANG_GR
					  PROBE " verursachte einen Systemstillstand oder Reboot.";
#else
					  PROBE " caused a system hang or reboot.";
#endif
static char CfgNoROMSRCH_Fail[] =
#ifdef LANG_GR
					  "Kein zus„tzliches HiDOS wiederhergestellt durch " PROBE;
#else
					  "No additional high DOS recovered by " PROBE;
#endif

static char ProbeID[] =    "; " PROBE;
static char ProbeSorry[] =
#ifdef LANG_GR
 PROBE " hat keine"
#else
 "Sorry,"
#endif
;
#define PROBESORRYLEN	sizeof(ProbeID)-1	/* Characters to compare */

#define ROMBASE 0xE000	    /* Start of possible ROM addresses */
#define ROMPAGES 32	/* Maximum possible 4K pages in ROM */

#ifdef LANG_GR

char *MsgExecuting = "fhre %s aus\n";
char *MsgParseProbe = "analysiere %s" PROBEOUT "-Datei\n";
char *MsgUpdateSys = "erneuere %s.SYS-Parameter\n";
char *MsgExecErr = "Achtung: kann %s nicht ausfhren!\n";
char *MsgOptCopied = "   ; MAXIMIZE ==> vom MAX Profil kopiert";
char *MsgSeeMaxCfg = "   ; MAXIMIZE ==> siehe MAXIMIZE.CFG (NOROMSRCH)";

#ifdef HARPO
char *MsgCheckHarpo = "verarbeite " HARPO " Zeile(n) in CONFIG.SYS\n";
char *MsgAddHPro = "; Erstellt von MAXIMIZE\n";
char *MsgHarpoFailSave = "Fehler bei Sicherung des " HARPO " Profils\n";
char *MsgEnvLow = "   ; MAXIMIZE ==> Lade Master-Environment niemals in HiDOS";
char *MsgMoveHarpo = "REM MAXIMIZE: " HARPO " muá am Ende der CONFIG.SYS stehen";
#endif	/* ifdef HARPO */

char *MsgPCIBIOS   = "PCIBIOS   ; MAXIMIZE ==> PCI Local Bus System erkannt\n";

#else

char *MsgExecuting = "Executing %s\n";
char *MsgParseProbe = "Parsing %s" PROBEOUT " file\n";
char *MsgUpdateSys = "Updating %s.SYS parameters\n";
char *MsgExecErr = "Warning: unable to execute %s\n";
char *MsgOptCopied = "   ; MAXIMIZE ==> Copied from MAX profile";
char *MsgSeeMaxCfg = "   ; MAXIMIZE ==> See MAXIMIZE.CFG (NOROMSRCH)";

#ifdef HARPO
char *MsgCheckHarpo = "Processing " HARPO " line(s) in CONFIG.SYS\n";
char *MsgAddHPro = "; Created by MAXIMIZE\n";
char *MsgHarpoFailSave = "Error creating backup of " HARPO " profile\n";
char *MsgEnvLow = "   ; MAXIMIZE ==> Never move master environment high";
char *MsgMoveHarpo = "REM MAXIMIZE: " HARPO " must come at the end of CONFIG.SYS";
#endif	/* ifdef HARPO */

char *MsgPCIBIOS   = "PCIBIOS   ; MAXIMIZE ==> PCI local bus system detected\n";

#endif

#endif /*PARSE_C*/

#ifdef CHKRAM_C
#ifdef LANG_GR
char *MsgScanRAM = "suche nach verfgbarem RAM (Schirm flackert)\n";
#else
char *MsgScanRAM = "Scanning for available RAM (screen will flash)\n";
#endif
#endif /*CHKRAM_C*/

#ifdef PROCCFG1_C
#endif /*PROCCFG1_C*/

#ifdef WRCONFIG_C
#ifdef LANG_GR
char *MsgUpdConf = "erneuere CONFIG.SYS-Datei\n";
#else
char *MsgUpdConf = "Updating CONFIG.SYS file\n";
#endif
char *MsgErrConf = "S.ErrConf";
#endif /*WRCONFIG_C*/

#ifdef COPYFILE_C
#ifdef LANG_GR
char *FlErrMsg = "Fehler bei Sicherung nach %s\n";
#else
char *FlErrMsg = "Error copying to backup %s\n";
#endif

#ifdef LANG_GR
char *MsgFileBr = "Dateien werden wiederhergestellt ...\n";
char *MsgCopying = "kopiere %s in %s\n";
#else
char *MsgFileBr = "Files are being restored ...\n";
char *MsgCopying = "Copying %s to %s\n";
#endif

#endif /*COPYFILE_C*/

#ifdef DOREBOOT_C

char *MsgReboot1A =
#ifdef LANG_GR
	"\n"
	"MAXIMIZE hat Phase 1 abgearbeitet und startet jetzt das "
	"System neu, um die Namen Ihrer TSR-Programme zu ermitteln.\n"
	"\n"
	"Laufwerk A: MUSS jetzt leer sein!\n";
#else
	"\n"
	"MAXIMIZE is at the end of the first phase and needs to "
	"reboot your system to determine the names of your TSRs.\n"
	"\n"
	"Please ensure that drive A is empty.\n";
#endif

char *MsgReboot1B =
#ifdef LANG_GR
	"\n"
	"MAXIMIZE hat Phase 1 abgearbeitet und startet jetzt das "
	"System neu, um die Namen Ihrer TSR-Programme zu ermitteln.\n";
#else
	"\n"
	"MAXIMIZE is at the end of the first phase and needs to "
	"reboot your system to determine the names of your TSRs.\n";
#endif

char *MsgReboot1C =
#ifdef LANG_GR
	"\n"
	"MAXIMIZE hat Phase 1 abgearbeitet und startet jetzt das "
	"System neu, um die Namen Ihrer TSR-Programme zu ermitteln.\n"
	"\n"
	"Bitte tauschen Sie Ihre Referenz-Diskette im Laufwerk "
	"A: gegen Ihre Installations-Diskette aus.\n";
#else
	"\n"
	"MAXIMIZE is at the end of the first phase and needs to "
	"reboot your system to determine the names of your TSRs.\n"
	"\n"
	"Please remove your reference diskette from "
	"drive A and insert your installation diskette.\n";
#endif

char *MsgReboot2A =
#ifdef LANG_GR
	"\n"
	"MAXIMIZE hat Phase 2 abgearbeitet und startet jetzt das "
	"System neu, um die Gr”áe Ihrer TSR-Programme zu ermitteln.\n"
	"\n"
	"Laufwerk A: MUSS jetzt leer sein!\n";
#else
	"\n"
	"MAXIMIZE is at the end of the second phase and needs to "
	"reboot your system to determine the size of your TSRs.\n"
	"\n"
	"Please ensure that drive A is empty.\n";
#endif

char *MsgReboot2B =
#ifdef LANG_GR
	"\n"
	"MAXIMIZE hat Phase 2 abgearbeitet und startet jetzt das "
	"System neu, um die Gr”áe Ihrer TSR-Programme zu ermitteln.\n";
#else
	"\n"
	"MAXIMIZE is at the end of the second phase and needs to "
	"reboot your system to determine the size of your TSRs.\n";
#endif

char *MsgReboot3A =
#ifdef LANG_GR
	"\n"
	"MAXIMIZE hat Phase 3 abgearbeitet und startet jetzt das "
	"System neu, um Ihre TSR in den HiDOS-Bereich zu laden. "
	"Dieser letzte Neustart beendet den MAXIMIZE-Prozess und "
	"gibt die Kontrolle an DOS zurck.\n"
	"\n"
	"Laufwerk A: MUSS jetzt leer sein!\n";
#else
	"\n"
	"MAXIMIZE is at the end of the last phase and needs to "
	"reboot your system to load your TSRs into high DOS memory.  "
	"This final reboot will conclude the MAXIMIZE process and "
	"return control to DOS.\n"
	"\n"
	"Please ensure that drive A is empty.\n";
#endif

char *MsgReboot3B =
#ifdef LANG_GR
	"\n"
	"MAXIMIZE hat Phase 3 abgearbeitet und startet jetzt das "
	"System neu, um Ihre TSR in den HiDOS-Bereich zu laden. "
	"Dieser letzte Neustart beendet den MAXIMIZE-Prozess und "
	"gibt die Kontrolle an DOS zurck.\n";
#else
	"\n"
	"MAXIMIZE is at the end of the last phase and needs to "
	"reboot your system to load your TSRs into high DOS memory.  "
	"This final reboot will conclude the MAXIMIZE process and "
	"return control to DOS.\n";
#endif


/*-------------------------------------------------------------*/
/*  Text to build AUTOEXEC.BAT files			       */
/*-------------------------------------------------------------*/

char BatchLm[] = "echo    ";
extern char BatchHdr[]; 	/* In VERSDATA.ASM */
#ifdef LANG_GR
char BatchA01[] = "ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»\n";
char BatchA02[] = "º                                                                      º\n";
char BatchA03[] = "ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶\n";
char BatchA04[] = "º Wenn Ihr System nach dem Start in eine Oberfl„che (DOSSHELL,ViewMAX, º\n";
char BatchA05[] = "º WINDOWS o.„.) umschaltet, verlassen Sie diese Programme sofort nach  º\n";
char BatchA06[] = "º deren Aktivierung, damit wir MAXIMIZE ungest”rt fortsetzen k”nnen !  º\n";
char BatchA07[] = "ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼\n";
#else
char BatchA01[] = "ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»\n";
char BatchA02[] = "º                                                                     º\n";
char BatchA03[] = "ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶\n";
char BatchA04[] = "º If your system automatically comes up in a shell (like DOSSHELL), a º\n";
char BatchA05[] = "º menu program, or an application program (like WINDOWS), please exit º\n";
char BatchA06[] = "º the program as soon as it appears so we may continue with MAXIMIZE. º\n";
char BatchA07[] = "ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼\n";
#endif

/* Changes made to BatchB?? strings must be reflected in BatchBtxt[] */
/* as well as in *_LN* #defines (after BatchBtxt[] in this file) */
char BatchB00[] = "pause\n";            /* PAUSE_LN */
/*   BatchB01[] = d:\path\BATPROC */	/* BPPATH_LN */
/*   BatchB02[] = " ?:\\autoexec." ABETA; */ /* BPAEXEC_LN */
char BatchB03[] = " maximize.out ";     /* BPMAXOUT_LN */
char BatchB04[] = LOADER;
char BatchB05[] = ".com maximize.trm\n";
char BatchB06[] = "ctty con\n";
char BatchB07[] = "if not errorlevel 1 goto MAXIMIZE\n";
#ifdef LANG_GR
char BatchB08[] = "echo BATPROC konnte Ihre Start-Dateien nicht abarbeiten.\n";
#else
char BatchB08[] = "echo BATPROC was unable to process your startup files.\n";
#endif
char BatchB09[] = "pause\n";
/*   BatchB10[] = files[ERRMAXIM] */	/* ERRMAXIM_LN2 */
/*   BatchB11[] = " PREMAXIM\n"; */
char BatchB12[] = ":MAXIMIZE\n";
/*   BatchB13[] = d:\path\... */	/* MAXIMPATH_LN */
char BatchB14[] = "maximize /? /";      /* MAXIMIZE_LN */
char BatchB15[] = "?:";                 /* MAXIMDRIVEARG_LN */
/*   BatchB16[] = options */		/* MAXIMOPT_LN */
char BatchB17[] = "if errorlevel 1 ";
/*   BatchB18[] = files[ERRMAXIM] */	/* ERRMAXIM_LN3 */
char BatchB19[] = " PREMAXIM\n";

char *BatchAtxt[] =
{
	"echo off\nif not exist "DEVNAME" ",
	0,			/* 1 - ERRMAXIM_LN1 */
				/* Filled in with ActiveFiles[ERRMAXIM] */
	"\ncls\n",              /* 2 */
	BatchLm, BatchA01,	/* 3 */
	BatchLm, BatchA02,
	BatchLm, BatchA03,
	BatchLm, BatchA04,
	BatchLm, BatchA05,
	BatchLm, BatchA06,
	BatchLm, BatchA07
};

#define ATXTLEN (sizeof (BatchAtxt) / sizeof (BatchAtxt[0]))

char *BatchBtxt[] = {	/* *_LN* #defines must be maintained below */
	BatchB00,	/* 0 - PAUSE_LN */
	0,		/* 1 - BPPATH_LN */
	0,		/* 2 - BPAEXEC_LN */
	BatchB03,	/* 3 - BPMAXOUT_LN */
	BatchB04,
	BatchB05,
	BatchB06,
	BatchB07,
	BatchB08,
	BatchB00,	/* 9 */
	0,		/* 10 - ERRMAXIM_LN2 */
	BatchB19,	/* 11 - "PREMAXIM" */
	BatchB12,
	0,		/* 13 - MAXIMPATH_LN */
	BatchB14,	/* 14 - MAXIMIZE_LN */
	BatchB15,	/* 15 - MAXIMDRIVEARG_LN */
	0,		/* 16 - MAXIMOPT_LN */
	BatchB17,
	0,		/* 18 - ERRMAXIM_LN3 */
	BatchB19	/* "PREMAXIM" */
};

#define BTXTLEN (sizeof (BatchBtxt) / sizeof (BatchBtxt[0]))

#define ERRMAXIM_LN1	1	/* Index into BatchAtxt[] */

#define PAUSE_LN	0	/* Indices into BatchBtxt[] */
#define BPPATH_LN	1
#define BPAEXEC_LN	2
#define BPMAXOUT_LN	3
#define ERRMAXIM_LN2	10
#define MAXIMPATH_LN	13
#define MAXIMIZE_LN	14
#define MAXIMDRIVEARG_LN 15
#define MAXIMOPT_LN	16
#define ERRMAXIM_LN3	18

#endif /*DOREBOOT_C*/

#ifdef PASS2_C
char *MsgErrWrite = "S.ErrWrite";
char *MsgNoneToDo = "S.NoneToDo";
char *MsgPreToggle = "M.PreToggle";

char *MsgP2Action[] = {
	"        ",     /* 0 */
	"  HIGH  ",     /* 1 = (mark == 3) */
	"  LOW   ",     /* 2 = (mark == 2) */
	"MAXIMIZE",     /* 3 = (mark == 1) */
#ifdef LANG_GR
	"ZU LANG ",     /* 4 = */
#else
	"TOO LONG",     /* 4 = */
#endif
	"  LOW   "      /* 5 = (mark == 4) */
};

char *MsgCacheWarn = "L.CacheWarn";

#endif /*PASS2_C*/

#ifdef REORDER_C

static BUTTON FeelLuckyButtons[] = {
#ifdef LANG_GR
   { {0,0}, 15, "mehr Info", {'m','M',KEY_ALTM,0}, 'M', TRUE,  TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 12, "Ja",        {'j','J',KEY_ALTJ,0}, 'J', FALSE, TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 12, "Nein",      {'n','N',KEY_ALTN,0}, 'N', FALSE, TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE }
#else
   { {0,0}, 15, "More Info", {'m','M',KEY_ALTM,0}, 'M', TRUE,  TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 12, "Yes",       {'y','Y',KEY_ALTY,0}, 'Y', FALSE, TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE },
   { {0,0}, 12, "No",        {'n','N',KEY_ALTN,0}, 'N', FALSE, TRUE, 0, 1, FG_BLUE|BG_GRAY, FALSE }
#endif
};

char *MsgFeelLucky = "M.FeelLucky";
char *MsgFeelLucky2 = "M.FeelLucky2";
char *MsgMultBatch = "M.MultBatch";
char *MsgGroupIntro = "M.Group";
char *MsgSingle = "M.Single";

#ifdef LANG_GR
char *MsgReorInProg = "Umsortierung l„uft, Moment bitte...";
#else
char *MsgReorInProg = "Reordering in progress, please wait...";
#endif

#define MENUWIDTH 11	/* Widest text item in menu */
#define MENUEXTRA 4	/* Number of extra menu items */
#define UNGROUP 0	/* Code for ungrouped lines */
#define GROUPBASE  '@'  /* Base for lettered groups */

#ifdef LANG_GR
char *TitleGroup = "Gruppe";     /* Title for group menu */
#else
char *TitleGroup = "Group";     /* Title for group menu */
#endif

#if 0
#define FIRSTGROUP 0xff /* Code for first group */
#define LASTGROUP  0xfe /* Code for last group */
#ifdef LANG_GR
char *MsgFirstGroup = "ERSTE GRUPPE";
char *MsgLastGroup  = "LETZTE GRUPPE";
char *MsgFirstAction = " ERSTE";
char *MsgLastAction  = " LETZTE";
#else
char *MsgFirstGroup = "FIRST GROUP";
char *MsgLastGroup  = "LAST GROUP ";
char *MsgFirstAction = " FIRST";
char *MsgLastAction  = " LAST";
#endif
#endif

#ifdef LANG_GR

char *MsgNewGroup   = "neue Gruppe ";
char *MsgUnGroup    = "ohne Gruppe ";
char *MsgGroupNum   = "Gruppe #    ";           /* # is used as a search and */
char *MsgGrpAction  = " GRUPPE #";              /* replace token in reorder.c */

#else

char *MsgNewGroup   = "New Group  ";
char *MsgUnGroup    = "No Group   ";
char *MsgGroupNum   = "Group #    ";
char *MsgGrpAction   = " GROUP #";

#endif

#endif /*REORDER_C*/


#ifdef BROWSE_C

/*
 *	Browse button definitions
 */

static BUTTON BrowseButtons[ 4 ] = {
#ifdef LANG_GR
   { { -3, 1  }, 12, "Fertig <ÄÙ",{ DONE_KEY, 0, 0, 0 },   DONE_KEY,   FALSE, FALSE, 7, 3, FG_BLUE | BG_GRAY, FALSE },
   { { -3, 15 }, 11, "F6",        { TOGGLE_KEY, 0, 0, 0 }, TOGGLE_KEY, FALSE, FALSE, 0, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -3, 28 }, 11, "vorher F7", { PREV_KEY, 0, 0, 0 },   PREV_KEY,   FALSE, FALSE, 7, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -3, 41 }, 12, "n„chst. F8",{ NEXT_KEY, 0, 0, 0 },   NEXT_KEY,   FALSE, FALSE, 8, 2, FG_BLUE | BG_GRAY, FALSE },
#else
   { { -3, 1  }, 12, "Done Enter",{ DONE_KEY, 0, 0, 0 },   DONE_KEY,   FALSE, FALSE, 5, 5, FG_BLUE | BG_GRAY, FALSE },
   { { -3, 15 }, 11, "F6",        { TOGGLE_KEY, 0, 0, 0 }, TOGGLE_KEY, FALSE, FALSE, 0, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -3, 28 }, 11, "Prev F7",   { PREV_KEY, 0, 0, 0 },   PREV_KEY,   FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -3, 41 }, 11, "Next F8",   { NEXT_KEY, 0, 0, 0 },   NEXT_KEY,   FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
#endif
};

#ifdef LANG_GR

char *MsgAction = "AKTION";
char *MsgFile = "Datei: %s";
#define GROUPTEXTLEN 7
char *MsgGroupText = "Gruppe F6";
#define TOGGLETEXTLEN 7
char *MsgToggleText = "Umsch. F6";

#else

char *MsgAction = "ACTION";
char *MsgFile = "File: %s";
#define GROUPTEXTLEN 6
char *MsgGroupText = "Group F6";
#define TOGGLETEXTLEN 7
char *MsgToggleText = "Toggle F6";

#endif

#endif /*BROWSE_C*/

#ifdef READMXMZ_C
#ifdef LANG_GR
char *MsgProcFile = "verarbeite %s-Datei\n";
char *MsgReadFile = "lese %s-Datei\n";
char *MsgParsMax = "analysiere MAXIMIZE.OUT-Datei\n";
#else
char *MsgProcFile = "Processing %s file\n";
char *MsgReadFile = "Reading %s file\n";
char *MsgParsMax = "Parsing MAXIMIZE.OUT file\n";
#endif
char *MsgErrRead = "S.ErrRead";
char *MsgLocMax = "S.LocMax";
char *MsgReadMax = "S.ReadMax";
#endif /*READMXMZ_C*/

#ifdef P3UPDATE_C
#ifdef LANG_GR
char *MsgUnpRes = "nicht bearbeitetes residentes Programm:  %s\n";
char *MsgMovHigh = "verlege %s Byte in den HiDOS Speicher\n";
char *MsgPRGREG = "PRGREG=%d  ; lade %s in diese Programm-Region";
#else
char *MsgUnpRes = "Unprocessed resident program:  %s\n";
char *MsgMovHigh = "Moving %s bytes into high DOS memory\n";
char *MsgPRGREG = "PRGREG=%d  ; Load %s into this program region";
#endif
#endif /*P3UPDATE_C*/

#ifdef WRFILES3_C
#ifdef LANG_GR
char *MsgDelAbeta = "l”sche AUTOEXEC." ABETA "\n";
#ifdef HARPO
char *MsgHarpoPro = "schreibe " HARPO " Profil\n";
char *MsgNoHarpoPro = "kein " HARPO " Profil gefunden\n";
#endif			/* ifdef HARPO */
#else
char *MsgDelAbeta = "Deleting AUTOEXEC." ABETA "\n";
#ifdef HARPO
char *MsgHarpoPro = "Writing " HARPO " profile\n";
char *MsgNoHarpoPro = "No " HARPO " profile found\n";
#endif			/* ifdef HARPO */
#endif
#endif /*WRFILES3_C*/

#ifdef INS_MCA_C
char *AbiosErr = "S.ABIOSErr";
#endif /*INS_MCA_C*/

#ifdef INS_ADF_C
static char *Static3270 = "L.Static3270";
static char *Static6001 = "L.Static6001";
static char *StaticUser = "L.StaticUser";

#ifdef LANG_GR

static char *MsgFindCmos1 = "kann die CMOS-eigene Auswahl nicht finden fr";
static char *MsgFindCmos2 = "  ADF-Name:  %s";
static char *MsgBuiltIn = "eingebauten Adapter";
static char *MsgFindAdf1 = "hier fehlt die ADF-Datei %s.";
static char *MsgFindAdf2 = "nehmen Sie die letztgltige Arbeitskopie Ihrer ";
static char *MsgFindAdf3 = "Referenz-Diskette und starten Sie MAXIMIZE neu!";
static char *MsgRangeValErr = "Bereichswert paát nicht";
static char *MsgTooMany = "zu viele int-Werte";

char *MsgErrPosMask = "Fehler beim Bearbeiten der POS MASK:  %s";
char *MsgUnaCreate = "kann %s nicht anlegen.";
char *MsgUnaWrite = "kann nicht auf %s schreiben.";
char *MsgUnaClose = "kann %s nicht schlieáen.";
char *MsgPosFilEqu = "POSFILE=%s%s ; schreibe POS-Werte heraus,";
static char *MsgErrAdap = "Adapter ID %04X im Slot %d";

#else

static char *MsgFindCmos1 = "Unable to find the CMOS defined choice for";
static char *MsgFindCmos2 = "  ADF Name:  %s";
static char *MsgBuiltIn = "Built-in adapter";
static char *MsgFindAdf1 = "Missing ADF file %s.";
static char *MsgFindAdf2 = "Find the most recent working copy of your";
static char *MsgFindAdf3 = "Reference disk and re-run MAXIMIZE.";
static char *MsgRangeValErr = "Mismatched range value";
static char *MsgTooMany = "Too many int values";

char *MsgErrPosMask = "Error while processing POS MASK:  %s";
char *MsgUnaCreate = "Unable to create %s.";
char *MsgUnaWrite = "Unable to write to %s.";
char *MsgUnaClose = "Unable to close %s.";
char *MsgPosFilEqu = "POSFILE=%s%s ; Write out POS values";
static char *MsgErrAdap = "Adapter ID %04X in slot %d";

#endif

static char *MsgNoAdf = "S.NoAdf";
static char *MsgErrAdap2 = "M.ErrAdap";

#endif /*INS_ADF_C*/

#ifdef INS_EXE_C
char *MsgUnaFind = "S.UnaFind";
char *MsgDosErr = "S.DosErr";
char *MsgBlkFacErr = "S.Blk";
#ifdef LANG_GR
char *MsgPatching = "berarbeite MC-Adapter %04X\n";
char *MsgADPFailure = "ADP-Fehler";
#else
char *MsgPatching = "Patching MC adapter %04X\n";
char *MsgADPFailure = "ADP failure";
#endif
#endif /*INS_EXE_C*/

#ifdef UTIL_C
#ifdef LANG_GR
char *MsgMemFail = "Speicher-Zuordnungsfehler in %s fr %d Byte, breche Programm ab\n";
#else
char *MsgMemFail = "Memory allocation error in %s for %d bytes, aborting program\n";
#endif
#endif /* UTIL_C */

#ifdef MXPRINT_C

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
   { { 15, 34 }, 14, "Abbruch ESC",     { KEY_ESCAPE, 'a', 'A', KEY_ALTA     }, KEY_ESCAPE,    TRUE,  TRUE,  8, 3, FG_BLUE      | BG_GRAY, FALSE },
#else
   { { 15, 34 }, 12, "Cancel",     { KEY_ESCAPE, 'c', 'C', KEY_ALTC     }, KEY_ESCAPE,    TRUE,  TRUE,  0, 1, FG_BLUE      | BG_GRAY, FALSE },
#endif
};

#endif /* MXPRINT_C */

#ifdef PASS3_C

#ifdef LANG_GR
char *MsgMaxInProg = "MAXimierung l„uft, Moment bitte...";
char *MsgReorTestInProg = "Neuordnung\xfftest fertig...";
char *MsgRestFail =	"Wiederherstellen aus MAXIMIZE.BST erfolglos\n";
#else
char *MsgMaxInProg = "Maximizing in progress, please wait...";
/* Note that this message has an embedded Alt-255 in lieu of a space... */
char *MsgReorTestInProg = "Reordering\xfftest in progress...";
char *MsgRestFail =	"Unable to restore from MAXIMIZE.BST\n";
#endif

char *MsgNoFit = "L.NoFit";
static char *SavePsumfitFname = "%sMAXIMIZE.BST";

#endif /* PASS3_C */

#endif /* MAXTEXT_INCLUDED */
