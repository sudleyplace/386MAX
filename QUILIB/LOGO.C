/*' $Header:   P:/PVCS/MAX/QUILIB/LOGO.C_V   1.3   11 Nov 1995 14:02:56   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * LOGO.C								      *
 *									      *
 * Display the Qualitas 'Q' logo                                              *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include <conio.h>
#include <process.h>

/*	Program Includes */
#include "commfunc.h"
#include "libcolor.h"
#include "screen.h"
#include "ui.h"
#include "myalloc.h"
#include "windowfn.h"


/* Local functions */

void wcenter(WINDESC *win,int row,char *text,char attr);

void qlogo(		/* Do qlogo, part 1 */
	int mode,		/* 1=on, 0=off, -1=end */
	char *filename, 	/* Name of char def file */
	int isvga,		/* TRUE for VGA adapter */
	int isq,		/* TRUE for 'Q' logo */
	int row,		/* Row on screen */
	int col,		/* Column on screen */
	int color,		/* Attribute value */
	void (*callback)(void)); /* Callback function */

int set_vmode(int	flag,int monitor);
void paint_text(int row,int col,char *str,int nstr,int attr);
void wait_retrace(void);


/*
doit > 0 == put up graphics logo
doit < 0 == take down graphics logo
doit == 0 == dont do graphics logo
*/


int showLogo(int doit,char *which,char **lines,char *serial,void (*callback)(void))
{
	int rtn;
	int kk;
	char temp1[128];
	BYTE *cp;
	int   count = 0;

	/* Check serial text for funny chars, with a few exceptions */
	if (doit > 0 && serial) {
		// Delete trailing CR, LF
		for (kk = strlen(serial) - 1; kk > 0; kk--)
		     if (serial[kk] == '\r' || serial[kk] == '\n')
			 serial[kk] = '\0';
		     else
			break;

		for (cp = serial+1; *cp; cp++) {
			// If there's an embedded CR or LF, change to '-'
			if (*cp == '\r' || *cp == '\n')
			    *cp = '-';
			else
			if (*cp > 126 && *cp == 'à' && *cp == 'á' &&
					*cp < 231) {
				doit = 0;
				break;
			}
		}
	}

	/* get exepath into filename here */

	get_exepath(temp1,128);
	strcat(temp1,"QLOGO.OVL");

	if ((AdapterType == ADAPTERID_VGA || AdapterType == ADAPTERID_EGA) &&
	    ScreenSize.row == 25 && doit && win_version() == 0 &&
	    _access(temp1,0) == 0) {

		qlogo(doit,
		      temp1,
		      AdapterType == ADAPTERID_VGA,
		      which ? *which : '*',
		      7,
		      17,
		      LogoColor,
		      callback);

		rtn = 0;
		if (doit < 0) goto bottom;
	}
	else {
		/* Put up alternate logo */
		int row1;
		WINDESC win;
		WINDESC win2;

		/* Background */
		if (callback) (*callback)();

		win.row = DataWin.row + (DataWin.nrows - ALOGOHEIGHT) / 2;
		win.col = DataWin.col + (DataWin.ncols - ALOGOWIDTH) / 2;
		win.nrows = ALOGOHEIGHT;
		win.ncols = ALOGOWIDTH;
		wput_sa(&win,AltLogoColor);

		/* Corners */
		win2.row = win.row;
		win2.col = win.col + 1;
		win2.nrows = win2.ncols = 1;
		wput_c(&win2,AltLogoCorners+0);
		win2.col = win.col + win.ncols - 2;
		wput_c(&win2,AltLogoCorners+1);
		win2.row = win.row + win.nrows - 1;
		wput_c(&win2,AltLogoCorners+2);
		win2.col = win.col + 1;
		wput_c(&win2,AltLogoCorners+3);

		/* Text */
		row1 = (win.nrows - ALTLOGOLINES) / 2;
		for (kk = 0; kk < ALTLOGOLINES; kk++, row1++) {
			wcenter(&win,row1,AltLogoText[kk],AltLogoColor);
		}
		rtn = 1;
	}

	wcenter(&DataWin,1,lines[0],DataColor);
	wcenter(&DataWin,3,lines[1],DataColor);

	if (serial) {
		char *pp1;
		char *pp2;
		char *pp3;

		strcpy(temp1,serial);
		// Delete initial line count
		if (*temp1 > 0 && *temp1 < ' ') *temp1 = ' ';
		trim(temp1);
		pp1 = strstr(temp1," - ");
		pp2 = strstr(temp1,"--");
		if (pp1 || pp2) {
			// Split at the earlier break point
			if (pp1 && pp2)
			    pp3 = (pp1 < pp2) ? pp1 : pp2;
			else if (pp1)
			    pp3 = pp1;
			else
			    pp3 = pp2;

			*pp3 = '\0';
			pp2 = pp3+2;
			pp1 = temp1;
			trim(pp1);
			trim(pp2);
		}
		else {
			pp1 = temp1;
			pp2 = NULL;
		}

		if (*pp1) {
			wcenter(&DataWin,DataWin.nrows-3,pp1,DataColor);
		}
		if (pp2) {
			int nc;

			nc = strlen(LicensedTo);
			if (strlen(pp2) > (unsigned)DataWin.ncols-2) {
				if (_memicmp(pp2,LicensedTo,nc) == 0) {
					strcpy(pp2,LicColon);
					strcat(pp2,pp2+nc);
				}
			}
			wcenter(&DataWin,DataWin.nrows-2,pp2,DataColor);
		}
	}

	wcenter(&QuickWin,1,lines[2],QHelpColors[0]);
	for (kk = 3; lines[kk]; kk++) {
		wcenter(&QuickWin,kk,lines[kk],QHelpColors[0]);
	}

	for (count = 0; LogoAddress[count]; count++);

	for (kk = 0; kk < count; kk++) {
		wcenter(&QuickWin,QuickWin.nrows-1+kk-count,LogoAddress[kk],QHelpColors[0]);
	}

bottom:
	return (rtn == 0) ? 0 : 1;
}

