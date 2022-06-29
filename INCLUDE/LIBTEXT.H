/*' $Header:   P:/PVCS/MAX/INCLUDE/LIBTEXT.H_V   1.9   30 May 1997 11:19:42   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * LIBTEXT.H								      *
 *									      *
 * This file contains all text strings and any defines that are required to   *
 * know about the string.						      *
 *									      *
 ******************************************************************************/

/*
*
* ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³ transferred to GERMAN 3 Mar 1992 by H.Reibe c/o Klaus Albrecht Mnchen ³
* ³ Needs to be checked thoroughly !!					   ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*
*/

#ifndef LIBTEXT_INCLUDED
#define LIBTEXT_INCLUDED

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

#define HELPMCONTENTS		0
#define HELPINDEX			1
#define HELPHELP			2
#define HELPMENUS			3
#define HELPDIALOGS		4
#define HELPPRINT			5
#define HELPEDITOR			6
#define HELPBROWSE			7
#define HELPOPTEDITOR		8

#ifndef BUTTON_INCLUDED
#include <button.h>
#endif

#ifndef ENGINE_INCLUDED
#include <engine.h>
#endif

#ifndef KEYBOARD_INCLUDED
#include <keyboard.h>
#endif

#ifndef MENU_INCLUDED
#include <menu.h>
#endif

#ifndef MESSAGE_INCLUDED
#include <message.h>
#endif

#ifndef PRINT_INCLUDED
#include <qprint.h>
#endif

#ifndef WINDOWFN_INCLUDED
#include <windowfn.h>
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


#define MNCALLBACK NULL

GLOBAL char *LogoAddress[10]
#ifdef GLINIT
 = {
	"(C) Copyright 1987-",
	"97 Qualitas, Inc.",
#ifdef LANG_GR
	"Alle Rechte ",
	"vorbehalten.",
#else
	"All rights reserved",
#endif
	"",
	"Qualitas, Inc.",
	"8601 Georgia Ave.",
	"Suite 908",
	"Silver Spring, MD 20910",
/*	"(301) 578-8400",       */
	NULL
}
#endif
;

/*
*  Stuff for global reserve
*/
GLOBAL void *globalReserve;
/*
* end stuff for global reserve
*/


/*
*	Stuff for help
*/
#define HELPFILENAME "MAX.HLP"
GLOBAL char HelpFileName[ 16 ]	/* Fixed size 'cause name may be overwritten */
#ifdef GLINIT
= HELPFILENAME
#endif
;

#define HELPCONTENTSTEXT "H.Contents"
GLOBAL char HelpContents[ sizeof( HELPCONTENTSTEXT ) ]
#ifdef GLINIT
= HELPCONTENTSTEXT
#endif
;

#define HELPINDEXTEXT "H.Index"
GLOBAL char HelpIndex[ sizeof( HELPINDEXTEXT ) ]
#ifdef GLINIT
= HELPINDEXTEXT
#endif
;

/*	Main window definitions */
#define NUMMAINBUTTONS 3
GLOBAL BUTTON MainButtons[ NUMMAINBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { -1, 1 },  12, "Ende ESC",        { KEY_ESCAPE, 0, 0, 0 }, KEY_ESCAPE,    FALSE, FALSE, 5, 3, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 15 }, 11, "Hilfe F1",        { KEY_F1,     0, 0, 0 }, KEY_F1,        FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Druck F2",        { KEY_F2,     0, 0, 0 }, KEY_F2,        FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
}
#else
= {
   { { -1, 1 },  12, "Exit Esc",        { KEY_ESCAPE, 0, 0, 0 }, KEY_ESCAPE,    FALSE, FALSE, 5, 3, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 15 }, 11, "Help F1",         { KEY_F1,         0, 0, 0 }, KEY_F1,            FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Print F2",        { KEY_F2,         0, 0, 0 }, KEY_F2,            FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
}
#endif
#endif
;

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿*/
/*³  German key names differ from your's as follows:            ³*/
/*ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´*/
/*³ US Version	   German Version	      in manuals	³*/
/*ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´*/
/*³ Tab 	   TAB			      Tabulator 	³*/
/*³ Esc 	   ESC			      ESC-Taste 	³*/
/*³ SPACE	   LEER 		      Leertaste 	³*/
/*³ Backspace	   Rckschritt		      Rckschritt-Taste ³*/
/*³ Prt Sc	   Druck		      Druck-Taste	³*/
/*³ Scroll Lock    Rollen		      Rollen-Taste	³*/
/*³ Break	   Untbr		      Unterbrechen-Taste³*/
/*³ ENTER	   <ÄÙ			      Eingabetaste	³*/
/*³ PgUp	   Bild \x18		      Bild auf		³*/
/*³ PgDn	   Bild \x19		      Bild ab		³*/
/*³ Arrow left	   \x1B 		      Pfeil links	³*/
/*³ Arrow right    \x1A 		      Pfeil rechts	³*/
/*³ Arrow up	   \x18 		      Pfeil auf 	³*/
/*³ Arrow down	   \x19 		      Pfeil ab		³*/
/*³ Home	   Pos1 		      Pos1-Taste	³*/
/*³ End 	   Ende 		      Ende-Taste	³*/
/*³ Ins 	   Einfg		      Einfge-Taste	³*/
/*³ Del 	   Entf 		      Entfernen-Taste	³*/
/*³ Ctrl	   Strg 		      Steuerung 	³*/
/*ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/

/*	New bottom of print window */
#ifdef LANG_GR
#define BOTTOMTITLE " [TAB \x18 \x19 LEER <ÄÙ ESC] "
#else
#define BOTTOMTITLE " [Tab \x18 \x19 Space Enter Esc] "
#endif
GLOBAL char BottomTitle[sizeof( BOTTOMTITLE )]
#ifdef GLINIT
= BOTTOMTITLE
#endif
;


/*	 Print file information - With all the dialog stuff */
#ifdef LANG_GR
#define PRINTTITLE " Druck "
#else
#define PRINTTITLE " Print "
#endif
GLOBAL char PrintTitle[ sizeof( PRINTTITLE )]
#ifdef GLINIT
= PRINTTITLE
#endif
;

#ifdef LANG_GR
#define FILENAMEKEY KEY_ALTD
#define PRINTFILENAME "Dateiname"
#define PRINTFILENAMETRIGGER 0
#else
#define FILENAMEKEY KEY_ALTN
#define PRINTFILENAME "File Name"
#define PRINTFILENAMETRIGGER 5
#endif
GLOBAL char PrintFileName[ sizeof( PRINTFILENAME )]
#ifdef GLINIT
= PRINTFILENAME
#endif
;

#ifdef LANG_GR
#define PRINTOUTPUT "Ausgabe-Umleitung"
#define PRINTOUTPUTTRIGGER 9
#else
#define PRINTOUTPUT "Output Routing"
#define PRINTOUTPUTTRIGGER 7
#endif
GLOBAL char PrintOutput[ sizeof( PRINTOUTPUT )]
#ifdef GLINIT
= PRINTOUTPUT
#endif
;

#ifdef LANG_GR
#define PRINTWHAT "was drucken ?"
#define PRINTWHATTRIGGER 0
#else
#define PRINTWHAT "What to Print"
#define PRINTWHATTRIGGER 0
#endif
GLOBAL char PrintWhat[ sizeof( PRINTWHAT )]
#ifdef GLINIT
= PRINTWHAT
#endif
;

