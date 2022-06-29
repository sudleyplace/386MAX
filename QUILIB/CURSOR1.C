/*' $Header:   P:/PVCS/MAX/QUILIB/CURSOR1.C_V   1.0   05 Sep 1995 17:02:02   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CURSOR1.C								      *
 *									      *
 * Cursor movement functions						      *
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
#include "ui.h"
#include "message.h"
#include "myalloc.h"

#include "editwin.h"

extern	 int   locate_cursor(
   PTEXTWIN pText,
   int	 row,
   int	 col);


int   insert_tab(
PTEXTWIN pText);
int   replace_tab(
PTEXTWIN pText);

int   linlen(
PTEXTWIN pText);


int   save_changes(
PTEXTWIN pText,
KEYCODE c)
{
   int	 display = 1, save_row = 0;

   display = pText->cursor.row;

   switch (c) {
   case  KEY_CHOME:
   case  KEY_CEND:
   case  KEY_CRIGHT:
   case  KEY_CLEFT:
   case  KEY_CUP:
   case  KEY_CDOWN:
   case  KEY_UP:
   case  KEY_DOWN:
   case  KEY_PGUP:
   case  KEY_PGDN:
   case  KEY_CPGUP:
   case  KEY_CPGDN:
   case  KEY_BKSP:
   case  KEY_ENTER:
   case  KEY_DEL:
   case  KEY_CINS:
   case  KEY_CDEL:
   case  KEY_ALTBKSP:
   case  KEY_SF3:
   case  KEY_SF4:
   case  KEY_SF5:
   case  KEY_SF6:
   case  KEY_SF7:
   case  KEY_SF8:
	 save_row = 1;
   }

   if (SHIFT && c == KEY_INS) save_row = 1;

   if (isascii(c) && markon) {
      save_row = 1;
   }

   return(save_row);
}

int   cursor5(		/* contains almost all text modification routines */
PTEXTWIN pText,
KEYCODE  c,
int	 *CurrentLine,
char	 *line[],
int	 *lines)
{
   char  temp1[4];
   int	 display;
   int	 start1, len;
   int	 length;
   char  tmp[MAXSTRING + 1];

   display = *CurrentLine;
   display = *lines;

   display = 1;

   switch (c) {

   case KEY_DEL:

      if (VIEW || BROWSE) return(0);

      start1 = *CurrentLine + pText->cursor.row;

      vWinGet_s(pText, pText->cursor.row, tmp);
      len = lnbc (tmp, MAXSTRING);     /* new 7/14 jhk was 255 */

      if (pText->cursor.col >= len) {

	 SaveLine(pText, line, *CurrentLine);

	 if (!(display = join_line(pText, CurrentLine, line, lines, 1))) {
	    goto mem_error;
	 }

      /*
	 fixup_corner(pText);
      */

	 FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
	 return(4);
      }
      else {
	 delete_char(pText);
      }
      FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
      return(2);

   case KEY_BKSP:

      if (VIEW || BROWSE) return(0);

      if (pText->cursor.col) {
	      pText->cursor.col--;
	      delete_char(pText);
	 FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;

      /* new jhk 8/19
	   if (pText->cursor.col < pText->corner.col) {
		 pText->corner.col = pText->cursor.col;
		 return(3);
	   }
	      else {
		 return(2);
	   }
      */
      /* new jhk 8/19 */
	 return(2);
      }
      else {

	 SaveLine(pText, line, *CurrentLine);

	 if (!(display = join_line(pText, CurrentLine, line, lines, 2))) {
	    goto mem_error;
	 }
      /* was commented out */
	 fixup_corner(pText);

	 FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
	 return(4);
      }
   /* return(1);	unreachable */

   case  KEY_ENTER:

      display = 1;

      SaveLine(pText, line, *CurrentLine);

      if (VIEW || !INSERT || BROWSE) {
	 display = 1;
	 pText->cursor.col = 0;

	 if (pText->cursor.row < pText->win.nrows - 1) {
	    if (*CurrentLine + pText->cursor.row < (*lines - 1)) pText->cursor.row++;
	    display = 1;
	 }
	 else {
	    if (*lines - pText->win.nrows - 1 < *CurrentLine) {
	       display = 1;
	    }
	    else {
	       if (pText->cursor.row < *lines) (*CurrentLine)++;
	       display = 3;
	    }
	 }

	 if (pText->cursor.row > *lines) {
	    pText->cursor.row--;
	 }
	 if (pText->corner.col != 0) {
	    pText->corner.col = 0;
	    display = 3;
	 }
	 return(display);
      }

      vWinGet_s(pText, pText->cursor.row, tmp);
      length = lnbc (tmp, MAXSTRING);	  /* new 7/14 jhk was 255 */
      tmp[length] = '\0';

      if (pText->cursor.col == 0) {
	 if (!(display = insert_line(pText, CurrentLine, line, lines))) {
	    goto mem_error;
	 }
	 if (display == 2) {
	    FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
	 }
      }
      else if (pText->cursor.col >= length) {
	 if (!(display = add_line(pText, CurrentLine, line, lines))) {
	    goto mem_error;
	 }
	 if (display == 2) {
	    FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
	 }
      }
      else {
	 if (!(display = split_line(pText, CurrentLine, line, lines, pText->cursor.col))) {
	    goto mem_error;
	 }
	 if (display == 2) {
	    FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
	 }
	 if (pText->cursor.row) {
	    FileChanged = PageChanged = LineChanged[pText->cursor.row-1] = 1;
	 }
      }

      pText->cursor.col = 0;
      pText->corner.col = 0;

      if (pText->cursor.row < pText->win.nrows - 1) {
	 if (pText->cursor.row < *lines) pText->cursor.row++;
	 return(4);
      }
      else {
	 if (*lines - pText->win.nrows - 1 < *CurrentLine) return(4);
	 if (pText->cursor.row < *lines) (*CurrentLine)++;
	 return(4);
      }
   /* return(1);	unreachable */
   }
   /* above is end case */

   /* printable character */
   if ( (isascii(c) && (c&0x00ff) > 31) || c == KEY_TAB || c == KEY_STAB) {
      if (c == KEY_STAB) c = KEY_TAB;

      temp1[0] = (char)c;
      temp1[1] = '\0';

      if (VIEW || BROWSE) return(0);

      if (markWasOn) return(0);

      if (INSERT) {
	 if (insert_char(pText, c)) {
	    FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
	    vWinPut_s(pText, pText->cursor.row, pText->cursor.col, temp1);
	    if (pText->cursor.col < MAXSTRING - 1) {
		    pText->cursor.col++;
		    display = 2;
	    }
		 if ((pText->cursor.col - pText->corner.col) >= pText->win.ncols) {
		   pText->corner.col = (pText->cursor.col - pText->win.ncols) + 1;
			 display = 3;
	    }
	 }
	      else {
	 }
      }
      else {
	 if (c == KEY_TAB) {
	    if (replace_tab(pText)) {
	       FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
	       vWinPut_s(pText, pText->cursor.row, pText->cursor.col, temp1);
	       if (pText->cursor.col < MAXSTRING - 1) {
		  pText->cursor.col++;
		       display = 2;
	       }
		    if ((pText->cursor.col - pText->corner.col) >= pText->win.ncols) {
			    pText->corner.col = (pText->cursor.col - pText->win.ncols) + 1;
		       display = 3;
	       }
	    }
	    else {
	    }
	 }
	 else {
	    FileChanged = PageChanged = LineChanged[pText->cursor.row] = 1;
	    vWinPut_s(pText, pText->cursor.row, pText->cursor.col, temp1);
	    if (pText->cursor.col < MAXSTRING - 1) {
	       pText->cursor.col++;
		    display = 2;
	    }
		 if ((pText->cursor.col - pText->corner.col) >= pText->win.ncols) {
			 pText->corner.col = (pText->cursor.col - pText->win.ncols) + 1;
		    display = 3;
	    }
	 }
      }
      return(display);
   }


   return(0);

mem_error:

   errorMessage( WIN_NOMEMORY); /* Insufficient Memory */

   return(0);
}

