/*' $Header:   P:/PVCS/MAX/INCLUDE/MESSAGE.H_V   1.1   02 Jun 1997 14:37:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * MESSAGE.H								      *
 *									      *
 * Message header file							      *
 *									      *
 ******************************************************************************/

#ifndef MESSAGE_INCLUDED
#define MESSAGE_INCLUDED

#ifndef BUTTON_INCLUDED
#include <button.h>
#endif

typedef enum {
	ERRTYPE_WINDOW,
	ERRTYPE_INFO,
	ERRTYPE_PRINT,
	ERRTYPE_FILE,
	ERRTYPE_HELP,
	ERRTYPE_ACTION,
	ERRTYPE_MESSAGE,
	ERRTYPE_WARNING,
	ERRTYPE_DEVICE,
	ERRTYPE_DISK,
	ERRTYPE_LAST
} ERROR_TYPE;			/*	What type of error messages are there */


typedef struct {
	int number;			/*	Message number */
	ERROR_TYPE type;		/*	What type of error is this */
	int buttonCount;		/*	How many buttons in this message */
	PBUTTON buttons;		/*	Pointer to list of buttons that go with it */
	char *message;			/*	Text to go with it */
} MSG;
typedef MSG *PMSG;


int askMessage( int message_number);

void errorMessage( int error_number );

PMSG findMessage( int message_number);

#endif /*  MESSAGE_INCLUDED */
