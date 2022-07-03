/*' $Header:   P:/PVCS/MAX/QUILIB/VIDEO.C_V   1.0   05 Sep 1995 17:02:30   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * VIDEO.C								      *
 *									      *
 * Video support functions						      *
 *									      *
 ******************************************************************************/

#include <stdio.h>

#ifdef OS2_VERSION
#define INCL_VIO
#include <os2.h>
#else
#include "commdef.h"
#endif

#include "video.h"              /* Video support functions */

static BOOL InitDone = FALSE;
static VIDEOPARM VideoParm;

static struct _cursorstate {	/* Cursor state info */
	int row;		/* Row position */
	int col;		/* Column position */
	BOOL hid;		/* TRUE if cursor hidden */
	CURSOR shape;		/* Cursor shape if not hidden */
} CursorStack[5];

static int CursorSp = 0;	/* Cursor stack pointer index */

#pragma optimize ("leg",off)
void get_video_parm(		/* Get video hardware parameters */
	VIDEOPARM *parm)	/* Parameter block to be filled in */
{
#ifdef OS2_VERSION
	static VIOMODEINFO ModeInfo;
	VIOCURSORINFO CurInfo;

	ModeInfo.cb = sizeof(ModeInfo);
	VioGetMode(&ModeInfo,0);
	VioGetCurPos(&CursorStack[0].row,&CursorStack[0].col,0);
	VioGetCurType(&CurInfo,0);

	VideoParm.mode = 3;
	VideoParm.monotube = 0;
	VideoParm.cursor = (((CurInfo.yStart&0xff)<<8) | CurInfo.cEnd);

	VideoParm.rows = ModeInfo.row;
	VideoParm.cols = ModeInfo.col;
	VideoParm.id[0].adapter = ADAPTERID_VGA;
	VideoParm.id[0].display = DISPLAYID_PS2COLOR;
	VideoParm.id[1].adapter = ADAPTERID_NONE;
	VideoParm.id[1].display = DISPLAYID_NONE;
#else	/* DOS_VERSION */
	WORD shape;
	BYTE mode;
	BYTE row;
	BYTE col;
	DWORD drtn;

	VideoParm.rows = 25;
	VideoParm.cols = 80;
	drtn = VideoID(VideoParm.id,sizeof(VideoParm.id)/sizeof(VIDEOID));
	VideoParm.mode = HIWORD(drtn);
	if (VideoParm.id[0].adapter == ADAPTERID_EGA || VideoParm.id[0].adapter == ADAPTERID_VGA) {
		BYTE far * biosdata = (BYTE far *)(0x00400000L);

		VideoParm.rows = biosdata[0x84] + 1;
	}
	switch (VideoParm.id[0].display) {
	case DISPLAYID_MDA:	/* MDA monochrome display */
		VideoParm.monotube = 1;
		break;
	case DISPLAYID_PS2MONO: /* PS/2 analog monochrome display */
	    /*	Note: Since the IBM 8514/a returns incorrect DCC information
		(it identifies itself as having an analog monochrome display
		connected) we rely on the current mode setting for default
		color or b&w color sets.
	    **/
	default:
		VideoParm.monotube = 0;
		break;
	}

	/* Get video mode */
	if (!VideoParm.monotube) {
		_asm {
			mov ah,15
			int 0x10
			mov mode,al
		}
		if (mode == 0 || mode == 2 || mode == 7)
			/* Some VGA's default to mode 7 (IBM PS/2 P70) */
			VideoParm.monotube = 1;
	}

	/* Get cursor shape */
	_asm {
		mov ah,3
		mov bh,0
		int 0x10
		mov shape,cx
		mov row,dh
		mov col,dl
	}
	CursorStack[0].row = row;
	CursorStack[0].col = col;
	VideoParm.cursor = shape;
#endif /* OS2_VERSION */
	if (parm) *parm = VideoParm;
	InitDone = TRUE;
	CursorStack[0].hid = FALSE;
	CursorStack[0].shape = VideoParm.cursor;
}

void set_video_mode(int mode)	/* Force screen to a standard mode */
{
#ifdef OS2_VERSION
	if (mode);
#else	/* DOS_VERSION */
	_asm {
		mov ah,0
		mov al,byte ptr mode
		int 0x10
	}
#endif /* OS2_VERSION */
}

void hide_cursor(void)	/* Make cursor disappear */
{
	/* Already hidden? */
	if (CursorStack[CursorSp].hid) return;

#ifdef OS2_VERSION
	{
		VIOCURSORINFO info;

		VioGetCurType(&info,0);
		info.attr = -1;
		VioSetCurType(&info,0);
	}
#else	/* DOS_VERSION */
	_asm {
		mov ah,3
		mov bh,0
		int 0x10
		mov ah,1
		mov ch,0x20
		int 0x10
	}
#endif /* OS2_VERSION */
	CursorStack[CursorSp].hid = TRUE;
}

