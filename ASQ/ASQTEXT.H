/*' $Header:   P:/PVCS/MAX/ASQ/ASQTEXT.H_V   1.2   26 Feb 1996 15:16:02   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * ASQTEXT.H								      *
 *									      *
 * All ASQ text strings and related definitions 			      *
 *									      *
 ******************************************************************************/

/*
*
*     ⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
*     ≥ German Version Feb '92 by H.Reibe c/o Klaus Albrecht / MÅnchen  ≥
*     ≥ Hi folks,							≥
*     ≥ !all transferred strings will need to be checked carefully!	≥
*     ≥ (modified: length a/o switching chars)				≥
*     ≥ please take care of the chars with diacritical marks:		≥
*     ≥ Ñ  =  ASCII 84h        î  =  ASCII 94h	    Å  =  ASCII 81h	≥
*     ≥ é  =  ASCII 8Eh        ô  =  ASCII 99h	    ö  =  ASCII 9Ah	≥
*     ≥ ·  =  ASCII E1h 						≥
*     ≥ German and Austrian and Swiss people really do use them.	≥
*     ≥ Approx. 100 millions of customers! Wow, what a marketplace!	≥
*     √ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥
*     ≥ ! above given remarks may be valid for ALL other files !	≥
*     ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
*/

// Turn off unsized array extern warning; we need /Gx to keep DGROUP < 64K.
#ifndef GLINIT
#pragma warning( disable : 4746 )
#endif

/* #define REVIVETHEMENUCALLBACKS */

#ifndef TEXT_INCLUDED
#define TEXT_INCLUDED

#ifndef BUTTON_INCLUDED
#include "button.h"
#endif

#ifndef QHELP_INCLUDED
#include "qhelp.h"
#endif

#ifndef KEYBOARD_INCLUDED
#include "keyboard.h"
#endif

#ifndef LIBTEXT_INCLUDED
#include "libtext.h"
#endif

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


#ifndef ENGINE_INCLUDED
#include "engine.h"
#endif

#ifndef KEYBOARD_INCLUDED
#include "keyboard.h"
#endif

#ifndef MENU_INCLUDED
#include "menu.h"
#endif

#ifndef MESSAGE_INCLUDED
#include "message.h"
#endif


#ifndef WINDOWFN_INCLUDED
#include "windowfn.h"
#endif

#ifndef SURFACE_INCLUDED
#include "surface.h"
#endif

#ifndef NULL
 #if (_MSC_VER >= 600)
  #define NULL	((void *)0)
 #elif (defined(M_I86SM) || defined(M_I86MM))
  #define NULL	0
 #else
  #define NULL	0L
 #endif
#endif

/*
*	All the stuff relating to tutorials
*/
#define HELPNAMEWIDTH (unsigned)15
#define WORKSPACESIZE ((unsigned)(2666*HELPNAMEWIDTH)) /*	39990 bytes */
GLOBAL char HelpNames[(WORKSPACESIZE/HELPNAMEWIDTH)][HELPNAMEWIDTH]
#ifdef GLINIT
= {
	"H.Contents",    /*  0   */
	"H.Index",               /*  1   */
	"H.U_Help",              /*  2   */
	"H.Default",     /*  3   */
	"H.U_Dial",              /*  4   */
	"H.U_Print",     /*  5   */
	"H.U_Editor",    /*  6   */
	"H.U_Browse",    /*  7   */
	"H.E_Option",    /*  8   */
	"H.Default",     /*  9   */
	/* These entries must correspond to the enum and help type below */
	"H.Mem_Sum",     /*  10  */

	"H.Mem_Low",
	"H.Mem_Hi",
	"H.Mem_ROM",
	"H.Mem_Int",
	"H.Mem_Ext",
	"H.Mem_Exp",
	"H.Mem_EMS",
	"H.Mem_XMS",
	"H.Mem_Tim",
	"H.Cfg_Sum",     /*  20  */

	"H.Cfg_Cfg",
	"H.Cfg_Aut",
	"H.Cfg_Pro",
	"H.Cfg_EPro",
	"H.Cfg_SYSINI",
	"H.Cfg_Qualitas",
	"H.Cfg_Windows",
	"H.Hdw_Sum",
	"H.Hdw_Vid",
	"H.Hdw_Drv",     /*  30  */

	"H.Hdw_Por",
	"H.Hdw_BIOS",
	"H.Cfg_CMO",
	"H.Snp_Info",
	"H.Index",
	"H.Default",
	"H.T_Mem_Lsn_01",
	"H.T_Cfg_Lsn_01",
	"H.T_Hdw_Lsn_01",
	"H.Index",       /*  40  */

	"H.Contents",
	"H.Contents",
	"H.Contents",
	"H.U_Help",
	"H.Default",
	"H.U_Dial",
	"H.U_Print",
	"H.U_Tutor",
	/* New contents of CONFIG menu are: */
	/* Summary */
	/* ------- */
	/* CONFIG.SYS */
	/* AUTOEXEC.BAT */
	/* MAX Profile */
	/* >>ExtraDOS profile */
	/* >>SYSTEM.INI */
	/* >>----------- */
	/* >>Qualitas */
	/* >>Windows */
	/* ---------- */
	/* CMOS detail */
	"Q_Cfg_AUT",
	"Q_Cfg_CFG",     /*  50  */

	"Q_Cfg_CMO",
	"Q_Cfg_PRO",
	"Q_Cfg_EPRO",
	"Q_Cfg_SYSINI",
	"Q_Cfg_Qualitas",
	"Q_Cfg_Windows",
	"Q_Cfg_Sum",
	"Q_Exit",
	"Q_Hdw_BIO",
	"Q_Hdw_Drv",     /*  60  */

	"Q_Hdw_Por",
	"Q_Hdw_Sum",
	"Q_Hdw_Vid",
	"Q_Help",
	"Q_L_Abt_ASQ",
	"Q_L_Cfg",
	"Q_L_Gloss",
	"Q_L_Hdw",
	"Q_L_Index",
	"Q_L_Contents",  /*  70  */

	"Q_L_Mem",
	"Q_L_Q",
	"Q_L_Tune",
	"Q_Mem_EMS",
	"Q_Mem_Exp",
	"Q_Mem_Ext",
	"Q_Mem_Hi",
	"Q_Mem_Int",
	"Q_Mem_Low",
	"Q_Mem_ROM",     /*  80  */

	"Q_Mem_Sum",
	"Q_Mem_Tim",
	"Q_Mem_XMS",
	"Q_Snp_Clear",
	"Q_Snp_Info",
	"Q_Snp_Load",
	"Q_Snp_Sav",
	"H.T_Mem_Lsn_01",
	"H.T_Mem_Low",
	"H.T_Mem_Hi",    /*  90  */

	"H.T_Mem_ROM",
	"H.T_Mem_Int",
	"H.T_Mem_Ext",
	"H.T_Mem_Exp",
	"H.T_Mem_Exp",
	"H.T_Mem_XMS",
	"H.T_Mem_Tim",
	"H.T_Cfg_Sum",
	"H.T_Cfg_Cfg",
	"H.T_Cfg_Aut",   /* 100  */

	"H.T_Cfg_Pro",
	"H.T_Cfg_EPro",
	"H.T_Cfg_SYSINI",
	"H.T_Cfg_Qualit",
	"H.T_Cfg_Window",
	"H.T_Hdw_Sum",
	"H.T_Hdw_Vid",
	"H.T_Hdw_Drv",
	"H.T_Hdw_Por",
	"H.T_Hdw_BIOS",  /* 110  */  /*  Stan            needs   these   */

	"H.T_Cfg_CMO",
	"H.T_Snapshot",
	"H.U_Browse",
	"H.Snp_Load",
	"H.Snp_Save",
	"H.Snp_Info",
	"H.Snp_Clear",
	"H.U_Gloss",
	"H.L_Abt_Q",
	"H.L_Abt_386",   /*  120 */

	"H.L_Abt_MAX",
	"H.L_Abt_MOVE",
	"H.L_Tun_Int",
	"H.L_Tun_Ver",
	"H.L_Tun_BUF",
	"H.L_Tun_FCB",
	"H.L_Tun_ENV",
	"H.L_Tun_STA",
	"H.L_Tun_FAS",
	"H.L_Tun_PRI",   /*  130 */

	"H.L_Tun_Mem",
	"H.Products",
	"H.Tuning",
	"H.L_Tun_FILLow",
	"H.L_Tun_FILMed",
	"H.L_Tun_FILHi", /* 136 */
#ifdef REVIVETHEMENUCALLBACKS
	"A_D_Clear",
	"A_D_Exit",
	"A_D_Load",
	"A_D_Save",
	"A_D_Help",
	"A_D_Learn",
#endif /* REVIVE... */
}
#endif
;

/*	 These are defined in LIBTEXT.H
#define HELPMCONTENTS		0		***  In libtext.h ****
#define HELPINDEX			1		***  In libtext.h ****
#define HELPHELP			2		***  In libtext.h ****
#define HELPMENUS			3		***  In libtext.h ****
#define HELPDIALOGS		4		***  In libtext.h ****
#define HELPPRINT			5		***  In libtext.h ****
#define HELPEDITOR			6		***  In libtext.h ****
#define HELPBROWSE			7		***  In libtext.h ****
#define HELPOPTEDITOR		8	   End of things defined in LIBTEXT.h */
/* These values need to correspond to members of HelpNames[] */
enum {
	HELPASQCONTENTS=9,		/*  9: Main screen */
	HELP_MEM_SUMM,			/* 10: Memory_Summary */

	HELP_MEM_LOW,			/*     Memory_Low_DOS */
	HELP_MEM_HIGH,			/*     Memory_High_DOS */
	HELP_MEM_ROM,			/*     Memory_ROM_Scan */
	HELP_MEM_INT,			/*     Memory_Interrupts */
	HELP_MEM_EXT,			/*     Memory_Extended */
	HELP_MEM_EXP,			/*     Memory_Expanded */
	HELP_MEM_EMS,			/*     Memory_EMS_Usage */
	HELP_MEM_XMS,			/*     Memory_XMS */
	HELP_MEM_TIME,			/*     Memory_Timing */
	HELP_CFG_SUMM,			/* 20: Config_Summary */

	HELP_CFG_CONFIG,		/*     Config_CONFIG_SYS */
	HELP_CFG_AUTOEXEC,		/*     Config_AUTOEXEC_BAT */
	HELP_CFG_386MAX,		/*     Config_386MAX_PRO */
	HELP_CFG_EXTRADOS,		/*     Config_ExtraDOS_PRO */
	HELP_CFG_SYSINI,		/*     Config_SYSTEM_INI */
	HELP_CFG_QUALITAS,		/*     Config_Qualitas */
	HELP_CFG_WINDOWS,		/*     Config_Windows */
	HELP_HW_SUMM,			/*     Hardware_Summary1 */
	HELP_HW_VIDEO,			/*     Hardware_Video */
	HELP_HW_DRIVES, 		/* 30: Hardware_Drives */

	HELP_HW_PORTS,			/*     Hardware_Ports */
	HELP_HW_BIOS,			/*     Hardware_BIOS_Detail */
	HELP_HW_CMOS,			/*     Hardware_CMOS_Detail */
	HELP_SNAPINFO,			/*     Snapshot */
	ASQHELPINDEX,			/*     Index	*/
	LEARNASQ,			/*	Asq Tutorial about Asq */
	LEARNMEMORY,			/*	Asq Tutorial about Memory */
	LEARNCONFIG,			/*	Asq Tutorial about Config */
	LEARNEQUIPMENT, 		/*	Asq Tutorial about Equipment */
	LEARNINDEX,			/*  40: Asq Tutorial  Index */

