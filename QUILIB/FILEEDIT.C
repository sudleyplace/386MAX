/*' $Header:   P:/PVCS/MAX/QUILIB/FILEEDIT.C_V   1.0   05 Sep 1995 17:02:06   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * FILEEDIT.C								      *
 *									      *
 * Display the file edit screen 					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <string.h>
#include <stdio.h>
#include <io.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <errno.h>
#include <ctype.h>

/*	Program Includes */

#include "button.h"
#include "commfunc.h"
#include "keyboard.h"
#include "message.h"
#include "ui.h"
#include "libcolor.h"
#include "libtext.h"
#include "myalloc.h"

#define OWNER
#include "editwin.h"

#define TABTEST

extern	 WINRETURN tWinPut_c(		/*	Write a text string into the window */
PTEXTWIN pText, 		/*	Pointer to text window */
WINDESC *win,			/*	Window to spray text into */
char *text );			/*	What text to write with default attr */

extern	 WINRETURN tWin_show(	/*	Dump the video buffer to screen USING TABS */
PTEXTWIN pText, 	/*	Text window to show in */
WINDESC *win ); /*	Subset to show */

WINRETURN ttWinPut_c(	/*	Write a text string into the window */
PTEXTWIN pText, 		/*	Pointer to text window */
WINDESC *win,			/*	Window to spray text into */
char *text ,			/*	What text to write with default attr */
int   len);	     /* actual length of characters (not expanded TABS) */


int   checkFileName(char *);
char  *SpecialSearchStr = NULL; /* Search for Ctrl-F5 */

/*	Definitions for this Module */

/*	Handy place to get the parameters for the left data window */
WINDESC EditWin;
/*	Handy place for the right Quick help window */
WINDESC QuickWin;

