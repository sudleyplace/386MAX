/*' $Header:   P:/PVCS/MAX/MAXIMIZE/PROFILE.C_V   1.0   05 Sep 1995 16:33:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * PROFILE.C								      *
 *									      *
 * Functions to manipulate profile					      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <string.h>

/* Local includes */
#include <maxvar.h>		/* MAXIMIZE global variables */
#include <mbparse.h>		/* MultiBoot parse functions */
#include <myalloc.h>
#include <debug.h>		/* Debug variables */

#ifndef PROTO
#include "linklist.pro"
#include "profile.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */
PRSL_T *DelPro = NULL;		/* Deleted profile options */

/* Local functions */

/****************************** REPLACE_IN_PROFILE ****************************/
/* Replace the ETYPE in the profile if found, */
/* otherwise append it.  Return 1 if high DOS regions added, otherwise 0. */

int replace_in_profile (ETYPE etype, char *Str, DWORD saddr, DWORD eaddr)

{
	PRSL_T *P;
	CONFIG_D *C;
	int ret;
	char *cmt;

	/* Search for ETYPE in existing entries */
	for (P = CfgHead; P; P = P->next)
		if (C = P->data, C->etype == etype)
		{
			/* If start and end address are specified, and */
			/* are different from the addresses they replace, */
			/* and it's not the page frame with the same start, */
			/* and the region is NOT being shrunk, flag it. */
			ret = (saddr &&
				(C->saddr != saddr || C->eaddr != eaddr) &&
				!(etype == FRAMEX && C->saddr == saddr) &&
				!(saddr >= C->saddr && eaddr <= C->eaddr));
			C->saddr = saddr;
			C->eaddr = eaddr;

			cmt = strpbrk (Str, QComments); /* Get comment */
			if (!C->comment)	/* No previous comment */
			{

				/* Include blanks which might precede the comment */
				if (cmt)
					while (C->origstr < cmt /* If we're in midstring */
					&& (cmt[-1] == ' ' /* Skip over blanks */
					|| cmt[-1] == '\t')) /* ...and tabs */
						cmt--;	/* which precede the comment */

				/* Finally, duplicate the string to something permanent */
				if (cmt) {
					C->comment = str_mem (cmt);
					*cmt = '\0';
				}
			} /* End IF */
			/* If there's an existing comment, clobber */
			/* any comment in the line we're adding */
			else if (cmt) *cmt = '\0';

			/* If there's an original string (why wouldn't there be?), */
			/* Yes, there is one, but not necessarily allocated by MALLOC */
			if (C->origstr)
				my_free (C->origstr);	/* Free it */

			C->origstr = str_mem (Str);

			return (ret);
		} /* End FOR/IF */

	/* Otherwise, just append it */
	return (add_to_profile (etype, Str, saddr, eaddr));

} /* End REPLACE_IN_PROFILE */

/******************************** ADD_TO_PROFILE ******************************/
/* Return non-zero if no entry covering the same address range with the */
/* same etype is found in the DelPro list.  In other words, the addition */
/* could possibly invalidate FLEXFRAME. */
/* Anything added by MAXIMIZE has to be in a section owned by the */
/* active section. */
int add_to_profile (ETYPE etype, char *Str, DWORD saddr, DWORD eaddr)

{
	CONFIG_D *C, *C2, *C2n;
	char *p, c;
	PRSL_T *dpwalk;
	PRSL_T *P, *Pn;
	char buff[128];

	C = get_mem (sizeof (CONFIG_D));

	C->saddr = saddr;
	C->eaddr = eaddr;
	C->etype = etype;

	/* Pick off comment (if any) */
	C->comment = strpbrk (Str, QComments);

	/* Include blanks which might precede the comment */
	if (C->comment)
	{
		p = C->comment;
		while (Str < p			/* If we're in midstring */
		&& (p[-1] == ' '           /* Skip over blanks */
		|| p[-1] == '\t'))        /* ...and tabs */
			p--;			/* which precede the comment */
		C->comment = str_mem (p);

		c = *p;
		*p = '\0';                       /* Terminate original string */
		C->origstr = str_mem (Str);
		*p = c;
	} /* End IF */
	else
		C->origstr = str_mem (Str);

#ifdef DEBUG
	if(Verbose)
		printf ("ADDING TO PROFILE:\n   %s\n", C->origstr);
#endif

	/* Find a line we want to insert after.  This may be the */
	/* end of the list, or it may be the last non-blank line. */
	/* In a MultiConfig environment, it'll usually be the last */
	/* non-blank line in the first section owned by ActiveOwner. */
	C->Owner = ActiveOwner;

	for ( P = NULL, Pn = CfgHead; Pn; Pn = Pn->next) {

	    /* Find the last line owned by ActiveOwner.  This will be */
	    /* one owned by ActiveOwner with the next entry null or */
	    /* owned by someone else. */
	    if ((C2 = Pn->data) == NULL) continue;
	    // ActiveOwner == CommonOwner if no MultiConfig active
	    if (/* MultiBoot && */ C2->Owner != ActiveOwner) continue;
	    if (C2->origstr && C2->origstr[0] && C2->origstr[0] != '\n') P = Pn;
	    if (Pn->next == NULL || (C2n = Pn->next->data) == NULL) break;
	    if (/* MultiBoot && */ C2n->Owner != ActiveOwner) break;

	} /* for all profile lines */

	if (!P) {

		if (/* MultiBoot && */ !Pn) {

		  C2 = get_mem (sizeof (CONFIG_D));
		  sprintf (buff, "\n[%s]\n", MultiBoot ? MultiBoot : "common");
		  C2->origstr = str_mem (buff);
		  C2->Owner = ActiveOwner;
		  addtolst (C2, CfgTail);

		} /* Add new section header */

		P = CfgTail;

	} /* Add to the end */

	addtolst (C, P);

	/* If no addresses are involved, high DOS not affected */
	if (!saddr)	return (0);

	/* If any address is involved, assume high DOS is changed */
	if (!DelPro)	return (1);

	/* If we find any deleted entry covering the same range, no change */
	for (dpwalk = DelPro; dpwalk->next; dpwalk = dpwalk->next) {
			if (	dpwalk->data->etype == etype &&
				dpwalk->data->saddr <= saddr &&
				dpwalk->data->eaddr >= eaddr	)
					return (0);
	}

	/* We didn't find a prior entry.  High DOS changed. */
	return (1);

} /* End ADD_TO_PROFILE */

/***************************** DEL_FROM_PROFILE *******************************/
/* Delete all etypes from the profile */

void del_from_profile (ETYPE etype)

{
	PRSL_T *L, *new, *nprev;

	for (L = CfgHead; L != NULL; L = L->next)
		if (L->data->etype == etype) {
			if (etype == RAM) {
				/* Save all RAM= statements */
				new = get_mem (sizeof (PRSL_T));
				new->data = get_mem (sizeof (CONFIG_D));
				memcpy (new->data, L->data, sizeof (CONFIG_D));
				new->prev = new->next = NULL;
				if (DelPro) {
					for (nprev = DelPro; nprev->next; )
						nprev = nprev->next;
					nprev->next = new;
				} /* DelPro != NULL */
				else {
					DelPro = new;
				} /* DelPro == NULL */
			} /* RAM statement */
			delfromlst (L, 1);
		}

} /* End DEL_FROM_PROFILE */