	LEARNCONTENTS,
	LEARNGLOSSARY,			/*	Asq Tutorial  Glossary */
	ASQHELPCONTENTS,
	ASQHELPHELP,
	ASQHELPMENUS,
	ASQHELPDIALOGS,
	ASQHELPPRINT,
	ASQHELPTUTOR,
	QUICK_Cfg_AUT,			/*	All quick help definitions */
	QUICK_Cfg_CFG,			/*  50: CONFIG.SYS browser */

	QUICK_Cfg_CMO,
	QUICK_Cfg_PRO,
	QUICK_Cfg_EPRO,
	QUICK_Cfg_SYSINI,
	QUICK_Cfg_Qualitas,
	QUICK_Cfg_Windows,
	QUICK_Cfg_Sum,
	QUICK_Exit,
	QUICK_Hdw_BIO,
	QUICK_Hdw_Drv,			/* 60: Drive summary */

	QUICK_Hdw_Por,
	QUICK_Hdw_Sum,
	QUICK_Hdw_Vid,
	QUICK_Help,
	QUICK_L_Abt_ASQ,
	QUICK_L_Cfg,
	QUICK_L_Gloss,
	QUICK_L_Hdw,
	QUICK_L_Index,
	QUICK_L_Contents,		/* 70: Tutorial contents */

	QUICK_L_Mem,
	QUICK_L_Q,
	QUICK_L_Tune,
	QUICK_Mem_EMS,
	QUICK_Mem_Exp,
	QUICK_Mem_Ext,
	QUICK_Mem_Hi,
	QUICK_Mem_Int,
	QUICK_Mem_Low,
	QUICK_Mem_ROM,			/* 80: ROM */

	QUICK_Mem_Sum,
	QUICK_Mem_Tim,
	QUICK_Mem_XMS,
	QUICK_Snp_Clear,
	QUICK_Snp_Info,
	QUICK_Snp_Load,
	QUICK_Snp_Save,
	TUTORIAL_Mem_Sum,	/*	Mem_Summ - HW_Cmos MUST!!!!!! be in */
	TUTORIAL_Mem_Low,	/*	the same order as */
	TUTORIAL_Mem_Hi,	/*  90: the engine.h definition numbers */

	TUTORIAL_Mem_ROM,
	TUTORIAL_Mem_Int,
	TUTORIAL_Mem_Ext,
	TUTORIAL_Mem_Exp,
	TUTORIAL_Mem_EMS,
	TUTORIAL_Mem_XMS,
	TUTORIAL_Mem_Tim,
	TUTORIAL_Cfg_Sum,
	TUTORIAL_Cfg_Cfg,
	TUTORIAL_Cfg_Aut,	/* 100: Tutorial CONFIG menu AUTOEXEC.BAT */

	TUTORIAL_Cfg_Pro,
	TUTORIAL_Cfg_EPro,
	TUTORIAL_Cfg_SYSINI,
	TUTORIAL_Cfg_Qualitas,
	TUTORIAL_Cfg_Windows,
	TUTORIAL_Hdw_Sum,
	TUTORIAL_Hdw_Vid,
	TUTORIAL_Hdw_Drv,
	TUTORIAL_Hdw_Por,
	TUTORIAL_Hdw_BIO,	/* 110: Tutorial hdw BIOS */

	TUTORIAL_Cfg_CMO,
	TUTORIAL_SnapShot,
	ASQHELPBROWSE,
	ASQHELPSnp_Load,
	ASQHELPSnp_Save,
	ASQHELPSnp_Info,
	ASQHELPSnp_Clear,
	ASQHELPGloss,
	LEARN_ABOUTQ,
	LEARN_ABOUT386, 	/* 120: Tutorial 386 */

	LEARN_ABOUTMAX,
	LEARN_ABOUTMOV,
	LEARN_TUNEINTRO,
	LEARN_TUNEVERS,
	LEARN_TUNEBUFF,
	LEARN_TUNEFCB,
	LEARN_TUNEENV,
	LEARN_TUNESTA,
	LEARN_TUNEFAS,
	LEARN_TUNEPRI,		/* 130: Tuning */

	LEARN_TUNEMEM,
	LEARNQUALITAS,		/*	Asq Tutorial about Qualitas */
	LEARNTUNING,		/*	Asq Tutorial about Tuning */
	LEARN_TUNEFILLOW,
	LEARN_TUNEFILMED,
	LEARN_TUNEFILHI,	/* 136: Tuning */
#ifdef REVIVETHEMENUCALLBACKS
	AS_DATA_Clear,
	AS_DATA_Exit,
	AS_DATA_Load,
	AS_DATA_Save,
	AS_DATA_Help,
	AS_DATA_Learn,
#endif /* REVIVE... */
	HELPLAST		/* 137: End of list */
}; /* end enum {} */

/*
*  There is an explicit extern reference to this
*  in help.c.  Make sure if you change one, you change the other
*/

GLOBAL HELPDEF HelpInfo[ HELPLAST+1 ]
#ifdef GLINIT
= {
	{ HELP_ASQHELP, HelpNames[0	],	0,	NULL },  /* 0	  */
	{ HELP_ASQHELP, HelpNames[1	],	0,	NULL },  /* 1	  */
	{ HELP_ASQHELP, HelpNames[2	],	0,	NULL },  /* 2	  */
	{ HELP_ASQHELP, HelpNames[3	],	0,	NULL },  /* 3	  */
	{ HELP_ASQHELP, HelpNames[4	],	0,	NULL },  /* 4	  */
	{ HELP_ASQHELP, HelpNames[5	],	0,	NULL },  /* 5	  */
	{ HELP_ASQHELP, HelpNames[6	],	0,	NULL },  /* 6	  */
	{ HELP_ASQHELP, HelpNames[7	],	0,	NULL },  /* 7	  */
	{ HELP_ASQHELP, HelpNames[8	],	0,	NULL },  /* 8	  */
	{ HELP_ASQHELP, HelpNames[ASQHELPCONTENTS],	0, NULL  },  /* 9  */
	{ HELP_ASQHELP, HelpNames[HELP_MEM_SUMM],	0, NULL  },  /* 10 */

	{ HELP_ASQHELP, HelpNames[HELP_MEM_LOW],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_MEM_HIGH],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_MEM_ROM],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_MEM_INT],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_MEM_EXT],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_MEM_EXP],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_MEM_EMS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_MEM_XMS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_MEM_TIME],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_CFG_SUMM],	0, NULL  },  /* 20 */

	{ HELP_ASQHELP, HelpNames[HELP_CFG_CONFIG],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_CFG_AUTOEXEC],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_CFG_386MAX],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_CFG_EXTRADOS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_CFG_SYSINI],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_CFG_QUALITAS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_CFG_WINDOWS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_HW_SUMM],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_HW_VIDEO],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_HW_DRIVES],	0, NULL  },  /* 30 */

	{ HELP_ASQHELP, HelpNames[HELP_HW_PORTS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_HW_BIOS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_HW_CMOS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[HELP_SNAPINFO],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPINDEX],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[LEARNASQ],		0, NULL  },
	{ HELP_TUTORIAL,HelpNames[LEARNMEMORY], 	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[LEARNCONFIG], 	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[LEARNEQUIPMENT],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[LEARNINDEX],		0, NULL  },  /* 40 */

	{ HELP_TUTORIAL,HelpNames[LEARNCONTENTS],	0, NULL  },
	{ HELP_GLOSSARY,HelpNames[LEARNGLOSSARY],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPCONTENTS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPHELP], 	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPMENUS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPDIALOGS],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPPRINT],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPTUTOR],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_AUT],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_CFG],	0, NULL  },  /* 50 */

	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_CMO],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_PRO],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_EPRO],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_SYSINI],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_Qualitas],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_Windows],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Cfg_Sum],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Exit],		0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Hdw_BIO],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Hdw_Drv],	0, NULL  },  /* 60 */

	{ HELP_ASQUICK, HelpNames[QUICK_Hdw_Por],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Hdw_Sum],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Hdw_Vid],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Help],		0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_L_Abt_ASQ],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_L_Cfg], 	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_L_Gloss],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_L_Hdw], 	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_L_Index],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_L_Contents],	0, NULL  },  /* 70 */

	{ HELP_ASQUICK, HelpNames[QUICK_L_Mem], 	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_L_Q],		0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_L_Tune],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_EMS],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_Exp],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_Ext],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_Hi],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_Int],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_Low],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_ROM],	0, NULL  },  /* 80 */

	{ HELP_ASQUICK, HelpNames[QUICK_Mem_Sum],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_Tim],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Mem_XMS],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Snp_Clear],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Snp_Info],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Snp_Load],	0, NULL  },
	{ HELP_ASQUICK, HelpNames[QUICK_Snp_Save],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_Sum],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_Low],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_Hi],	0, NULL  },  /* 90 */

	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_ROM],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_Int],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_Ext],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_Exp],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_EMS],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_XMS],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Mem_Tim],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_Sum],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_Cfg],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_Aut],	0, NULL  },  /* 100 */

	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_Pro],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_EPro],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_SYSINI], 0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_Qualitas], 0, NULL },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_Windows], 0, NULL },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Hdw_Sum],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Hdw_Vid],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Hdw_Drv],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Hdw_Por],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Hdw_BIO],	0, NULL  },  /* 110 */	/* Stan needs these */

	{ HELP_TUTORIAL,HelpNames[TUTORIAL_Cfg_CMO],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[TUTORIAL_SnapShot],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPBROWSE],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPSnp_Load],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPSnp_Save],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPSnp_Info],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPSnp_Clear],	0, NULL  },
	{ HELP_ASQHELP, HelpNames[ASQHELPGloss],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_ABOUTQ],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_ABOUT386],	0, NULL  },  /* 120 */

	{ HELP_ASQLEARN,HelpNames[LEARN_ABOUTMAX],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_ABOUTMOV],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEINTRO],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEVERS],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEBUFF],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEFCB],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEENV],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNESTA],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEFAS],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEPRI],	0, NULL  },  /* 130 */

	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEMEM],	0, NULL  },
	{ HELP_TUTORIAL,HelpNames[LEARNQUALITAS],	0, &setupRecommend },
	{ HELP_TUTORIAL,HelpNames[LEARNTUNING], 	0, &setupTuning  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEFILLOW],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEFILMED],	0, NULL  },
	{ HELP_ASQLEARN,HelpNames[LEARN_TUNEFILHI],	0, NULL  },  /* 136 */
#ifdef REVIVETHEMENUCALLBACKS
	{ HELP_AS_DATA, HelpNames[AS_DATA_Clear],	0, NULL  },
	{ HELP_AS_DATA, HelpNames[AS_DATA_Exit],	0, NULL  },
	{ HELP_AS_DATA, HelpNames[AS_DATA_Load],	0, NULL  },
	{ HELP_AS_DATA, HelpNames[AS_DATA_Save],	0, NULL  },
	{ HELP_AS_DATA, HelpNames[AS_DATA_Help],	0, NULL  },
	{ HELP_AS_DATA, HelpNames[AS_DATA_Learn],	0, NULL  },  /* 142 */
#endif /* REVIVE... */
	{ HELP_LAST,	  NULL, 	0, NULL  }  /* 137 (143) */
}
#endif
;

/*
*  Workspace for initialization
*/
GLOBAL char far *tutorWorkSpace
#ifdef GLINIT
= HelpNames[0]
#endif
;

/* These are screen identifiers.  They need to be sequential, as they're */
/* also used as indices. */
/* The entries between MEMORYSUMMARY and SNAPINFO (inclusive) are also */
/* indices which must be represented in altPgUp and altPgDn. */
enum {
	MEMORYSUMMARY=1,
	MEMORYLOWDOS,
	MEMORYHIGHDOS,
	MEMORYROMSCAN,
	MEMORYINTERRUPTS,
	MEMORYEXTENDED,
	MEMORYEXPANDED,
	MEMORYEMS,
	MEMORYXMS,
	MEMORYTIMING,

