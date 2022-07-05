/*' $Header:   P:/PVCS/MAX/MAXIMIZE/LINKLIST.C_V   1.0   05 Sep 1995 16:33:06   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * LINKLIST.C								      *
 *									      *
 * Linked list routines 						      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stddef.h>
#include <malloc.h>

/* Local includes */
#include <maxvar.h>		/* MAXIMIZE global variables */

#ifndef PROTO
#include "linklist.pro"
#include "util.pro"             /* Utility functions */
#endif /*PROTO*/

/* Local variables */

/* Local functions */

/********************************* ADDTOLST ***********************************/
/* Append to the profile list DP just after LP. */
/* LP is typically CFG_HEAD or CFG_TAIL. */
/* The PRSL_T list is doubly linked. */

void addtolst (CONFIG_D *dp, PRSL_T *lp)

{
	PRSL_T *p;

	p = get_mem (sizeof (PRSL_T));

	p->data = dp;
	p->prev = lp;

	if (lp == NULL) 		/* If there's no list, */
		CfgHead = CfgTail = p;	/* ...start a new one with us */
	else
	{
		p->next = lp->next;		/* Our next is LP's */
		lp->next = p;			/* We're LP's next */

		if (p->next == NULL)		/* If nothing is next */
			CfgTail = p;		/* Set as new tail */
		else
			p->next->prev = p;		/* It was LP */
	} /* End ELSE */

} /* End ADDTOLST */

/********************************* DELFROMLST *********************************/
/* Delete LP from the doubly-linked list */
/* If FLAG = 0, leave the data intact if there's a comment portion */
/* otherwise, free the comment, too */

void delfromlst (PRSL_T *lp, int flag)

{
	lp->data->etype = 0;		/* Mark as untyped */

	if (flag && lp->data->comment)	/* If asked to and there's a comment, */
	{
		free_mem (lp->data->comment);	/* ...free it */
		lp->data->comment = NULL;	/* Mark as freed */
	} /* End IF */

	if (lp->data->comment == NULL)	/* If there's no comment, */
	{
		if (lp->prev == NULL)		/* If nothing prev (we're the head), */
		{
			CfgHead = lp->next;	/* ...the new head is our next */

			if (CfgHead == NULL)	/* If that's empty, */
				CfgTail = NULL; /* ...so is the tail */
			else
				CfgHead->prev = NULL;	/* Otherwise, zap prev ptr */
		} /* End IF */
		else
			lp->prev->next = lp->next;	/* Delete ourselves from next chain */

		if (lp->next == NULL)		/* If nothing next (we're the tail), */
		{
			CfgTail = lp->prev;	/* ...the new tail is our prev */

			if (CfgTail == NULL)	/* If that's empty, */
				CfgHead = NULL; /* ...so is the head */
			else
				CfgTail->next = NULL;	/* Otherwise, zap next ptr */
		} /* End IF */
		else
			lp->next->prev = lp->prev;	/* Delete ourselves from the prev chain */

		free_mem (lp);			/* Finally, free the old storage */
	} /* End IF no comment */
} /* End DELFROMLST */