/*	Program Code */
/**
*
* Name		fileEdit - Edit a file by showing it on the screen
*
* Synopsis		int fileEdit( int help, int tutor, char *name )
*
* Parameters
*		int help			what help number to use
*		int tutor			which tutorial to show
*		char *name			name of file to edit.
*		int browseOnly			TRUE for browse only
*		char *xtitle			extra title text if not NULL
*
* Description
*		Call the ui function to paint the main screens up
*	This means that it will return all sorts of information about the main
*	windows
*	NULL for a file name implies that user can set it.
*
* Returns	0 for no errors - 1 for an error exit
*
* Version	1.0
*/
#pragma optimize ("leg",off)
int fileEdit( int help, int tutor, char *name , int browseOnly, char *xtitle)
{
	static char otherName[MAXFILELENGTH] = {
		'\0'    };
	char *workingName;

	FILE *fh = NULL;
	int result, i;
	int oldButtons;
	WINRETURN winReturn = 0;
	int newFile = FALSE;

	workingName = name ? name : otherName;

	if (xtitle && *xtitle)	SpecialSearchStr = xtitle;
	else			SpecialSearchStr = NULL;

	EditorLines = 0;
	if ( (EditorLine = my_calloc(8192, sizeof(char *))) == NULL) {
		errorMessage( WIN_NOMEMORY);	/* Insufficient Memory */
		goto error;
	}

	if ( (reserve = my_calloc(1000, sizeof(char))) == NULL) {
		errorMessage( WIN_NOMEMORY);	/* Insufficient Memory */
		goto error;
	}

	/* get 386 max path */
	if (get_pathCB) (*get_pathCB) ();


	result = fileOpen(&fh, workingName, name == NULL , &newFile);
	if (!result)
		goto error;

	CreateEditWindow( );

	INSERT = 1;
	if (newFile) set_cursor(fat_cursor());
	else	     set_cursor(thin_cursor());

	BLOCK_EXISTS = 0;
	buffrows = 0;
	duffrows = 0;

	if( fh ) {
		int winError;
		TEXTWIN fWin;

		/*	Open the Virtual window
		*/
		winError = vWin_create( /*	Create a text window */
		&fWin,			/*	Pointer to text window */
		&EditWin,		/* Window descriptor */
		EditWin.nrows + 1,	/*	How many rows in the window*/
		MAXSTRING,		/*	How wide is the window */
		EditorDataColor,	/*	Default Attribute */
		SHADOW_DOUBLE,		/*	Should this have a shadow */
		BORDER_BLANK,		/*	Single line border */
		TRUE, TRUE,		/*	Scroll bars */
		TRUE,			/*	Should we remember what was below */
		FALSE );		/*	Is this window delayed */

		if( winError == WIN_OK ) {
			vWinTitle(&fWin, workingName,xtitle);

			result = fileLoad(&fWin, &fh, EditorLine, &EditorLines);
			fclose( fh );
			fh = NULL;

			if (!result) {
				if (reserve) {
					my_free(reserve);
					reserve = NULL;
				}
				errorMessage( 207 ); /* Insufficient Memory */
				vWin_destroy( &fWin );
				goto error;
			} /* Failed to load everything into memory */

			/*	Enable the current existing print button */

			if (!browseOnly) {
				addButton( EditButtons, NUMEDITBUTTONS, &oldButtons );
			}
			if( altPageOK )
				addButton( DataButtons, NUMDATABUTTONS, &oldButtons );

			disableButton( KEY_F2, FALSE );

			showAllButtons();

			winReturn = vWin_edit_ask(&fWin,
				workingName,
				EditorLine,
				&EditorLines,
				help,
				tutor,
				browseOnly,
				newFile);

			/*	Put things back and release the space */
			/* free up buffer space */
			for (i = 0; i < EditorLines; i++) {
				if( EditorLine[i] )
					my_free(EditorLine[i]);
			}

			if( EditorLine )
				my_free(EditorLine);
			EditorLine = NULL;
			if( reserve )
				my_free( reserve );
			reserve = NULL;

			if (buffrows) {
				for (i = 0; i < buffrows; i++) {
					if (buffer[i]) my_free(buffer[i]);
				}
				my_free(buffer);
			}
			if (duffrows) {
				for (i = 0; i < duffrows; i++) {
					if (duffer[i]) my_free(duffer[i]);
				}
				my_free(duffer);
			}

			if (!browseOnly) {
				dropButton(EditButtons, NUMEDITBUTTONS);
			}
			if( altPageOK )
				dropButton( DataButtons, NUMDATABUTTONS );
			vWin_destroy( &fWin );
		}
		else {
			errorMessage( WIN_NOMEMORY);
			goto error;
		}
	}
	return winReturn;

error:

	for (i = 0; i < EditorLines; i++) {
		if( EditorLine[i] )
			my_free(EditorLine[i]);
	}
	if( EditorLine )
		my_free( EditorLine );
	EditorLine = NULL;
	if( reserve )
		my_free( reserve );
	reserve = NULL;

	if( fh )
		fclose( fh );


	if (!globalReserve) {
		/* allocate a 1K universal reserve buffer */
		globalReserve = my_malloc(1000);
	}

	return (1);
}
#pragma optimize ("",on)

int   getLineLength(
int line_number)
{
	return(strlen(EditorLine[line_number]));
}

int   vWinTitle(
PTEXTWIN fWin,
char	 *filename,
char *xtitle)
{
	char	string[60];
	int length, len, pos;
	WINDESC tempWin;

	length = strlen(filename);
	if (length < fWin->win.ncols - 22) {
		strcpy(string, MsgFileCol);
		strcat(string, filename);
		length += strlen(MsgFileCol);
	}
	else if (length < fWin->win.ncols - 16) {
		strcpy(string, filename);
	}
	else {
		len = fWin->win.ncols - 20;   /* was 17 */
		pos = length - len;
		length = len + 3;

		strcpy(string,"...");
		strncpy(string+3, filename+pos, len);
		string[length] = '\0';
	}

	if (xtitle) {
		int xlength = strlen(xtitle);

		if (xlength > 0 && xlength+length+1 < fWin->win.ncols - 22) {
			strcat(string," ");
			strcat(string,xtitle);
			length += xlength+1;
		}
	}

	tempWin.row = fWin->win.row-1;
	tempWin.nrows = 1;
	tempWin.ncols = length;

	tempWin.col = fWin->win.col + (fWin->win.ncols - 16 - length) / 2;

	/*	Blast out the text */
	wput_csa( &tempWin, string, EditorHighColor);

	/*
	if( triggerPos != -1 ) {
	tempWin.col += triggerPos;
	tempWin.ncols = 1;
	wput_a( &tempWin, &tAttr );
	}
	*/

	return(0);
}