int   insert_char(
PTEXTWIN pText,
int   c)
{
	PCELL startPos, endPos;

	startPos = pText->data + (pText->cursor.row * pText->size.col + pText->cursor.col);
	endPos	 = pText->data + (pText->cursor.row * pText->size.col + MAXSTRING - 1);

   if (endPos->ch == 32) {
      memmove(startPos + 1, startPos, (endPos - startPos) * sizeof(CELL));
      startPos->ch = (char)c;
      if (linlen(pText) > MAXSTRING) {
	 memmove(startPos, startPos+1, (endPos - startPos) * sizeof(CELL));
	 endPos->ch =32;
	 beep();
	 return(0);
      }
      else  return(2);
   }
   else {
      beep();
      return(0);
   }
}

int   replace_tab(
PTEXTWIN pText)
{
   int	 hold;
	PCELL startPos;

	startPos = pText->data + (pText->cursor.row * pText->size.col + pText->cursor.col);

   hold = (int)startPos->ch;
   startPos->ch = 9;
   if (linlen(pText) > MAXSTRING) {
      startPos->ch = (char)hold;
      beep();
      return(0);
   }
   else  return(2);
}

int   delete_char(
PTEXTWIN pText)
{
   PCELL startPos, endPos;

   startPos = pText->data + (pText->cursor.row * pText->size.col + pText->cursor.col);
   endPos   = pText->data + (pText->cursor.row * pText->size.col + MAXSTRING - 1);

   memmove(startPos, startPos + 1, (endPos - startPos) * sizeof(CELL));
   endPos->ch = ' ';

   return(2);
}