	CONFIGSUMMARY,		/* 11 */
	CONFIGSYS,
	CONFIGAUTOEXEC,
	CONFIGMAXPRO,
	CONFIGEXTRADOSPRO,
	CONFIGSYSINI,
	CONFIGQUALITAS,
	CONFIGWINDOWS,

	HARDSUMMARY,		/* 19 */
	HARDVIDEO,
	HARDDRIVES,
	HARDPORTS,
	HARDBIOS,

	CONFIGCMOS,		/* 24 */
	SNAPINFO,		/* 25: Used as an endpoint in altPg{Up,Dn} */
				/*	structures defined below for ASQ.C */

	ASQFILEMENU,		/* 26 */
	ASQMEMORYMENU,
	ASQCONFIGMENU,
	ASQHARDMENU,
	ASQLEARNMENU,
	ASQHELPMENU,

	SNAPLOAD,		/* 32 */
	SNAPSAVE,
	SNAPCLEAR,
	SNAPEXIT,

	MLEARNASQ,		/* 36 */
	MLEARNQUALITAS,
	MLEARNTUNING,
	MLEARNMEMORY,
	MLEARNCONFIG,
	MLEARNEQUIPMENT,
	MLEARNCONTENTS,
	MLEARNINDEX,
	MLEARNGLOSSARY,

	AHELPCONTENTS,		/* 45 */
	AHELPINDEX,
	AHELPHELP,
	AHELPMENUS,
	AHELPDIALOGS,
	AHELPPRINT,
	AHELPTUTORIAL
};

/* Menu IDs.  Some of these are used interchangeably with screen identifiers. */
enum {
	MAINFILEMENU=101,
	MAINASQMENU,
	MAINMAXIMIZEMENU,
	MAININFOMENU,
	MAINHELPMENU,			/* 105 */

	FILECONFIG=  CONFIGSYS, 	/* 12 */
	FILEAUTOEXEC=CONFIGAUTOEXEC,
	FILEPROFILE= CONFIGMAXPRO,
	FILEEPROFILE=CONFIGEXTRADOSPRO,
	FILESYSINI=  CONFIGSYSINI,
	FILEQUALITAS=CONFIGQUALITAS,
	FILEWINDOWS= CONFIGWINDOWS,
	FILEOTHER=MAINHELPMENU+7+1,	/* 113 */
	FILEUPDATE,
	FILEEXIT,

	ASQASQ, 			/* 116 */
	ASQMEMORY=MEMORYSUMMARY,	/* 1 */
	ASQCONFIG=CONFIGSUMMARY,	/* 11 */
	ASQEQUIPMENT=HARDSUMMARY,	/* 19 */

	MAXIMIZEQUICK=ASQASQ+3+1,	/* 120 */
	MAXIMIZEFULL,

	INFOOVERVIEW,			/* 122 */
	INFOEMS,
	INFORESIDENT,
	INFODEVICE,
	INFOLOAD,
	INFOROM,
	INFOTIME,

	MHELPCONTENTS,			/* 129 */
	MHELPINDEX,
	MHELPHELP,
	MHELPMENUS,
	MHELPDIALOGS,
	MHELPPRINT,
	MHELPEDITOR			/* 135 */
};


/*	Asq menu definitions
*/
#ifdef REVIVETHEMENUCALLBACKS
#define CALLBACKF &quickAsq
#else
#define CALLBACKF NULL
#endif /* Menu callbacks in use */

#define NUMASQBUTTONS 4
#define ASQEXITESC 0
GLOBAL BUTTON AsqButtons[ NUMASQBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { -1, 1  }, 12, "Ende ESC", { KEY_ESCAPE,     0, 0, 0 }, KEY_ESCAPE,   FALSE, FALSE, 5, 3, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 15 }, 11, "Hilfe F1", { KEY_F1,         0, 0, 0 },     KEY_F1,   FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Druck F2", { KEY_F2,         0, 0, 0 },     KEY_F2,   FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 41 }, 11, "Lerne F3", { KEY_F3,         0, 0, 0 },     KEY_F3,   FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
}
#else
= {
   { { -1, 1  }, 12, "Exit Esc",         { KEY_ESCAPE, 0, 0, 0 }, KEY_ESCAPE,   FALSE, FALSE, 5, 3, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 15 }, 11, "Help F1", { KEY_F1,          0, 0, 0 },     KEY_F1,               FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Print F2", { KEY_F2,         0, 0, 0 },     KEY_F2,               FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 41 }, 11, "Tutor F3", { KEY_F3,         0, 0, 0 },     KEY_F3,               FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
}
#endif
#endif
;

enum {
		S_POS0,
	SLPOS,
	SSPOS,
	SIPOS,
	SCPOS,
		S_POS1,
	SXPOS,
		NUMSNAPMENUITEMS
};

GLOBAL struct
{
	MENUINFO info;
	MENUITEM items[ NUMSNAPMENUITEMS ];
} SnapMenu
#ifdef GLINIT
#ifdef LANG_GR
= {
	{ NUMSNAPMENUITEMS, MENU_VERTICAL, { 1, 0 , 9, 14 }, TRUE, 0, MENU_NOTSHOWN, (FG_BLACK | BG_GRAY), NULL, CALLBACKF },
 {
		{ { 1,	1 }, 0, 	   ITEM_INFO,	  { 0, 0}, NULL, -1, -1,			  -1,	-1,	-1,		   { 0,   0,   0 }, 8,	FG_BLUE  | BG_GRAY, "-Snapshot-" },
		{ { 2,	1 }, SNAPLOAD,	   ITEM_ACTIVE,   { 0, 0}, NULL, 2,  QUICK_Snp_Load,  ASQHELPSnp_Load,	P_HELP, -1,		   { 'a', 'A', 0 }, 4,  FG_BLACK | BG_GRAY, "Laden"     },
		{ { 3,	1 }, SNAPSAVE,	   ITEM_ACTIVE,   { 0, 0}, NULL, 1,  QUICK_Snp_Save,  ASQHELPSnp_Save,	P_HELP, -1,		   { 's', 'S', 0 }, 7,  FG_BLACK | BG_GRAY, "Sichern"  },
		{ { 4,	1 }, SNAPINFO,	   ITEM_DISABLED, { 0, 0}, NULL, 1,  QUICK_Snp_Info,  ASQHELPSnp_Info,	P_HELP, TUTORIAL_SnapShot, { 'i', 'I', 0 }, 4,  FG_BLACK | BG_GRAY, "Info"     },
		{ { 5,	1 }, SNAPCLEAR,    ITEM_ACTIVE,   { 0, 0}, NULL, 1,  QUICK_Snp_Clear, ASQHELPSnp_Clear, P_HELP, -1,		   { 'l', 'L', 0 }, 5,  FG_BLACK | BG_GRAY, "Leeren"    },
		{ { 6,	1 }, 0, 	   ITEM_SEPARATOR,{ 0, 0}, NULL, -1, -1,			  -1,	-1,	-1,		   { 0,   0,   0 }, 0,	FG_BLACK | BG_GRAY, ""         },
		{ { 7,	1 }, SNAPEXIT,	   ITEM_ACTIVE,   { 0, 0}, NULL, 1,  QUICK_Exit,		  -1,	-1,	-1,		   { 'b', 'B', 0 }, 7,  FG_BLACK | BG_GRAY, "Beenden"  }
	}
}
#else
= {
	{ NUMSNAPMENUITEMS, MENU_VERTICAL, { 1, 0 , 9, 14 }, TRUE, 0, MENU_NOTSHOWN, (FG_BLACK | BG_GRAY), NULL, CALLBACKF },
 {
		{ { 1,	1 }, 0, 		   ITEM_INFO,	  { 0, 0}, NULL, -1, -1,			  -1,				-1,		-1,			   { 0,   0,   0 }, 10, FG_BLUE  | BG_GRAY,	"-Snapshot-" },
		{ { 2,	1 }, SNAPLOAD,	   ITEM_ACTIVE,   { 0, 0}, NULL, 1,  QUICK_Snp_Load,  ASQHELPSnp_Load,	P_HELP, -1,			   { 'l', 'L', 0 }, 4,  FG_BLACK | BG_GRAY, "Load"       },
		{ { 3,	1 }, SNAPSAVE,	   ITEM_ACTIVE,   { 0, 0}, NULL, 1,  QUICK_Snp_Save,  ASQHELPSnp_Save,	P_HELP, -1,			   { 's', 'S', 0 }, 4,  FG_BLACK | BG_GRAY, "Save..." },
		{ { 4,	1 }, SNAPINFO,	   ITEM_DISABLED, { 0, 0}, NULL, 1,  QUICK_Snp_Info,  ASQHELPSnp_Info,	P_HELP, TUTORIAL_SnapShot, { 'i', 'I', 0 }, 4,  FG_BLACK | BG_GRAY, "Info"       },
		{ { 5,	1 }, SNAPCLEAR,    ITEM_ACTIVE,   { 0, 0}, NULL, 1,  QUICK_Snp_Clear, ASQHELPSnp_Clear, P_HELP, -1,			   { 'c', 'C', 0 }, 5,  FG_BLACK | BG_GRAY, "Clear"      },
		{ { 6,	1 }, 0, 		   ITEM_SEPARATOR,{ 0, 0}, NULL, -1, -1,			  -1,				-1,	-1,			   { 0, 	0, 0 }, 0,	FG_BLACK | BG_GRAY, ""           },
		{ { 7,	1 }, SNAPEXIT,	   ITEM_ACTIVE,   { 0, 0}, NULL, 2,  QUICK_Exit,	  -1,				-1,		-1,			   { 'x', 'X', 0 }, 4,  FG_BLACK | BG_GRAY, "Exit"               }
	}
}
#endif
#endif
;

enum {
	MSPOS,
		M_POS0,
	MLPOS,
	MHPOS,
	MRPOS,
	MIPOS,
		M_POS1,
	MTPOS,
	MPPOS,
	MEPOS,
	MXPOS,
		M_POS2,
	MAPOS,
		NUMMEMORYMENUITEMS
};