#define NUMPRINTBUTTONS 4
GLOBAL BUTTON PrintButtons[ NUMPRINTBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { -1, 15 }, 11, "Hilfe F1",        { KEY_F1,                  0, 0, 0 }, KEY_F1,        FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Druck F2",        { KEY_F2,                  0, 0, 0 }, KEY_F2,        FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 19, 24 }, 14, "Fertig <ÄÙ",      { 'f', 'F', KEY_ALTF,    KEY_ENTER }, KEY_ENTER,     TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 19, 41 }, 14, "Abbruch ESC",     { 'a', 'A', KEY_ALTA,   KEY_ESCAPE }, KEY_ESCAPE,    FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#else
= {
   { { -1, 15 }, 11, "Help F1",         { KEY_F1,         0, 0, 0 }, KEY_F1,            FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Print F2",        { KEY_F2,         0, 0, 0 }, KEY_F2,            FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 19, 27 }, 12, "OK",              { 'o', 'O', KEY_ALTO,   KEY_ENTER }, KEY_ENTER,         TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 19, 41 }, 12, "Cancel",  { 'c', 'C', KEY_ALTC,   KEY_ESCAPE }, KEY_ESCAPE,       FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#endif
#endif
;

/* Note that each group of topic strings must have unique triggers */

#ifdef LANG_GR
#define HELPCURRENTDOC "[ ] diese Datei"
#define HELPCURRENTDOCTRIGGER 6
#else
#define HELPCURRENTDOC "[ ] This document"
#define HELPCURRENTDOCTRIGGER 4
#endif
GLOBAL char HelpCurrentDoc[ sizeof( HELPCURRENTDOC )]
#ifdef GLINIT
= HELPCURRENTDOC
#endif
;

#ifdef LANG_GR
#define HELPFORBROWSER "[ ] Hilfen zum Bl„ttern"
#define HELPFORBROWSERTRIGGER 4
#else
#define HELPFORBROWSER "[ ] Browser help topics"
#define HELPFORBROWSERTRIGGER 4
#endif
GLOBAL char HelpForBrowser[ sizeof( HELPFORBROWSER )]
#ifdef GLINIT
= HELPFORBROWSER
#endif
;

#ifdef LANG_GR
#define HELPFORALL "[ ] alle Hilfe-Themen"
#define HELPFORALLTRIGGER 10
#else
#define HELPFORALL "[ ] All help topics"
#define HELPFORALLTRIGGER 4
#endif
GLOBAL char HelpForAll[ sizeof( HELPFORALL )]
#ifdef GLINIT
= HELPFORALL
#endif
;

#define NUMP_BROWSER 3
GLOBAL struct
{
	int numItems;
	BLINFO info;
	BLITEM items[ NUMP_BROWSER ];
} P_Browser
#ifdef GLINIT
#ifdef LANG_GR
= {
	NUMP_BROWSER,
	{ BTYPE_CHECK, NUMP_BROWSER, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, HELPCURRENTDOCTRIGGER,	{ 'e', 'E' }, KEY_ALTE, sizeof( HELPCURRENTDOC ),       HelpCurrentDoc },
		{ {FALSE,FALSE}, { 2, 1 }, HELPFORBROWSERTRIGGER,	{ 'h', 'H' }, KEY_ALTH, sizeof( HELPFORBROWSERTRIGGER ),HelpForBrowser },
		{ {FALSE,FALSE}, { 3, 1 }, HELPFORALLTRIGGER,		{ 'i', 'I' }, KEY_ALTI, sizeof( HELPFORALL ),           HelpForAll },
	}
}
#else
= {
	NUMP_BROWSER,
	{ BTYPE_CHECK, NUMP_BROWSER, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, HELPCURRENTDOCTRIGGER,	{ 't', 'T' }, KEY_ALTT, sizeof( HELPCURRENTDOC ),               HelpCurrentDoc },
		{ {FALSE,FALSE}, { 2, 1 }, HELPFORBROWSERTRIGGER,	{ 'b', 'B' }, KEY_ALTB, sizeof( HELPFORBROWSERTRIGGER ),HelpForBrowser },
		{ {FALSE,FALSE}, { 3, 1 }, HELPFORALLTRIGGER,		{ 'a', 'A' }, KEY_ALTA, sizeof( HELPFORALL ),                   HelpForAll },
	}
}
#endif
#endif
;

#ifdef LANG_GR
#define HELPFOREDITOR "[ ] Hilfen zum Editor"
#define HELPFOREDITORTRIGGER 4
#else
#define HELPFOREDITOR "[ ] Editor help topics"
#define HELPFOREDITORTRIGGER 4
#endif
GLOBAL char HelpForEditor[ sizeof( HELPFOREDITOR )]
#ifdef GLINIT
= HELPFOREDITOR
#endif
;

#define NUMP_EDITOR 3
GLOBAL struct
{
	int numItems;
	BLINFO info;
	BLITEM items[ NUMP_EDITOR ];
} P_Editor
#ifdef GLINIT
#ifdef LANG_GR
= {
	NUMP_EDITOR,
	{ BTYPE_CHECK, NUMP_EDITOR, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, HELPCURRENTDOCTRIGGER,	{ 'e', 'E' }, KEY_ALTE, sizeof( HELPCURRENTDOC ),       HelpCurrentDoc },
		{ {FALSE,FALSE}, { 2, 1 }, HELPFOREDITORTRIGGER,	{ 'h', 'H' }, KEY_ALTH, sizeof( HELPFOREDITORTRIGGER ), HelpForEditor },
		{ {FALSE,FALSE}, { 3, 1 }, HELPFORALLTRIGGER,		{ 'i', 'I' }, KEY_ALTI, sizeof( HELPFORALL ),           HelpForAll },
	}
}
#else
= {
	NUMP_EDITOR,
	{ BTYPE_CHECK, NUMP_EDITOR, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, HELPCURRENTDOCTRIGGER,	{ 't', 'T' }, KEY_ALTT, sizeof( HELPCURRENTDOC ),               HelpCurrentDoc },
		{ {FALSE,FALSE}, { 2, 1 }, HELPFOREDITORTRIGGER,	{ 'e', 'E' }, KEY_ALTE, sizeof( HELPFOREDITORTRIGGER ), HelpForEditor },
		{ {FALSE,FALSE}, { 3, 1 }, HELPFORALLTRIGGER,		{ 'a', 'A' }, KEY_ALTA, sizeof( HELPFORALL ),                   HelpForAll },
	}
}
#endif
#endif
;

#define NUMP_OEDITOR 2
GLOBAL struct
{
	int numItems;
	BLINFO info;
	BLITEM items[ NUMP_OEDITOR ];
} P_OEditor
#ifdef GLINIT
#ifdef LANG_GR
= {
	NUMP_OEDITOR,
	{ BTYPE_CHECK, NUMP_OEDITOR, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, HELPFOREDITORTRIGGER,	{ 'h', 'H' }, KEY_ALTH, sizeof( HELPFOREDITORTRIGGER ), HelpForEditor },
		{ {FALSE,FALSE}, { 2, 1 }, HELPFORALLTRIGGER,		{ 'i', 'I' }, KEY_ALTI, sizeof( HELPFORALL ),           HelpForAll },
	}
}
#else
= {
	NUMP_OEDITOR,
	{ BTYPE_CHECK, NUMP_OEDITOR, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, HELPFOREDITORTRIGGER,	{ 'e', 'E' }, KEY_ALTE, sizeof( HELPFOREDITORTRIGGER ), HelpForEditor },
		{ {FALSE,FALSE}, { 2, 1 }, HELPFORALLTRIGGER,		{ 'a', 'A' }, KEY_ALTA, sizeof( HELPFORALL ),                   HelpForAll },
	}
}
#endif
#endif
;