int   fileLoad(
PTEXTWIN fWin,
FILE **fh,
char *line[],
int *lines)
{
	int   len, error = 0;
	char tmp[MAXSTRING+2];
	WINDESC tempWin;
	SETWINDOW( &tempWin, 0, 0, 1, MAXSTRING );  /* new 7/14  was -1 */

	for( ;; ) {
		if( fgets( tmp, MAXSTRING + 2, *fh ) == NULL ) {

			/*	error occured reading the file */
			if( feof( *fh ) ) {
				if (error) errorMessage( 216  ); /* Insufficient Memory */
				return 1;
			}
			else {
				/*	Else legitimate error */
				errorMessage( 206 );
				break;
			}
		}
		len = strlen(tmp);
		if (len > 0) {
			if (tmp[len-1] == '\n') {
				tmp[len-1] = '\0';     /* if newline left in line */
			}
		}
		if ( (line[(*lines)++] = salloc(tmp)) == NULL) {
			return(0);
		}
		if (*lines >= MAXLINES + 1) {
			return(0);
		}
		if (*lines < EditWin.nrows - 1) {
#ifdef TABTEST
			len = tempWin.ncols = tablen( tmp );
			ttWinPut_c( fWin, &tempWin, tmp , strlen(tmp));
#else
			len = tempWin.ncols = strlen( tmp );
			*/  /* ??? jhk	was -1*/
			vWinPut_c( fWin, &tempWin, tmp );
#endif
			tempWin.row++;
		}
		else {
#ifdef TABTEST
			len = tablen(tmp);
#else
			len = strlen(tmp);
#endif
		}
		if (len > MAXSTRING) error++;
	}
	return(0);
}

int   fileSave(
char  *name,
char  *line[],
int   lines)
{
	FILE *fh = NULL;
	int   i;

	fh = fopen ( name, "w+b");

	if (!fh) {
		errorMessage( 201 ); /* Unable to open file */
		return(0);
	}

	for (i = 0; i < lines; i++) {
		if (line[i]) fputs( line[i],  fh);
		fputs("\r\n", fh);
	}

	fclose(fh);
	fh = NULL;

	return(1);
}

int   fileOpen(
FILE **fh,
char *name,
int changeName,
int   *newFile)
{
	/* try to open file */
	int badName = changeName;
	int create = 0;
	int	 result, i, j, maxk;
	long  available;

	struct stat buf;

	*newFile = FALSE;

	while (!(*fh)) {
		while (badName || strlen(name) == 0 || name[0] == ' ') {
			/* message box for file name */
			/* open file */
			badName = FALSE;
			if (!askFileNameCB ||
				(*askFileNameCB) ( name ) == KEY_ESCAPE )
				return 0;
		}

		result = stat( name, &buf);

		if (result != 0) {	/* File or path not found */
			if( !changeName ) {
				errorMessage(200); /* File or path not found */
				return(0);
			}
			create = askMessage( 209 );
			if (toupper (create) != RESP_YES) {
				badName = TRUE;
				continue;	/*	Go around again */
			}
			else {
				/* check the file name */
				if (!checkFileName(name)) {
					errorMessage( 213 ); /* Unable to open file */
					badName = TRUE;
					continue;	/* Go around again */
				}

				*fh = fopen ( name, "w+");
				if (*fh) {
					fputs("\n", *fh);
					fclose(*fh);
					*fh = fopen ( name, "r+");
					*newFile = TRUE;
					return(1);
				}
				else {
					errorMessage( 201 ); /* Unable to open file */
					badName = TRUE;
					continue;	/* Go around again */
				}
			}
		}

		i = 0;
		maxk =	(int) (buf.st_size / 1000L) +
			(int)(buf.st_size / 10000L) + 1;
		for (j = 0; j < maxk; j++) {
			EditorLine[j] = my_malloc(1000);
			if (EditorLine[j] != NULL) {
				i = j + 1;
			}
		}
		for (j = 0; j < i; j++) {
			if (EditorLine[j]) my_free (EditorLine[j]);
		}
		available = (long)i * 1000L;

		if ( buf.st_size > available) {     /* was 200000 */
			/* check buf.st_size against memory available */

			errorMessage( 207 );	/*	File too large */
			badName = TRUE;
		}
		else if ( (access(name, 0)) == -1) {
			errorMessage( 200 );	/* File or path not found */
			badName = TRUE;
		}
		else if ( (access(name, 6)) == -1) {
			errorMessage( 208 );	/* you don't have write permission */
			badName = TRUE;
		}
		else {
			*fh = fopen ( name, "r+");

			if (!*fh) {
				errorMessage( 201 ); /* Unable to open file */
				badName = TRUE;
			}
		}
		if( badName && !changeName )
			return(0);
	}
	return(1);
}

