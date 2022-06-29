/*' $Header:   P:/PVCS/MAX/INCLUDE/INTMSG.H_V   1.0   05 Sep 1995 13:29:58   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * INTMSG.H								      *
 *									      *
 * Definitions for intermediate message window				      *
 *									      *
 ******************************************************************************/

#ifndef INTMSG_INCLUDED
#define INTMSG_INCLUDED

void intmsg_setup(int indent);	/* Set up the window for dointmsg() */
void intmsg_save(void); 	/* Save intmsg window */
void intmsg_restore(void);	/* Restore dointmsg() window */
void intmsg_clear(void);	/* Remove intmsg window */
void intmsg_indent(int indent); /* Set intmsg indent */

void _cdecl do_intmsg(char *format,...); /* Print intermediate message */

#endif /*INTMSG_INCLUDED*/
