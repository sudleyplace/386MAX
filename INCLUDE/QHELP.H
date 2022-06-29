/*' $Header:   P:/PVCS/MAX/INCLUDE/QHELP.H_V   1.1   02 Jun 1997 14:37:32   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * QHELP.H								      *
 *									      *
 * This file contains all definitions that are related to help		      *
 *									      *
 ******************************************************************************/

#ifndef QHELP_INCLUDED
#define QHELP_INCLUDED

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


#include <qwindows.h>

typedef enum {
	HELP_HELP,				/* QS_H_HLP */
	HELP_ASQHELP,			/* AS_H_HLP */
	HELP_GLOSSARY,			/* AS_G_HLP */
	HELP_ASQLEARN,			/* AS_L_HLP */
	HELP_TUTORIAL,			/* AS_T_HLP */
	HELP_OPTION,			/* QS_O_HLP */
	HELP_QSQUICK,			/* QS_Q_HLP */
	HELP_ASQUICK,			/* AS_Q_HLP */
	HELP_INSTALL,			/* IN_H_HLP */
	HELP_INSTALL_S, 		/* IN_S_HLP */
	HELP_INSTALL_M, 		/* IN_M_HLP */
	HELP_INSTALL_L, 		/* IN_L_HLP */
	HELP_MAXIMIZE,			/* MX_H_HLP */
	HELP_MAXIMIZE_Q,		/* MX_Q_HLP */
	HELP_MAXIMIZE_S,		/* MX_S_HLP */
	HELP_MAXIMIZE_M,		/* MX_M_HLP */
	HELP_MAXIMIZE_L,		/* MX_L_HLP */
	HELP_QS_DATA,			/* QS_D_HLP */
	HELP_AS_DATA,			/* AS_D_HLP */
	HELP_MX_DATA,			/* MX_D_HLP */
	HELP_INSTALL_Q, 		/* IN_Q_HLP */
	HELP_LAST
} HELPTYPE;	/*	Which type of thing to use */

typedef int (*HELPCALLBACK)(int);			/*	Menu callback function */

typedef struct {
	HELPTYPE type;		/*	Which type of thing to use */
	char *context;		/* What to look up */
	long contextNumber;	/* What to look up */
	HELPCALLBACK helpBuild; /* ??? */
} HELPDEF;


typedef struct {	/*	Control structure for loadText/showText */
	int nRows;	/*	Total rows in buffer */
	void far *dBuf; /*	Help text decompression buffer */
} HELPTEXT;

#ifdef LANG_GR
#define HTITLE_HELP	" Hilfe "
#define HTITLE_GLOSSARY " Glossar "
#define HTITLE_LEARN	" Lernen "
#define HTITLE_TUTORIAL " Lernhilfe "
#else
#define HTITLE_HELP	" Help "
#define HTITLE_GLOSSARY " Glossary "
#define HTITLE_LEARN	" Learn "
#define HTITLE_TUTORIAL " Tutorial "
#endif

GLOBAL struct {
	long context;
	long contentsContext;
	long indexContext;
	char *name;
	char *title;
} HelpTitles[ HELP_LAST ]
#ifdef GLINIT
= {
	{ 0, 0, 0, "QS_H_HLP.HLP!", HTITLE_HELP }, /*      Qshell */
	{ 0, 0, 0, "AS_H_HLP.HLP!", HTITLE_HELP }, /*      Asq Help */
	{ 0, 0, 0, "AS_G_HLP.HLP!", HTITLE_GLOSSARY },
	{ 0, 0, 0, "AS_L_HLP.HLP!", HTITLE_LEARN}, /*      Asq Learn stuff */
	{ 0, 0, 0, "AS_T_HLP.HLP!", HTITLE_TUTORIAL}, /*   Asq Tutorial stuff */
	{ 0, 0, 0, "QS_O_HLP.HLP!", NULL },
	{ 0, 0, 0, "QS_Q_HLP.HLP!", NULL },        /*      Quick help for qshell */
	{ 0, 0, 0, "AS_Q_HLP.HLP!", NULL },        /*      Quick help for qshell */
	{ 0, 0, 0, "IN_H_HLP.HLP!", HTITLE_HELP },      /*      Install help */
	{ 0, 0, 0, "IN_S_HLP.HLP!", NULL },     /*      Install small dialogs */
	{ 0, 0, 0, "IN_M_HLP.HLP!", NULL },     /*      Install medium dialogs */
	{ 0, 0, 0, "IN_L_HLP.HLP!", NULL },     /*      Install large dialogs */
	{ 0, 0, 0, "MX_H_HLP.HLP!", HTITLE_HELP },/*    Maximize help */
	{ 0, 0, 0, "MX_Q_HLP.HLP!", NULL },             /*      Maximize Quick help */
	{ 0, 0, 0, "MX_S_HLP.HLP!", NULL },     /*      Maximize small dialogs */
	{ 0, 0, 0, "MX_M_HLP.HLP!", NULL },     /*      Maximize medium dialogs */
	{ 0, 0, 0, "MX_L_HLP.HLP!", NULL },     /*      Maximize large dialogs */
	{ 0, 0, 0, "QS_D_HLP.HLP!", NULL },     /*      QShell dead screen displays */
	{ 0, 0, 0, "AS_D_HLP.HLP!", NULL },     /*      Asq dead screen displays */
	{ 0, 0, 0, "MX_D_HLP.HLP!", NULL },     /*      Maximize dead screen displays */
	{ 0, 0, 0, "IN_Q_HLP.HLP!", NULL },             /*      Install Quick help */
}
#endif
;

