/*' $Header:   P:/PVCS/MAX/QUILIB/CURSOR.C_V   1.0   05 Sep 1995 17:02:00   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CURSOR.C								      *
 *									      *
 * Standard cursor movement and editing functions			      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>

/*	Program Includes */
#include "button.h"
#include "commfunc.h"
#include "qwindows.h"
#include "ui.h"
#include "windowfn.h"
#include "keyboard.h"
#include "video.h"
#include "fldedit.h"
#include "message.h"
#include "libtext.h"
#include "libcolor.h"
#include "myalloc.h"
#include "editwin.h"

#define OWNER
#include "asqshare.h"
#include "edittext.h"
#undef OWNER

#define TABTEST

extern	 int   locate_display(
   PTEXTWIN pText,
   int	 row,
   int	 col);

extern int   locate_cursor(
   PTEXTWIN pText,
   int	 row,
   int	 col);

extern char  *SpecialSearchStr; /* From FILEEDIT.C: Search for Ctrl-F5 */

int get_path(void)
{
   char  path[256];
	char *bslash;

	strcpy( path, MAXName);
	bslash = strrchr(path, '\\');
	if (bslash) *(++bslash) = '\0';

   PathLength = strlen(path);
   return(PathLength);
}

int insert_sys(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines)
{
   int	 start = *CurrentLine + pText->cursor.row;
   int	 i = *lines;
   char  tmp[MAXSTRING+1], *t;
   int	 whiteSpace = 0;
   int	 PostEqual;

   if (VIEW) return(1);

   if (!line[start]) {
      beep();
      return(1);
   }

   strcpy(tmp, line[start]);
   strupr(tmp);

   whiteSpace = strspn(line[start], " \t");

   if (memicmp(line[start]+whiteSpace, device, DEVICELEN) ||
	/* Is character after DEVICE not a valid separator? */
	!strchr (ValPathTerms, line[start][whiteSpace+DEVICELEN])) {
      beep();
      return(1);
   }

   /* Find out how far it is to the start of the line */
   PostEqual = strspn(line[start]+whiteSpace+DEVICELEN, ValPathTerms);

   strcpy(tmp, line[start]);
   strupr(tmp);
   if (strstr(tmp, "386LOAD.SYS ") != NULL || strstr(tmp, "PROG=") != NULL) return(1);

   if (tablen(line[start]) + PathLength > 0 ? PathLength : 2 +
      tablen(load386sys) + tablen(getsize) + tablen(device)
      < MAXSTRING) {

      if (PathLength == 0) {
	 askMessage( 212 );   /* Inform user that we cant find path */
      }

      /* Copy original line back to preserve case */
      strcpy (tmp, line[start]);
      tmp[whiteSpace + DEVICELEN + PostEqual] = '\0';

      if (PathLength) strncat(tmp, MAXName, PathLength);
      else	      strcat(tmp, "##\\");

      strcat(tmp, load386sys);
      strcat(tmp, getsize);
      strcat(tmp, line[start] + whiteSpace + DEVICELEN + PostEqual); /* Original line after DEVICE*=* */

      if ((t = salloc(tmp)) == NULL) return(0);    /* was NULL */
      my_free(line[start]);
      line[start] = t;
      return(4);
   }
   else beep();

   return(1);
}

int delete_sys(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines)
{
   int	 start = *CurrentLine + pText->cursor.row;
   int	len = *lines;
   char  *t;
   int	 whiteSpace = 0;
   char *sysptr;
   int	 PostEqual;

   if (VIEW) return(1);

   if (!line[start]) {
      beep();
      return(1);
   }

   whiteSpace = strspn(line[start], " \t");

   if (memicmp(line[start]+whiteSpace, device, DEVICELEN) ||
	/* Is character after DEVICE not a valid separator? */
	!strchr (ValPathTerms, line[start][whiteSpace+DEVICELEN])) {
      beep();
      return(1);
   }

   /* Find out how far it is to the start of the line */
   PostEqual = strspn(line[start]+whiteSpace+DEVICELEN, ValPathTerms);

   {
      char  tmp[MAXSTRING+1];
      char  *p;

      strcpy(tmp, line[start]);
      strupr(tmp);

      if ((sysptr = strstr(tmp, "386LOAD.SYS")) == NULL) {
	 beep();
	 return(1);
      }

      p = strstr(sysptr, "PROG=");
      if (p == NULL) {
	 beep();
	 return(1);
      }

      /* Preserve case by re-copying original DEVICE = */
      strncpy (tmp, line[start], whiteSpace + DEVICELEN + PostEqual);
      tmp [whiteSpace + DEVICELEN + PostEqual] = '\0';
      strcat (tmp, p+5);

      if ((t = salloc(tmp)) == NULL) return(0);    /* was NULL */
      my_free(line[start]);
      line[start] = t;
   }

   return(4);
}

