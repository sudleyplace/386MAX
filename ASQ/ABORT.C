/*' $Header:   P:/PVCS/MAX/ASQ/ABORT.C_V   1.0   05 Sep 1995 15:04:44   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * ABORT.C								      *
 *									      *
 * Bailout routine for ^C or A/R/I traps				      *
 *									      *
 ******************************************************************************/

#include "commfunc.h"
#include "ui.h"

void abortprep(int flag)
{
	if (flag);
	end_input();
	move_cursor(ScreenSize.row-1, 0 );
	show_cursor();
	set_cursor( thin_cursor() );

	/*	Lazy way to clear the screen */
	SETWINDOW( &DataWin, 0,0, ScreenSize.row, ScreenSize.col );
	wput_sca( &DataWin, VIDWORD( FG_GRAY|BG_BLACK, ' ' ));
	done2324();
}
