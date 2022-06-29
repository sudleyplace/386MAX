/*' $Header:   P:/PVCS/MAX/INCLUDE/EDITWIN.H_V   1.1   02 Jun 1997 14:37:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * EDITWIN.H								      *
 *									      *
 * Editor window functions header file					      *
 *									      *
 ******************************************************************************/

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

#define VERTBORDER   76
#define MAXSTRING    256
#define MAXMINUS1    MAXSTRING - 1
#define OPTSTRING    12
#define MAXLINES     8190
#define VERTSPACE    2
#define BACKCHAR     '\xdb'

#define KEY_CCLEFT	 0xF900
#define KEY_CCRIGHT	 0XFA00


GLOBAL	 char  *reserve;

GLOBAL	 char  LocalLine[256];

/* pointers, counters and flags for copy, cut and paste */
GLOBAL	 char  **buffer;
GLOBAL	 int   buffrows;
GLOBAL	 int   BLOCK_EXISTS;  /* has a block been copied */

/* pointers, counters and flags for del and bksp deletes */
GLOBAL	 char  **duffer;
GLOBAL	 int   duffrows;
GLOBAL	 int   DELETE_BLOCK_EXISTS;  /* has a block been copied */

GLOBAL	 int   INSERT;	      /* in insert mode */
GLOBAL	 int   VIEW;	      /* are we in view mode */
GLOBAL	 int   BROWSE;	      /* are we in browse mode */
GLOBAL	 int   SAVEON;	      /* is the save button turned on */
GLOBAL	 int   SHIFT;	      /* was the SHIFT key been pressed */
GLOBAL	 int   altPageOK	  /* Should Alt/PGUP and Alt/PGDN return */
#ifdef GLINIT
= FALSE
#endif
;

GLOBAL	 int   FileChanged;
GLOBAL	 int   PageChanged;
GLOBAL	 int   LineChanged[50];

typedef struct _blk {
   int	 row;
   int	 col;
   int	 cur;
} BLOCK;

GLOBAL	 BLOCK mark[4];
GLOBAL	 int   markon, markWasOn;

/*	So print knows what is going on */
GLOBAL	 char *EditorFileName;	/*	Pointer to name of file */

#ifndef BUTTON_INCLUDED
#include <button.h>
#endif

#define EDITF6	0	/* If 1, F6 needed to toggle Edit / R/O */

/* Note that the trigger offsets here go with EditBtext and ViewBtext, and */
/* hence differ from the triggers used in the button definition record. */
#if EDITF6
#ifdef LANG_GR
#define EDIT_BTEXT	"Bearb F6"
#define VIEW_BTEXT	"Lesen F6"
#define EDIT_TRIG	7
#define VIEW_TRIG	7
#else
#define EDIT_BTEXT	"Edit F6"
#define VIEW_BTEXT	"View F6"
#define EDIT_TRIG	6
#define VIEW_TRIG	6
#endif

GLOBAL char *EditBtext
#ifdef GLINIT
= " " EDIT_BTEXT " "
#endif
;

GLOBAL char *ViewBtext
#ifdef GLINIT
= " " VIEW_BTEXT " "
#endif
;
#endif /* EDITF6 */

#if EDITF6
#define NUMEDITBUTTONS 3
#else
#define NUMEDITBUTTONS 2
#endif
GLOBAL BUTTON EditButtons[ NUMEDITBUTTONS ]
#ifdef GLINIT
= {
#if EDITF6
   { { -3, 15 }, 11, EDIT_BTEXT, { KEY_F6, 0, 0, 0 }, KEY_F6,	 FALSE, FALSE, 6, 2, FG_BLUE | BG_GRAY, TRUE },
#endif
#ifdef LANG_GR
   { { -3, 28 }, 12, "Sichern F7", { KEY_F7, 0, 0, 0 }, KEY_F7,    FALSE, FALSE, 8, 2, FG_BLUE | BG_GRAY, TRUE },
   { { -3, 42 }, 11, "Option F8",{ KEY_F8, 0, 0, 0 }, KEY_F8,   FALSE, FALSE, 7, 2, FG_BLUE | BG_GRAY, TRUE },
#else
   { { -3, 28 }, 11, "Save F7", { KEY_F7, 0, 0, 0 }, KEY_F7,    FALSE, FALSE, 5, 2, FG_BLUE | BG_GRAY, TRUE },
   { { -3, 41 }, 11, "Option F8",{ KEY_F8, 0, 0, 0 }, KEY_F8,   FALSE, FALSE, 7, 2, FG_BLUE | BG_GRAY, TRUE },
#endif
}
#endif
;
GLOBAL	 int   TabStop
#ifdef GLINIT
 = 8
#endif
;

/*	moved from FileEdit.c */
GLOBAL char	**EditorLine
#ifdef GLINIT
 = NULL
#endif
;
GLOBAL int	EditorLines;

/*	 Option editor stuff moved to options.h 	*/

/* Text used in FILEEDIT.C */
GLOBAL char MsgFileCol[]
#ifdef GLINIT
#ifdef LANG_GR
 = "Datei: "
#else
 = "File: "
#endif
#endif
;


/* Define Option Editor callbacks and default to NULL (not available) */
GLOBAL char * (*CB_option_editor) (PTEXTWIN, int, int *, int, int)
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL int (*CB_option_replace) (PTEXTWIN, char *, int)
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL int (*CB_option_insert) (PTEXTWIN, char *, int *, char *[], int *)
#ifdef GLINIT
 = NULL