void show_cursor(void)	/* Make cursor visible */
{
	/* Already shown? */
	if (!CursorStack[CursorSp].hid) return;

#ifdef OS2_VERSION
	{
		VIOCURSORINFO info;

		VioGetCurType(&info,0);
		info.attr = 0;
		info.yStart = (CursorStack[CursorSp].shape >> 8) & 0xff;
		info.cEnd =  CursorStack[CursorSp].shape & 0xff;
		VioSetCurType(&info,0);
	}
#else	/* DOS_VERSION */
	{
		WORD shape;

		shape = CursorStack[CursorSp].shape;
		_asm {
			mov ah,1
			mov cx,shape
			int 0x10
		}
	}
#endif /* OS2_VERSION */
	CursorStack[CursorSp].hid = FALSE;
}

CURSOR get_cursor(void) 	/* Get current cursor shape */
{
	return CursorStack[CursorSp].shape;
}

CURSOR set_cursor(		/* Set cursor shape */
	WORD shape)		/* Desired cursor shape */
{
	WORD oldshape;

#ifdef OS2_VERSION
	{
		VIOCURSORINFO info;

		VioGetCurType(&info,0);
		info.yStart = ((shape>>8)&0xff);
		info.cEnd = (shape & 0xff);
		VioSetCurType(&info,0);
	}
#else	/* DOS_VERSION */
	if (!CursorStack[CursorSp].hid) _asm {
		mov ah,3
		mov bh,0
		int 0x10
		mov ah,1
		mov cx,shape
		int 0x10
	}
#endif /* OS2_VERSION */
	oldshape = CursorStack[CursorSp].shape;
	CursorStack[CursorSp].shape = shape;
	return oldshape;
}

CURSOR fat_cursor(void) 	/* Return shape for fat (i.e. block) cursor */
{
	WORD newshape;
	if (!InitDone) {
		get_video_parm(NULL);
	}

	switch (VideoParm.id[0].adapter) {
	case ADAPTERID_MDA:
	case ADAPTERID_HGC:
	case ADAPTERID_HGCPLUS:
	case ADAPTERID_INCOLOR:
		newshape = 0x010C;
		break;
	case ADAPTERID_CGA:
	case ADAPTERID_EGA:
	case ADAPTERID_MCGA:
		newshape = 0x0107;
		break;
	case ADAPTERID_VGA:
		newshape = 0x010E;
		break;
	}
	return newshape;
}

CURSOR thin_cursor(void)	/* Return shape for thin (i.e. line) cursor */
{
	WORD newshape;
	if (!InitDone) {
		VIDEOPARM dummy;
		get_video_parm(&dummy);
	}

	switch (VideoParm.id[0].adapter) {
	case ADAPTERID_MDA:
	case ADAPTERID_HGC:
	case ADAPTERID_HGCPLUS:
	case ADAPTERID_INCOLOR:
		newshape = 0x0B0C;
		break;
	case ADAPTERID_CGA:
	case ADAPTERID_EGA:
	case ADAPTERID_MCGA:
		newshape = 0x0607;
		break;
	case ADAPTERID_VGA:
		newshape = 0x0D0E;
		break;
	}
	return newshape;
}

void move_cursor(		/* Move cursor to new position */
	int y,			/* Vertical position, from 0 */
	int x)			/* Horizontal position, from 0 */
{
#ifdef OS2_VERSION
	VioSetCurPos(y,x,0);
#else	/* DOS_VERSION */
	_asm {
		mov ah,2
		mov bh,0
		mov dl,byte ptr x
		mov dh,byte ptr y
		int 0x10
	}
#endif /* OS2_VERSION */
	CursorStack[CursorSp].row = y;
	CursorStack[CursorSp].col = x;
}

void push_cursor(void)		/* Save current cursor state */
{
	if (CursorSp+1 >= sizeof(CursorStack)/sizeof(CursorStack[0])) {
		/* Stack overflow, do nothing */
		return;
	}
	CursorSp++;
	CursorStack[CursorSp] = CursorStack[CursorSp-1];
}

void pop_cursor(void)		/* Restore previous cursor state */
{
	if (CursorSp < 1) {
		/* Stack underflow, do nothing */
		return;
	}
	CursorSp--;

	move_cursor(CursorStack[CursorSp].row,CursorStack[CursorSp].col);
	if (CursorStack[CursorSp].hid) {
		CursorStack[CursorSp].hid = FALSE;
		hide_cursor();
	}
	else {
		CursorStack[CursorSp].hid = TRUE;
		show_cursor();
	}
}


#pragma optimize ("",on)