GLOBAL int helpSystem;
GLOBAL int PrintableHelp;

GLOBAL int HelpArgCnt		   /* Argument count */
#ifdef GLINIT
= 0
#endif
;
GLOBAL int HelpTopicCnt
#ifdef GLINIT
= 0
#endif
;

GLOBAL char **HelpArgTo;	/* These bad boys are supposed to point */
GLOBAL char **HelpArgFrom;	/* to an array of pointers that might	*/
				/* get changed later -HG		*/

void endHelp( void );		/*	Kill all parts of the help system */

WINRETURN loadHelp(		/*	Create a text window */
		PTEXTWIN fWin,		/*	Pointer to text window */
		WINDESC *win,		/* Window descriptor */
		HELPTYPE *type, 	/* Where to start looking by type */
		long context,		/*	Which help text structure to use */
		char attr,			/*	Default Attribute */
		SHADOWTYPE shadow,	/*	Should this have a shadow */
		BORDERTYPE border,	/*	Single line border */
		int vScroll,		/*	Vertical Scroll bars */
		int hScroll,		/*	Horizontal scroll bars */
		int remember);		/*	Should we remember what was below */

void showHelp(				/*	How the help screen */
	int helpNumber, 	/*	What help screen to show */
	int fromPrint );	/*	Is print calling this */
void showDataHelp(	/*	Load the quick help window with this info */
	int helpNumber );	/*	What context to grab */
void showQuickHelp(	/*	Load the quick help window with this info */
	int helpNumber );	/*	What context to grab */

int startHelp( char *helpName, int numContexts ); /*	Open up the help file system */


int loadText(				/*	Load text from help file */
		HELPTEXT *htext,	/* Control structure to be filled in */
		HELPTYPE type,		/* Where to start looking by type */
		char *context); 	/*	Which help text structure to use */

void showText(				/*	Load text from help file */
		HELPTEXT *htext,	/* Control structure from loadText */
		WINDESC *win,		/* Descriptor of target window */
		char *attr,		/*	Attribute translation array (see HelpColors) */
		void (*callback)(WINDESC *win, WORD *line)); /* Callback function if not NULL */

void setHelpArgs(		/* Set help argument list */
	int argcnt,		/* Argument count */
	char **argfrom, 	/* Array of from (or tag) strings */
	char **argto);		/* Array of to (or substitution strings) */

long setHelp(				/*	Do all the decompression for a specific help */
	HELPTYPE hType, 		/*	Which file to look in */
	char *contextString,	/*	What to get */
	long *prev,			/*	Where to put previous context if any */
	long *next );			/*	Where to put next context if any */

long contextHelp (			/*	Set the help print based on this context */
	HELPTYPE hType, 		/*	Which file to look in */
	long context,
	long *prev,			/*	Where to put previous context if any */
	long *next );			/*	Where to put next context if any */

long nextContextHelp (		/*	Return the next context in file */
	HELPTYPE hType, 		/*	Which file to look in */
	long context ); 		/*	Where we are now */

int getHelpLine(			/*	Get a line of text from a decompressed area */
	int row,				/*	Which row to fetch */
	char *line );			/*	Where to put the line - Assumed large enough */

void freeHelp( void );		/*	Release the decompressed help record */

void freeCallbackHelp( void );	/*	Release the low level alloc */

void help_argsubs(
	WORD *	 dst,		/* destination */
	WORD *	 src,		/* source */
	int len);		/* length of source and dest */

#endif /* QHELP_INCLUDED */