int insert_exe(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines)
{
   int	 start = *CurrentLine + pText->cursor.row;
   int	 i = *lines;
   char  tmp[MAXSTRING+1];
   char  *t;
   int	 whiteSpace = 0;

   if (VIEW) return(1);

   if (!line[start]) {
      beep();
      return(1);
   }

   strcpy(tmp, line[start]);
   strupr(tmp);

   whiteSpace = strspn(line[start], " \t");

   if (strstr(tmp, "386LOAD ") != NULL || strstr(tmp, "PROG=") != NULL) return(1);

   if (tablen(line[start]) + PathLength > 0 ? PathLength : 2 +
      tablen(load386exe) + tablen(getsize)
      < MAXSTRING) {

      if (PathLength == 0) {
	 askMessage( 212 );   /* Inform user that we cant find path */
      }

      tmp[whiteSpace] = '\0';

      if (PathLength) strncat(tmp, MAXName, PathLength);
      else	      strcat(tmp, "##\\");

      strcat(tmp, load386exe);
      strcat(tmp, getsize);
      strcat(tmp, line[start] + whiteSpace); /* was just line[start] */

      if ((t = salloc(tmp)) == NULL) return(0);    /* was NULL */
      my_free(line[start]);
      line[start] = t;
      return(4);
   }
   else beep();

   return(1);
}

int delete_exe(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines)
{
   int	 start = *CurrentLine + pText->cursor.row;
   int	len = *lines;
   char  *t;
   int	 whiteSpace = 0;

   if (VIEW) return(1);

   if (!line[start]) {
      beep();
      return(1);
   }

   whiteSpace = strspn(line[start], " \t");

   {
      char  tmp[MAXSTRING+1];
      char  *p;

      strcpy(tmp, line[start]);
      strupr(tmp);

      if (strstr(tmp, "386LOAD ") == NULL) {
	 beep();
	 return(1);
      }

      p = strstr(tmp, "PROG=");
      if (p == NULL) {
	 beep();
	 return(1);
      }

      tmp[whiteSpace] = '\0';

      strcat(tmp, p+5);
      if ((t = salloc(tmp)) == NULL) return(0);    /* was NULL */
      line[start] = t;
      my_free(line[start]);
   }

   return(4);
}

int insert_remark(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines)
{
   int	 start = *CurrentLine + pText->cursor.row;
   int	 i = *lines;
   char  *t;

   if (VIEW) return(0);

   if (!line[start]) {
      if ((line[start] = salloc("REM")) == NULL) return(0);        /* was NULL */
   }
   else {
      if (tablen(line[start]) < MAXSTRING - 4) {
	 char tmp[MAXSTRING+1];

	 if (!memicmp(line[start], "REM ", 4)) return(1);

	 strcpy(tmp, "REM ");
	 strcat(tmp, line[start]);

	 if ((t = salloc(tmp)) == NULL) return(0);	   /* was NULL */
	 my_free(line[start]);
	 line[start] = t;
      }
      else {
	 beep();
	 return(1);
      }
   }

   return(4);
}

int delete_remark(
PTEXTWIN pText,
int   *CurrentLine,
char  *line[],
int   *lines)
{
   int	 start = *CurrentLine + pText->cursor.row;
   int	i = *lines;
   char  *t;

   if (VIEW) return(0);

   if (!line[start]) {
      return(0);
   }

   if (!memicmp(line[start], "REM ", 4)) {
      char  tmp[MAXSTRING+1];
      strcpy(tmp, line[start]+4);

      if ((t = salloc(tmp)) == NULL) return(0);    /* was NULL */
      my_free(line[start]);
      line[start] = t;
   }

   return(4);
}