int   insert_line(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines)
{
   int	 start;
   char  *t;

   if (*lines >= MAXLINES) {
      beep();
      return(1);
   }

   start = *CurrentLine + pText->cursor.row;

   if ((t = salloc("")) == NULL) return(0);        /* was NULL */

   memmove((char *)&line[start+1], (char *)&line[start],
      (*lines - start) * sizeof(char *));

   line[start] = t;

   (pText->size.row)++;
   (*lines)++;
   return(2);
}

int   add_line(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines)
{
   int	 start;
   char  *t;

   if (*lines >= MAXLINES) {
      beep();
      return(1);
   }

   start = *CurrentLine + pText->cursor.row + 1;

   if (start < *lines) {

      if ((t = salloc("")) == NULL) return(0);  /* was NULL; */

      memmove((char *)&line[start+1], (char *)&line[start],
	 (*lines - start) * sizeof(char *));

      line[start] = t;
   }
   else {
      if ((line[start+1] = salloc("")) == NULL) return(0); /* was NULL */
   }
   (pText->size.row)++;
   (*lines)++;
   return(2);
}

int   split_line(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 col)
{
   int	 start;
   char  tmp[MAXSTRING+1];
   char  *t, *u;

   if (*lines >= MAXLINES) {
      beep();
      return(1);
   }

   start = *CurrentLine + pText->cursor.row + 1;
   if (line[start-1]) strcpy(tmp,line[start-1]);

   if (start < *lines) {

      if ((t = salloc((char *)&tmp[col])) == NULL) return(0);

      if (col == MAXSTRING) col = MAXMINUS1;	  /* new 7/14 jhk wasn't here */

      tmp[col] = '\0';
      if ((u = salloc(tmp)) == NULL) return(0);

      memmove((char *)&line[start+1], (char *)&line[start],
	 (*lines - start) * sizeof(char *));

      line[start] = t;

      if (line[start-1]) my_free(line[start-1]);
      line[start-1] = u;
   }
   else {     /* below was start+1 and start */

      if ((t = salloc((char *)&tmp[col])) == NULL) return(0);

      if (col == MAXSTRING) col = MAXMINUS1;	  /* new 7/14 jhk wasn't here */

      tmp[col] = '\0';
      if ((u = salloc(tmp)) == NULL) return(0);

      line[start] = t;
      if (line[start-1]) my_free(line[start-1]);
      line[start-1] = u;
   }

   (pText->size.row)++;
   (*lines)++;
   return(2);
}

