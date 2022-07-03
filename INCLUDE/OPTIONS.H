/*' $Header:   P:/PVCS/MAX/INCLUDE/OPTIONS.H_V   1.1   02 Jun 1997 14:37:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * OPTIONS.H								      *
 *									      *
 * Data for option editor						      *
 *									      *
 ******************************************************************************/

/* transferred to GERMAN 24-03-1992 by Herbert Reibe c/o Klaus Albrecht */

#ifndef OPTIONS_INCLUDED

#define OPTIONS_INCLUDED

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


#include <commdef.h>
#include <qwindows.h>

#ifndef BUTTON_INCLUDED
#include <button.h>
#endif

/* Prototype functions in option.c */
int   option_replace( PTEXTWIN pText, char  *p, int   row);
int option_insert( PTEXTWIN pText, char *p, int *CurrentLine, char *line[], int *lines);
char *option_editor( PTEXTWIN pText, int row, int *replace, int help, int tutor);

/* Define structure for option list */
typedef struct _optlist {
 char *option;		/* Actual option (BCF) */
 char *usage;		/* Usage example (BCF=d:\path\filename.ext) */
 BYTE flags;		/* Who uses it */
} OPTLIST;

/* Define bits for flags byte */
#define OLF_386MAX	0x01				/* 386MAX only */
/* (Currently, nothing is defined as 386MAX only, not BlueMAX) */
#define OLF_BLUEMAX	0x02				/* BlueMAX only */
#define OLF_MOVE	0x04				/* Move'em only */
#define OLF_ALL 	0xff				/* Up for grabs */
#define OLF_MAX 	(OLF_386MAX|OLF_BLUEMAX)	/* 386MAX or BlueMAX */

GLOBAL BYTE optsActive
#ifdef GLINIT
= OLF_ALL
#endif
;