/* Find target and (if found) update current position. */
/* If no target specified, ask for one. */
int search_text (char *target,		/* String to search for */
		PTEXTWIN pText, 	/* Window */
		int *pwCLine,		/* Current line (origin:0) */
		char **ppszData,	/* File data */
		int cLines)		/* Number of lines */
{
  int current;
  char **ppsz;
  char temp[256];
  char targtmp[80];
  char *findloc;
  int startoff;
#if 0
  static char lastsrch[80] = {0};

  /* Use last search specified as default */
  /* If we find it, mark it for editing. */
  if (!target) {
  } /* Ask what to search for */
  target = lastsrch;
#endif
  strcpy (targtmp, target);
  strlwr (targtmp);

  temp[sizeof(temp)-1] = '\0';
  startoff = pText->cursor.col;
  /* Start from current position and search till end of file */
  for (current = *pwCLine, ppsz = &ppszData[*pwCLine];
	current < cLines;
	current++, ppsz++) {
    strncpy (temp, *ppsz, sizeof(temp)-1);
    strlwr (temp);
    if (startoff < (int) strlen (temp)) {
	if (findloc = strstr (temp+startoff, targtmp)) goto foundit;
    } /* Cursor is within current line */
    startoff = 0;
  }

  /* If we didn't find it, try again from the start of the file */
  for (current = 0, ppsz = ppszData;
	current < *pwCLine;
	current++, ppsz++) {
    strncpy (temp, *ppsz, sizeof(temp)-1);
    strlwr (temp);
    if (findloc = strstr (temp, targtmp)) goto foundit;
  }

  /* Try again with colon prepended */
  if (
#if 0
	target != lastsrch &&
#endif
	strchr (targtmp, '[')) {
	sprintf (temp, ":%s", strtok (targtmp, "[]\n"));
	return (search_text (temp, pText, pwCLine, ppszData, cLines));
  } /* Try search with colon appendix (ha ha ha) */

  return (0);

foundit:
#if 0
  if (target == lastsrch) {
	return (4);
  } /* target specified interactively - highlight it */
  else {
#endif
	*pwCLine = current;
	pText->cursor.col = (int) (findloc + strlen (targtmp) - temp);
	return (3);
#if 0
  } /* target passed on command line - position on next line */
#endif
} /* search_text */