#endif
;

/* Define other callbacks */
GLOBAL int (*highlight_areaCB) (PTEXTWIN, int)
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL int (*save_changesCB) (PTEXTWIN, KEYCODE)
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL int (*cursor3CB) (PTEXTWIN, KEYCODE, int *, char **, int *)
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL int (*cursor4CB) (PTEXTWIN, KEYCODE, int *, int *)
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL int (*cursor5CB) (PTEXTWIN, KEYCODE, int *, char **, int *)
#ifdef GLINIT
 = NULL
#endif
;

GLOBAL int  (*askFileNameCB) (char *)
#ifdef GLINIT
 = NULL /* Function to ask for filename */
#endif
;

GLOBAL int  (*get_pathCB) (void)
#ifdef GLINIT
 = NULL /* Callback to set MAX path */
#endif
;

#undef OWNER


/* routine definitions */



WINRETURN vWinPut_s(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int   row,
   int	 col,
	char *text );			/*	What text to write with default attr */

WINRETURN vWinPut_a(		/*	Write an attribute into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int   row1,	     /* starting row */
   int	 col1,		/* starting column */
	int   row2,	     /* ending row */
   int	 col2,		/* ending column */
	int   attr );			/*	What attribute */

WINRETURN vWinGet_s(		/*	Write a text string into the window */
	PTEXTWIN pText, 		/*	Pointer to text window */
	int   row,
	char *text );			/*	What text to write with default attr */

WINRETURN vWin_edit_ask(	/*	Let a user run around a window */
   PTEXTWIN pText,		   /*	Text window to run around in */
   char  *name, 	   /* full name of file being edited */
   char  *line[],	   /* actual data file */
   int *lines,		      /* number of lines in file */
   int	 help,				/*	Help screen to show */
   int	tutor,			/*	Tutorial to use */
   int	 browseOnly,	   /* are we being called as a browser only */
   int	 newFile);	   /* are we being called with an empty new file */

void paintScrollBar( WINDESC *win, char attr, int max, int current );

WINRETURN NewScroll(		/*	Translate a mouse action into a window movement */
	WINDESC *win,			/* Window that will get the action */
	INPUTEVENT *event,		/*	What mouse event occured */
	int max,				/*	Max number of items */
	int *current ); 		/*	Where we are right now */

int   save_changes(PTEXTWIN, KEYCODE);
int   highlight_area(PTEXTWIN, int);
int   cursor3(PTEXTWIN, KEYCODE, int *, char **, int *);
int   cursor4(PTEXTWIN, KEYCODE, int *, int *);
int   cursor4b(PTEXTWIN, KEYCODE, int *, int *);
int   cursor5(PTEXTWIN, KEYCODE, int *, char **, int *);
char  *salloc(char *);

int	act(PTEXTWIN, WINRETURN);
int	display_status(PTEXTWIN, int);
int	LoadScreen(PTEXTWIN, char **, int, int);
int	lnbc(char *, int);
int   clear(PTEXTWIN);
int   SaveLine(PTEXTWIN, char **, int);

void  CreateEditWindow( void );

int   fileOpen(FILE **fh,char *name,int changeName,int	 *newFile);
int   fileLoad(PTEXTWIN, FILE **, char **, int *);
int   fileSave(char *, char **, int);
int   vWinTitle(PTEXTWIN, char *,char *);


int   lnbc(char *, int);
int   insert_char(PTEXTWIN, int);
int   delete_char(PTEXTWIN);
int   add_line	 (PTEXTWIN, int *, char **, int *);
int   insert_line(PTEXTWIN, int *, char **, int *);
int   delete_line(PTEXTWIN, int *, char **, int *);
int   split_line(PTEXTWIN, int *, char **, int *, int);
int   join_line(PTEXTWIN, int *, char **, int *, int);

int   getLineLength(int);

int   copy_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines);

int   copy_block_delete(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines);

int   cut_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines);

int   paste_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines);

int   paste_block_delete(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines);

int   split_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row,
int	 col);

int   split_block1(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row,
int	 col);

int   join_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row,
int	 type);

int   delete_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row);

int   insert_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row);

int   add_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row);

int   add_block_delete(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row);


void clear_mark(PTEXTWIN pText);
void clear_area(PTEXTWIN pText);


WINRETURN vNew_mouse(		/*	Translate a mouse action into a window movement */
	PTEXTWIN pText, 		/* Window that will get the action */
	INPUTEVENT *event,
   int	 *CurrentLine );	/*	What mouse event occured */



int fixup_corner(
PTEXTWIN pText);

int fixup_cursor(
PTEXTWIN pText);

int   reset_column (
int   *row2,
int   *col2,
int   *cur2);

int insert_remark(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines);

int delete_remark(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines);

int get_path(void);

int insert_sys(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines);

int delete_sys(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines);

int insert_exe(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines);

int delete_exe(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines);

WINRETURN vNew_key(	/*	Take a key and return an appropriate action */
	PTEXTWIN pText, 	/*	Window to consider */
	KEYCODE key );	  /*	Actual key pressed */

int   tablen(	     /* strlen with calculation for TABS */
char  *string);

int askFileName(		/*	Get a file name from the user */
	char *name);		/*	Place to store the name - MAXFILELENGTH long */