#ifdef LANG_GR
#define CURRENTGLOSSDISPLAY "[ ] dieses Glossar-Thema"
#define CURRENTGLOSSTRIGGER 6
#else
#define CURRENTGLOSSDISPLAY "[ ] This glossary topic"
#define CURRENTGLOSSTRIGGER 4
#endif
GLOBAL char CurrentGlossDisplay[ sizeof( CURRENTGLOSSDISPLAY )]
#ifdef GLINIT
= CURRENTGLOSSDISPLAY
#endif
;

#ifdef LANG_GR
#define ALLGLOSSDISPLAY "[ ] alle Glossar-Themen"
#define ALLGLOSSDISPLAYTRIGGER 5
#else
#define ALLGLOSSDISPLAY "[ ] All glossary topics"
#define ALLGLOSSDISPLAYTRIGGER 4
#endif
GLOBAL char AllGlossDisplay[ sizeof( ALLGLOSSDISPLAY )]
#ifdef GLINIT
= ALLGLOSSDISPLAY
#endif
;

#define NUMP_GLOSS 2
GLOBAL struct
{
	int numItems;
	BLINFO info;
	BLITEM items[ NUMP_GLOSS ];
} P_Gloss
#ifdef GLINIT
#ifdef LANG_GR
= {
	NUMP_GLOSS,
	{ BTYPE_CHECK, NUMP_GLOSS, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, CURRENTGLOSSTRIGGER,    { 'e', 'E' }, KEY_ALTE, sizeof( CURRENTGLOSSDISPLAY ), CurrentGlossDisplay },
		{ {FALSE,FALSE}, { 2, 1 }, ALLGLOSSDISPLAYTRIGGER, { 'l', 'L' }, KEY_ALTL, sizeof( ALLGLOSSDISPLAY ),     AllGlossDisplay },
	}
}
#else
= {
	NUMP_GLOSS,
	{ BTYPE_CHECK, NUMP_GLOSS, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, CURRENTGLOSSTRIGGER,    { 't', 'T' }, KEY_ALTT, sizeof( CURRENTGLOSSDISPLAY ), CurrentGlossDisplay },
		{ {FALSE,FALSE}, { 2, 1 }, ALLGLOSSDISPLAYTRIGGER, { 'a', 'A' }, KEY_ALTA, sizeof( ALLGLOSSDISPLAY ),     AllGlossDisplay },
	}
}
#endif
#endif
;

#ifdef LANG_GR
#define HELPFORTOPIC "[ ] dieses Hilfe-Thema"
#define HELPFORTOPICTRIGGER 11
#else
#define HELPFORTOPIC "[ ] Current help topic"
#define HELPFORTOPICTRIGGER 12
#endif
GLOBAL char HelpForTopic[ sizeof( HELPFORTOPIC )]
#ifdef GLINIT
= HELPFORTOPIC
#endif
;

#define NUMP_HELP 2
GLOBAL struct
{
	int numItems;
	BLINFO info;
	BLITEM items[ NUMP_HELP ];
} P_Help
#ifdef GLINIT
#ifdef LANG_GR
= {
	NUMP_HELP,
	{ BTYPE_CHECK, NUMP_HELP, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, HELPFORTOPICTRIGGER, { 'h', 'H' }, KEY_ALTH, sizeof( HELPFORTOPIC ), HelpForTopic },
		{ {FALSE,FALSE}, { 2, 1 }, HELPFORALLTRIGGER,	{ 'i', 'I' }, KEY_ALTI, sizeof( HELPFORALL ),   HelpForAll },
	}
}
#else
= {
	NUMP_HELP,
	{ BTYPE_CHECK, NUMP_HELP, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, HELPFORTOPICTRIGGER, { 'h', 'H' }, KEY_ALTH, sizeof( HELPFORTOPIC ), HelpForTopic },
		{ {FALSE,FALSE}, { 2, 1 }, HELPFORALLTRIGGER,	{ 'a', 'A' }, KEY_ALTA, sizeof( HELPFORALL ),   HelpForAll },
	}
}
#endif
#endif
;

#ifdef LANG_GR
#define CURRENTDISPLAY "[ ] diese Daten-Anzeige"
#define CURRENTDISPLAYTRIGGER 6
#else
#define CURRENTDISPLAY "[ ] This data display"
#define CURRENTDISPLAYTRIGGER 4
#endif
GLOBAL char CurrentDisplay[ sizeof( CURRENTDISPLAY )]
#ifdef GLINIT
= CURRENTDISPLAY
#endif
;

#ifdef LANG_GR
#define ALLDISPLAY "[ ] alle Daten-Anzeigen"
#define ALLDISPLAYTRIGGER 5
#else
#define ALLDISPLAY "[ ] All data displays"
#define ALLDISPLAYTRIGGER 8
#endif
GLOBAL char AllDisplay[ sizeof( ALLDISPLAY )]
#ifdef GLINIT
= ALLDISPLAY
#endif
;

#define NUMP_MENU 4
GLOBAL struct
{
	int numItems;
	BLINFO info;
	BLITEM items[ NUMP_MENU ];
} P_Menu
#ifdef GLINIT
#ifdef LANG_GR
= {
	NUMP_MENU,
	{ BTYPE_CHECK, NUMP_MENU, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, CURRENTDISPLAYTRIGGER, { 'e', 'E' }, KEY_ALTE, sizeof( CURRENTDISPLAY ), CurrentDisplay },
		{ {FALSE,FALSE}, { 2, 1 }, ALLDISPLAYTRIGGER,	  { 'l', 'L' }, KEY_ALTL, sizeof( ALLDISPLAY ),     AllDisplay },
		{ {FALSE,FALSE}, { 3, 1 }, HELPFORTOPICTRIGGER,   { 'h', 'H' }, KEY_ALTH, sizeof( HELPFORTOPIC ),   HelpForTopic },
		{ {FALSE,FALSE}, { 4, 1 }, HELPFORALLTRIGGER,	  { 'i', 'I' }, KEY_ALTI, sizeof( HELPFORALL ),     HelpForAll },
	}
}
#else
= {
	NUMP_MENU,
	{ BTYPE_CHECK, NUMP_MENU, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, CURRENTDISPLAYTRIGGER, { 't', 'T' }, KEY_ALTT, sizeof( CURRENTDISPLAY ), CurrentDisplay },
		{ {FALSE,FALSE}, { 2, 1 }, ALLDISPLAYTRIGGER,	  { 'd', 'D' }, KEY_ALTD, sizeof( ALLDISPLAY ),         AllDisplay },
		{ {FALSE,FALSE}, { 3, 1 }, HELPFORTOPICTRIGGER,   { 'h', 'H' }, KEY_ALTH, sizeof( HELPFORTOPIC ),       HelpForTopic },
		{ {FALSE,FALSE}, { 4, 1 }, HELPFORALLTRIGGER,	  { 'a', 'A' }, KEY_ALTA, sizeof( HELPFORALL ),         HelpForAll },
	}
}
#endif
#endif
;

#ifdef LANG_GR
#define CURRENTTUTORDISPLAY "[ ] dieses Lernhilfe-Thema"
#define CURRENTTUTORDISPLAYTRIGGER 6
#else
#define CURRENTTUTORDISPLAY "[ ] This tutorial topic"
#define CURRENTTUTORDISPLAYTRIGGER 4
#endif
GLOBAL char CurrentTutorDisplay[ sizeof( CURRENTTUTORDISPLAY )]
#ifdef GLINIT
= CURRENTTUTORDISPLAY
#endif
;