GLOBAL struct
{
	MENUINFO info;
	MENUITEM items[ NUMMEMORYMENUITEMS ];
} MemoryMenu
#ifdef GLINIT
#ifdef LANG_GR
= {
	{ NUMMEMORYMENUITEMS, MENU_VERTICAL, { 1, 6, 15, 17 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF	},
	{
		{ { 1,	1 }, MEMORYSUMMARY,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Sum, HELP_MEM_SUMM, P_MENU, TUTORIAL_Mem_Sum, { 'g', 'G', 0 },     6,      FG_BLACK | BG_GRAY, "Gesamt" },
		{ { 2,	1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,		  -1,		 -1,	 -1,		   { 0,     0, 0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 3,	1 }, MEMORYLOWDOS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Low, HELP_MEM_LOW,  P_MENU, TUTORIAL_Mem_Low, { 'l', 'L', 0 },     5,      FG_BLACK | BG_GRAY, "LoDOS"  },
		{ { 4,	1 }, MEMORYHIGHDOS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Hi,  HELP_MEM_HIGH, P_MENU, TUTORIAL_Mem_Hi,  { 'h', 'H', 0 },     5,      FG_BLACK | BG_GRAY, "HiDOS"  },
		{ { 5,	1 }, MEMORYROMSCAN,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_ROM, HELP_MEM_ROM,  P_MENU, TUTORIAL_Mem_ROM, { 'r', 'R', 0 },     8,      FG_BLACK | BG_GRAY, "ROM-Bild"  },
		{ { 6,	1 }, MEMORYINTERRUPTS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Int, HELP_MEM_INT,  P_MENU, TUTORIAL_Mem_Int, { 'i', 'I', 0 },    10,      FG_BLACK | BG_GRAY, "Interrupts"   },
		{ { 7,	1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,		  -1,		 -1,	 -1,		   { 0,     0, 0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 8,	1 }, MEMORYEXTENDED,	ITEM_ACTIVE,	{ 0, 0}, NULL, 3,  QUICK_Mem_Ext, HELP_MEM_EXT,  P_MENU, TUTORIAL_Mem_Ext, { 't', 'T', 0 },    11,      FG_BLACK | BG_GRAY, "ExT-Bereich"  },
		{ { 9,	1 }, MEMORYEXPANDED,	ITEM_ACTIVE,	{ 0, 0}, NULL, 3,  QUICK_Mem_Exp, HELP_MEM_EXP,  P_MENU, TUTORIAL_Mem_Exp, { 'p', 'P', 0 },    11,      FG_BLACK | BG_GRAY, "ExP-Bereich"  },
		{ { 10, 1 }, MEMORYEMS, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_EMS, HELP_MEM_EMS,  P_MENU, TUTORIAL_Mem_EMS, { 'e', 'E', 0 },    12,      FG_BLACK | BG_GRAY, "EMS-Belegung" },
		{ { 11, 1 }, MEMORYXMS, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_XMS, HELP_MEM_XMS,  P_MENU, TUTORIAL_Mem_XMS, { 'x', 'X', 0 },     3,      FG_BLACK | BG_GRAY, "XMS"    },
		{ { 12, 1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,		  -1,		 -1,	 -1,		   { 0,     0, 0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 13, 1 }, MEMORYTIMING,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Tim, HELP_MEM_TIME, P_MENU, TUTORIAL_Mem_Tim, { 'z', 'Z', 0 },    13,      FG_BLACK | BG_GRAY, "Zeitverhalten" },
	}
}
#else
= {
	{ NUMMEMORYMENUITEMS, MENU_VERTICAL, { 1, 6, 15, 17 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF	},
	{
		{ { 1,	1 }, MEMORYSUMMARY,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Sum, HELP_MEM_SUMM, P_MENU, TUTORIAL_Mem_Sum, { 's', 'S', 0 },     7,      FG_BLACK | BG_GRAY, "Summary"   },
		{ { 2,	1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,			 -1,	 -1,			   { 0, 	0, 0 }, 0,	FG_BLACK | BG_GRAY, ""  },
		{ { 3,	1 }, MEMORYLOWDOS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Low, HELP_MEM_LOW,  P_MENU, TUTORIAL_Mem_Low, { 'l', 'L', 0 },     7,      FG_BLACK | BG_GRAY, "Low DOS"   },
		{ { 4,	1 }, MEMORYHIGHDOS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Hi,  HELP_MEM_HIGH, P_MENU, TUTORIAL_Mem_Hi,  { 'h', 'H', 0 },     8,      FG_BLACK | BG_GRAY, "High DOS"  },
		{ { 5,	1 }, MEMORYROMSCAN,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_ROM, HELP_MEM_ROM,  P_MENU, TUTORIAL_Mem_ROM, { 'r', 'R', 0 },     8,      FG_BLACK | BG_GRAY, "ROM scan"  },
		{ { 6,	1 }, MEMORYINTERRUPTS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Int, HELP_MEM_INT,  P_MENU, TUTORIAL_Mem_Int, { 'i', 'I', 0 },     10, FG_BLACK | BG_GRAY, "Interrupts"    },
		{ { 7,	1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,			 -1,	 -1,			   { 0, 	0, 0 }, 0,	FG_BLACK | BG_GRAY, ""  },
		{ { 8,	1 }, MEMORYEXTENDED,	ITEM_ACTIVE,	{ 0, 0}, NULL, 3,  QUICK_Mem_Ext, HELP_MEM_EXT,  P_MENU, TUTORIAL_Mem_Ext, { 't', 'T', 0 },     8,      FG_BLACK | BG_GRAY, "Extended"  },
		{ { 9,	1 }, MEMORYEXPANDED,	ITEM_ACTIVE,	{ 0, 0}, NULL, 3,  QUICK_Mem_Exp, HELP_MEM_EXP,  P_MENU, TUTORIAL_Mem_Exp, { 'p', 'P', 0 },     8,      FG_BLACK | BG_GRAY, "Expanded"  },
		{ { 10, 1 }, MEMORYEMS, 		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_EMS, HELP_MEM_EMS,  P_MENU, TUTORIAL_Mem_EMS, { 'e', 'E', 0 },     3,      FG_BLACK | BG_GRAY, "EMS usage" },
		{ { 11, 1 }, MEMORYXMS, 		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_XMS, HELP_MEM_XMS,  P_MENU, TUTORIAL_Mem_XMS, { 'x', 'X', 0 },     3,      FG_BLACK | BG_GRAY, "XMS"       },
		{ { 12, 1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,			 -1,	 -1,			   { 0, 	0, 0 }, 0,	FG_BLACK | BG_GRAY, ""  },
		{ { 13, 1 }, MEMORYTIMING,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Mem_Tim, HELP_MEM_TIME, P_MENU, TUTORIAL_Mem_Tim, { 'a', 'A', 0 },     13,     FG_BLACK | BG_GRAY, "Access timing"     },
	}
}
#endif
#endif
;

enum {
	CSPOS,
		C_POS0,
	CCPOS,
	CAPOS,
	CPPOS,
	CEPPOS,
	CSIPOS,
		C_POS1,
	CQPOS,
	CWPOS,
		C_POS2,
	CMPOS,
		NUMCONFIGMENUITEMS
};

GLOBAL struct
{
	MENUINFO info;
	MENUITEM items[ NUMCONFIGMENUITEMS ];
} ConfigMenu
#ifdef GLINIT
#ifdef LANG_GR
= {
	{ NUMCONFIGMENUITEMS, MENU_VERTICAL, { 1, 14, 14, 20 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF	},
	{
		{ { 1,	1 }, CONFIGSUMMARY,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_Sum, HELP_CFG_SUMM,     P_MENU, TUTORIAL_Cfg_Sum,	    { 'g', 'G', 0 },        6,      FG_BLACK | BG_GRAY, "Gesamt"   },
		{ { 2,	1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,		  -1,		     -1,     -1,		    { 0,    0,	0 },	    0,	    FG_BLACK | BG_GRAY, ""  },
		{ { 3,	1 }, CONFIGSYS, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_CFG, HELP_CFG_CONFIG,   P_MENU, TUTORIAL_Cfg_Cfg,	    { 'c', 'C', 0 },        10,     FG_BLACK | BG_GRAY, "CONFIG.SYS"    },
		{ { 4,	1 }, CONFIGAUTOEXEC,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_AUT, HELP_CFG_AUTOEXEC, P_MENU, TUTORIAL_Cfg_Aut,	    { 'a', 'A', 0 },        12,     FG_BLACK | BG_GRAY, "AUTOEXEC.BAT"  },
		{ { 5,	1 }, CONFIGMAXPRO,	ITEM_ACTIVE,	{ 0, 0}, NULL, 5,  QUICK_Cfg_PRO, HELP_CFG_386MAX,   P_MENU, TUTORIAL_Cfg_Pro,	    { 'p', 'P', 0 },        10,     FG_BLACK | BG_GRAY, "MAX-PROfil"    },
		{ { 6,	1 }, CONFIGEXTRADOSPRO, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_EPRO, HELP_CFG_EXTRADOS,	 P_MENU, TUTORIAL_Cfg_EPro,	{ 'e', 'E', 0 },        16,     FG_BLACK | BG_GRAY, "ExtraDOS PROfile"       },
		{ { 7,	1 }, CONFIGSYSINI,		ITEM_ACTIVE,	{ 0, 0}, NULL, 8,  QUICK_Cfg_SYSINI, HELP_CFG_SYSINI,	 P_MENU, TUTORIAL_Cfg_SYSINI,	{ 'i', 'I', 0 },        10,     FG_BLACK | BG_GRAY, "SYSTEM.INI"       },
		{ { 8,	1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,				 -1,	 -1,				{ 0,	0,	0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 9,	1 }, CONFIGQUALITAS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_Qualitas, HELP_CFG_QUALITAS, P_MENU, TUTORIAL_Cfg_Qualitas,{ 'q', 'Q', 0 },         8,     FG_BLACK | BG_GRAY, "Qualitas"       },
		{ { 10, 1 }, CONFIGWINDOWS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_Windows, HELP_CFG_WINDOWS,  P_MENU, TUTORIAL_Cfg_Windows,	{ 'w', 'W', 0 },         7,     FG_BLACK | BG_GRAY, "Windows"       },
		{ { 11, 1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,		  -1,		     -1,     -1,		    { 0,    0,	0 },	    0,	    FG_BLACK | BG_GRAY, ""  },
		{ { 12, 1 }, CONFIGCMOS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 6,  QUICK_Cfg_CMO, HELP_HW_CMOS,      P_MENU, TUTORIAL_Cfg_CMO,	    { 'd', 'D', 0 },        11,     FG_BLACK | BG_GRAY, "CMOS-Detail"   },
	}
}
#else
= {
	{ NUMCONFIGMENUITEMS, MENU_VERTICAL, { 1, 14, 14, 16 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF	},
	{
		{ { 1,	1 }, CONFIGSUMMARY,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_Sum, HELP_CFG_SUMM,	 P_MENU, TUTORIAL_Cfg_Sum,	{ 's', 'S', 0 },        7,      FG_BLACK | BG_GRAY, "Summary"   },
		{ { 2,	1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,				 -1,	 -1,				{ 0,	0,	0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 3,	1 }, CONFIGSYS, 		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_CFG, HELP_CFG_CONFIG,	 P_MENU, TUTORIAL_Cfg_Cfg,	{ 'c', 'C', 0 },        10,     FG_BLACK | BG_GRAY, "CONFIG.SYS"        },
		{ { 4,	1 }, CONFIGAUTOEXEC,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_AUT, HELP_CFG_AUTOEXEC, P_MENU, TUTORIAL_Cfg_Aut,	{ 'a', 'A', 0 },        12,     FG_BLACK | BG_GRAY, "AUTOEXEC.BAT"      },
		{ { 5,	1 }, CONFIGMAXPRO,		ITEM_ACTIVE,	{ 0, 0}, NULL, 5,  QUICK_Cfg_PRO, HELP_CFG_386MAX,	 P_MENU, TUTORIAL_Cfg_Pro,	{ 'p', 'P', 0 },        11,     FG_BLACK | BG_GRAY, "MAX PROfile"       },
		{ { 6,	1 }, CONFIGEXTRADOSPRO, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_EPRO, HELP_CFG_EXTRADOS,	 P_MENU, TUTORIAL_Cfg_EPro,	{ 'e', 'E', 0 },        16,     FG_BLACK | BG_GRAY, "ExtraDOS PROfile"       },
		{ { 7,	1 }, CONFIGSYSINI,		ITEM_ACTIVE,	{ 0, 0}, NULL, 8,  QUICK_Cfg_SYSINI, HELP_CFG_SYSINI,	 P_MENU, TUTORIAL_Cfg_SYSINI,	{ 'i', 'I', 0 },        10,     FG_BLACK | BG_GRAY, "SYSTEM.INI"       },
		{ { 8,	1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,				 -1,	 -1,				{ 0,	0,	0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 9,	1 }, CONFIGQUALITAS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_Qualitas, HELP_CFG_QUALITAS, P_MENU, TUTORIAL_Cfg_Qualitas,{ 'q', 'Q', 0 },         8,     FG_BLACK | BG_GRAY, "Qualitas"       },
		{ { 10, 1 }, CONFIGWINDOWS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Cfg_Windows, HELP_CFG_WINDOWS,  P_MENU, TUTORIAL_Cfg_Windows,	{ 'w', 'W', 0 },         7,     FG_BLACK | BG_GRAY, "Windows"       },
		{ { 11, 1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,				 -1,	 -1,				{ 0,	0,	0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 12, 1 }, CONFIGCMOS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 2,  QUICK_Cfg_CMO, HELP_HW_CMOS, 	 P_MENU, TUTORIAL_Cfg_CMO,	{ 'm', 'M', 0 },        11,     FG_BLACK | BG_GRAY, "CMOS detail"       },
	}
}
#endif
#endif
;

enum {
	HSPOS,
		H_POS0,
	HVPOS,
	HDPOS,
	HPPOS,
		H_POS1,
	HBPOS,
		NUMHARDMENUITEMS
};

GLOBAL struct
{
	MENUINFO info;
	MENUITEM items[ NUMHARDMENUITEMS ];
} HardMenu
#ifdef GLINIT
#ifdef LANG_GR
= {
	{ NUMHARDMENUITEMS, MENU_VERTICAL, { 1, 22, 9, 15 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF },
	{
		{ { 1,	1 }, HARDSUMMARY,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_Sum, HELP_HW_SUMM,   P_MENU, TUTORIAL_Hdw_Sum, { 'g', 'G', 0 },    6,      FG_BLACK | BG_GRAY, "Gesamt"  },
		{ { 2,	1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,		  -1,		  -1,	  -1,		    { 0,    0,	0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 3,	1 }, HARDVIDEO, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_Vid, HELP_HW_VIDEO,  P_MENU, TUTORIAL_Hdw_Vid, { 'v', 'V', 0 },    5,      FG_BLACK | BG_GRAY, "Video"   },
		{ { 4,	1 }, HARDDRIVES,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_Drv, HELP_HW_DRIVES, P_MENU, TUTORIAL_Hdw_Drv, { 'l', 'L', 0 },    9,      FG_BLACK | BG_GRAY, "Laufwerke"   },
		{ { 5,	1 }, HARDPORTS, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_Por, HELP_HW_PORTS,  P_MENU, TUTORIAL_Hdw_Por, { 'p', 'P', 0 },    5,      FG_BLACK | BG_GRAY, "Ports"   },
		{ { 6,	1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,		  -1,		  -1,	  -1,		    { 0,    0,	0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 7,	1 }, HARDBIOS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_BIO, HELP_HW_BIOS,   P_MENU, TUTORIAL_Hdw_BIO, { 'b', 'B', 0 },    11,     FG_BLACK | BG_GRAY, "BIOS-Detail" },
	}
}
#else
= {
	{ NUMHARDMENUITEMS, MENU_VERTICAL, { 1, 22, 9, 15 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF },
	{
		{ { 1,	1 }, HARDSUMMARY,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_Sum, HELP_HW_SUMM,   P_MENU, TUTORIAL_Hdw_Sum,	{ 's', 'S', 0 },        7,      FG_BLACK | BG_GRAY, "Summary"   },
		{ { 2,	1 }, 0, 			ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,			  -1,	  -1,				{ 0,		0, 0 }, 0,	FG_BLACK | BG_GRAY, ""  },
		{ { 3,	1 }, HARDVIDEO, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_Vid, HELP_HW_VIDEO,  P_MENU, TUTORIAL_Hdw_Vid,	{ 'v', 'V', 0 },        5,      FG_BLACK | BG_GRAY, "Video"     },
		{ { 4,	1 }, HARDDRIVES,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_Drv, HELP_HW_DRIVES, P_MENU, TUTORIAL_Hdw_Drv, { 'd', 'D', 0 },    6,      FG_BLACK | BG_GRAY, "Drives"    },
		{ { 5,	1 }, HARDPORTS, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_Por, HELP_HW_PORTS,  P_MENU, TUTORIAL_Hdw_Por, { 'p', 'P', 0 },    5,      FG_BLACK | BG_GRAY, "Ports"     },
		{ { 6,	1 }, 0, 			ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			  -1,			  -1,	  -1,				{ 0,		0, 0 }, 0,	FG_BLACK | BG_GRAY, ""  },
		{ { 7,	1 }, HARDBIOS,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Hdw_BIO, HELP_HW_BIOS,   P_MENU, TUTORIAL_Hdw_BIO, { 'b', 'B', 0 },    11,     FG_BLACK | BG_GRAY, "BIOS detail"       },
	}
}
#endif
#endif
;

enum {
	LAPOS,
	LQPOS,
		L_POS0,
	LTPOS,
		L_POS1,
		L_TPOS2,
	LMPOS,
	LOPOS,
	LEPOS,
	LCPOS,
	LIPOS,
		L_POS3,
	LGPOS,
		NUMLEARNMENUITEMS
};

GLOBAL struct
{
	MENUINFO info;
	MENUITEM items[ NUMLEARNMENUITEMS ];
} LearnMenu
#ifdef GLINIT
#ifdef LANG_GR
= {
	{ NUMLEARNMENUITEMS, MENU_VERTICAL, { 1, 33, 15, 16 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF	},
	{
		{ { 1,	1 }, MLEARNASQ, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 2,  QUICK_L_Abt_ASQ,	ASQHELPTUTOR, P_TUTOR, -1,	      { 'b', 'B', 0 },      8,      FG_BLACK | BG_GRAY, "Åber ASQ" },
		{ { 2,	1 }, MLEARNQUALITAS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Q,		ASQHELPTUTOR, P_TUTOR, -1,	      { 'q', 'Q', 0 },      8,      FG_BLACK | BG_GRAY, "Qualitas" },
		{ { 3,	1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			-1,	      -1,      -1,	      { 0,   0,   0 },	    0,	    FG_BLACK | BG_GRAY, ""  },
		{ { 4,	1 }, MLEARNTUNING,	ITEM_ACTIVE,	{ 0, 0}, NULL, 2,  QUICK_L_Tune,	ASQHELPTUTOR, P_TUTOR, -1,	      { 'u', 'U', 0 },      6,      FG_BLACK | BG_GRAY, "Tuning"   },
		{ { 5,	1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			-1,	      -1,      -1,	      { 0,   0,   0 },	    0,	    FG_BLACK | BG_GRAY, ""  },
		{ { 6,	1 }, 0, 		ITEM_INFO,	{ 0, 0}, NULL, -1, -1,-1, -1,	-1,					      { 0	    },	   11,	    FG_BLUE  | BG_GRAY, "-Lernhilfe-" },
		{ { 7,	1 }, MLEARNMEMORY,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Mem, 	ASQHELPTUTOR, P_TUTOR, LEARNMEMORY,   { 's', 'S', 0 },      8,      FG_BLACK | BG_GRAY, "Speicher" },
		{ { 8,	1 }, MLEARNCONFIG,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Cfg, 	ASQHELPTUTOR, P_TUTOR, LEARNCONFIG,   { 'k', 'K', 0 },      9,      FG_BLACK | BG_GRAY, "Konfig" },
		{ { 9,	1 }, MLEARNEQUIPMENT,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Hdw, 	ASQHELPTUTOR, P_TUTOR, LEARNEQUIPMENT,{ 'm', 'M', 0 },      8,      FG_BLACK | BG_GRAY, "Maschine" },
		{ { 10, 1 }, MLEARNCONTENTS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Contents,	ASQHELPTUTOR, P_TUTOR, LEARNCONTENTS, { 't', 'T', 0 },      6,      FG_BLACK | BG_GRAY, "Themen"   },
		{ { 11, 1 }, MLEARNINDEX,	ITEM_ACTIVE,	{ 0, 0}, NULL, 3,  QUICK_L_Index,	ASQHELPTUTOR, P_TUTOR, LEARNINDEX,    { 'i', 'I', 0 },     10,      FG_BLACK | BG_GRAY, "Stichworte"  },
		{ { 12, 1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,			-1,	      -1,      -1,	      { 0,    0,  0 },	    0,	    FG_BLACK | BG_GRAY, ""  },
		{ { 13, 1 }, MLEARNGLOSSARY,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Gloss,	ASQHELPGloss, P_GLOSS, -1,	      { 'g', 'G', 0 },      7,      FG_BLACK | BG_GRAY, "Glossar"  },
	}
}
#else
= {
	{ NUMLEARNMENUITEMS, MENU_VERTICAL, { 1, 33, 15, 14 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF	},
	{
		{ { 1,	1 }, MLEARNASQ, 		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Abt_ASQ, ASQHELPTUTOR, P_TUTOR, -1,			  { 'a', 'A', 0 },      9,      FG_BLACK | BG_GRAY, "About ASQ" },
		{ { 2,	1 }, MLEARNQUALITAS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Q,		ASQHELPTUTOR, P_TUTOR, -1,			  { 'q', 'Q', 0 },      8,      FG_BLACK | BG_GRAY, "Qualitas"  },
		{ { 3,	1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,				-1,			 -1,   -1,			  { 0,	 0,   0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 4,	1 }, MLEARNTUNING,		ITEM_ACTIVE,	{ 0, 0}, NULL, 2,  QUICK_L_Tune,	ASQHELPTUTOR, P_TUTOR, -1,			  { 'u', 'U', 0 },      6,      FG_BLACK | BG_GRAY, "Tuning"    },
		{ { 5,	1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,				-1,			 -1,   -1,			  { 0,	 0,   0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 6,	1 }, 0, ITEM_INFO,{ 0, 0}, NULL, -1, -1,-1, -1,   -1,  { 0			},	12, FG_BLUE  | BG_GRAY, "-Tutorial-"              },
		{ { 7,	1 }, MLEARNMEMORY,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Mem, 	ASQHELPTUTOR, P_TUTOR, LEARNMEMORY,   { 'm', 'M', 0 },  6,      FG_BLACK | BG_GRAY, "Memory"    },
		{ { 8,	1 }, MLEARNCONFIG,		ITEM_ACTIVE,	{ 0, 0}, NULL, 2,  QUICK_L_Cfg, 	ASQHELPTUTOR, P_TUTOR, LEARNCONFIG,   { 'o', 'O', 0 },  6, FG_BLACK | BG_GRAY, "Config" },
		{ { 9,	1 }, MLEARNEQUIPMENT,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Hdw, 	ASQHELPTUTOR, P_TUTOR, LEARNEQUIPMENT,{ 'e', 'E', 0 },  9,      FG_BLACK | BG_GRAY, "Equipment" },
		{ { 10, 1 }, MLEARNCONTENTS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Contents,ASQHELPTUTOR, P_TUTOR, LEARNCONTENTS, { 't', 'T', 0 },      8,      FG_BLACK | BG_GRAY, "Topics"    },
		{ { 11, 1 }, MLEARNINDEX,		ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Index,	ASQHELPTUTOR, P_TUTOR, LEARNINDEX,	  { 'i', 'I', 0 },      5,      FG_BLACK | BG_GRAY, "Index"     },
		{ { 12, 1 }, 0, 				ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,				-1,			 -1,   -1,			  { 0,	  0,  0 },	0,	FG_BLACK | BG_GRAY, ""  },
		{ { 13, 1 }, MLEARNGLOSSARY,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_L_Gloss,	ASQHELPGloss, P_GLOSS, -1,			  { 'g', 'G', 0 },      8,      FG_BLACK | BG_GRAY, "Glossary"  },
	}
}
#endif
#endif
;

enum {
	PCPOS,
	PIPOS,
		P_POS0,
		P_POS1,
	PHPOS,
	PMPOS,
	PDPOS,
	PPPOS,
	PTPOS,
		NUMASQHELPMENUITEMS
};

GLOBAL struct
{
	MENUINFO info;
	MENUITEM items[ NUMASQHELPMENUITEMS ];
} AsqHelpMenu
#ifdef GLINIT
#ifdef LANG_GR
= {
	{ NUMASQHELPMENUITEMS, MENU_VERTICAL, { 1, 38, 11, 15 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF },
	{
		{ { 1,	1 }, AHELPCONTENTS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPCONTENTS, P_HELP, -1, { 't', 'T' }, 6,  FG_BLACK | BG_GRAY, "Themen"     },
		{ { 2,	1 }, AHELPINDEX,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPINDEX,	P_HELP, -1, { 's', 'S' }, 10, FG_BLACK | BG_GRAY, "Stichworte" },
		{ { 3,	1 }, 0, 		ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,	       -1,		-1,	-1, { 0        }, 0,  FG_BLACK | BG_GRAY, ""           },
		{ { 4,	1 }, 0, 		ITEM_INFO,	{ 0, 0}, NULL, -1, -1,	       -1,		-1,	-1, { 0        }, 10, FG_BLUE  | BG_GRAY, "-Hilfe zu-" },
		{ { 5,	1 }, AHELPHELP, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPHELP,	P_HELP, -1, { 'h', 'H' }, 5,  FG_BLACK | BG_GRAY, "Hilfe"      },
		{ { 6,	1 }, AHELPMENUS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPMENUS,	P_HELP, -1, { 'm', 'M' }, 5,  FG_BLACK | BG_GRAY, "MenÅs"      },
		{ { 7,	1 }, AHELPDIALOGS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 3,  QUICK_Help, ASQHELPDIALOGS,	P_HELP, -1, { 'a', 'A' }, 7,  FG_BLACK | BG_GRAY, "Dialog"    },
		{ { 8,	1 }, AHELPPRINT,	ITEM_ACTIVE,	{ 0, 0}, NULL, 3,  QUICK_Help, ASQHELPPRINT,	P_HELP, -1, { 'u', 'U' }, 5,  FG_BLACK | BG_GRAY, "Druck"      },
		{ { 9,	1 }, AHELPTUTORIAL,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPTUTOR,	P_HELP, -1, { 'l', 'L' }, 6,  FG_BLACK | BG_GRAY, "Lernen"     },
	}
}
#else
= {
	{ NUMASQHELPMENUITEMS, MENU_VERTICAL, { 1, 40, 11, 13 }, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, CALLBACKF },
	{
		{ { 1,	1 }, AHELPCONTENTS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPCONTENTS, P_HELP, -1, { 't', 'T' }, 6, FG_BLACK | BG_GRAY, "Topics"       },
		{ { 2,	1 }, AHELPINDEX,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPINDEX,	P_HELP, -1, { 'i', 'I' }, 5, FG_BLACK | BG_GRAY, "Index"                },
		{ { 3,	1 }, 0, 			ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1,		   -1,				-1,	-1, { 0 },		  0, FG_BLACK | BG_GRAY, ""                     },
		{ { 4,	1 }, 0, 			ITEM_INFO,		{ 0, 0}, NULL, -1, -1,		   -1,				-1,	-1, { 0 },		  9, FG_BLUE  | BG_GRAY, "- Using -" },
		{ { 5,	1 }, AHELPHELP, 	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPHELP,	P_HELP, -1, { 'h', 'H' }, 4, FG_BLACK | BG_GRAY, "Help"         },
		{ { 6,	1 }, AHELPMENUS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPMENUS,	P_HELP, -1, { 'm', 'M' }, 5, FG_BLACK | BG_GRAY, "Menus"        },
		{ { 7,	1 }, AHELPDIALOGS,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPDIALOGS,	P_HELP, -1, { 'd', 'D' }, 7, FG_BLACK | BG_GRAY, "Dialogs"      },
		{ { 8,	1 }, AHELPPRINT,	ITEM_ACTIVE,	{ 0, 0}, NULL, 1,  QUICK_Help, ASQHELPPRINT,	P_HELP, -1, { 'p', 'P' }, 5, FG_BLACK | BG_GRAY, "Print"        },
		{ { 9,	1 }, AHELPTUTORIAL,	ITEM_ACTIVE,	{ 0, 0}, NULL, 2,  QUICK_Help, ASQHELPTUTOR,	P_HELP, -1, { 'u', 'U' }, 8, FG_BLACK | BG_GRAY, "Tutorial"     },
	}
}
#endif
#endif
;

enum {
	SNAPMENUPOS,
	MEMORYMENUPOS,
	CONFIGMENUPOS,
	HARDWAREMENUPOS,
	LEARNMENUPOS,
	HELPMENUPOS,
		NUMASQTOPMENUITEMS
};

GLOBAL struct
{
	MENUINFO info;
	MENUITEM items[ NUMASQTOPMENUITEMS ];
} AsqTopMenu
#ifdef GLINIT
#ifdef LANG_GR
= {
	{ NUMASQTOPMENUITEMS, MENU_BAR, { 0, 0, 1, 56}, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, MNCALLBACK },
	{
		{ { 0,	1 }, ASQFILEMENU,	ITEM_ACTIVE, { 0, 0}, (PMENU)&SnapMenu,    1, -1, -1, -1, -1, { 'd', 'D' },       5, FG_BLACK | BG_GRAY, "Datei"    },
		{ { 0,	8 }, ASQMEMORYMENU,	ITEM_ACTIVE, { 0, 0}, (PMENU)&MemoryMenu,  1, -1, -1, -1, -1, { 's', 'S' },       8, FG_BLACK | BG_GRAY, "Speicher" },
		{ { 0, 18 }, ASQCONFIGMENU,	ITEM_ACTIVE, { 0, 0}, (PMENU)&ConfigMenu,  1, -1, -1, -1, -1, { 'k', 'K' },       6, FG_BLACK | BG_GRAY, "Konfig"},
		{ { 0, 26 }, ASQHARDMENU,	ITEM_ACTIVE, { 0, 0}, (PMENU)&HardMenu,    1, -1, -1, -1, -1, { 'm', 'M' },       8, FG_BLACK | BG_GRAY, "Maschine" },
		{ { 0, 36 }, ASQLEARNMENU,	ITEM_ACTIVE, { 0, 0}, (PMENU)&LearnMenu,   1, -1, -1, -1, -1, { 'l', 'L' },       6, FG_BLACK | BG_GRAY, "Lernen"   },
		{ { 0, 44 }, ASQHELPMENU,	ITEM_ACTIVE, { 0, 0}, (PMENU)&AsqHelpMenu, 1, -1, -1, -1, -1, { 'h', 'H' },       5, FG_BLACK | BG_GRAY, "Hilfe"    }
	}
}
#else
= {
	{ NUMASQTOPMENUITEMS, MENU_BAR, { 0, 0, 1, 48}, 0, 0, 0, FG_BLACK | BG_GRAY, NULL, MNCALLBACK },
	{
		{ { 0,	1 }, ASQFILEMENU,		ITEM_ACTIVE, { 0, 0}, (PMENU)&SnapMenu,    1, -1, -1, -1, -1, { 'f', 'F' },       4, FG_BLACK | BG_GRAY, "File"          },
		{ { 0,	7 }, ASQMEMORYMENU,		ITEM_ACTIVE, { 0, 0}, (PMENU)&MemoryMenu,  1, -1, -1, -1, -1, { 'm', 'M' },       6, FG_BLACK | BG_GRAY, "Memory"        },
		{ { 0, 15 }, ASQCONFIGMENU,	ITEM_ACTIVE, { 0, 0}, (PMENU)&ConfigMenu,  1, -1, -1, -1, -1, { 'c', 'C' },       6, FG_BLACK | BG_GRAY, "Config"        },
		{ { 0, 23 }, ASQHARDMENU,		ITEM_ACTIVE, { 0, 0}, (PMENU)&HardMenu,    1, -1, -1, -1, -1, { 'e', 'E' },       9, FG_BLACK | BG_GRAY, "Equipment" },
		{ { 0, 34 }, ASQLEARNMENU,		ITEM_ACTIVE, { 0, 0}, (PMENU)&LearnMenu,   1, -1, -1, -1, -1, { 'l', 'L' },       5, FG_BLACK | BG_GRAY, "Learn"         },
		{ { 0, 41 }, ASQHELPMENU,		ITEM_ACTIVE, { 0, 0}, (PMENU)&AsqHelpMenu, 1, -1, -1, -1, -1, { 'h', 'H' },       4, FG_BLACK | BG_GRAY, "Help"          }
	}
}
#endif
#endif
;

extern char AsqName[];		/* Actual data in VERSDATA.ASM */

GLOBAL WINDESC AsqNameWin
#ifdef GLINIT
= { 0, 70, 1, 10 }
#endif
;

extern char *MsgLogoText[];

GLOBAL char *WhichLogo
#ifdef GLINIT
= "ASQ"
#endif /*GLINIT*/
;

/*	Now add in the default file names accessed from main */
GLOBAL char DefaultGrabFile[]
#ifdef GLINIT
= "MEMIMAGE.ASQ"
#endif
;

extern char HelpString[];

/*
*  Stuff relating to data on the screen
*  Any kind of information for data windows
*  These entries must correspond to the enum beginning with MEMORYSUMMARY
*/
GLOBAL DATAINFO DataInfo[]
#ifdef GLINIT
#ifdef LANG_GR
= {
	{ FALSE, "unbekannt"},
	{ FALSE, "Speicher-öbersicht" },
	{ FALSE, "LoDOS Speicher" },
	{ FALSE, "HiDOS Speicher" },
	{ FALSE, "Speicher-ROM-Plan" },
	{ TRUE,  "Speicher-Interrupts" },
	{ FALSE, "Extended Memory" },
	{ FALSE, "Expanded Memory" },
	{ FALSE, "Speicher-EMS-Belegung" },
	{ FALSE, "XMS Speicher" },
	{ TRUE,  "Speicher-Geschwindigkeit" },
	{ FALSE, "Konfigurations-öberblick" },
	{ FALSE, "CONFIG.SYS-Datei" },
	{ FALSE, "AUTOEXEC.BAT-Datei" },
	{ FALSE, "386MAX.PRO-Datei" },
	{ FALSE, "ExtraDOS.PRO-Datei"},
	{ FALSE, "SYSTEM.INI-Datei"},
	{ FALSE, "Qualitas Info"},
	{ FALSE, "Windows Info"},
	{ FALSE, "Maschine: öbersicht" },
	{ FALSE, "Maschine: Video" },
	{ FALSE, "Maschine: Laufwerke" },
	{ FALSE, "Maschine: Ports" },
	{ FALSE, "Maschine: BIOS-Detail" },
	{ TRUE,  "Konfiguration CMOS-Detail" },
	{ FALSE, "Snapshot-Information" }
}
#else
= {
	{ FALSE, "Unknown"},
	{ FALSE, "Memory Summary" },            /* 1 */
	{ FALSE, "Memory Low DOS" },
	{ FALSE, "Memory High DOS" },
	{ FALSE, "Memory ROM Scan" },
	{ TRUE,  "Memory Interrupts" },
	{ FALSE, "Memory Extended" },
	{ FALSE, "Memory Expanded" },
	{ FALSE, "Memory EMS Usage" },
	{ FALSE, "Memory XMS" },
	{ TRUE,  "Memory Access Timing" },
	{ FALSE, "Configuration Summary" },     /* 11 */
	{ FALSE, "CONFIG.SYS File" },
	{ FALSE, "AUTOEXEC.BAT File" },
	{ FALSE, "386MAX.PRO File" },
	{ FALSE, "ExtraDOS.PRO File"},
	{ FALSE, "SYSTEM.INI File"},
	{ FALSE, "Qualitas Info"},
	{ FALSE, "Windows Info"},
	{ FALSE, "Equipment Summary" },         /* 19 */
	{ FALSE, "Equipment Video" },
	{ FALSE, "Equipment Drives" },
	{ FALSE, "Equipment Ports" },
	{ FALSE, "Equipment BIOS Detail" },
	{ TRUE,  "Configuration CMOS Detail" }, /* 24 */
	{ FALSE, "Snapshot Information" }       /* 25 */
}
#endif
#endif
;


/*
*	All the stuff relating to error messages or printer messages
*/

#ifdef LANG_GR
#define ERROR " Fehler "
#define MESSAGE " Meldung "
#define PRINTING "Drucke Seite %d..."
#else
#define ERROR " Error "
#define MESSAGE " Message "
#define PRINTING "Printing page %d..."
#endif
GLOBAL char Error[ sizeof( ERROR )]
#ifdef GLINIT
= ERROR
#endif
;

GLOBAL char Message[ sizeof( MESSAGE )]
#ifdef GLINIT
= MESSAGE
#endif
;

GLOBAL char Printing[ sizeof( PRINTING )]
#ifdef GLINIT
= PRINTING
#endif
;

typedef enum { PRINTTYPEANALYSIS,
			   PRINTTYPEHELP,
			   PRINTTYPETUTORIAL,
			   PRINTTYPEFILE,
			   PRINTTYPEGLOSSARY,
			   PRINTTYPENONE } PRINTTITLETYPE;
GLOBAL char *PRINTTYPETEXT[PRINTTYPENONE]
#ifdef GLINIT
#ifdef LANG_GR
=
{
	"ANALYSE",
	"HILFE",
	"LERNHILFE",
	"DATEI",
	"GLOSSAR"
}
#else
=
{
	"ANALYSIS",
	"HELP",
	"TUTORIAL",
	"FILE",
	"GLOSSARY"
}
#endif
#endif
;

#ifdef LANG_GR
#define PRINTPAGETITLE " von Qualitas"
#else
#define PRINTPAGETITLE " by Qualitas"
#endif
GLOBAL char PrintPageTitle[ sizeof( PRINTPAGETITLE )]
#ifdef GLINIT
= PRINTPAGETITLE
#endif
;

GLOBAL char PrintPage[]
#ifdef GLINIT
#ifdef LANG_GR
= "Seite: %d"
#else
= "page: %d"
#endif
#endif
;

#ifdef LANG_GR
#define FILEPROMPT "Datei: "
#else
#define FILEPROMPT "File: "
#endif
GLOBAL char FilePrompt[sizeof( FILEPROMPT )]
#ifdef GLINIT
= FILEPROMPT
#endif
;

#ifdef LANG_GR
#define ARROWS "Pfeiltasten"
#define ENTER "<ƒŸ"
#else
#define ARROWS "Arrows"
#define ENTER "Enter"
#endif
GLOBAL char Arrows[sizeof(ARROWS)]
#ifdef GLINIT
= ARROWS
#endif
;


GLOBAL char Enter[ sizeof( ENTER )]
#ifdef GLINIT
= ENTER
#endif
;

#define NUMPRINTINGBUTTONS 1
GLOBAL BUTTON PrintingButtons[ NUMPRINTINGBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { 15, 34 }, 12, "Abbruch",  { KEY_ESCAPE, 'a', 'A', KEY_ALTA }, KEY_ESCAPE, TRUE,  TRUE,  0, 1, FG_BLUE     | BG_GRAY, FALSE },
}
#else
= {
   { { 15, 34 }, 12, "Cancel",  { KEY_ESCAPE, 'c', 'C', KEY_ALTC }, KEY_ESCAPE, TRUE,  TRUE,  0, 1, FG_BLUE     | BG_GRAY, FALSE },
}
#endif
#endif
;



/*
*	Stuff for snapshots
*/
#define DEFAULTSNAPSHOT "SNAPSHOT.ASQ"
GLOBAL char DefaultSnapShot[ sizeof( DEFAULTSNAPSHOT )]
#ifdef GLINIT
= DEFAULTSNAPSHOT
#endif
;

#ifdef LANG_GR
#define SAVETITLE " SnapShot speichern "
#else
#define SAVETITLE " SnapShot Save "
#endif
GLOBAL char SaveTitle[ sizeof( SAVETITLE )]
#ifdef GLINIT
= SAVETITLE
#endif
;

#define SNAPSEARCHSPEC "*.ASQ"
GLOBAL char SnapSearchSpec[ sizeof( SNAPSEARCHSPEC )]
#ifdef GLINIT
= SNAPSEARCHSPEC
#endif
;

#define SNAPINPARENS "(Snapshot)"
GLOBAL char SnapInParens[ sizeof( SNAPINPARENS )]
#ifdef GLINIT
= SNAPINPARENS
#endif
;



#define SNAPDIRKEY KEY_ALTD
#ifdef LANG_GR
#define SNAPDIR "Verzeichnis- und Datei-Angabe"
#else
#define SNAPDIR "Directory and File Specification"
#endif
#define SNAPDIRTRIGGER 0
GLOBAL char SnapDir[ sizeof( SNAPDIR )]
#ifdef GLINIT
= SNAPDIR
#endif
;

#define SNAPDESCKEY KEY_ALTS
#ifdef LANG_GR
#define SNAPDESC "Snapshot-Dateibeschreibung"
#else
#define SNAPDESC "Snapshot File Description"
#endif
#define SNAPDESCTRIGGER 0
GLOBAL char SnapDesc[ sizeof( SNAPDESC )]
#ifdef GLINIT
= SNAPDESC
#endif
;

#define NUMSNAPBUTTONS 4
GLOBAL BUTTON SnapButtons[ NUMSNAPBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { -1, 15 }, 11, "Hilfe F1", { KEY_F1,      0,   0,  0        }, KEY_F1,     FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Druck F2", { KEY_F2,      0,   0,  0        }, KEY_F2,     FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 15, 26 }, 12, "Fertig",   { KEY_ENTER,  'f', 'F', KEY_ALTF }, KEY_ENTER,  TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 15, 40 }, 12, "Abbruch",  { KEY_ESCAPE, 'a', 'A', KEY_ALTA }, KEY_ESCAPE, FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#else
= {
   { { -1, 15 }, 11, "Help F1",         { KEY_F1,         0, 0, 0 }, KEY_F1,            FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Print F2",        { KEY_F2,         0, 0, 0 }, KEY_F2,            FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 15, 26 }, 12, "OK",        { KEY_ENTER,  'o', 'O', KEY_ALTO }, KEY_ENTER,          TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 15, 40 }, 12, "Cancel",  { KEY_ESCAPE, 'c', 'C', KEY_ALTC }, KEY_ESCAPE, FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#endif
#endif
;

GLOBAL BUTTON SnapLoadButton
#ifdef GLINIT
#ifdef LANG_GR
= { { -3, 15	}, 11, "Beschr. F6",      { KEY_F6,         0, 0, 0 }, KEY_F6,            FALSE,  FALSE,  8, 2, FG_BLUE | BG_GRAY, TRUE }
#else
= { { -3, 15	}, 11, "Descr F6",      { KEY_F6,         0, 0, 0 }, KEY_F6,            FALSE,  FALSE,  6, 2, FG_BLUE | BG_GRAY, TRUE }
#endif
#endif
;

GLOBAL MENUINFO SnapFileMenuInfo
#ifdef GLINIT
= { 0, MENU_VERTICAL, { 2, 14 , 2, 17}, 1, 0, 0, FG_BLACK | BG_GRAY, NULL, NULL }
#endif
;

#define SNAPFILEOTHER 256
GLOBAL MENUITEM SnapMenuItems[3]
#ifdef GLINIT
= {
		{ { 0, 1 }, 0,			  ITEM_ACTIVE,	  { 0, 0}, NULL, -1, -1, ASQHELPSnp_Load, P_HELP, -1, { 0,	 0,   0 },	0,	FG_BLACK | BG_GRAY, ""                          },
		{ { 0, 1 }, 0,			  ITEM_SEPARATOR, { 0, 0}, NULL, -1, -1, -1,			  -1,	  -1, { 0,	 0,	  0 },	0,	FG_BLACK | BG_GRAY, ""                          },
#ifdef LANG_GR
		{ { 0, 1 }, SNAPFILEOTHER,ITEM_ACTIVE,	  { 0, 0}, NULL, -1, -1, ASQHELPSnp_Load, P_HELP, -1, { 0,    0, 0 }, 12,      FG_BLACK | BG_GRAY, "andere Datei"              }
#else
		{ { 0, 1 }, SNAPFILEOTHER,ITEM_ACTIVE,	  { 0, 0}, NULL, -1, -1, ASQHELPSnp_Load, P_HELP, -1, {   0,	0, 0 }, 13,	FG_BLACK | BG_GRAY, "Other file..."     }
#endif
}
#endif
;

#ifdef LANG_GR
#define NONETEXT "kein(e)"
#define SNAPDESCCOLON "Snapshot-Datei-Beschreibung: "
#else
#define NONETEXT "None"
#define SNAPDESCCOLON "Snapshot File Description: "
#endif
GLOBAL char NoneText[ sizeof( NONETEXT )]
#ifdef GLINIT
= NONETEXT
#endif
;

GLOBAL char SnapDescColon[ sizeof( SNAPDESCCOLON )]
#ifdef GLINIT
= SNAPDESCCOLON
#endif
;

GLOBAL char *UtilDataError
#ifdef GLINIT
#ifdef LANG_GR
= "386UTIL-Daten nicht verfÅgbar."
#else
= "386UTIL data not available."
#endif
#endif
;

GLOBAL char *AsqDataError
#ifdef GLINIT
#ifdef LANG_GR
= "ASQ-Daten nicht verfÅgbar."
#else
= "ASQ data not available."
#endif
#endif
;

#ifdef LANG_GR
#define UPDATEDISKTITLE " Update "
#define UPDATEDISKTEXT	"Geben Sie Laufwerk/Pfad fÅr das UPDATE-Programm ein:"
#define ADFSPECTITLE " Aktion "
#else
#define UPDATEDISKTITLE " Update "
#define UPDATEDISKTEXT	"Enter the drive and/or path for the Update program:"
#define ADFSPECTITLE " Action "
#endif

#define ADFSPECNCOLS	64

GLOBAL char *AdfSpecText
#ifdef GLINIT
#ifdef LANG_GR
 =	"Geben Sie Laufwerk/Pfad fÅr die Adapter-Beschreibungs-\n"
	"Dateien (ADF) ein, die Sie normalerweise auf der Referenz-\n"
	"Diskette finden. (Wenn Sie diesen Schritt Åbergehen, wird\n"
	"die Maschinen-GesamtÅbersicht unvollstÑndig dargestellt): "
#else
 =	"Enter the drive and/or path for the Adapter Description\n"
	"(ADF) Files, normally found on the Reference Diskette\n"
	"(bypassing this step will cause Equipment Summary\n"
	"information to be incomplete): "
#endif
#endif
;

#ifdef LANG_GR
#define EVALFMT "bewerte %s\n"
#else
#define EVALFMT "Evaluating %s\n"
#endif
GLOBAL char EvalFmt[sizeof(EVALFMT)]
#ifdef GLINIT
= EVALFMT
#endif
;

GLOBAL char * EvalText[EVAL_TOOBIG]
#ifdef GLINIT
#ifdef LANG_GR
//#error xlat Plug and Play
=
{
	"",                     /* EVAL_NONE            */
	"CPU-Typ",              /* EVAL_CPUTYPE         */
	"CPU-Takt",             /* EVAL_CPUCLOCK        */
	"Maus",                 /* EVAL_MOUSE           */
	"Game-Port",            /* EVAL_GAME            */
	"Tastatur",             /* EVAL_KEYBOARD        */
	"BIOS-ID",              /* EVAL_BIOS            */
	"BIOS-Signatur",        /* EVAL_BIOSMFR         */
	"DOS-Informationen",    /* EVAL_DOSLIST         */
	"Karten-ROM",           /* EVAL_ROMS            */
	"Maschinen-ID",         /* EVAL_MACHID          */
	"POS-Daten",            /* EVAL_POS             */
	"ASQ-Profil",           /* EVAL_ASQPROF         */
	"CMOS",                 /* EVAL_CMOS            */
	"XMS",                  /* EVAL_XMS             */
	"EMS",                  /* EVAL_EMS             */
	"EMS/XMS dynamisch",    /* EVAL_EMSXMS          */
	"Disk-Laufwerke",       /* EVAL_DISK            */
	"Disk-Cache",           /* EVAL_CACHE           */
	"DOS",                  /* EVAL_DOS             */
	"DOS-Interna",          /* EVAL_DOSINT          */
	"Einheiten-Treiber",    /* EVAL_DEVDRV          */
	"offene Dateien",       /* EVAL_OPENFILES       */
	"Basis-Hauptspeicher",  /* EVAL_BASEMEM         */
	"LoDOS-Speicher",       /* EVAL_LOWDOS          */
	"HiDOS (MAX)",          /* EVAL_HIGHDOS1        */
	"Flex-ROM",             /* EVAL_FLEXROM         */
	"HiDOS (MOVE'EM)",      /* EVAL_HIGHDOS2        */
	"HiDOS-Speicher",       /* EVAL_HIGHDOS3        */
	"Disk-ROM",             /* EVAL_DISKROM         */
	"Video-ROM",            /* EVAL_VIDROM          */
	"BIOS-CRC",             /* EVAL_CRC             */
	"CPU (SX)",             /* EVAL_CPUSX           */
	"DOS-Umgebung",         /* EVAL_ENVIRON         */
	"Chipsatz",             /* EVAL_CHIPSET         */
	"Speicher-Zeitverhalten", /* EVAL_TIME          */
	"DOS-Daten",            /* EVAL_DOSDATA         */
	"Speicher-Plan",        /* EVAL_MAP             */
	"CONFIG.SYS",           /* EVAL_CONFIG          */
	"AUTOEXEC.BAT",         /* EVAL_AUTOEXEC        */
	"MAX PROfil",           /* EVAL_MAXPRO          */
	"ExtraDOS PROfil",      /* EVAL_EXTRADOS        */
	"SYSTEM.INI",           /* EVAL_SYSINI          */
	"Windows",              /* EVAL_WINDOWS         */
	"Qualitas info",        /* EVAL_QUALITAS        */
	"Mikrokanal",           /* EVAL_MCA             */
	".ADF-Dateien",         /* EVAL_ADF             */
//#error Translation?
	"Plug and Play",	/* EVAL_PNP		*/
	"CD-ROM",		/* EVAL_CDROM		*/
	""                      /* EVAL_DONE            */
}
#else
=
{
	"",                     /* EVAL_NONE            */
	"CPU type",             /* EVAL_CPUTYPE         */
	"CPU clock",            /* EVAL_CPUCLOCK        */
	"Mouse",                /* EVAL_MOUSE           */
	"Game port",            /* EVAL_GAME            */
	"Keyboard",             /* EVAL_KEYBOARD        */
	"BIOS ID",              /* EVAL_BIOS            */
	"BIOS signature",       /* EVAL_BIOSMFR         */
	"DOS lists",            /* EVAL_DOSLIST         */
	"On-card ROM",          /* EVAL_ROMS            */
	"Machine id",           /* EVAL_MACHID          */
	"POS data",             /* EVAL_POS             */
	"ASQ profile",          /* EVAL_ASQPROF         */
	"CMOS",                 /* EVAL_CMOS            */
	"XMS",                  /* EVAL_XMS             */
	"EMS",                  /* EVAL_EMS             */
	"EMS/XMS sharing",      /* EVAL_EMSXMS          */
	"Disk drives",          /* EVAL_DISK            */
	"Disk cache",           /* EVAL_CACHE           */
	"DOS",                  /* EVAL_DOS             */
	"DOS internals",        /* EVAL_DOSINT          */
	"Device drivers",       /* EVAL_DEVDRV          */
	"Open files",           /* EVAL_OPENFILES       */
	"Base memory",          /* EVAL_BASEMEM         */
	"Low DOS memory",       /* EVAL_LOWDOS          */
	"High DOS (MAX)",       /* EVAL_HIGHDOS1        */
	"Flexed ROM",           /* EVAL_FLEXROM         */
	"High DOS (MOVE'EM)",   /* EVAL_HIGHDOS2        */
	"High DOS memory",      /* EVAL_HIGHDOS3        */
	"Disk ROM",             /* EVAL_DISKROM         */
	"Video ROM",            /* EVAL_VIDROM          */
	"BIOS CRC",             /* EVAL_CRC             */
	"CPU (sx)",             /* EVAL_CPUSX           */
	"DOS environment",      /* EVAL_ENVIRON         */
	"Chipset",              /* EVAL_CHIPSET         */
	"Memory timing",        /* EVAL_TIME            */
	"DOS data",             /* EVAL_DOSDATA         */
	"Memory map",           /* EVAL_MAP             */
	"CONFIG.SYS",           /* EVAL_CONFIG          */
	"AUTOEXEC.BAT",         /* EVAL_AUTOEXEC        */
	"MAX PROfile",          /* EVAL_MAXPRO          */
	"ExtraDOS PROfile",     /* EVAL_EXTRADOS        */
	"SYSTEM.INI",           /* EVAL_SYSINI          */
	"Windows",              /* EVAL_WINDOWS         */
	"Qualitas info",        /* EVAL_QUALITAS        */
	"MicroChannel",         /* EVAL_MCA             */
	".ADF files",           /* EVAL_ADF             */
	"Plug and Play",	/* EVAL_PNP		*/
	"CD-ROM",		/* EVAL_CDROM		*/
	""                      /* EVAL_DONE            */
}
#endif
#endif
;




#ifdef LANG_GR
#define LOADING "lade Snapshot..."
#define HARDWARE "Hardware"
#define WRITESNAP "schreibe Snapshot"
#else
#define LOADING "Loading Snapshot..."
#define HARDWARE "Hardware"
#define WRITESNAP "Writing Snapshot"
#endif
GLOBAL char Loading[sizeof(LOADING)]
#ifdef GLINIT
= LOADING
#endif
;

GLOBAL char Hardware[sizeof(HARDWARE)]
#ifdef GLINIT
= HARDWARE
#endif
;


GLOBAL char WriteSnap[sizeof(WRITESNAP)]
#ifdef GLINIT
= WRITESNAP
#endif
;

GLOBAL int HelpArgNum[16];	/* Shared by ahelp.c and asqprint.c */
				/* Used in processing multiple help contexts */

GLOBAL char *SnapMallocErr
#ifdef GLINIT
#ifdef LANG_GR
= "Kein Speicherplatz fÅr Zwischenpuffer vorhanden\n"
#else
= "No memory for scratch buffer\n"
#endif
#endif
;

GLOBAL char *SnapSysinfoErr
#ifdef GLINIT
#ifdef LANG_GR
= "SysInfo-Init-Fehler\n"
#else
= "SysInfo init error\n"
#endif
#endif
;

GLOBAL char *SnapWriteErr
#ifdef GLINIT
#ifdef LANG_GR
= "Fehler beim Schreiben der SysInfo\n"
#else
= "SysInfo write error\n"
#endif
#endif
;

GLOBAL char *SnapWriting
#ifdef GLINIT
#ifdef LANG_GR
= "schreibe Snapshot auf %s\n"
#else
= "Writing snapshot to %s\n"
#endif
#endif
;

GLOBAL char *SnapADFQuery
#ifdef GLINIT
#ifdef LANG_GR
= "Wollen Sie diesen Schritt Åbergehen (j/n)?  "
#else
= "Do you want to bypass this step (y/n)?  "
#endif
#endif
;

GLOBAL char *SnapADFDefault
#ifdef GLINIT
#ifdef LANG_GR
= "\nvoreingestellt ist %s\n"
#else
= "\nDefault is %s\n"
#endif
#endif
;

#ifdef LANG_GR
#define MSG_FILENAME	"[dateiname]"
#else
#define MSG_FILENAME	"[filename]"
#endif

#ifdef ASQ_C
/* These are the retrogressive and progressive state transitions */
/* for the walking through the info screens using prev/next page. */
/* Each entry is indexed by an entry between MEMORYSUMMARY and */
/* SNAPINFO inclusive, and points to the appropriate node. */
	static altPgUp[] = {
	/*	?	*/	0,			/* Invalid request */
	/* MEMORYSUMMARY */	SNAPINFO,
	/* MEMORYLOWDOS */	MEMORYSUMMARY,
	/* MEMORYHIGHDOS */	MEMORYLOWDOS,
	/* MEMORYROMSCAN */	MEMORYHIGHDOS,
	/* MEMORYINTERRUPTS */	MEMORYROMSCAN,
	/* MEMORYEXTENDED */	MEMORYINTERRUPTS,
	/* MEMORYEXPANDED */	MEMORYEXTENDED,
	/* MEMORYEMS	*/	MEMORYEXPANDED,
	/* MEMORYXMS	*/	MEMORYEMS,
	/* MEMORYTIMING */	MEMORYXMS,
	/* CONFIGSUMMARY */	MEMORYTIMING,
	/* CONFIGSYS	*/	CONFIGSUMMARY,
	/* CONFIGAUTOEXEC */	CONFIGSYS,
	/* CONFIGMAXPRO */	CONFIGAUTOEXEC,
	/* CONFIGEXTRADOSPRO */ CONFIGMAXPRO,
	/* CONFIGSYSINI */	CONFIGEXTRADOSPRO,
	/* CONFIGQUALITAS */	CONFIGSYSINI,
	/* CONFIGWINDOWS */	CONFIGQUALITAS,
	/* HARDSUMMARY */	CONFIGCMOS,
	/* HARDVIDEO	*/	HARDSUMMARY,
	/* HARDDRIVES	*/	HARDVIDEO,
	/* HARDPORTS	*/	HARDDRIVES,
	/* HARDBIOS	*/	HARDPORTS,
	/* CONFIGCMOS	*/	CONFIGEXTRADOSPRO,
	/* SNAPINFO	*/	HARDBIOS,
	};

	static altPgDn[] = {
	/*	?	*/	0,			/* Invalid request */
	/* MEMORYSUMMARY */	MEMORYLOWDOS,
	/* MEMORYLOWDOS */	MEMORYHIGHDOS,
	/* MEMORYHIGHDOS */	MEMORYROMSCAN,
	/* MEMORYROMSCAN */	MEMORYINTERRUPTS,
	/* MEMORYINTERRUPTS */	MEMORYEXTENDED,
	/* MEMORYEXTENDED */	MEMORYEXPANDED,
	/* MEMORYEXPANDED */	MEMORYEMS,
	/* MEMORYEMS	*/	MEMORYXMS,
	/* MEMORYXMS	*/	MEMORYTIMING,
	/* MEMORYTIMING */	CONFIGSUMMARY,
	/* CONFIGSUMMARY */	CONFIGSYS,
	/* CONFIGSYS	*/	CONFIGAUTOEXEC,
	/* CONFIGAUTOEXEC */	CONFIGMAXPRO,
	/* CONFIGMAXPRO */	CONFIGEXTRADOSPRO,
	/* CONFIGEXTRADOSPRO */ CONFIGSYSINI,
	/* CONFIGSYSINI */	CONFIGQUALITAS,
	/* CONFIGQUALITAS */	CONFIGWINDOWS,
	/* CONFIGWINDOWS */	CONFIGCMOS,
	/* HARDSUMMARY */	HARDVIDEO,
	/* HARDVIDEO	*/	HARDDRIVES,
	/* HARDDRIVES	*/	HARDPORTS,
	/* HARDPORTS	*/	HARDBIOS,
	/* HARDBIOS	*/	SNAPINFO,
	/* CONFIGCMOS	*/	HARDSUMMARY,
	/* SNAPINFO	*/	MEMORYSUMMARY,
	};

#endif	/* ASQ_C defined */

#endif	/*TEXT_INCLUDED*/
