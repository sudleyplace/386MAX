/*' $Header:   P:/PVCS/MAX/QUILIB/CURSOR2.C_V   1.0   05 Sep 1995 17:02:02   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CURSOR2.C								      *
 *									      *
 * Block cut/paste functions						      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>

/*	Program Includes */
#include "commfunc.h"
#include "ui.h"
#include "fldedit.h"
#include "message.h"
#include "myalloc.h"

#include "editwin.h"

int   copy_block_delete(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines)
{
   int	 i, j, row1, col1, row2, col2, len1, len2, row11, row22;
   char *p;

   i = *CurrentLine;
   i = *lines;
   p = line[0];

   if (mark[0].row > mark[1].row ||
      (mark[0].row == mark[1].row && mark[0].col >= mark[1].col)) {
      row2 = mark[0].row;
      col2 = mark[0].col;

      row1 = mark[1].row;
      col1 = mark[1].col;
   }
   else {
      row1 = mark[0].row;
      col1 = mark[0].col;

      row2 = mark[1].row;
      col2 = mark[1].col;
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

   if (duffrows) {
      for (i = 0; i < duffrows; i++) {
	 if (duffer[i]) my_free(duffer[i]);
       }
       my_free(duffer);
   }

   duffrows = row2 - row1 + 1;
   if ( (duffer = my_calloc(duffrows, sizeof(char *))) == NULL) {
      return(0);
   }

   pText->cursor.row = row1;

   if (row1 == row2) {
      char tmp[MAXSTRING+1];
      memcpy(tmp, line[row1]+col1, col2 - col1 + 1);
      tmp[col2 - col1 + 1] = '\0';
      if ((duffer[0] = salloc(tmp)) == NULL) {
	 duffrows = 0;
	 if (duffer) my_free(duffer);
	 return(0);
      }
   }
   else {
      char tmp[MAXSTRING+1];
      memcpy(tmp, line[row1]+col1, len1 - col1 + 1);
      tmp[len1 - col1 + 1] = '\0';
      if ((duffer[0] = salloc(tmp)) == NULL) {
	 duffrows = 0;
	 if (duffer) my_free(duffer);
	 return(0);
      }

      row11 = row1 + 1;
      row22 = row2 + 1;
      for (i = row11; i < row2; i++) {
	 if ((duffer[i-row1] = salloc(line[i])) == NULL) {
	    for (j = row11; j < i; j++) {
	       if (duffer[j - row1 - 1]) my_free(duffer[j - row1 - 1]);
	    }
	    if (duffer) my_free(duffer);
	    duffrows = 0;
	    return(0);
	 }
      }

      memcpy(tmp, line[row2], col2+1);
      tmp[col2+1] = '\0';
      if ((duffer[duffrows-1] = salloc(tmp)) == NULL) {
	 for (j = 0; j < duffrows; j++) {
	    if (duffer[j]) my_free(duffer[j]);
	 }
	 if (duffer) my_free(duffer);
	 duffrows = 0;
	 return(0);
      }
   }
   return(2);
}

int   paste_block_delete(
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
      if (col1 > len1) col1 = len1;

      /* new 7/14 jhk all below was 255 */

      len4 = len1 - col1;
      len2 = tablen(duffer[0]); 	/* get the first line in the block */
      len3 = tablen(duffer[duffrows-1]);	/* get the last line in the block */
      len1 = col1;

       if ( (duffrows == 1 && (len1 + len2 + len4) > MAXSTRING) ||
	      ((len1 + len2) > MAXSTRING) || ((len3 + len4) > MAXSTRING) ) {
	 beep();
	 return(1);
       }
   }

   {
      char  **lline;
      long required = 0L;
      int   i, j=0, maxk;

      for (i = 0; i < duffrows; i++) {
	 if (duffer[i]) required += (long) strlen(duffer[i]) + 3;
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

   if (!add_block_delete(pText, CurrentLine, line, lines, row1)) return(0);

   if (!join_block(pText, CurrentLine, line, lines, row1, 1)) return(0);
   if (!join_block(pText, CurrentLine, line, lines, row1+duffrows-1, 1)) return(0);

   pText->cursor.col = col1;
   pText->cursor.row = row1 - *CurrentLine;
   *CurrentLine      = cur1;

   return(1);

}

int   add_block_delete(
PTEXTWIN pText,
int	 *CurrentLine,
char	 *line[],
int	 *lines,
int	 row)
{
   int	 start, i;
   char  *t;

   i = *CurrentLine;

   if (*lines + duffrows >= MAXLINES) return(1);

   start = row + 1;

   for (i = 0; i < duffrows; i++) {

      if (start < *lines) {

	 if (duffer[duffrows - i - 1]) {
	    if ((t = salloc(duffer[duffrows - i - 1])) == NULL) return(0);	/* was NULL; */
	 }
	 else {
	    if ((t = salloc("")) == NULL) return(0);
	 }

	 memmove((char *)&line[start+1], (char *)&line[start],
	    (*lines - start) * sizeof(char *));

	 line[start] = t;
      }
      else {
	 if (duffer[duffrows - i - 1]) {
	    if ((line[start+1] = salloc(duffer[duffrows - i - 1])) == NULL) return(0); /* was NULL */
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
