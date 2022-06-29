// SCREENIO.C - Hardware dependent video i/o routines for 4DOS & 4OS2
//   (c) 1988, 1989, 1990  Rex C. Conn  All rights reserved

//   This file contains various screen I/O functions for 4DOS & 4OS2.
//   If you are porting 4DOS to other than standard IBM PC hardware, you will
//   need to edit some of the functions in this file.  Also see 4DOSUTIL.ASM
//   for qprint() and prtline().  For 4OS2, no changes are necessary.


#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <dos.h>
#include <io.h>
#include <string.h>

#include "batproc.h"


static int pascal position(char *);
static void pascal clearline(char *);
static void pascal efputs(char *);


static char *base;			// start of line

static int home_row;			// starting row & column
static int home_col;
static int csr_row;			// current row & column position
static int csr_col;


// clear the screen (using ANSI or BIOS calls)
int cls(register int argc, char **argv)
{
	unsigned int far *i29seg = (unsigned int far *)((0x29 * 4) + 2);
	unsigned int far *i20seg = (unsigned int far *)((0x20 * 4) + 2);
	int attrib = 7, location = 1;

	// check for presence of ANSI (INT 29h in ANSI will be set above
	//   the IBMDOS.COM segment in INT 20h)
	if ((cfgdos.ansi != 2) && ((*i29seg > *i20seg) || (cfgdos.ansi == 1) || (argc > 1))) {

		// if colors were requested, call COLOR to set them
#ifdef COMPAT_4DOS
		if ((argc > 1) && (color(argc,argv) != 0))
			return ERROR_EXIT;
#endif

		// output ANSI clear screen sequence
		qputs(STDOUT,"\033[2J");

		// if the ANSI sequence worked, the cursor will be at 0,0
_asm {
		push	bp		; for PC1 bug
		mov	ah,0fh
		int	10h		; get current page into BH
		mov	ax,0300h
		int	10h
		pop	bp
		mov	location,dx	; put cursor row & column into argc
}

	}

	if (location != 0) {

		// were colors requested?
#ifdef COMPAT_4DOS
		if (argc > 1) {
			attrib = -1;
			argv++;
			set_colors(argv,&attrib);
			if (attrib == -1)
				return (usage(COLOR_USAGE));
		}
#endif

		// ANSI didn't work, so try the BIOS
		window(0,0,screenrows(),screencols()-1,0,attrib);

		// move cursor to upper left corner
		screen(0,0);
	}

	return 0;
}


// get string from STDIN, with full line editing
//	curpos = input string
//	max_length = max entry length
//	editflag =  COMMAND = command line
//		    DATA = other input
int pascal egets(register char *curpos, unsigned int max_length, char editflag)
{
	extern char *histlist, *Hptr;	// history list & pointer
	extern unsigned int env_seg;

	register unsigned int c;
	char insflag, curstate;

	// get the insert mode
	insflag = (char)cfgdos.editmode;

	// default cursor
	curstate = 0;

	base = curpos;

	*curpos = '\0';

	// get the cursor position and start/end lines
	getcursor();

	// set the default cursor shape (underline or block)
	setcursor(0);

	csr_row = home_row;
	csr_col = home_col;

	for ( ; ; ) {

		// get & set cursor position
		position(curpos);

		c = getkey(NO_ECHO);

		if ((c == LF) || (c == CR)) {

			// reset cursor shape on exit
			setcursor(0);

			// go to EOL before CR/LF (may be multiple lines)
			position(curpos+strlen(curpos));
			crlf();

			return strlen(base);

		} else if (c == ESC) {		// cancel line
			curpos = base;
			clearline(curpos);
			*curpos = '\0';

		} else if (c == CUR_LEFT) {	// left arrow
			if (curpos > base)
				curpos--;

		} else if (c == CUR_RIGHT) {	// right arrow
			if (*curpos)
				curpos++;

		} else if (c == INS) {		// insert
			insflag ^= 1;
			curstate ^= 1;
			setcursor(curstate);

		} else if ((c == BACKSPACE) || (c == DEL)) {

			if (c == BACKSPACE) {
				if (curpos == base)
					continue;
				curpos--;
			}

			if (*curpos) {
				clearline(curpos);
				strcpy(curpos,curpos+1);
				position(curpos);
				efputs(curpos);
			}

		} else {

			// check for invalid or overlength entry
			if ((c > 0xFF) || ((strlen(base) >= max_length) && ((*curpos == '\0') || (insflag))))
				honk();

			else {

				// open a hole for insertions
				if (insflag)
					memmove(curpos+1,curpos,strlen(curpos)+1);

				// add new terminator if at EOL
				if (*curpos == '\0')
					curpos[1] = '\0';
				*curpos = (char)c;
				efputs(curpos++);

				// adjust home row if necessary
				position(curpos+strlen(curpos));
			}
		}
	}
}