/**
*
* Name		CreateEditWindow
*
* Synopsis	void CreateEditWindow( void )
*
* Parameters
*		none
*
* Description
*		This routine draws in the basic background screen for the file editor.
*
* Returns	It ALWAYS works.
*
* Version	1.0  copied directly from paintBackgroundScreen in UI.C
*/
void CreateEditWindow( void )
{

	SETWINDOW( &EditWin, 2,1, ScreenSize.row, VERTBORDER );
	EditWin.row = 2;
	EditWin.col = 1;
	EditWin.nrows -=5;
	EditWin.ncols = VERTBORDER;
}

char  *salloc(char *s)	/* make a duplicate of s */
{
	char  *p;

	p = (char *) my_malloc(strlen(s) + 1);	  /* +1 for '\0' */
	if (p != NULL) {
		strcpy(p, s);
	}
	else {
		/* Don't try to use the reserve; save it for displaying */
		/* error messages. */
		if (reserve) {
/*			errorMessage( 214 );  /* Low on memory */
			my_free(reserve);
			reserve = NULL;
/*			p = (char *) my_malloc(strlen(s) + 1);	  /* +1 for '\0' */
/*			if (p != NULL) {	*/
/*				strcpy(p, s);	*/
/*			}			*/
		}
/*		else {				*/
			/* you are completely out of memory */
			errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
/*		}				*/
	} /* Out of memory */
	return(p);
}

int   checkFileName(
char  *name)
{
	char  *cp, *dot;

	cp = strrchr(name,'\\');
	if (!cp) {
		cp = strrchr(name, ':');
		if (!cp) cp = name;
	}
	if (cp != name) cp++;

	if (strlen(cp) > 12) return(0);
	dot = strchr(cp,'.');
	if (dot) {
		if (dot - cp > 8) return(0);
		dot++;
		if (strlen(dot) > 3) return(0);
	}

	while (*cp) {
		if (*cp <= ' ') return(0);
		if (strchr("\"+,/;<=>[\\]",*cp)) return(0);
		cp++;
	}

	return(1);
}

int   tablen(	     /* strlen with calculation for TABS */
char  *string)
{
	int   len = 0;
	char *cp = string;

	while (*cp) {
		if (*cp == 9) {
			len += (TabStop - 1) - (len % TabStop);
		}
		len++;
		cp++;
	}
	return(len);
}

/**
*
* Name		ttWinPut_c - Write a string of text into the memory /video
*		space.	If the end of a line, just wrap to the next line.
*
* Synopsis	WINRETURN ttWinPut_c(PTEXTWIN pText, WINDESC *win, char *text )
*
*
* Parameters
*	PTEXTWIN pText; 			Pointer to text window
*	WINDESC *win;				Window to use
*	char *text );				What text to write with default attr
*
* Description
*		Put text into the video image as required.	Keep track of
*	where we went so we can through it out on the screen if what
*	we wrote if visible.  If the text win is <= real win, we just adjust
*	the start and drop into wput_c.
*
* Returns	WIN_OK for no errors
*
* Version	1.0
*/
WINRETURN ttWinPut_c(	/*	Write a text string into the window */
PTEXTWIN pText, 		/*	Pointer to text window */
WINDESC *win,			/*	Window to spray text into */
char *text ,			/*	What text to write with default attr */
int	 len)	       /* actual length of characters (not expanded TABS) */
{
	PCELL startPos;

	int nrows, ncols;
	startPos = pText->data + (win->row * pText->size.col + win->col);

	/*	Now will fit in window */
	for( nrows = win->nrows; nrows; nrows-- ) {
		PCELL thisCell = startPos;
		for( ncols = 0; ncols < len; ncols++ ) {
			thisCell++->ch = *text++;
		}
		startPos += pText->size.col;
	}
	/*	Now dump the modified part out to the real screen */
	if( pText->delayed )
		return WIN_OK;
	else
#ifdef TABTEST
		tWin_show( pText, win );
#else
	vWin_show( pText, win );
#endif
}
