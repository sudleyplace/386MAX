// $Header:   P:/PVCS/MAX/WINMXMZ/MESSAGES.H_V   1.4   26 Feb 1996 17:22:12   HENRY  $
//
// MESSAGES.H - Strings used in WINMAXIM.EXE
//
// Copyright (C) 1995-96 Qualitas, Inc.  All rights reserved.
//

#ifndef _MESSAGES_INCLUDED
#define	_MESSAGES_INCLUDED

// Files and data
#define	MAXIMIZE_CFG	"MAXIMIZE.CFG"
#define	MAXIMIZE_INI	"MAXIMIZE.INI"
#define	MAXIMIZE_EXE	"MAXIMIZE.EXE"
#define	MGRNAME_SYS		"386max.sys"
#define	ALTMGRNAME_SYS	"bluemax.sys"
#define	TEMPAUTO		"AUTO_WMX"
#define	TEMPAUTO_TMP	TEMPAUTO ".$$$"
#define	TEMPAUTO_BAT	TEMPAUTO ".bat"
#define	TEMPAUTO_CFG	TEMPAUTO ".cfg"

#define	INIS_DEFAULTS	"Defaults"
#define	 INI_CUSTOM		"Custom"
#define	 INI_ROMSRCH	"ROMSrch"
#define	 INI_VGASWAP	"VGAswap"
#define	 INI_EXTRADOS	"ExtraDOS"
#define	 INI_DOSSTART	"DOSStart"
#define	INIS_REMOVE		"Remove"
#define	 INI_USEHIGH	"UseHigh"
//efine  INI_VGASWAP
#define	INIS_CURRENTSECT "Current Section"
#define	 INI_STARTUPBAT "StartupBat"
#define	INIS_SUMMARY	"Summary"
#define	 INI_REMOVELINE	"RemoveLine"
#define	 INI_REMOVEMENU	"RemoveMenu"
#define	 INI_NHIGHREGS	"NHighRegs"
#define	 INI_REGTEMPLATE "Reg%d"
#define	 INI_HIGHPARAS	"HighParas"
#define	 INI_NHIGH		"NHigh"
#define	 INI_NLOW		"NLow"
#define	 INI_HIGHSEGTEMPLATE "Hiseg%d"
#define	INIS_LASTACT	"Last Action"
//efine	 INI_REMOVELINE2 INI_REMOVELINE
#define	INIS_INTL		"Intl"
#define	 INI_THOUSANDSEP "sThousand"

//------------------------------------------------------------------
#ifdef LANG_GR
// German
//------------------------------------------------------------------
// Dialog data
#define	DLGMSG_NAMEBYTES " Name\t\t\tBytes"
#define	DLGMSG_TOTAL	"    Insgesamt"
#define	DLGMSG_NOLOW1	"Keines der ausgewไhlten"
#define	DLGMSG_NOLOW2	"Programme verleibt im"
#define	DLGMSG_NOLOW3	"LoDOS-Speicher."

// Error messages
#define	ERRMSG_NOMAX	"Sie müssen zuerst Qualitas MAX installieren."
#define	ERRMSG_MAX_MCFG	"Sie müssen zuerst Qualitas MAX in diesem MultiConfig-Block installieren."
#define	ERRMSG_CANTEXIT	"Kann Windows nicht beenden. Bitte schlie฿en\n" \
			"Sie alle DOS-Fenster und versuchen Sie es erneut."
#define	ERRMSG_CANTPREMAXIM "Kann Windows nicht beenden, um die vorherige Konfiguration\n" \
			"wiederherzustellen. Rufen Sie PREMAXIM.BAT auf und starten Sie den Computer neu."

#define FMT_MOVED "Maximize hat %dKB in HiDOS-Speicher verlagert."
#define FMT_REMAIN "Es sind noch %dKB HiDOS-Speicher frei."
#define FMT_FREE "Insgesamt freier konventioneller Speicher: %dKB"

// Module-specific static values
#ifdef WINMXMZ
static char *MsgAutotemp =
	  "@echo off\n"
	  "echo off\n"
	  "echo ออออออออออออออ Qualitas MAX Maximize ออออออออออออออออ\n"
	  "echo Ein evtl. vorhandenes Menuprogramm beenden Sie bitte\n"
	  "echo sobald es geladen ist, damit MAXIMIZE fortfahren kann.\n"
	  "echo อออออออออออออออออออออออออออออออออออออออออออออออออออออ\n"
	  "copy %s ";
    // end of ifdef WINMXMZ
#endif

//------------------------------------------------------------------
#else
// English
//------------------------------------------------------------------

// Dialog data
#define	DLGMSG_NAMEBYTES " Name\t\t\tbytes"
#define	DLGMSG_TOTAL	"    Total"
#define	DLGMSG_NOLOW1	"No programs selected for"
#define	DLGMSG_NOLOW2	"processing remain in low"
#define	DLGMSG_NOLOW3	"DOS memory."

// Error messages
#define	ERRMSG_NOMAX	"You must first install Qualitas MAX"
#define	ERRMSG_MAX_MCFG	"You must first install Qualitas MAX into this MultiConfig section"
#define	ERRMSG_CANTEXIT	"Unable to exit Windows.  Please close\n" \
						"any DOS sessions and try again."
#define	ERRMSG_CANTPREMAXIM "Unable to exit Windows to restore and reboot\n" \
						"previous configuration.  Run PREMAXIM.BAT and reboot."

#define FMT_MOVED "Maximize has moved %dKB into high DOS."
#define FMT_REMAIN "You have %dKB of unused high DOS memory remaining."
#define FMT_FREE "Total Free Conventional Memory %dKB"

// Module-specific static values
#ifdef WINMXMZ
static char *MsgAutotemp =
	  "@echo off\n"
	  "echo off\n"
	  "echo ออออออออออออออ Qualitas MAX Maximize ออออออออออออออออ\n"
	  "echo Please exit any menu or shell programs as soon as\n"
	  "echo they appear so that we may proceed with MAXIMIZE.\n"
	  "echo อออออออออออออออออออออออออออออออออออออออออออออออออออออ\n"
	  "copy %s ";
    // end of ifdef WINMXMZ
#endif

    // end of ifdef LANG_GR else
#endif

    // end of ifndef _MESSAGES_INCLUDED
#endif