#ifdef LANG_GR
#define ALLTUTORDISPLAY "[ ] alle Lernhilfe-Themen"
#define ALLTUTORDISPLAYTRIGGER 5
#else
#define ALLTUTORDISPLAY "[ ] All tutorial topics"
#define ALLTUTORDISPLAYTRIGGER 4
#endif
GLOBAL char AllTutorDisplay[ sizeof( ALLTUTORDISPLAY )]
#ifdef GLINIT
= ALLTUTORDISPLAY
#endif
;

#define NUMP_TUTOR 2
GLOBAL struct
{
	int numItems;
	BLINFO info;
	BLITEM items[ NUMP_TUTOR ];
} P_Tutor
#ifdef GLINIT
#ifdef LANG_GR
= {
	NUMP_TUTOR,
	{ BTYPE_CHECK, NUMP_TUTOR, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, CURRENTTUTORDISPLAYTRIGGER, { 'e', 'E' }, KEY_ALTE, sizeof( CURRENTTUTORDISPLAY ), CurrentTutorDisplay },
		{ {FALSE,FALSE}, { 2, 1 }, ALLTUTORDISPLAYTRIGGER,     { 'l', 'L' }, KEY_ALTL, sizeof( ALLTUTORDISPLAY ),     AllTutorDisplay },
	}
}
#else
= {
	NUMP_TUTOR,
	{ BTYPE_CHECK, NUMP_TUTOR, 0, KEY_ALTW, FG_BLACK | BG_GRAY, { 3,24, 6, 31 } },
	{
		{ {FALSE,TRUE},  { 1, 1 }, CURRENTTUTORDISPLAYTRIGGER, { 't', 'T' }, KEY_ALTT, sizeof( CURRENTTUTORDISPLAY ), CurrentTutorDisplay },
		{ {FALSE,FALSE}, { 2, 1 }, ALLTUTORDISPLAYTRIGGER,	   { 'a', 'A' }, KEY_ALTA, sizeof( ALLTUTORDISPLAY ),     AllTutorDisplay },
	}
}
#endif
#endif
;

#ifdef LANG_GR
#define TOPRINTER "( ) Drucker"
#define TOPRINTERTRIGGER 6
#else
#define TOPRINTER "( ) Printer"
#define TOPRINTERTRIGGER 4
#endif
GLOBAL char ToPrinter[ sizeof( TOPRINTER )]
#ifdef GLINIT
= TOPRINTER
#endif
;

#ifdef LANG_GR
#define TODISK "( ) Datei"
#define TODISKTRIGGER 6
#else
#define TODISK "( ) Disk file"
#define TODISKTRIGGER 9
#endif
GLOBAL char ToDisk[ sizeof( TODISK )]
#ifdef GLINIT
= TODISK
#endif
;

#ifdef LANG_GR
#define APPENDTOFILE "( ) h„nge an Datei"
#define APPENDTOFILETRIGGER 6
#else
#define APPENDTOFILE "( ) Add to disk file"
#define APPENDTOFILETRIGGER 12
#endif
GLOBAL char AppendToFile[ sizeof( APPENDTOFILE )]
#ifdef GLINIT
= APPENDTOFILE
#endif
;

#define NUMWHEREPRINT 3
GLOBAL struct
{
	int numItems;
	BLINFO info;
	BLITEM items[ NUMWHEREPRINT ];
} WherePrintList
#ifdef GLINIT
#ifdef LANG_GR
= {
	NUMWHEREPRINT,
	{ BTYPE_RADIO, NUMWHEREPRINT, 0, KEY_ALTM, FG_BLACK | BG_GRAY, { 11,24, 5, 31 } },
	{
		{ {FALSE,TRUE }, { 1, 1 }, TOPRINTERTRIGGER,	{ 'u', 'U' }, KEY_ALTU, sizeof( TOPRINTER ),    ToPrinter },
		{ {FALSE,FALSE}, { 2, 1 }, TODISKTRIGGER,	{ 't', 'T' }, KEY_ALTT, sizeof( TODISK ),       ToDisk },
		{ {FALSE,FALSE}, { 3, 1 }, APPENDTOFILETRIGGER, { 'n', 'N' }, KEY_ALTN, sizeof( APPENDTOFILE ), AppendToFile },
	}
}
#else
= {
	NUMWHEREPRINT,
	{ BTYPE_RADIO, NUMWHEREPRINT, 0, KEY_ALTR, FG_BLACK | BG_GRAY, { 11,24, 5, 31 } },
	{
		{ {FALSE,TRUE }, { 1, 1 }, TOPRINTERTRIGGER,	{ 'p', 'P' }, KEY_ALTP, sizeof( TOPRINTER ),    ToPrinter },
		{ {FALSE,FALSE}, { 2, 1 }, TODISKTRIGGER,	{ 'f', 'F' }, KEY_ALTF, sizeof( TODISK ),       ToDisk },
		{ {FALSE,FALSE}, { 3, 1 }, APPENDTOFILETRIGGER, { 'i', 'I' }, KEY_ALTI, sizeof( APPENDTOFILE ), AppendToFile },
	}
}
#endif
#endif
;

GLOBAL PBUTTONLIST PrintOptions [P_LAST]
#ifdef GLINIT
= {
	(LPBUTTONLIST)&P_Editor,
	(LPBUTTONLIST)&P_Gloss,
	(LPBUTTONLIST)&P_Help,
	(LPBUTTONLIST)&P_Menu,
	(LPBUTTONLIST)&P_Menu,
	(LPBUTTONLIST)&P_Tutor,
	(LPBUTTONLIST)&P_Browser,
	(LPBUTTONLIST)&P_OEditor,
}
#endif
;

#define MAXPRINTFILELENGTH 64
GLOBAL char PrintFile[ MAXPRINTFILELENGTH ];

#define NUMMESSAGEBUTTONS 1
GLOBAL BUTTON MessageButtons[ NUMMESSAGEBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { 0, 0  }, 14, "Fertig <ÄÙ",       { 'f','F', KEY_ALTF, KEY_ENTER }, KEY_ENTER, TRUE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE }
}
#else
= {
   { { 0, 0  }, 12, "OK",       { 'o','O', KEY_ALTO, KEY_ENTER }, KEY_ENTER, TRUE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE }
}
#endif
#endif
;

