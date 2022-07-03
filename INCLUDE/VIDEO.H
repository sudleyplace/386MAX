/*' $Header:   P:/PVCS/MAX/INCLUDE/VIDEO.H_V   1.0   05 Sep 1995 13:29:56   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * VIDEO.H								      *
 *									      *
 * Video support functions						      *
 *									      *
 ******************************************************************************/

#ifndef VIDEO_INCLUDED
#define VIDEO_INCLUDED

#ifndef TYPE_WORD
#define TYPE_WORD
typedef unsigned short WORD;	/* 16-bit unsigned value */
#endif

/*
 *	Defines for video modes
 */

#define VMODE_BW80 2		/* Color hardware, mono tube */
#define VMODE_CO80 3		/* Color hardware, color tube */
#define VMODE_MONO 7		/* Mono hardware, mono tube */

/* Data types, structs, enums */

typedef enum _adapterid {	/* Video adapter IDs */
	ADAPTERID_NONE, 	/* None or unknown */
	ADAPTERID_MDA,		/* Monochrome display adapter */
	ADAPTERID_CGA,		/* Color Graphics adapter */
	ADAPTERID_EGA,		/* Enhanced Graphics adapter */
	ADAPTERID_MCGA, 	/* Multi Color Graphics Array */
	ADAPTERID_VGA,		/* Video Graphics Array */
	ADAPTERID_HGC = 0x80,	/* Hercules Graphics Card */
	ADAPTERID_HGCPLUS = 0x81, /* Hercules Graphics Card Plus */
	ADAPTERID_INCOLOR = 0x82, /* Hercules InColor Card */
} ADAPTERID;

typedef enum _displayid {	/* Video display IDs */
	DISPLAYID_NONE, 	/* None or unknown */
	DISPLAYID_MDA,		/* MDA monochrome display */
	DISPLAYID_CGA,		/* CGA color display */
	DISPLAYID_EGA,		/* EGA color display */
	DISPLAYID_PS2MONO,	/* PS/2 analog monochrome display */
	DISPLAYID_PS2COLOR	/* PS/2 analog color display */
} DISPLAYID;

typedef struct _videoid {	/* Video ID information */
	int adapter;		/* Adapter ID */
	int display;		/* Display ID */
} VIDEOID;

typedef struct _videoparm {	/* Video system parameters */
	int mode;		/* Video mode, as per int 0x10 */
	int monotube;		/* 1 if monochrome tube, independent of mode */
	int cursor;		/* Cursor shape */
	int rows;		/* Screen rows */
	int cols;		/* Screen columns */
	VIDEOID id[2];		/* Adapter / display codes for pri / sec displays */
} VIDEOPARM;

typedef unsigned short CURSOR;

/* Functions */

void get_video_parm(		/* Get video hardware parameters */
	VIDEOPARM *parm);	/* Parameter block to be filled in */

void set_video_mode(int mode);	/* Force screen to a standard mode */
void show_cursor(void); 	/* Show cursor */
void hide_cursor(void); 	/* Hide cursor */
CURSOR get_cursor(void);
CURSOR set_cursor(CURSOR cur);
CURSOR fat_cursor(void);	/* Return shape for fat (i.e. block) cursor */
CURSOR thin_cursor(void);	/* Return shape for thin (i.e. line) cursor */

void move_cursor(int row,int col);	/* Move cursor to new position */

void push_cursor(void); 	/* Save current cursor state */
void pop_cursor(void);		/* Restore previous cursor state */

long pascal far VideoID(VIDEOID far *id,int nid);

#endif /*VIDEO_INCLUDED*/