#pragma optimize ("leg",off)
int   cursor3(
PTEXTWIN pText,
KEYCODE c,
int   *CurrentLine,
char  *line[],
int   *lines)
{
   int	 display;

   display = *lines;

   if (VIEW) return(0);

   switch (c) {
   case KEY_SF3 :
      display = insert_remark(pText, CurrentLine, line, lines);
      if (display == 4) FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
      return(display);
   case KEY_SF4 :
      display = delete_remark(pText, CurrentLine, line, lines);
      if (display == 4) FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
      return(display);
   case KEY_SF5:
      display = insert_sys(pText, CurrentLine, line, lines);
      if (display == 4) FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
      return(display);
   case KEY_SF6:
      display = delete_sys(pText, CurrentLine, line, lines);
      if (display == 4) FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
      return(display);
   case KEY_SF7:
      display = insert_exe(pText, CurrentLine, line, lines);
      if (display == 4) FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
      return(display);
   case KEY_SF8:
      display = delete_exe(pText, CurrentLine, line, lines);
      if (display == 4) FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
      return(display);
   }

   if (!SHIFT && c == KEY_BKSP && markon) {
      /* delete marked text */
      FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;

      if (!(display = copy_block_delete(pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
	 clear_mark(pText);
	 return(4);
      }
      if (!(display = cut_block (pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
	 clear_mark(pText);
	 return(4);
      }

      DELETE_BLOCK_EXISTS = 1;

      mark[2].row = mark[0].row;
      mark[2].col = mark[0].col;
      mark[2].cur = mark[0].cur;

      clear_mark(pText);

      return(4);
   }
   if (!SHIFT && c == KEY_DEL && markon) {
      /* delete marked text */
      FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;

      if (!(display = copy_block_delete(pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
	 clear_mark(pText);
	 return(4);
      }
      if (!(display = cut_block (pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
	 clear_mark(pText);
	 return(4);
      }

      DELETE_BLOCK_EXISTS = 1;

      mark[2].row = mark[0].row;
      mark[2].col = mark[0].col;
      mark[2].cur = mark[0].cur;

      clear_mark(pText);

      return(4);
   }
   if (SHIFT && c == KEY_DEL && markon) { /* cut block */
      FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;

      if (!(display = copy_block(pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
	 clear_mark(pText);
	 return(4);
      }
      if (!(display = cut_block (pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
	 clear_mark(pText);
	 return(4);
      }

      BLOCK_EXISTS = 1;

      clear_mark(pText);

      return(4);
   }
   if (SHIFT && c == KEY_INS && BLOCK_EXISTS) { /* paste block */
      FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;

      if (!(display = paste_block(pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
      }

      clear_mark(pText);

      return(4);
   }
   if (c == KEY_CINS && markon) {	/* copy block */

      if(!(display = copy_block(pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
      }

      BLOCK_EXISTS = 1;

      clear_mark(pText);

      return(3);
   }
   if (c == KEY_ALTBKSP && DELETE_BLOCK_EXISTS) {	  /* undo block cut */
      FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;

      if (mark[2].row < *lines) {
	 pText->cursor.row = mark[2].row - mark[2].cur;
	 pText->cursor.col = mark[2].col;
	 *CurrentLine	  = mark[2].cur;
      }
      else {
	 errorMessage( 9 );	/* Cant Do it */
	 return(1);
      }

      if (!(display = paste_block_delete(pText, CurrentLine, line, lines))) {
		   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */
      }

      DELETE_BLOCK_EXISTS = 0;

      clear_mark(pText);

      return(4);
   }
   if (c == KEY_F3 && !markon) {
      markon = 1;

      mark[0].row = mark[1].row = *CurrentLine + pText->cursor.row;
      mark[0].col = mark[1].col = pText->cursor.col;
      mark[0].cur = mark[1].cur = *CurrentLine;

      /* change cursor */
      highlight_area(pText, *CurrentLine);

      return(1);
   }
   if (c == KEY_F3 && markon) {
      return(0);
   }
   if (c == 0) {
      if (markon) {
	 /* un mark all columns */

	 clear_mark(pText);

	 return(3);
      }
      return(0);
   }
   if (c == KEY_F4 && !markon) {
      /* blank out space first */

      clear_mark(pText);

      markon = 1;
      mark[0].row = mark[1].row = *CurrentLine + pText->cursor.row;
      mark[0].col = mark[1].col = pText->cursor.col;
      mark[0].cur = mark[1].cur = *CurrentLine;

      highlight_area(pText, *CurrentLine);

      return(2);
   }
   if (c == KEY_F4) {
      highlight_area(pText, *CurrentLine);
      return(3);
   }
   if (c == KEY_CF5 && SpecialSearchStr) {
	return (search_text (SpecialSearchStr, pText, CurrentLine, line,
			*lines));
   } /* Find next MultiConfig header */
#if 0
   if (c == KEY_F5) {
	return (search_text (NULL, pText, CurrentLine, line, *lines));
   } /* Find text */
#endif
   if (markon) {
      /* un mark all columns */

      clear_mark(pText);

      return(3);
   }
   return(0);
}
#pragma optimize ("",on)

int highlight_area(
PTEXTWIN pText,
int	 CurrentLine)
{
   int	 row0 = 0, col0 = 0;  /* where we are now */
   int	 row1 = 0, col1 = 0;  /* where we started */
   int	 row2 = 0, col2 = 0;  /* where we last were */
   int	 direction;

   /* first do this to find out if we need to restore any of
      the previous attributes because we moved backwards

      then do this from the initial point forwards */

/* phase I */

   /* figure where we are from original point */
   row1 = mark[0].row;
   col1 = mark[0].col;

   if (row1 < CurrentLine) {
      row1 = 0;
      col1 = 0;
   }
   else if (row1 == CurrentLine) {
      row1 = 0;
   }
   else if (row1 > CurrentLine + pText->win.nrows - 1) {
      row1 = pText->win.nrows - 1;
      col1 = pText->win.ncols - 1;
   }
   else if (row1 > CurrentLine) {
      row1 = row1 - CurrentLine;
   }

   /* figure where we are from previous point */
   row2 = mark[1].row;
   col2 = mark[1].col;

   if (row2 < CurrentLine) {
      row2 = 0;
      col2 = 0;
   }
   else if (row2 == CurrentLine) {
      row2 = 0;
   }
   else if (row2 > CurrentLine + pText->win.nrows - 1) {
      row2 = pText->win.nrows - 1;
      col2 = pText->win.ncols - 1;
   }
   else if (row2 > CurrentLine) {
      row2 = row2 - CurrentLine;
   }

   direction = 1;
   if (row2 < row1 || (row2 == row1 && col2 < col1)) {
      direction = 0;
   }

   row0 = pText->cursor.row;
   col0 = pText->cursor.col;	    /* was + direction */

   if (direction == 1 && (row0 < row2 || (row0 == row2 && col0 < col2))) {
	   /* if (we are not going backwards from the last point */
	   /* or just going backwards */
      vWinPut_a(pText, row0, col0, row2, col2, pText->attr);
   }
   if (direction == 0 && (row2 < row0 || (row2 == row0 && col2 < col0))) {
      vWinPut_a(pText, row2, col2, row0, col0, pText->attr);
   }

/* phase II */

   if (row0 < row1 || (row0 == row1 && col0 < col1)) {
	/* if (we are nor going backwards from the original point */
	/* or just going backwards */

   /* ultimate lazyness */
      vWinPut_a(pText, 0, 0, row0, col0, pText->attr);

      vWinPut_a(pText, row0, col0, row1, col1, EditorMarkColor);
   }
   else {
      /* ultimate lazyness */
      vWinPut_a(pText, 0, 0, row1, col1, pText->attr);

      vWinPut_a(pText, row1, col1, row0, col0, EditorMarkColor);
   }

   mark[1].row = row0 + CurrentLine;
   mark[1].col = col0;
   mark[1].cur = CurrentLine;

   return(3);
}

int   cursor4(
PTEXTWIN pText,
KEYCODE c,
int   *CurrentLine,
int   *lines)
{
   char  temp1[4];
   int	 display, disp;

   char tmp[MAXSTRING+1];
   int i, j, start, newpos;

   display = *CurrentLine;

   temp1[0] = '\0';

   display = 1;

   switch (c) {

   case KEY_INS:
      if (VIEW || BROWSE) return(0);
      pText->cShape = !INSERT ? thin_cursor() : fat_cursor();
      INSERT = !INSERT;
      return(1);

   case KEY_CLEFT:

      if (BROWSE) return(0);

      vWinGet_s(pText, pText->cursor.row, tmp);

      display = 1;
      start = 0;
      if (pText->cursor.col > 0) {
	 newpos = 0;
	 start = 0;
	 for (j = pText->cursor.col; j >= 0; j--) {
	    if (j == 0 && tmp[j] != 32 && tmp[j] != 9) { /* new jhk 8/19 */
	       newpos = 0;
	       start = 3;
	       break;
	    }
	    if ((tmp[j] == 32 || tmp[j] == 9) && start == 2) {/* new jhk 8/19 */
	       newpos = j + 1;
	       start = 3;
	       break;
	    }
	    if ((tmp[j] == 32 || tmp[j] == 9) && !start) {/* new jhk 8/19 */
	       start = 1;
	    }
	    if ((tmp[j] != 32 && tmp[j] != 9) && j != pText->cursor.col) {/* new jhk 8/19 */
	 start = 2;
	    }
	 }
	 pText->cursor.col = newpos;


/* new jhk 8/19
	 if (pText->cursor.col < pText->corner.col) {
	    pText->corner.col = pText->cursor.col;
	    return(3);
	 }
*/
      }

      /* special case of being at the beginning of the line */
      if (start != 3) {
	 char tmp[MAXSTRING+1];

	 if (pText->cursor.row) {
	    pText->cursor.row--;
	    display = 1;
	 }
	      else if (*CurrentLine) {
	      (*CurrentLine)--;
	      display = 3;
	 }
	 else {
	    display = 2;
	 }

	 if (display == 1) {
	    vWinGet_s(pText, pText->cursor.row, tmp);
	    pText->cursor.col = lnbc (tmp, MAXSTRING);	 /* new 7/14 jhk */
	    if (pText->cursor.col == MAXSTRING) pText->cursor.col = MAXMINUS1;	 /* new 7/14 jhk */
	 }
	 else if (display == 3) { /* don't ever ever ever do this (ok, I won't) */
	    pText->cursor.col = getLineLength(*CurrentLine + pText->cursor.row);
	 }
	 else {
	    pText->cursor.col = 0;
	 }
      }
/* new jhk 8/19
      if (pText->cursor.col < pText->corner.col) {
	 pText->corner.col = pText->cursor.col;
	 display = 3;
      }
*/
      disp = fixup_corner(pText);
      if (disp == 3) display = 3;
      return(display);

   case KEY_CRIGHT:	  /* FIX if at end go to next line */
      if (BROWSE) return(0);

      vWinGet_s(pText, pText->cursor.row, tmp);
      i = lnbc(tmp, MAXSTRING);     /* new 7/14 jhk was 255 */

      display = 1;
      start = 0;
      newpos = i;
      if (i > pText->cursor.col) {
	 for (j = pText->cursor.col; j < i; j++) {
	    if (tmp[j] == 32 || tmp[j] == 9) {/* new jhk 8/19 */
	       start = 1;
	    }
	    if (start && (tmp[j] != 32 && tmp[j] != 9)) {/* new jhk 8/19 */
	       start = 2;
	       newpos = j;
	       break;
	    }
	 }
	 /* if we haven't moved then we are at the end and must go to the next line */
	 if (pText->cursor.col != newpos) {
	    pText->cursor.col = newpos;
	 }
	 start = 2;	/* new to allow going to end of line */
      }

      /* special case of being at end of line */
      if (start != 2) {
	 if (pText->cursor.row < pText->win.nrows - 1) {
	    if (*CurrentLine + pText->cursor.row < (*lines - 1)) {
	       pText->cursor.row++;
	       pText->cursor.col = 0;
	       pText->corner.col = 0;
	       display = 3;
	    }
	 }
	 else {
	    display = 1;
	    if (*lines - pText->win.nrows - 1 >= *CurrentLine) {
	       if (pText->cursor.row < *lines) {
		  (*CurrentLine)++;
		  pText->cursor.col = 0;
		  pText->corner.col = 0;
		  display = 3;
	       }
	    }
	 }
      }

      disp = fixup_corner(pText);
      if (disp == 3) display = 3;
      return(display);

   default:
	return (cursor4b (pText, c, CurrentLine, lines));

   }

   return(0);
}

int   cut_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines)
{
   int	 i, row1, col1, cur1, row2, col2, cur2, len1, len2;

   if (mark[0].row > mark[1].row ||
      (mark[0].row == mark[1].row && mark[0].col >= mark[1].col)) {
      row2 = mark[0].row;
      col2 = mark[0].col;
      cur2 = mark[0].cur;

      row1 = mark[1].row;
      col1 = mark[1].col;
      cur1 = mark[1].cur;
   }
   else {
      row1 = mark[0].row;
      col1 = mark[0].col;
      cur1 = mark[0].cur;

      row2 = mark[1].row;
      col2 = mark[1].col;
      cur2 = mark[1].cur;
   }

   /* fix up ending column to not include cursor */
   reset_column (&row2, &col2, &cur2);

   len1 = strlen(line[row1]);
   len2 = strlen(line[row2]);
   if (col1 > len1) col1 = len1;
   if (col2 > len2) col2 = len2;

   if (col2 >= 0) {
      if (col2 == len2) { /* new was just split_block call */
	 if (!split_block1(pText, CurrentLine, line, lines, row2, col2)) return(0);
      }
      else {
	 if (!split_block(pText, CurrentLine, line, lines, row2, col2)) return(0);
      }
   }

   if (col1 == len1) { /* new was just split_block call */
      if (!split_block1(pText, CurrentLine, line, lines, row1, col1)) return(0);
   }
   else {
      if (!split_block(pText, CurrentLine, line, lines, row1, col1)) return(0);
   }

   if (col2 >= 0) {
      for (i = row1; i < row2+1; i++) {
	 delete_block(pText, CurrentLine, line, lines, row1+1);
      }
   }
   else {
      for (i = row1; i < row2; i++) {
	 delete_block(pText, CurrentLine, line, lines, row1+1);
      }
      col2 = 0;
   }


   if (!join_block(pText, CurrentLine, line, lines, row1, 1)) return(0);

   pText->cursor.col = col1;
   pText->cursor.row = row1 - cur1;
   *CurrentLine      = cur1;

   return(1);
}

int   copy_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines)
{
   int	 i, j, row1, col1, cur1, row2, col2, cur2, len1, len2, row11, row22;
   char *p;

   i = *CurrentLine;
   i = *lines;
   p = line[0];

   if (mark[0].row > mark[1].row ||
      (mark[0].row == mark[1].row && mark[0].col >= mark[1].col)) {
      row2 = mark[0].row;
      col2 = mark[0].col;
      cur2 = mark[0].cur;

      row1 = mark[1].row;
      col1 = mark[1].col;
      cur1 = mark[1].cur;
   }
   else {
      row1 = mark[0].row;
      col1 = mark[0].col;
      cur1 = mark[0].cur;

      row2 = mark[1].row;
      col2 = mark[1].col;
      cur2 = mark[1].cur;
   }

   /* fix up ending column to not include cursor */
   reset_column (&row2, &col2, NULL);

   len1 = strlen(line[row1]);
   len2 = strlen(line[row2]);
   if (col1 > len1) col1 = len1;
   if (col2 > len2) col2 = len2;

   /* free any existing buffer
      allocate row2 - row1 + 1 number of character * pointers
      retreive the row portions and allocate the space to each line
   */

   if (buffrows) {
       for (i = 0; i < buffrows; i++) {
	 if (buffer[i]) my_free(buffer[i]);
       }
       my_free(buffer);
   }

   buffrows = row2 - row1 + 1;
   if ( (buffer = my_calloc(buffrows, sizeof(char *))) == NULL) {
      return(0);
   }

   pText->cursor.col = col1;
   pText->cursor.row = row1 - cur1;
   *CurrentLine = cur1;

   if (row1 == row2) {
      char tmp[MAXSTRING+1];

      memcpy(tmp, line[row1]+col1, col2 - col1 + 1);
      tmp[col2 - col1 + 1] = '\0';
      if ((buffer[0] = salloc(tmp)) == NULL) {
	 buffrows = 0;
	 if (buffer) my_free(buffer);
	 return(0);
      }
   }
   else {
      char tmp[MAXSTRING+1];
      memcpy(tmp, line[row1]+col1, len1 - col1 + 1);
      tmp[len1 - col1 + 1] = '\0';
      if ((buffer[0] = salloc(tmp)) == NULL) {
	 buffrows = 0;
	 if (buffer) my_free(buffer);
	 return(0);
      }

      row11 = row1 + 1;
      row22 = row2 + 1;
      for (i = row11; i < row2; i++) {
	 if ((buffer[i-row1] = salloc(line[i])) == NULL) {
	    for (j = row11; j < i; j++) {
	       if (buffer[j - row1 - 1]) my_free(buffer[j - row1 - 1]);
	    }
	    if (buffer) my_free(buffer);
	    buffrows = 0;
	    return(0);
	 }
      }

      memcpy(tmp, line[row2], col2+1);
      tmp[col2+1] = '\0';
      if ((buffer[buffrows-1] = salloc(tmp)) == NULL) {
	 for (j = 0; j < buffrows; j++) {
	    if (buffer[j]) my_free(buffer[j]);
	 }
	 if (buffer) my_free(buffer);
	 buffrows = 0;
	 return(0);
      }
   }
   return(2);
}

int   paste_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines)
{
   int	 i, row1, col1, cur1;

   i = 0;

   row1 = *CurrentLine + pText->cursor.row;
   col1 = pText->cursor.col;
   cur1 = *CurrentLine;

   /* calculate whether any line exceeds 256, if so beep */
   {
      int   len1, len2, len3, len4;
      len1 = 0;

      if (line[row1]) len1 = tablen(line[row1]);
      if (col1 > len1) len1 = col1;

      len4 = len1 - col1;
      len2 = tablen(buffer[0]); 	/* get the first line in the block */
      len3 = tablen(buffer[buffrows-1]);	/* get the last line in the block */
      len1 = col1;

      if ( (buffrows == 1 && (len1 + len2 + len4) > MAXMINUS1) ||
	 ((len1 + len2) > MAXMINUS1) || ((len3 + len4) > MAXMINUS1) ) {
	  beep();
	  return(1);
      }
   }

   {
      char  **lline;
      long required = 0L;
      int   i, j=0, maxk;

      for (i = 0; i < buffrows; i++) {
	 if (buffer[i]) required += (long) strlen(buffer[i]) + 3;
      }

      maxk = (int)(required / 1000L) + 1;
      if ( (lline = my_calloc(maxk, sizeof(char *))) == NULL) {
	 return(0);
	}

      for (i = 0; i < maxk; i++) {
	 lline[i] = my_malloc(1000);
	 if (lline[i] != NULL) {
	    j = i + 1;
	 }
      }
      for (i = 0; i < j; i++) {
	 if (lline[i]) my_free (lline[i]);
      }
      if (lline) my_free(lline);
      if (j != maxk) return(0);
   }


   /* new added col1-1 */
   if (!split_block1(pText, CurrentLine, line, lines, row1, col1)) return(0);

   if (!add_block(pText, CurrentLine, line, lines, row1)) return(0);

   if (!join_block(pText, CurrentLine, line, lines, row1, 1)) return(0);
   if (!join_block(pText, CurrentLine, line, lines, row1+buffrows-1, 1)) return(0);

   pText->cursor.col = col1;
   pText->cursor.row = row1 - *CurrentLine;
   *CurrentLine      = cur1;

   return(1);

}

int   split_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row,
int	 col)
{
   int	 i, start, len;
   char  tmp[MAXSTRING+1];

   i = *CurrentLine;

   if (*lines >= MAXLINES) {
      beep();
      return(1);
   }

   start = row;

   tmp[0] = '\0';

   if (line[start]) strcpy(tmp,line[start]);
   len = strlen(tmp);
   if (col > len) col = len;

   if (start < *lines) {
      char  *t, *u;

      if ((t = salloc((char *)&tmp[col+1])) == NULL) return(0);
      tmp[col] = '\0';
      if ((u = salloc(tmp)) == NULL) return(0);

      memmove((char *)&line[start+1], (char *)&line[start],
	 (*lines - start) * sizeof(char *));

      if (line[start+1]) my_free(line[start+1]);
      line[start+1] = t;
      line[start] = u;
   }
   else { /* FIX ME FIX ME Below should be start-1 and start ????????? */
      char  *t, *u;

      if ((t = salloc((char *)&tmp[col+1])) == NULL) return(0);
      tmp[col] = '\0';
      if ((u = salloc(tmp)) == NULL) return(0);


      line[start+1] = t;
      if (line[start]) my_free(line[start]);
      line[start] = u;
   }

   (pText->size.row)++;
   (*lines)++;
   return(2);
}

int   split_block1(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row,
int	 col)
{
   int	 i, start, len;
   char  tmp[MAXSTRING+1];

   i = *CurrentLine;

   if (*lines >= MAXLINES) {
      beep();
      return(1);
   }

   start = row;

   memset(tmp, ' ', MAXSTRING);

   tmp[0] = '\0';

   if (line[start]) strcpy(tmp,line[start]);
   len = strlen(tmp);

   if (col > len) {
      tmp[len] = ' ';
      len = col;
      tmp[col] = '\0';
   }

   if (start < *lines) {
      char  *t, *u;


      if ((t = salloc((char *)&tmp[col])) == NULL) return(0);
      tmp[col] = '\0';
      if ((u = salloc(tmp)) == NULL) return(0);

      memmove((char *)&line[start+1], (char *)&line[start],
	 (*lines - start) * sizeof(char *));

      if (line[start+1]) my_free(line[start+1]);
      line[start+1] = t;

      line[start] = u;
   }
   else { /* FIX ME FIX ME Below should be start-1 and start ????????? */
      char  *t, *u;

      if ((t = salloc((char *)&tmp[col])) == NULL) return(0);
      tmp[col] = '\0';
      if ((u = salloc(tmp)) == NULL) return(0);

      line[start+1] = t;
      if (line[start]) my_free(line[start]);
      line[start] = u;

   }

   (pText->size.row)++;
   (*lines)++;
   return(2);
}

int   join_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row,
int	 type)
{
   int	 start1, start2, len1 = 0, len2 = 0;
   char  tmp[MAXSTRING+1];
   char  *t;

   if (!*lines) return(1);
   start1 = *CurrentLine;   /* just for the compiler */

   type = 1;

   if (type == 1) {
      start1 = row;
      start2 = row + 1;
   }
   if (start1 < 0) return(0);

   if (line[start1]) len1 = tablen(line[start1]);
   if (line[start2]) len2 = tablen(line[start2]);
   if (len1 + len2 > MAXSTRING) return(0);	/* new 7/14 was 255 */

/*
   if (line[start1]) pText->cursor.col = len1;
*/

   if (line[start1]) {
      strcpy(tmp, line[start1]);
      if (line[start2]) {
	 strcat(tmp, line[start2]);
      }
   }
   else {
      if (line[start2]) {
	 strcpy(tmp, line[start2]);
      }
   }

   if ((t = salloc(tmp)) == NULL) return(0);

   if (line[start1]) my_free(line[start1]);
   line[start1] = t;

   if (line[start2]) my_free(line[start2]);
   line[start2] = NULL;

   memmove((char *)&line[start2], (char *)&line[start2+1],
      (*lines - start2) * sizeof(char *));

   (pText->size.row)--;
   (*lines)--;
   return(2);
}

int   delete_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row)
{
   int	 start;

   start = *CurrentLine;

   if (*lines == 0) return(1);

   start = row;

   if (line[start]) my_free(line[start]);

   memmove((char *)&line[start], (char *)&line[start+1],
      (*lines - start) * sizeof(char *));

   (pText->size.row)--;
   (*lines)--;
   return(2);
}

int   insert_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row)
{
   int	 start;
   char  *t;

   start = row;

   if (*lines >= MAXLINES) return(1);

   start = *CurrentLine + pText->cursor.row;

   if ((t = salloc("")) == NULL) return(0);        /* was NULL */

   memmove((char *)&line[start+1], (char *)&line[start],
      (*lines - start) * sizeof(char *));

   line[start] = t;

   (pText->size.row)++;
   (*lines)++;
   return(2);
}

int   add_block(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row)
{
   int	 start, i;
   char  *t;

   i = *CurrentLine;

   if (*lines + buffrows >= MAXLINES) return(1);

   start = row + 1;

   for (i = 0; i < buffrows; i++) {

      if (start < *lines) {
	 if (buffer[buffrows - i - 1]) {
	    if ((t = salloc(buffer[buffrows - i - 1])) == NULL) return(0);	/* was NULL; */
	 }
	 else {
	    if ((t = salloc("")) == NULL) return(0);
	 }

	 memmove((char *)&line[start+1], (char *)&line[start],
	    (*lines - start) * sizeof(char *));

	 line[start] = t;
      }
      else {
	 if (buffer[buffrows - i - 1]) {
	    if ((line[start+1] = salloc(buffer[buffrows - i - 1])) == NULL) return(0); /* was NULL */
	 }
	 else {
	    if ((line[start+1] = salloc("")) == NULL) return(0);
	 }
      }
      (pText->size.row)++;
      (*lines)++;
   }
   return(2);
}

void clear_mark(
PTEXTWIN pText)
{
   vWinPut_a(pText, 0, 0, pText->win.nrows - 1, pText->size.col-1, pText->attr);

   markon = 0;

   mark[1].row = 0;
   mark[1].col = 0;
   mark[1].cur = 0;
}

void clear_area(
PTEXTWIN pText)
{
   vWinPut_a(pText, 0, 0, pText->win.nrows - 1, pText->size.col-1, pText->attr);

   markon = 0;
}

int fixup_cursor(
PTEXTWIN pText)
{
   if (pText->cursor.col > pText->corner.col + pText->win.ncols - 1) {
      pText->cursor.col = pText->corner.col + pText->win.ncols - 1;
   }
   return(0);
}

int   reset_column (
int   *row2,
int   *col2,
int   *cur2)
{
   int i = *row2, j;

    if (cur2) j = *cur2;

   (*col2)--;

/*
   if (*col2) {
      (*col2)--;
   }
   else {
      if (*row2) {
	 (*row2)--;
	 *col2 = MAXMINUS1;
	 if (cur2) {
	    (*cur2)--;
	 }
      }
   }
*/
   return(0);
}