void wcenter(WINDESC *win,int row,char *text,char attr)
{
	int nc;
	WINDESC workwin;

	nc = strlen(text);

	if (nc < 1) return;
	if (nc > win->ncols-2) nc = win->ncols-2;

	workwin = *win;
	workwin.row += row;
	workwin.nrows = 1;
	workwin.col += (win->ncols - nc) / 2;
	workwin.ncols = nc;

	wput_csa(&workwin,text,attr);
}

/*
 *	Q/Asq logo code.  Formerly QLOGO.EXE
 */


/* defines */
enum _states { ON, OFF, END};

#pragma optimize ("leg",off)
void qlogo(		/* Do qlogo, part 1 */
	int mode,		/* +1=on,-1=off */
	char *filename, 	/* Name of char def file */
	int isvga,		/* TRUE for VGA adapter */
	int isq,		/* Which logo:	'Q' or 'A' */
	int row,		/* Row on screen */
	int col,		/* Column on screen */
	int color,		/* Attribute value */
	void (*callback)(void)) /* Callback function */
{
	int	 i;
	char  *p1 = NULL;
	char  *p2 = NULL;
	char far *fp2 = NULL;

	int	 nchars;
	int	 nothing;

	int	 fh = 0;

	if (row < 0) row = 7;
	if (col < 0) col = 17;
	if (color < 0) color = LogoColor;

	if (mode < 0) {
		wput_sca(&DataWin,VIDWORD(color,' '));

		set_vmode(OFF, isvga);

		/* re-load the original character set */
		if (isvga) {
			wait_retrace();        /* wait until we are in retrace */
			_asm {
				mov ax, 1104H  /* Set function and subfunction number */
				mov bx, 0000H  /* set bytes per character and block (use 0E00H for ega */
				int 10h
			}
		}
		else {
			wait_retrace();        /* wait until we are in retrace */
			_asm {
				mov ax, 1101H  /* Set function and subfunction number */
				mov bx, 0000H  /* set bytes per character and block (use 0E00H for ega */
				int 10h
			}
		}
		set_vmode(END, isvga);
		if (callback) (*callback)();
		return;
	}

	/* Else:  ON */
	set_vmode(ON, isvga);

	if (callback) (*callback)();

	/* _open the logo file and _read in the number of characters in the logo */
	if ((fh = _open(filename, O_RDONLY)) == -1) goto done;

	if ((nothing = _read (fh, (char *)&nchars, sizeof(int))) != 2) goto done;

	if (isq == 'A') {
		long skip;

		skip = 2 + (12 * 22) + (nchars * 14);
		if (_lseek(fh,skip,0) != skip) goto done;
		if ((nothing = _read (fh, (char *)&nchars, sizeof(int))) != 2) goto done;
	}

	/* allocate temporary space for the logo character redefinitions p2
	   and for the character matrix to print */
	if ((p1 = (char *)my_malloc(12 * 22))	 == NULL) goto done;
	if ((p2 = (char *)my_malloc(nchars * 14))	 == NULL) goto done;

	/* _read in the character redefinitions and the print matrix */
	if (( nothing = _read (fh,p1,12 * 22 )) != 12 * 22) goto done;
	if (( nothing = _read (fh,p2, nchars * 14)) != nchars * 14) goto done;	  /* nchars1 * 14 */

	/* load up the altered character set */
	wait_retrace();   /* wait until we are in retrace */
	fp2 = p2;
	_asm {
		mov ax, 1100H  /* Set function and subfunction number */
		mov bx, 0E00H	/* set bytes per character and block (use 0E00H for ega */
		mov cx, nchars /* redefine n characters */
		mov dx, 127	/* starting at character 127 */
		les si, fp2
		push bp
		mov bp, si
		int 10h     /* do it */
		pop bp
	}

	/* now actually draw the logo on the screen */
	for (i = 0; i < 12; i++) {
		paint_text(i+row, col,p1 + (22 * i),22,color);
	}

done:

	if (fh) _close(fh);
	if (p1) my_free(p1);
	if (p2) my_free(p2);
}