// get & set column position in the current line
static int pascal position(char *curpos)
{
	register char *ptr;
	register int columns, rows;

	// get the number of screen lines and columns
	rows = screenrows();
	columns = screencols();
	csr_row = home_row;
	csr_col = home_col;

	// increment column position
	for (ptr = base; (ptr != curpos); ptr++)
		incr_column(*ptr,&csr_col);

	// check for line wrap
	csr_row += (csr_col / columns);
	csr_col = (csr_col % columns);

	// adjust cursor row for wrap at end of screen
	if (csr_row > rows) {
		home_row -= (csr_row - rows);
		csr_row = rows;
	}

	// set cursor to "curpos"
	screen(csr_row,csr_col);

	// return length in columns from base to curpos
	return (((csr_row - home_row) * columns) + (csr_col - home_col));
}


// scrub the line from "base" onwards
static void pascal clearline(char *ptr)
{
	register int i, n;

	i = position(ptr + strlen(ptr));

	// position cursor at "ptr" and fill line with blanks
	//  (note that a line full of tabs will be > 255 chars, which is the
	//   max allowed with qprintf)
	i -= position(ptr);

	while (i > 0) {

		if (i > CMDBUFSIZ) {
			n = CMDBUFSIZ;
			i -= CMDBUFSIZ;
		} else {
			n = i;
			i = 0;
		}

		qprintf(STDOUT,"%*s",n,NULLSTR);
	}

	screen(csr_row,csr_col);
}


// print the string to STDOUT
static void pascal efputs(register char *s)
{
	register int column;

	for ( ; *s; s++) {

		column = csr_col;
		incr_column(*s,&csr_col);

		qputc(STDOUT,*s);
	}
}


// increment the column counter
void pascal incr_column(char c, register int *column)
{
	// increment column position
	*column += 1;
}



// return the current number of screen rows (make it 0 based)
unsigned int screenrows(void)
{
	if (cfgdos.rows != 0)
		return (cfgdos.rows - 1);

	// check for EGA/VGA - if so, get rows from BIOS data area
	return (get_video() < 2) ? 24 : (int)*(char far *)0x0484L;
}


// return the current number of screen columns
unsigned int screencols(void)
{
	register int columns;

	// get the number of columns from the BIOS data area
	// (TI Professionals return 0!)
	if ((columns = (*(unsigned int far *)0x044A)) == 0)
		columns = 80;

	return columns;
}


// set the cursor type:  0 = default (underline), 1 = reverse (usually a block)
void pascal setcursor(int type)
{
	unsigned char c_start, c_end;

	// get the end & start lines for the cursor cell
	c_end = (char)cfgdos.cursor_end;

	// check for people who have a block as their default cursor
	//   and change the reverse to an underline
	if (type == 0)
		c_start = (char)cfgdos.cursor_start;
	else
		c_start = (char)((cfgdos.cursor_start == 0) ? c_end - 1 : 0);

	// get the video mode from the BIOS data area & test for BIOS
	//   bug on older machines (mono mode, cursor = 6,7)
	if (((*(char far *)0x0449) == 7) && (cfgdos.cursor_start == 6) && (cfgdos.cursor_end == 7)) {
		c_end += 6;
		if (c_start)
			c_start += 6;
	}

_asm {
	mov	ax,0100h
	mov	ch,c_start
	mov	cl,c_end
	push	bp		; for PC1 bug
	int	10h
	pop	bp
}

}


// get the cursor location & shape
void getcursor(void)
{
	unsigned char h_row, h_col, c_start, c_end;

_asm {
	mov	ax,0300h
	mov	bx,0		; page 0
	push	bp		; for PC1 bug
	int	10h
	pop	bp
	mov	h_row,dh
	mov	h_col,dl
	mov	c_start,ch
	mov	c_end,cl
}

	home_row = h_row;
	home_col = h_col;

	// set cursor shape at startup from BIOS
	if (cfgdos.cursor_end < 0) {
		cfgdos.cursor_start = c_start;
		cfgdos.cursor_end = c_end;
	}

}


// return the character attribute at the current cursor position
void pascal get_attribute(register int *normal, register int *inverse)
{
	unsigned char att;

_asm {
	mov	ah,8
	mov	bh,0		; page 0
	push	bp		; for PC1 bug
	int	10h
	pop	bp
	mov	att,ah
}
	*normal = att;

	// remove blink & intensity bits, & do a ROL 4 to get inverse
	//   (make sure foreground & background aren't identical)
	*inverse = ((*normal & 0x70) >> 4);
	if ((*normal & 0x07) == *inverse) {
		*normal = 0x07;
		*inverse = 0;
	}

	*inverse |= ((*normal & 0x07) << 4);
}