GLOBAL OPTLIST optionList[]
#ifdef GLINIT
= {
{"AMRS",        "AMRS=n",               OLF_MAX},
{"AUTO",        "AUTO",                 OLF_MAX},
{"AUTOBCF",     "AUTOBCF",              OLF_BLUEMAX},

#ifdef LANG_GR
{"BCF",         "BCF=laufw:\\pfad\\dateiname.bcf",
#else
{"BCF",         "BCF=drive:\\path\\filename.bcf",
#endif
					OLF_BLUEMAX},

{"CGA",         "CGA",                  OLF_MAX},

{"DMA",         "DMA=n",                OLF_MAX},
{"DOS4",        "DOS4",                 OLF_MAX},

{"EGA",         "EGA",                  OLF_MAX},
{"EMS",         "EMS",                  OLF_MOVE},
{"EMS=",        "EMS=n",                OLF_MAX},
{"EXCLUDE",     "EXCLUDE=xxxx-yyyy",    OLF_MAX},
{"EXT",         "EXT=n",                OLF_MAX},
{"EXTSIZE",     "EXTSIZE=n",            OLF_MAX},

{"FASTROM",     "FASTROM",              OLF_MOVE},
{"FORCEA20",    "FORCEA20",             OLF_MAX},
{"FRAME",       "FRAME=xxxx",           OLF_MAX},

{"HPDAREG",     "HPDAREG=nnn,r",        OLF_MAX},
{"HMAMIN",      "HMAMIN=n",             OLF_MAX},

{"INCLUDE",     "INCLUDE=[xxxx-yyyy][,n]",
					OLF_MAX},

{"MONO",        "MONO",                 OLF_MAX},

{"NOCOMPROM",   "NOCOMPROM",            OLF_MAX},
{"NODPMI",      "NODPMI",               OLF_MAX},
{"NOFLEX",      "NOFLEX",               OLF_MAX},
{"NOFRAME",     "NOFRAME",              OLF_ALL},
{"NOHIGH",      "NOHIGH",               OLF_MAX},
{"NOLOADHI",    "NOLOADHI",             OLF_ALL},
{"NOLOW",       "NOLOW",                OLF_ALL},
{"NOROM",       "NOROM",                OLF_MAX},
{"NOSCAN",      "NOSCAN",               OLF_MAX},
{"NOSCSI",      "NOSCSI",               OLF_MAX},
{"NOVGASIG",    "NOVGASIG",             OLF_MAX},
{"NOWARMBOOT",  "NOWARMBOOT",           OLF_MAX},
{"NOWIN3",      "NOWIN3",               OLF_MAX},
{"NOWIN30",     "NOWIN30",              OLF_MAX},
{"NOXBIOS",     "NOXBIOS",              OLF_MAX},
{"NOXRAM",      "NOXRAM",               OLF_MAX},

{"OFF",         "OFF",                  OLF_MAX},
{"ON",          "ON",                   OLF_MAX},

{"PRGREG",      "PRGREG=n",             OLF_ALL},
#ifdef LANG_GR
{"PRO",         "PRO=laufw:\\pfad\\dateiname",
#else
{"PRO",         "PRO=drive:\\path\\filename",
#endif
					OLF_ALL},
{"PSMEM",       "PSMEM=n[,xxxx]",       OLF_MAX},

{"RAM",         "RAM=xxxx-yyyy",        OLF_ALL},
{"ROM",         "ROM=xxxx-yyyy",        OLF_MAX},

{"SHADOWRAM",   "SHADOWRAM",            OLF_MAX},
{"SHADOWROM",   "SHADOWROM",            OLF_MAX},
{"STACKREG",    "STACKREG=nnn,r",       OLF_MAX},
{"STACKS",      "STACKS",               OLF_MAX},
{"SWAP",        "SWAP=n",               OLF_MAX},
{"SWAPFILE",    "SWAPFILE [=filename] [/P] [/S=n]",  OLF_MAX},
{"SYS",         "SYS=sysname",          OLF_MAX},

{"TOP384",      "TOP384",               OLF_MAX},

{"UMB",         "UMB",                  OLF_MOVE},
{"USE",         "USE=xxxx-yyyy",        OLF_ALL},

{"VGA",         "VGA",                  OLF_MAX},
{"VGASWAP",     "VGASWAP[=[xxxx],[yyyy],[zzzz]]",               OLF_MAX},
{"VIDMEM",      "VIDMEM=xxxx-yyyy",     OLF_MAX},
#ifdef LANG_GR
{"VXD",         "VXD=laufw:\\pfad\\386MAX.VXD",
#else
{"VXD",         "VXD=drive:\\path\\386MAX.VXD",
#endif
					OLF_MAX},

{"WEITEK",      "WEITEK=ON/OFF/FORCE",  OLF_MAX},

{"XBDAREG",     "XBDAREG=nnn,r",        OLF_MAX},
{"XBIOSHI",     "XBIOSHI",              OLF_MAX},
{"XMSHNDL",     "XMSHNDL=n",            OLF_MAX},

}
#endif
;

#ifdef GLINIT
#define MAXOPTIONS	(sizeof (optionList) / sizeof (OPTLIST))
#endif

/* Index list into complete list - this contains only the indices of */
/* active options */
GLOBAL int optionIdx [
#ifdef GLINIT
MAXOPTIONS
#endif
];

#ifdef LANG_GR
#define OPTIONTITLE " Optionszeile einfÅgen "
#else
#define OPTIONTITLE " Insert Option Line "
#endif
GLOBAL char OptionTitle[ sizeof( OPTIONTITLE )]
#ifdef GLINIT
= OPTIONTITLE
#endif
;

#ifdef LANG_GR
#define KEY1 KEY_ALTO
#define TITLE1 "Option"
#define TITLE1TRIGGER 0
#else
#define KEY1 KEY_ALTP
#define TITLE1 "Option"
#define TITLE1TRIGGER 1
#endif
GLOBAL char Title1[ sizeof( TITLE1 )]
#ifdef GLINIT
= TITLE1
#endif
;

#ifdef LANG_GR
#define KEY2 KEY_ALTB
#define TITLE2 "Options-Beschreibung"
#define TITLE2TRIGGER 8
#else
#define KEY2 KEY_ALTD
#define TITLE2 "Option Description"
#define TITLE2TRIGGER 7
#endif
GLOBAL char Title2[ sizeof( TITLE2 )]
#ifdef GLINIT
= TITLE2
#endif
;

#define KEY3 KEY_ALTT
#ifdef LANG_GR
#define TITLE3 "Options-Text"
#define TITLE3TRIGGER 8
#else
#define TITLE3 "Option Text"
#define TITLE3TRIGGER 7
#endif
GLOBAL char Title3[ sizeof( TITLE3 )]
#ifdef GLINIT
= TITLE3
#endif
;

#define MAXOPTIONTEXTLENGTH 71
GLOBAL char OptionText[ MAXOPTIONTEXTLENGTH ]
#ifdef GLINIT
= "AMRS=nnn"
#endif
;


#define NUMOPTIONBUTTONS 4
GLOBAL BUTTON OptionButtons[ NUMOPTIONBUTTONS ]
#ifdef GLINIT
= {
#ifdef LANG_GR
   { { -5, 25 }, 12, "Fertig",{ KEY_ENTER, 'f', 'F', KEY_ALTF }, KEY_ENTER,    TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, TRUE },
   { { -5, 39 }, 12, "Abbruch",{ KEY_ESCAPE, 'a', 'A', KEY_ALTA }, KEY_ESCAPE,   FALSE, TRUE,    0, 1, FG_BLUE | BG_GRAY, TRUE },
   { { -1, 15 }, 11, "Hilfe F1",{ KEY_F1, 0, 0, 0 },        KEY_F1,                              FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, TRUE },
   { { -1, 28 }, 11, "Druck F2", { KEY_F2,                 0, 0, 0 },  KEY_F2,                  FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
#else
   { { -5, 25 }, 12, "OK",{ KEY_ENTER, 'o', 'O', KEY_ALTO }, KEY_ENTER,    TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, TRUE },
   { { -5, 39 }, 12, "Cancel",{ KEY_ESCAPE, 'c', 'C', KEY_ALTC }, KEY_ESCAPE,   FALSE, TRUE,    0, 1, FG_BLUE | BG_GRAY, TRUE },
   { { -1, 15 }, 11, "Help F1",{ KEY_F1, 0, 0, 0 },        KEY_F1,                              FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, TRUE },
   { { -1, 28 }, 11, "Print F2", { KEY_F2,                 0, 0, 0 },  KEY_F2,                  FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
#endif
}
#endif
;


/*	New bottom of option editor window */
#ifdef LANG_GR
#define OPTBOTTOMTITLE " [TAB \x18 \x19 <ƒŸ ESC] "
#else
#define OPTBOTTOMTITLE " [Tab \x18 \x19 Enter Esc] "
#endif
GLOBAL char OptBottomTitle[sizeof( OPTBOTTOMTITLE )]
#ifdef GLINIT
= OPTBOTTOMTITLE
#endif
;

#endif

