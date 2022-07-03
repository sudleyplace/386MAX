/*' $Header:   P:/PVCS/MAX/QUILIB/WINSVRS.C_V   1.0   05 Sep 1995 17:02:44   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * WINSVRS.C								      *
 *									      *
 * Functions to save/restore text windows				      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdlib.h>

/*	Program Includes */
#include "screen.h"
#include "windowfn.h"
#include "myalloc.h"

/*	Definitions for this Module */
#define HALFSHADOWWIDTH 1
#define SHADOWWIDTH 2
#define SHADOWHEIGHT 1

/*	Program Code */
/**
*
* Name		win_save
*
* Synopsis	void *win_save( WINDESC *win, int shadowed )
*
* Parameters
*		WINDESC *win;		Window descriptor of window to save
*		int shadowed;		Save the shadow area TO
*
* Description
*		Dump a screen block into an allocated buffer.  The front of
*	the buffer contains a WINDESC that describes what we snapshot.
*	This makes things simpler to restore.
*
* WARNING - If you adjust this - Check askmenu in the callback logic
*
* Returns	Pointer to buffer that contains saved image and paint info
*			Null if the allocated block failed
*
* Version	1.0
*/
void *win_save( 			/*	Save a block of video memory */
	WINDESC *win,			/*	Definition of what to save	*/
	SHADOWTYPE shadow )			/*	Should we save the shadow area too */
{
	int width = win->ncols;
	int height = win->nrows;
	int area;
	WINDESC *buff;

	switch( shadow ) {
	case SHADOW_SINGLE:
		width += HALFSHADOWWIDTH;
		if( win->col + width >= ScreenSize.col )
			width = ScreenSize.col - win->col;
		height += SHADOWHEIGHT;
		if( win->row + height >= ScreenSize.row )
			height = ScreenSize.row - win->row;

	case SHADOW_DOUBLE:
		width += SHADOWWIDTH;
		if( win->col + width >= ScreenSize.col )
			width = ScreenSize.col - win->col;
		height += SHADOWHEIGHT;
		if( win->row + height >= ScreenSize.row )
			height = ScreenSize.row - win->row;
		break;
	}
	area = sizeof( WINDESC ) + (width * height * sizeof(WORD));

	buff = my_malloc(area); 		/*	Allocate enough room to hold things */
	if (buff) {
		*buff = *win;
		buff->nrows = height;
		buff->ncols = width;
		wget_ca(buff,(WORD *)(buff+1));
	}
	return (void *)buff;
}

/**
*
* Name		win_restore
*
* Synopsis	void *win_restore( void *buffer, int release )
*
* Parameters
*		void *buffer;			What to restore
*		int  release;			Should we free the buffer this time
*
* Description
*		Take a preserved screen block and put it back to the screen
*	Drop the block if requested.
*
* WARNING - If you adjust this - Check askmenu in the callback logic
*
* Returns	The pointer to the save buffer - NULL if buffer released
*
* Version	1.0
*/
void *win_restore(			/*	Restore a block of video memory */
	void *buffer,			/*	what to restore */
	int release )			/*	Should the buffer be released */
{
	wput_ca((WINDESC *)buffer, (WORD *)((WINDESC *)buffer+1));
	if( release && buffer ) {
		my_free( buffer );
		buffer = NULL;
	}
	return buffer;
}