#define VGA  1

int set_vmode(int flag, int monitor)
{

 static int lastmode;

   if (flag == END) {
      if (monitor == VGA) {
	   _asm {
	    mov ax,lastmode	/* Set mode 2 or 3 */
	    int 0x10		/* Call int 10 */
	   }
	   reset_mode ();	/* Tell windowfns we might have changed modes */
      }
      return(0);
   }

   if (flag == ON) {
      /* Save initial mode on entry */
      _asm {
	   mov ah,0x0f		/* Get mode */
	   int 0x10		/* Call int 10 */
	   sub ah,ah		/* Convert to word */
	   mov lastmode,ax	/* Save for later comparison */
      }
      /* Make sure we preserve the color-enabled bit */
      if (lastmode <= 3)	lastmode |= 2;	/* Force 80 columns */
      else			lastmode = 3;

      if (monitor == VGA) {
	 wait_retrace();	/* wait until we are in retrace */
	 _asm {
	    mov ah,12H	/* step 1: go into 350 scan line mode */
	    mov al, 1H
	    mov bl,30H
	    int   10H

	    mov ax,lastmode	/* Get mode 2 or 3 */
	    or	al,80H		/* Change modes without erasing screen */
	    int   10H
	 }
      }
   }
   else {
      if (monitor == VGA) {
	 wait_retrace();	/* wait until we are in retrace */
	 _asm {
	    mov ah,12H	/* step 1: go into 480 scan line mode */
	    mov al, 2H
	    mov bl,30H
	    int   10H

	    mov ax,lastmode	/* Get mode 2 or 3 */
	    or	al,80H		/* Change modes without erasing screen */
	    int   10H
	 }
      }
   }
   reset_mode();	/* Tell windowfns we might be in a new mode */
   return(0);
}

/* paint directly to the display memory, thereby avoiding an int 10 call
   that used to trash the color on a previous version of this program. */

void paint_text(int row,int col,char *str,int nstr,int attr)
{
	int ii;
	char far *pp;

	/* This works because we are NEVER here with less than an
	 * EGA or VGA adapter.
	 */
	pp = (char far *)0xb8000000L;
	pp += row*2*80;
	pp += col*2;

	for (ii = 0; ii < nstr; ii++) {
		*pp++ = *str++;
		*pp++ = (char)attr;
	}
}

#pragma optimize("leg",off)
/* wait for the card to be in retrace mode before doing anything */
void wait_retrace(void)
{

   _asm {
	mov	dx,0x40;	/* Get BIOSDATA segment */
	mov	es,dx;		/* Address it using ES */
	mov	dx,es:[0x63];	/* Get CRT base port */
	add	dx,6;		/* Point to 3BA/3DA */
WR_LOOP1:
	in	al,dx;		/* Get byte */
	test	al,8;		/* Check bit 3 */
	jnz	WR_LOOP1;	/* Jump if set */

WR_LOOP2:
	in	al,dx;		/* Get byte */
	test	al,8;		/* Check bit 3 */
	jz	WR_LOOP2;	/* Jump if clear */
   }

}
#pragma optimize("",on)
