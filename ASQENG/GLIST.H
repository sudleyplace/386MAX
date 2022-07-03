/*' $Header:   P:/PVCS/MAX/ASQENG/GLIST.H_V   1.1   30 May 1997 14:58:38   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * GLIST.H								      *
 *									      *
 * Generic linked list system						      *
 *									      *
 ******************************************************************************/

#ifndef GLIST_INCLUDED
#define GLIST_INCLUDED

typedef enum _glisttype {	/* Generic list types */
	GLIST_LINKED,		/* Doubly linked list (default) */
	GLIST_ARRAY		/* Linear or array type list */
} GLISTTYPE;

typedef struct _glisthdr {	/* Generic linkde list header */
	void *next;		/* Pointer to next record (sort of) */
	void *prev;		/* Pointer to previous record (sort of) */
} GLISTHDR;

typedef struct _glist { 	/* Generic linked list */
	GLISTTYPE type; 	/* Type of list */
	unsigned count; 	/* Item count */
	unsigned size;		/* How many bytes per item */
	unsigned inc;		/* Incremental allocation for array lists */
	char *first;		/* Pointer to first item */
	char *last;		/* Pointer to last item of linked list */
				/* ..or last byte + 1 of array list */
} GLIST;

/* Macros */
#define glist_head(g) ((void *)((g)->first))
#define glist_count(g) ((g)->count)

/* BEWARE!  These only work on LINKED lists */
#define glist_hdr(g) ((GLISTHDR *)(((char *)(g))-sizeof(GLISTHDR)))

/* Functions */
void glist_init(		/* Initialize a list */
	GLIST *list,		/* Pointer to list */
	GLISTTYPE type, 	/* List type */
	unsigned size,		/* Item size for array lists */
	unsigned inc);		/* Incremental allocation for array lists */

void * glist_tail(		/* Return pointer to last item in list */
	GLIST *list);		/* Target list */

void glist_alloc(		/* Allocate buffer for array list */
	GLIST *list,		/* Pointer to list */
	unsigned size); 	/* How many bytes for buffer */

void * glist_new(		/* Add a new item to a list */
	GLIST *list,		/* Target list */
	void *data,		/* Data to add */
	int size);		/* How many bytes in data */

void * glist_insert(		/* Insert an item in a list */
	GLIST *list,		/* Target list */
	void *where,		/* Which item to insert before */
	void *data,		/* Data item to insert */
	int size);		/* How many bytes in data item */

void *glist_delete(		/* Delete an item from a list */
	GLIST *list,		/* Target list */
	void *which);		/* Which item to delete */

void glist_purge(		/* Purge an entire list */
	GLIST *list);		/* Target list */

void glist_sort(		/* Sort a list */
	GLIST *list,		/* Target list */
	int (_cdecl *cmpf)(const void *,const void *)); /* Compare function */

void glist_array(		/* Convert from linked list to array list */
	GLIST *list,		/* Target list */
	unsigned size,		/* Item size in bytes if not 0 */
	unsigned inc);		/* Allocation increment if not 0 */

void glist_linked(		/* Convert from array list to linked list */
	GLIST *list);		/* Target list */

void *glist_next(		/* Return pointer to next item */
	GLIST *list,		/* Target list */
	void *here);		/* Where we are now */

void *glist_prev(		/* Return pointer to previous item */
	GLIST *list,		/* Target list */
	void *here);		/* Where we are now */

void *glist_lookup(		/* Look up list item by ordinal */
	GLIST *list,		/* Target list */
	int ord);		/* Ordinal, from 1 */

#endif /* GLIST_INCLUDED */
/* Thu Feb 21 12:47:32 1991 alan:  add glist_tail() */