int   join_line(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 type)
{
   int	 start1, start2, len1 = 0, len2 = 0, len3 = 0;
   char  tmp[MAXSTRING+1];
   char  *t;

   if (!*lines) {
      beep();
      return(1);
   }

   if (type == 1) {
      start1 = *CurrentLine + pText->cursor.row;
      start2 = *CurrentLine + pText->cursor.row + 1;
   }
   else {
      start1 = *CurrentLine + pText->cursor.row - 1;
      start2 = *CurrentLine + pText->cursor.row;
   }
   if (start1 < 0 || start2 >= *lines) {
      beep();
      return(1);
   }

   if (line[start1]) len1 = tablen(line[start1]);
   if (line[start2]) len2 = tablen(line[start2]);
		     len3 = locate_cursor(pText, pText->cursor.row,
			    pText->cursor.col);
   if (type == 1) {
      if (len2 + len3 > MAXSTRING) { /* new 7/14 jhk was 255 */
	 beep();
	 return(1);
      }
   }
   else {
      if (len1 + len2 > MAXSTRING) { /* new 7/14 jhk was 255 */
	 beep();
	 return(1);
      }
   }

/* new jhk */

   if (line[start1]) len1 = strlen(line[start1]);
		     len3 = pText->cursor.col;
   if (type == 1) {
      pText->cursor.col = len3;
   }
   else {
      pText->cursor.col = len1;
   }

   if (type == 1) {
      memset(tmp,' ',len3);
      tmp[len3] = '\0';
      if (line[start1]) {
	 strncpy(tmp, line[start1], strlen(line[start1]));
	 if (line[start2]) {
	    strcat(tmp, line[start2]);
	 }
      }
      else {
	 if (line[start2]) {
	    strcpy(tmp, line[start2]);
	 }
      }

   }
   else {
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
   }

   if ((t = salloc(tmp)) == NULL) return(0);

   if (line[start1]) my_free(line[start1]);
   line[start1] = t;

   if (line[start2]) my_free(line[start2]);
   line[start2] = NULL;

   memmove((char *)&line[start2], (char *)&line[start2+1],
      (*lines - start2) * sizeof(char *));
   /* FIX ME null out the pointer made empty by the above process */


   if (type == 2) {
      if (pText->cursor.row) {
	 pText->cursor.row--;
      }
      else {
	 if (*CurrentLine) {
	    (*CurrentLine)--;
	 }
      }
   }
   (pText->size.row)--;
   (*lines)--;
   return(2);
}

int   delete_line(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines)
{
   int	 start;

   if (*lines == 0) {
      beep();
      return(1);
   }

   start = *CurrentLine + pText->cursor.row;

   if (line[start]) my_free(line[start]);

   memmove((char *)&line[start], (char *)&line[start+1],
      (*lines - start) * sizeof(char *));
   /* FIX ME null out the pointer made empty by the above process */

/*
   line[start] = salloc("");
*/

   (pText->size.row)--;
   (*lines)--;
   return(2);
}

int   linlen(
PTEXTWIN pText)
{
	PCELL startPos, endPos, Pos;
   char  *from;
   int	 cnt, i, len = 0, ncols;

	startPos = pText->data + (pText->cursor.row * pText->size.col);
	endPos	 = pText->data + (pText->cursor.row * pText->size.col + MAXSTRING - 1);

   Pos = endPos;
   from = (char *)startPos;

   for (ncols = MAXSTRING; ncols; ncols--) {
      if (Pos->ch != 32) goto skip;
      Pos--;
   }

skip:

   len = 1;
   for (i = 0; i < ncols; i++) {
		if (*from == 9) {
			cnt = (TabStop - 1) - ((len) % TabStop);
	 len += cnt;
		}
      len++;
      from += sizeof(WORD);
	}
   return(len + 1);	   /* ????? why +1, I don't know */
}
