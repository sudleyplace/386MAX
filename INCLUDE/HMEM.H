/*' $Header:   P:/PVCS/MAX/INCLUDE/HMEM.H_V   1.1   02 Jun 1997 14:37:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * HMEM.H								      *
 *									      *
 * Memory handle manager definitions					      *
 *									      *
 ******************************************************************************/

#ifndef HMEM_INCLUDED
#define HMEM_INCLUDED

#include <commdef.h>		/* Common definitions */
#define MAX_ALLOC_SIZE 0xFF00

HANDLE mem_alloc(		/* Allocate a memory handle */
	WORD nbytes,		/* How many bytes */
	int type);		/* Memory type */

LPVOID mem_lock(		/* Lock handle, return pointer */
	HANDLE handle); 	/* Memory handle */

LPVOID mem_unlock(		/* Unlock handle */
	HANDLE handle); 	/* Memory handle */

HANDLE mem_realloc(		/* Allocate a memory handle */
	HANDLE handle,		/* Memory handle */
	WORD nbytes);		/* How many bytes */

HANDLE mem_clone(		/* Clone a memory handle - Return the new one */
	HANDLE handle); 	/* Memory handle */

BOOL mem_grow(			/* Grow a memory handle */
	LPHANDLE handle,	/* Pointer to memory handle */
	WORD   nbytes); 	/* How many bytes to grow by */

void mem_free(			/* Free a memory handle */
	HANDLE handle); 	/* Memory handle */

void mem_setname(		/* Set name for a memory handle */
	HANDLE handle,		/* Memory handle */
	LPSTR name);		/* Name, 1 to 9 chars */

void mem_report(		/* Report handle table */
	int flag);		/* 0 for normal, 1 for full report */

void mem_sethwin(LPVOID wndp);	/* Set window handle for debug messages */

#endif	/*HMEM_INCLUDED*/
