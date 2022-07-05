/*' $Header:   P:/PVCS/MAX/INCLUDE/WINDOWFN.H_V   1.0   05 Sep 1995 13:29:56   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * WINDOWFN.H								      *
 *									      *
 * Window functions							      *
 *									      *
 ******************************************************************************/


#ifndef WINDOWFN_INCLUDED
#define WINDOWFN_INCLUDED

#ifndef NEAR
#define NEAR _near
#endif
#ifndef FAR
#define FAR _far
#endif

#ifndef TYPE_WORD
#define TYPE_WORD
typedef unsigned short WORD;	/* 16-bit unsigned value */
#endif

/* Window I/O modes */
#define WINMODE_FAST	0	/* Fast update mode */
#define WINMODE_SLOW	1	/* Slow update mode (for CGA) */
#define WINMODE_SCRUP	2	/* Screen update mode */

/*	How to get parts of an attribute */
#define BACKTOFORE( attr ) (((attr) & 0xf0)>>4)
#define FORETOBACK( attr ) (((attr) & 0xf)<<4)
#define BACKGROUND( attr ) ((attr) & 0xf0)
#define FOREGROUND( attr ) ((attr) & 0xf)

/* Color codes */
#define FG_BLACK	0x00
#define FG_BLUE 	0x01
#define FG_GREEN	0x02
#define FG_CYAN 	0x03
#define FG_RED		0x04
#define FG_MAGENTA	0x05
#define FG_BROWN	0x06
#define FG_GRAY 	0x07
#define FG_DKGRAY	0x08
#define FG_LTBLUE	0x09
#define FG_LTGREEN	0x0A
#define FG_LTCYAN	0x0B
#define FG_LTRED	0x0C
#define FG_LTMAGENTA	0x0D
#define FG_YELLOW	0x0E
#define FG_WHITE	0x0F

#define BG_BLACK	0x00
#define BG_BLUE 	0x10
#define BG_GREEN	0x20
#define BG_CYAN 	0x30
#define BG_RED		0x40
#define BG_MAGENTA	0x50
#define BG_BROWN	0x60
#define BG_GRAY 	0x70

#define FG_BLINK	0x80
#define FG_BRIGHT	0x08

#ifndef TYPE_WINDESC
#define TYPE_WINDESC
typedef struct _windesc {	/* Window descriptor */
	int row;		/* Starting row, from 0 */
	int col;		/* Starting column, from 0 */
	int nrows;		/* Number of rows */
	int ncols;		/* Number of columns */
} WINDESC;
#endif /*TYPE_WINDESC*/

/* Macros */

/* Init window descriptor */
#define SETWINDOW(w,r,c,nr,nc) {(w)->row=(r);(w)->col=(c);(w)->nrows=(nr);(w)->ncols=(nc);}

/*	Flip background foreground info */
#define REVATT( a ) ((char)((((a)&0x7) << 4 ) | (((a)&0x70) >> 4 )))

/* Assemble one video data word */
#define VIDWORD(a,c) (((((WORD)a)&0xff)<<8) | ((c)&0xff))

/* Exported functions */

void wput_c(		/* Put characters only into a window. */
	WINDESC *win,	/* Window descriptor */
	char *text);	/* Text to display */

void wput_a(		/* Put attributes only into a window. */
	WINDESC *win,	/* Window descriptor */
	char *attr);	/* Attributes to display */

void wput_sc(		/* Smear (fill) a character into a window. */
	WINDESC *win,	/* Window descriptor */
	char text);	/* Character to fill with */

void wput_sa(		/* Smear (fill) an attribute into a window. */
	WINDESC *win,	/* Window descriptor */
	char attr);	/* Attribute to fill with */

void wput_ca(		/* Put text and attributes into a window. */
	WINDESC *win,	/* Window descriptor */
	WORD *textattr);/* Text and attributes to write */

void wput_sca(		/* Smear text and attribute into a window. */
	WINDESC *win,	/* Window descriptor */
	WORD textattr); /* Text and attributes to write */

void wput_csa(		/* Put text & smear attribute into a window. */
	WINDESC *win,	/* Window descriptor */
	char *text,	/* Text to display */
	char attr);	/* Attribute to fill with */

void wget_c(		/* Get chararacters only from a window. */
	WINDESC *win,	/* Window descriptor */
	char *text);	/* Text returned here */

void wget_a(		/* Get attributes only from a window.	*/
	WINDESC *win,	/* Window descriptor */
	char *attr);	/* Attributes returned here */

void wget_ca(		/* Get chararacters and attributes from a window. */
	WINDESC *win,	/* Window descriptor */
	WORD *textattr);/* Text/attributes returned here */

void set_mode(		/* Set the video state to an 80-column screen */
	int mode);	/* See WINMODE definitions above */

void reset_mode(void);	/* Reset the internal video state based upon the current mode */

#endif /*WINDOWFN_INCLUDED*/