#define NUMYESNOBUTTONS 2
GLOBAL BUTTON YesNoButtons[ NUMYESNOBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {	/*	Returns (JN) MUST be upper case */
   { { 0, 0  }, 12, "Ja",         { 'j', 'N', KEY_ALTJ, 0 }, 'J', TRUE,   TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 12, "Nein",       { 'n', 'N', KEY_ALTN, 0 }, 'N', FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE }
}
#else
= {											/*	Returns (YN) MUST be upper case */
   { { 0, 0  }, 12, "Yes",      { 'y', 'Y', KEY_ALTY, 0 }, 'Y', TRUE,   TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 12, "No",       { 'n', 'N', KEY_ALTN, 0 }, 'N', FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE }
}
#endif
#endif
;

#define NUMSAVEBUTTONS 3
GLOBAL	BUTTON YesNoEscButtons[ NUMSAVEBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {											/*	Returns !(JN)! MUST be upper case */
   { { 0, 0  }, 12, "Ja",               { 'j', 'J', KEY_ALTJ, 0 },               'J',            TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 12, "Nein",             { 'n', 'N', KEY_ALTN, 0 },               'N',            FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 12, "Abbruch",      { 'a', 'A', KEY_ALTA, 0 }, KEY_ESCAPE,                   FALSE, TRUE,  8, 3, FG_BLUE | BG_GRAY, FALSE }
}
#else
= {											/*	Returns (YN) MUST be upper case */
   { { 0, 0  }, 12, "Yes",              { 'y', 'Y', KEY_ALTY, 0 },               'Y',            TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 12, "No",               { 'n', 'N', KEY_ALTN, 0 },               'N',            FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 12, "Cancel",   { 'c', 'C', KEY_ALTC, 0 }, KEY_ESCAPE,           FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE }
}
#endif
#endif
;


#define NUMARFBUTTONS 3
GLOBAL BUTTON ArfButtons[ NUMARFBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {											/*	Returns (JN) MUST be upper case */
   { { 0, 0  }, 10, "Abbruch",      { 'a', 'A', KEY_ALTA, 0 }, 'A', FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 14, "Wiederholen",  { 'w', 'W', KEY_ALTW, 0 }, 'W', FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 10, "Fehler",       { 'f', 'F', KEY_ALTF, 0 }, 'F', FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE }
}
#else
= {											/*	Returns (YN) MUST be upper case */
   { { 0, 0  }, 12, "Abort",    { 'a', 'A', KEY_ALTA, 0 }, 'A', FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 12, "Retry",    { 'r', 'R', KEY_ALTR, 0 }, 'R', FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 0, 0  }, 12, "Fail",     { 'f', 'F', KEY_ALTF, 0 }, 'F', FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE }
}
#endif
#endif
;


/*	Update window definitions */
#define NUMUPDBUTTONS 3
GLOBAL BUTTON UpdateButtons[ NUMUPDBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { -8, 22}, 12, "Weiter",   { 'w', 'W', KEY_ALTW, 0 }, KEY_ALTW,   FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -8, 38},  8, "Zurck",   { 'z', 'Z', KEY_ALTZ, 0 }, KEY_ALTZ,   TRUE,  TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -8, 49},  8, "Beenden",  { 'b', 'B', KEY_ALTB, 0 }, KEY_ESCAPE, FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#else
= {
   { { -8, 22}, 12, "Continue", { 'c', 'C', KEY_ALTC, 0 }, KEY_ALTC,   FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -8, 38},  8, "Back",     { 'b', 'B', KEY_ALTB, 0 }, KEY_ALTB,   TRUE,  TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -8, 49},  8, "Exit",     { 'e', 'E', KEY_ALTE, 0 }, KEY_ESCAPE, FALSE, TRUE, 0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#endif
#endif
;


GLOBAL char *TypeMessage[ERRTYPE_LAST]
#ifdef GLINIT
#ifdef LANG_GR
= {
	" Dialogfenster-Fehler ",
	" Prf-Fehler ",
	" Drucker-Fehler ",
	" Datei-Fehler ",
	" Hilfe-Fehler ",
	" Aktion ",
	" Meldung ",
	" Vorsicht! ",
	" Ger„te-Fehler ",
	" Platten-Fehler "
}
#else
= {
	" Window Error ",
	" Examine Error ",
	" Print Error ",
	" File Error ",
	" Help Error ",
	" Action ",
	" Message ",
	" Warning ",
	" Device Error ",
	" Disk Error "
}
#endif
#endif
;

GLOBAL MSG msgs[52]
#ifdef GLINIT
#ifdef LANG_GR
= {
	{	0, ERRTYPE_WINDOW, 0, NULL, NULL },	/*	This message unstable */
	{	WIN_NOROOM,   ERRTYPE_WINDOW, NUMMESSAGEBUTTONS, MessageButtons, "zu wenig Fenster-Speicher zum Bearbeiten." },
	{	WIN_NOMEMORY, ERRTYPE_WINDOW, NUMMESSAGEBUTTONS, MessageButtons, "zu wenig Speicher zum Bearbeiten." },
	{	WIN_NOTFOUND, ERRTYPE_WINDOW, NUMMESSAGEBUTTONS, MessageButtons, "Hilfe-Zugang nicht gefunden." },
	{	WIN_WEIRD,	  ERRTYPE_WINDOW, NUMMESSAGEBUTTONS, MessageButtons, "unerwarteter Fenster-Fehler." },
	{	9, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, "Block nicht wiederherstellbar." },

	{ 200, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Datei oder Pfad nicht gefunden."},
	{ 201, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "kann Datei nicht ”ffnen."},
	{ 206, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "DOS- oder I/O-Fehler %d."},
	{ 207, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Datei ist zu groá zum Bearbeiten."},
	{ 208, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Sie haben keine Schreib-Erlaubnis."},
	{ 209, ERRTYPE_ACTION, NUMYESNOBUTTONS, YesNoButtons,	"Datei nicht gefunden - neu anlegen?" },

	{ 210, ERRTYPE_ACTION, NUMSAVEBUTTONS,	YesNoEscButtons,   "Datei wurde ge„ndert. nderungen abspeichern?" },
	{ 211, ERRTYPE_ACTION, NUMMESSAGEBUTTONS, MessageButtons,  "Datei wird gespeichert." },
	{ 212, ERRTYPE_MESSAGE,NUMMESSAGEBUTTONS, MessageButtons,
						   "386LOAD-Datei nicht gefunden. Geben Sie Laufwerk und Pfad der 386LOAD-Datei in der Zeile mit der ##-Marke ein." },
	{ 213, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "unzul„ssiger Dateiname." },
	{ 214, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, "Speicher ist fast voll." },
	{ 215, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, "Speicher ist voll." },
	{ 216, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, "Zeile(n) zu lang, auf 255 Zeichen gekrzt." },
	{ 232, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Platte ist voll." },
	{ 233, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "keine .ADF-Dateien gefunden." },

	{ 300, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Stichwort fehlt in der betreffenden Hilfe-Datei." },
	{ 301, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Fehler beim ™ffnen der Datei." },
	{ 302, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Fehler beim Lesen der Hilfe-Datei." },
	{ 303, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "zu viele Hilfe-Dateien offen." },
	{ 304, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Fehler beim Anh„ngen an Datei." },
	{ 305, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "keine Hilfe-Datei." },
	{ 306, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "neuere oder unpassende Hilfe-Datei." },
	{ 307, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Speicher-Zuordnungsfehler." },
	{ 308, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Hilfe-Datei nicht gefunden." },

	{ 401, ERRTYPE_PRINT, NUMMESSAGEBUTTONS, MessageButtons, "Drucker-Zeitberschreitung." },
	{ 402, ERRTYPE_PRINT, NUMMESSAGEBUTTONS, MessageButtons, "I/O-Fehler."},
	{ 403, ERRTYPE_PRINT, NUMMESSAGEBUTTONS, MessageButtons, "Papier-Fehler."},
	{ 404, ERRTYPE_PRINT, NUMMESSAGEBUTTONS, MessageButtons, "unbekannter Fehler."},

	{ 500, ERRTYPE_INFO, NUMMESSAGEBUTTONS, MessageButtons, "kann Prffunktion nicht starten." },
	{ 501, ERRTYPE_INFO, NUMMESSAGEBUTTONS, MessageButtons, "kann Info-Abfrage nicht starten." },
	{ 509, ERRTYPE_ACTION, NUMYESNOBUTTONS,   YesNoButtons,   "Datei vorhanden - berschreiben?" },
	{ 511, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Snapshot-Datei nicht gefunden oder unzul„ssiger Name." },
	{ 512, ERRTYPE_INFO, NUMMESSAGEBUTTONS, MessageButtons, "ungltige Snapshot-Datei." },

	{ 550, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "386UTIL-Programm nicht gefunden." },
	{ 551, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "kann 386UTIL-Programm nicht ausfhren." },
	{ 552, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "MAXIMIZE-Programm nicht gefunden." },
	{ 553, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "UPDATE-Programm nicht gefunden." },
	{ 554, ERRTYPE_WARNING, NUMYESNOBUTTONS, YesNoButtons,	"@Bediener-Abbruch eingeleitet.\n@1Wollen Sie jetzt beenden?" },
	{ 555, ERRTYPE_WARNING, NUMARFBUTTONS, ArfButtons,	"Arf!" },
	{ 556, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "ASQ-Programm nicht gefunden." },
	{ 557, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "MOVE'EM-Programm nicht gefunden." },
	{ 558, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "kann MOVE'EM-Programm nicht ausfhren." },
	{ 559, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Bitte zuerst INSTALLation durchfhren." },
	{ 560, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "kann die Datei nicht anlegen." },
	{ 561, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "kann die Datei nicht lesen." },
	{ 562, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "kann nicht in die Datei schreiben." }
}
#else
= {
	{	0, ERRTYPE_WINDOW, 0, NULL, NULL },	/*	This message unstable */
	{	WIN_NOROOM,   ERRTYPE_WINDOW, NUMMESSAGEBUTTONS, MessageButtons, "Insufficient window memory to continue this function." },
	{	WIN_NOMEMORY, ERRTYPE_WINDOW, NUMMESSAGEBUTTONS, MessageButtons, "Insufficient memory to continue this function." },
	{	WIN_NOTFOUND, ERRTYPE_WINDOW, NUMMESSAGEBUTTONS, MessageButtons, "Help entry not found." },
	{	WIN_WEIRD,	  ERRTYPE_WINDOW, NUMMESSAGEBUTTONS, MessageButtons, "Unexpected window error." },
	{	9, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, "Cannot UNDO Block Delete." },

	{ 200, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "File or path not found."},
	{ 201, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Unable to open file."},
	{ 206, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "DOS or I/O error %d."},
	{ 207, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "File is too large to edit."},
	{ 208, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "You don't have write permission."},
	{ 209, ERRTYPE_ACTION, NUMYESNOBUTTONS, YesNoButtons,	"File not found.  Do you wish to create it?" },

	{ 210, ERRTYPE_ACTION, NUMSAVEBUTTONS,	YesNoEscButtons,   "Changes have been made to this file.  Save the changes to disk?" },
	{ 211, ERRTYPE_ACTION, NUMMESSAGEBUTTONS, MessageButtons,  "Saving file to disk." },
	{ 212, ERRTYPE_MESSAGE,NUMMESSAGEBUTTONS, MessageButtons,
						   "Could not discern the location of the 386LOAD file.  You must manually enter the drive and path for 386LOAD on the line where ## appears." },
	{ 213, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Invalid file name." },
	{ 214, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, "Almost out of memory." },
	{ 215, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, "Out of memory." },
	{ 216, ERRTYPE_MESSAGE, NUMMESSAGEBUTTONS, MessageButtons, "Line(s) exceed maximum length, truncated to 255 characters." },
	{ 232, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Out of disk space." },
	{ 233, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "No .ADF files found." },

	{ 300, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Missing context inside valid help file." },
	{ 301, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "OpenFileOnPath failed." },
	{ 302, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "ReadHelpFile failed on header." },
	{ 303, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "to many open helpfiles." },
	{ 304, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "bad appended file." },
	{ 305, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Not a help file." },
	{ 306, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "newer or incompatible help file." },
	{ 307, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "memory allocation failed." },
	{ 308, ERRTYPE_HELP, NUMMESSAGEBUTTONS, MessageButtons, "Help file not found." },

	{ 401, ERRTYPE_PRINT, NUMMESSAGEBUTTONS, MessageButtons, "Printer timed-out." },
	{ 402, ERRTYPE_PRINT, NUMMESSAGEBUTTONS, MessageButtons, "I/O error."},
	{ 403, ERRTYPE_PRINT, NUMMESSAGEBUTTONS, MessageButtons, "Out of paper."},
	{ 404, ERRTYPE_PRINT, NUMMESSAGEBUTTONS, MessageButtons, "Unknown error."},

	{ 500, ERRTYPE_INFO, NUMMESSAGEBUTTONS, MessageButtons, "Unable to initialize Examine function." },
	{ 501, ERRTYPE_INFO, NUMMESSAGEBUTTONS, MessageButtons, "Unable to initialize Info Query." },
	{ 509, ERRTYPE_ACTION, NUMYESNOBUTTONS,   YesNoButtons,   "File exists - Do you want to overwrite it?" },
	{ 511, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Snapshot file not found or file name invalid." },
	{ 512, ERRTYPE_INFO, NUMMESSAGEBUTTONS, MessageButtons, "Invalid snapshot file." },

	{ 550, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "386UTIL program not found." },
	{ 551, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Unable to execute 386UTIL program." },
	{ 552, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "MAXIMIZE program not found." },
	{ 553, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "UPDATE program not found." },
	{ 554, ERRTYPE_WARNING, NUMYESNOBUTTONS, YesNoButtons,	"@Abort requested.  @1Do you want to quit now?" },
	{ 555, ERRTYPE_WARNING, NUMARFBUTTONS, ArfButtons,	"Arf!" },
	{ 556, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "ASQ program not found." },
	{ 557, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "MOVE'EM program not found." },
	{ 558, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Unable to execute MOVE'EM program." },
	{ 559, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "You must run the SETUP program first." },
	{ 560, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Unable to create file." },
	{ 561, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Unable to read file." },
	{ 562, ERRTYPE_FILE, NUMMESSAGEBUTTONS, MessageButtons, "Unable to write file." }
}
#endif
#endif
;


#ifdef LANG_GR
#define PRESSANYKEYTEXT " weiter mit beliebiger Taste oder Mausklick "
#else
#define PRESSANYKEYTEXT " Press any key, or click a mouse button. "
#endif
GLOBAL char PressAnyKeyData[80]
#ifdef GLINIT
= PRESSANYKEYTEXT
#endif
;

#ifdef LANG_GR
#define TOPICTRIGGER 'T'
#define INDEXTRIGGER 'S'
#define NEXTTRIGGER  'N'
#define BACKTRIGGER  'V'
#else
#define TOPICTRIGGER 'T'
#define INDEXTRIGGER 'I'
#define NEXTTRIGGER  'N'
#define BACKTRIGGER  'B'
#endif

#define NUMHELPBUTTONS 7
GLOBAL BUTTON HelpButtons[ NUMHELPBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { -1, 15 }, 11, "Hilfe F1",        { KEY_F1,         0, 0, 0 }, KEY_F1,                    FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Druck F2",        { KEY_F2,         0, 0, 0 }, KEY_F2,                    FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -5,  3 }, 12, "Themen",          { 't',          'T', KEY_ALTT, 0 },      'T',           TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -5, 17 }, 12, "Stichwort",       { 's',          'S', KEY_ALTS, 0 },      'S',           FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -5, 31 }, 12, "n„chste",         { 'n',          'N', KEY_ALTN, 0 },      'N',           FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -5, 45 }, 12, "vorher",          { 'v',          'V', KEY_ALTV, 0 },      'V',           FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -5, 59 }, 15, "Abbruch ESC",     { 'a',          'A', KEY_ALTA, KEY_ESCAPE       },      KEY_ESCAPE,     FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#else
= {
   { { -1, 15 }, 11, "Help F1",         { KEY_F1,         0, 0, 0 }, KEY_F1,                    FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Print F2",        { KEY_F2,         0, 0, 0 }, KEY_F2,                    FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -5,	5 }, 12, "Topics",              { 't',          'T', KEY_ALTT, 0 },      'T',           TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -5, 19 }, 12, "Index",           { 'i',          'I', KEY_ALTI, 0 },      'I',           FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -5, 33 }, 12, "Next",            { 'n',          'N', KEY_ALTN, 0 },      'N',           FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -5, 47 }, 12, "Back",            { 'b',          'B', KEY_ALTB, 0 },      'B',           FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { -5, 61 }, 12, "Cancel",          { 'c',          'C', KEY_ALTC, KEY_ESCAPE       },      KEY_ESCAPE,     FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#endif
#endif
;

/* #define QUICKREFERENCE "\4 Quick Reference \4" */
#ifdef LANG_GR
#define QUICKREFERENCE "Kurz-Referenz"
#else
#define QUICKREFERENCE "Quick Reference"
#endif
GLOBAL char QuickReference[ sizeof( QUICKREFERENCE ) ]
#ifdef GLINIT
= QUICKREFERENCE
#endif
;

/*	Stuff for the file name dialog box */
#define FILENAMENROWS  9
#define FILENAMENCOLS  55
#ifdef LANG_GR
#define FILELOADTITLE " Datei laden "
#define FILELOADTEXT  "Verzeichnis- und Datei-Spezifikation"
#else
#define FILELOADTITLE " File Load "
#define FILELOADTEXT  "Directory and File Specification"
#endif
#define FILETEXTROW  2
#define FILEEDITROW  3
#define FILEBUTTONROW 6

#define NUMFILENAMEBUTTONS 4
GLOBAL BUTTON FileNameButtons[ NUMFILENAMEBUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { -1, 15 }, 11, "Hilfe F1",     { KEY_F1,         0, 0, 0 }, KEY_F1,            FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Druck F2",     { KEY_F2,         0, 0, 0 }, KEY_F2,            FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 26 }, 14, "Fertig <ÄÙ",   { KEY_ENTER,  'f', 'F', KEY_ALTF }, KEY_ENTER,  TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 42 }, 16, "Abbruch ESC",  { KEY_ESCAPE, 'a', 'A', KEY_ALTA }, KEY_ESCAPE, FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#else
= {
   { { -1, 15 }, 11, "Help F1",         { KEY_F1,         0, 0, 0 }, KEY_F1,            FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, FALSE },
   { { -1, 28 }, 11, "Print F2",        { KEY_F2,         0, 0, 0 }, KEY_F2,            FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 26 }, 12, "OK",              { KEY_ENTER,  'o', 'O', KEY_ALTO }, KEY_ENTER,          TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
   { { 13, 40 }, 12, "Cancel",  { KEY_ESCAPE, 'c', 'C', KEY_ALTC }, KEY_ESCAPE, FALSE, TRUE,  0, 1, FG_BLUE | BG_GRAY, FALSE },
}
#endif
#endif
;

/*
*	 Definitions for Evaluating and Working messages
*/
#define EVALBOX 32
#ifdef LANG_GR
#define WORKING "bearbeite..."
#else
#define WORKING "Working..."
#endif

GLOBAL char ButtonStart[2]
#ifdef GLINIT
= "["
#endif
;

GLOBAL char ButtonStop[2]
#ifdef GLINIT
= "]"
#endif
;

#ifdef LANG_GR
#define MENUESCTRIG 5
#define MENUESC "Men ESC"
#else
#define MENUESCTRIG 5
#define MENUESC "Menu Esc"
#endif
GLOBAL char MenuEsc[ sizeof( MENUESC )]
#ifdef GLINIT
= MENUESC
#endif
;

#ifdef LANG_GR
#define DONEESCTRIG 7
#define DONEESC "Fertig ESC"
#else
#define DONEESCTRIG 5
#define DONEESC "Done Esc"
#endif
GLOBAL char DoneEsc[ sizeof( DONEESC )]
#ifdef GLINIT
= DONEESC
#endif
;


/*
 * Special words for do_intmsg()
 *
 * Note that this list need not be a constant length between languages.
 * In other words, the German version may have more words and/or phrases
 * than the international version.
 *
 * These words and/or phrases must correspond to messages passed to
 * do_intmsg().  Embedded spaces are now handled automatically.
 *
 */
GLOBAL char *IntMsgStrList[22]
#ifdef GLINIT
#ifdef LANG_GR
 = {
	"kopiere",
	"lege an",
	"l”sche",
	"fhre aus",
	"extrahiere",
	"bewerte",
	"hole",
	"lade",
	"optimiere",
	"analysiere",
	"berarbeite",
	"verarbeite",
	"lese",
	"starte",
	"lese ein",
	"erneuere",
	"schreibe",
	"erzeuge",
	"suche nach",
	"durchlauf",
	"ermittle",
	NULL
}
#else
 = {
	"copying",
	"creating",
	"deleting",
	"executing",
	"extracting",
	"evaluating",
	"getting",
	"loading",
	"optimizing",
	"parsing",
	"patching",
	"processing",
	"reading",
	"running",
	"scanning",
	"updating",
	"writing",
	NULL
}
#endif
#endif
;

#ifdef LANG_GR
#define SAVING "speichere..."
#else
#define SAVING "Saving..."
#endif
GLOBAL char Saving[sizeof(SAVING)]
#ifdef GLINIT
= SAVING
#endif
;


/*	Since the browser needs this data */
#define NUMDATABUTTONS 2
GLOBAL BUTTON DataButtons[ NUMDATABUTTONS ]
#ifdef GLINIT
#ifdef LANG_GR
= {
   { { -3, 28 }, 14, "vorher F7", { KEY_F7, 0, 0, 0 }, KEY_APGUP, FALSE, FALSE,  7, 2, FG_BLUE | BG_GRAY, TRUE },
   { { -3, 45 }, 15, "n„chste F8",  { KEY_F8, 0, 0, 0 }, KEY_APGDN, FALSE, FALSE,  8, 2, FG_BLUE | BG_GRAY, TRUE },
}
#else
= {
   { { -3, 28 }, 11, "Prev F7", { KEY_F7, 0, 0, 0 }, KEY_APGUP, FALSE, FALSE,   5, 2, FG_BLUE | BG_GRAY, TRUE },
   { { -3, 41 }, 11, "Next F8", { KEY_F8, 0, 0, 0 }, KEY_APGDN, FALSE, FALSE,  5, 2, FG_BLUE | BG_GRAY, TRUE },
}
#endif
#endif
;


/*	New bottom of HELPion editor window */
#ifdef LANG_GR
#define HELPBOTTOMTITLE " [TAB \x18 \x19 \x1a \x1b <ÄÙ ESC] "
#else
#define HELPBOTTOMTITLE " [Tab \x18 \x19 \x1a \x1b Enter Esc] "
#endif
GLOBAL char HelpBottomTitle[sizeof( HELPBOTTOMTITLE )]
#ifdef GLINIT
= HELPBOTTOMTITLE
#endif
;

/* Text used in showLogo and in SETUP (security.c) */

#ifdef LANG_GR
#define LICENSEDTO "Lizenz fr "
#define COMPANY_STR "Firma Name "
#define SERIALNUM_STR "Seriennr.: "
#else
#define LICENSEDTO "Licensed to "
#define COMPANY_STR "Company Name "
#define SERIALNUM_STR "Serial # "
#endif
GLOBAL char LicensedTo[sizeof(LICENSEDTO)]
#ifdef GLINIT
= LICENSEDTO
#endif
;

GLOBAL char CompanyName[sizeof(COMPANY_STR)]
#ifdef GLINIT
= COMPANY_STR
#endif
;

#ifdef LANG_GR
#define LICCOLON "Liz: "
#else
#define LICCOLON "Lic: "
#endif
GLOBAL char LicColon[sizeof(LICCOLON)]
#ifdef GLINIT
= LICCOLON
#endif
;

#define ALOGOWIDTH 22
#define ALOGOHEIGHT 8
GLOBAL char *AltLogoCorners
#ifdef GLINIT
 = "Ú¿ÙÀ"
#endif
;

#define ALTLOGOLINES	4

GLOBAL char *AltLogoText[ALTLOGOLINES]
#ifdef GLINIT
#ifdef LANG_GR
 = {
	"Memory Management",
	"Systeme",
	"von",
	"Qualitas"
}
#else
 = {
	"Advanced",
	"Memory Solutions",
	"from",
	"Qualitas"
}
#endif
#endif
;

/* Messages used by FILEDIFF.C */
GLOBAL char MsgFileErr[80]
#ifdef GLINIT
#ifdef LANG_GR
 = "file_diff: Kann %s nicht ”ffnen\n"
#else
 = "file_diff: unable to open %s\n"
#endif
#endif
;

GLOBAL char MsgFDMallocErr[80]
#ifdef GLINIT
#ifdef LANG_GR
 = "malloc Fehler in file_diff\n"
#else
 = "malloc failure in file_diff\n"
#endif
#endif
;

GLOBAL char MsgChgsMade[80]
#ifdef GLINIT
#ifdef LANG_GR
 = "Empfohlene nderungen fr %s:\n\n"
#else
 = "Proposed changes to %s:\n\n"
#endif
#endif
;

#if 0 /* We don't need these anymore */
#ifdef LANG_GR
 = "¯¯   ALT: "
 = "¯¯   NEU: "
#else
 = "¯¯ OLD: "
 = "¯¯ NEW: "
#endif
#endif /* if 0 */

GLOBAL char MsgAddLine[80]
#ifdef GLINIT
#ifdef LANG_GR
 = "¯¯ HINZU: "
#else
 = "¯¯ ADD: "
#endif
#endif
;

GLOBAL char MsgDelLine[80]
#ifdef GLINIT
#ifdef LANG_GR
 = "¯¯ L™SCH: "
#else
 = "¯¯ DEL: "
#endif
#endif
;

GLOBAL char MsgSameLine[80]
#ifdef GLINIT
#ifdef LANG_GR
 = "  GLEICH: "
#else
 = "  SAME: "
#endif
#endif
;
#define MSGOUTLEN	(sizeof(MsgSameLine)-1)

/* Some countries use 24-hour time (no AM/PM) */
#ifdef LANG_GR
#define TIME_FMT24
#else
#undef TIME_FMT24
#endif

#ifndef TIME_FMT24
GLOBAL char *AmPm[2]
#ifdef GLINIT
= {"AM","PM" }
#endif
;
#endif

/* Define characters to use for thousands and decimal separator */
/* Note that in German , is used for decimal, except for version numbering */
#ifdef LANG_GR
#define NUM_COMMA	'.'
#define NUM_DECIMAL	','
#define NUM_VDECIMAL	','     /* Use the opposite so it gets changed back */
#else
#define NUM_COMMA	','
#define NUM_DECIMAL	'.'
#define NUM_VDECIMAL	'.'
#endif

/* Define some basic message constants */
#ifdef LANG_GR
#define NATL_UNKNOWN	"unbekannt"
#define NATL_NONE	"ohne"
#define NATL_EMULATED	"emuliert"
#define NATL_BUILTIN	"eingebaut"
#define NATL_DATEFMT	"  .  .  "
#define NATL_DATEFMPOS	3
#define NATL_DATEFDPOS	0
#define NATL_DATEFYPOS	6
#else
#define NATL_UNKNOWN	"Unknown"
#define NATL_NONE	"None"
#define NATL_EMULATED	"Emulated"
#define NATL_BUILTIN	"Built In"
#define NATL_DATEFMT	"  -  -  "
#define NATL_DATEFMPOS	0
#define NATL_DATEFDPOS	3
#define NATL_DATEFYPOS	6
#endif

GLOBAL char *Daysofwk[7]
#ifdef GLINIT
= {
#ifdef LANG_GR
	"So ",  "Mo ",  "Di ",  "Mi ",  "Do ",  "Fr ",  "Sa "
#else
	"Sun",  "Mon",  "Tue",  "Wed",  "Thu",  "Fri",  "Sat"
#endif
}
#endif
;

/* If non-zero, number of characters we can take from beginning of month */
#ifdef LANG_GR
#define NATL_MONTH_ABBR 0
#else
#define NATL_MONTH_ABBR 3
#endif

GLOBAL char *Monthsofyr[12]
#ifdef GLINIT
= {
#ifdef LANG_GR
	"Januar",       "Februar",      "M„rz",         "April",
	"Mai",          "Juni",         "Juli",         "August",
	"September",    "Oktober",      "November",     "Dezember"
#else
	"January",      "February",     "March",        "April",
	"May",          "June",         "July",         "August",
	"September",    "October",      "November",     "December"
#endif
}
#endif
;

#ifdef LANG_GR
#define MAXMESSAGEWIDTH 48
#else
#define MAXMESSAGEWIDTH 36
#endif

GLOBAL char *ValPathTerms	/* Valid pathname terminators */
#ifdef GLINIT
= " \t=\"/[]|;,+<>\n"
#endif
;

GLOBAL int SnapshotOnly 	/* For ASQ: use printf output only */
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL char *CfgKeywordSeps	/* *.CFG file keyword delimiters */
#ifdef GLINIT
= " \t=,-\n;*"
#endif
;

GLOBAL char *ProKeywordSeps	/* *.PRO file keyword delimiters */
#ifdef GLINIT
= " \t=,\n;*"
#endif
;

GLOBAL char QComments[80]	/* Comment characters */
#ifdef GLINIT
= ";*"
#endif
;

GLOBAL int TimeoutInput 	/* Wait 30 seconds for input, then */
#ifdef GLINIT			/* accept default */
= 0
#endif
;

GLOBAL long TimeoutDelay	/* Default delay for TimeoutInput in ms */
#ifdef GLINIT
= 30000L			/* 30 seconds */
#endif
;

GLOBAL int TimeoutKey		/* Key returned when TimeoutDelay elapses */
#ifdef GLINIT
= KEY_ENTER
#endif
;

#endif /*  LIBTEXT_INCLUDED	*/

/* We can add static text for individual modules here.	Mbootsel is only */
/* used by SETUP and MAXIMIZE. */
#ifdef LIBTEXT_MBOOTSEL
#undef LIBTEXT_MBOOTSEL

#define NUMMBMENUBUTTONS 2
static BUTTON MBMenuButtons[ NUMMBMENUBUTTONS ] = {
#ifdef LANG_GR
   { { -6, 33 }, 12, "Fertig",{ KEY_ENTER, 'f', 'F', KEY_ALTF }, KEY_ENTER,    TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, TRUE },
#else
   { { -6, 33 }, 12, "OK",{ KEY_ENTER, 'o', 'O', KEY_ALTO }, KEY_ENTER,    TRUE,  TRUE,  0, 1, FG_BLUE | BG_GRAY, TRUE },
#endif
};


#ifdef LANG_GR
#define MENUTITLE " Auswahl der DOS 6 Multiboot-Konfiguration "
#else
#define MENUTITLE " Select DOS 6 MultiConfig Section "
#endif
static char MBMenuTitle[ sizeof( MENUTITLE )] = MENUTITLE;

/*	New bottom of option editor window */
#ifdef LANG_GR
#define MENUBOTTOMTITLE " [\x18 \x19 <ÄÙ] "
#else
#define MENUBOTTOMTITLE " [\x18 \x19 Enter] "
#endif
static char MBMenuBottomTitle[sizeof( MENUBOTTOMTITLE )] = MENUBOTTOMTITLE;

#endif /* LIBTEXT_MBOOTSEL */
