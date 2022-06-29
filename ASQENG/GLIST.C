/*' $Header:   P:/PVCS/MAX/ASQENG/GLIST.C_V   1.2   02 Jun 1997 14:40:04   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * GLIST.C								      *
 *									      *
 * Generic linked list functions					      *
 *									      *
 ******************************************************************************/

/*
 *	These functions implement a generic list that can be either
 *  doubly linked, or linear.
 */

#include <stdio.h>		/* C runtime includes */
#include <stdlib.h>
#include <string.h>

#include <commfunc.h>
#include <myalloc.h>
#include "glist.h"              /* Generic list functions */

#define GLIST_C
#include "engtext.h"            /* Text strings */

void glist_init(		/* Initialize a list */
	GLIST *list,		/* Pointer to list */
	GLISTTYPE type, 	/* List type */
	unsigned size,		/* Item size for array lists */
	unsigned inc)		/* Incremental allocation for array lists */
{
	memset(list,0,sizeof(GLIST));
	list->type = type;
	list->size = size;
	list->inc = (inc > size) ? inc : size;
}

void glist_alloc(		/* Allocate buffer for array list */
	GLIST *list,		/* Pointer to list */
	unsigned size)		/* How many bytes for buffer */
{
	if (list->type != GLIST_LINKED) {
		list->first = my_malloc(size);
		memset(list->first,'?',size);
		if (!list->first) goto disaster;
		list->last = list->first + size;
	}
	return;
disaster:
	nomem_bailout(201);
}

void * glist_tail(		/* Return pointer to last item in list */
	GLIST *list)		/* Target list */
{
	if (!list) return NULL;
	if (list->type == GLIST_LINKED) return list->last;
	else {
		if (list->count) return (char *)list->first + ((list->count-1) * list->size);
		else return NULL;
	}
}

void * glist_new(		/* Add a new item to a list */
	GLIST *list,		/* Target list */
	void *data,		/* Data to add */
	int size)		/* How many bytes in data */
{
	if (!list || list->type == GLIST_LINKED) {
		GLISTHDR *hdr;		/* Pointer to list header */
		char *newitem;		/* Pointer to new item */

		newitem = my_malloc(sizeof(GLISTHDR) + size);
		if (!newitem) goto disaster;

		if (data) {
			memset(newitem,0,sizeof(GLISTHDR));
			memcpy(newitem+sizeof(GLISTHDR),data,size);
		}
		else	memset(newitem,0,size+sizeof(GLISTHDR));

		if (!list) return newitem; /* Short circuit */

		hdr = (GLISTHDR *)newitem;
		newitem += sizeof(GLISTHDR);

		hdr->next = hdr->prev = NULL;
		if (!list->first) {
			list->first = list->last = newitem;
		}
		else {
			hdr->prev = list->last;
			glist_hdr(list->last)->next = newitem;
			list->last = newitem;
		}
		list->count++;
		return newitem;
	}
	else {
		unsigned used;	/* Bytes used in array */
		unsigned total; /* Bytes total in array */
		char *p;	/* Pointer into array */

		if (!list->first) {
			unsigned n;

			n = list->inc > list->size ? list->inc : list->size;
			list->first = my_malloc(n);
			if (!list->first) goto disaster;

			list->last = list->first + n;
		}

		used = list->count * list->size;
		total = list->last - list->first;

		if (used+size > total) {
			p = my_realloc(list->first,total + list->inc);
			if (!p) goto disaster;

			total += list->inc;
			list->first = p;
			list->last = p + total;
		}

		p = list->first+used;

		if (data) memcpy(p,data,size);
		else	  memset(p,0,size);

		list->count++;
		return p;
	}

disaster:
	nomem_bailout(202);
}

void * glist_insert(		/* Insert an item in a list */
	GLIST *list,		/* Target list */
	void *where,		/* Which item to insert before */
	void *data,		/* Data item to insert */
	int size)		/* How many bytes in data item */
{
	if (!list || !where) return glist_new(list,data,size);

	if (list->type == GLIST_LINKED) {
		GLISTHDR *newhdr;	/* Pointer to new list header */
		GLISTHDR *thishdr;	/* Pointer to target list header */
		char *newitem;		/* Pointer to new item */

		newitem = my_malloc(sizeof(GLISTHDR) + size);
		if (!newitem) goto disaster;

		if (data) {
			memset(newitem,0,sizeof(GLISTHDR));
			memcpy(newitem+sizeof(GLISTHDR),data,size);
		}
		else	memset(newitem,0,size+sizeof(GLISTHDR));

		newhdr = (GLISTHDR *)newitem;
		newitem += sizeof(GLISTHDR);

		thishdr = glist_hdr(where);

		newhdr->next = where;
		newhdr->prev = thishdr->prev;
		thishdr->prev = newitem;

		if (where == list->first) {
			list->first = newitem;
		}
		else {
			glist_hdr(newhdr->prev)->next = newitem;
		}
		list->count++;
		return newitem;
	}
	else {
		unsigned offset;	/* Offset to selected item */
		char *here;		/* Pointer to where to insert */
		char *end;		/* Pointer to end of real data */

		/* Make empty space in the list */
		offset = (char *)where - list->first;
		glist_new(list,NULL,size);
		where = list->first + offset;

		here = (char *)where + list->size;
		end = list->first + (list->count * list->size);
		if (here < end) memmove(here,where,end - here);
		memcpy(where,data,list->size);
		return where;
	}
disaster:
	nomem_bailout(203);
}

void *glist_delete(		/* Delete an item from a list */
	GLIST *list,		/* Target list */
	void *which)		/* Which item to delete */
{
	void *rtnitem;		/* Item pointer to return */

	if (list->type == GLIST_LINKED) {
		GLISTHDR *hdr;

		hdr = glist_hdr(which);
		rtnitem = hdr->next;

		if (which == list->first) {
			list->first = hdr->next;
			if (hdr->next) glist_hdr(hdr->next)->prev = 0;
		}
		else if (which == list->last) {
			list->last = hdr->prev;
			if (hdr->prev) glist_hdr(hdr->prev)->next = 0;
		}
		else {
			glist_hdr(hdr->prev)->next = hdr->next;
			glist_hdr(hdr->next)->prev = hdr->prev;
		}
		my_free(hdr);
		list->count--;
	}
	else {
		char *here;		/* Pointer to where to delete */
		char *end;		/* Pointer to end of real data */

		here = (char *)which + list->size;
		end = list->first + (list->count * list->size);
		if (here < end) {
			memcpy(which,here,end-here);
			rtnitem = which;
		}
		else	rtnitem = NULL;
		memset(end-list->size,'?',list->size);
		list->count--;
	}
	return rtnitem;
}

void glist_purge(		/* Purge an entire list */
	GLIST *list)		/* Target list */
{
	if (list->type == GLIST_LINKED) {
		void *p1;
		void *p2;

		p1 = glist_head(list);
		while (p1) {
			p2 = glist_hdr(p1)->next;
			my_free(glist_hdr(p1));
			p1 = p2;
		}
	}
	else {
		if (list->first) my_free(list->first);
	}
	memset(list,0,sizeof(GLIST));
}

void glist_sort(		/* Sort a list */
	GLIST *list,		/* Target list */
	int (_cdecl *cmpf)(const void *,const void *)) /* Compare function */
{
	if (list->type != GLIST_ARRAY) return;	/* No can do */

	qsort(list->first,list->count,list->size,cmpf);
}

void glist_array(		/* Convert from linked list to array list */
	GLIST *list,		/* Target list */
	unsigned size,		/* Item size in bytes if not 0 */
	unsigned inc)		/* Allocation increment if not 0 */
{
	GLIST newlist;		/* New list */
	char *p1;		/* Scratch pointer */

	if (!size) size = list->size;
	if (!inc) inc = list->inc;

	glist_init(&newlist,GLIST_ARRAY,size,list->count*size);

	p1 = glist_head(list);
	while (p1) {
		char *p2;

		p2 = glist_hdr(p1)->next;
		glist_new(&newlist,p1,size);
		glist_delete(list,p1);
		p1 = p2;
	}
	memcpy(list,&newlist,sizeof(newlist));
	list->inc = inc;
}


void glist_linked(		/* Convert from array list to linked list */
	GLIST *list)		/* Target list */
{
	GLIST newlist;		/* New list */
	unsigned k;		/* Loop counter */

	glist_init(&newlist,GLIST_LINKED,list->size,list->inc);

	for (k = 0; k < list->count; k++) {
		glist_new(&newlist,list->first + (k * list->size),list->size);
	}
	glist_purge(list);
	memcpy(list,&newlist,sizeof(newlist));
}

void *glist_next(		/* Return pointer to next item */
	GLIST *list,		/* Target list */
	void *here)		/* Where we are now */
{
	if (list->type == GLIST_LINKED) {
		return glist_hdr(here)->next;
	}
	else {
		unsigned offset;	/* Offset into array */

		offset = (char *)here - list->first;
		if (offset+list->size < list->count * list->size) {
			return (char *)here + list->size;
		}
		return NULL;
	}
}

void *glist_prev(		/* Return pointer to previous item */
	GLIST *list,		/* Target list */
	void *here)		/* Where we are now */
{
	if (list->type == GLIST_LINKED) {
		return glist_hdr(here)->prev;
	}
	else {
		unsigned offset;	/* Offset into array */

		offset = (char *)here - list->first;
		if (offset > list->size) {
			return (char *)here - list->size;
		}
		return NULL;
	}
}

void *glist_lookup(		/* Look up list item by ordinal */
	GLIST *list,		/* Target list */
	int ord)		/* Ordinal, from 1 */
{
	if (list->type == GLIST_LINKED) {
		void *p;

		p = glist_head(list);
		while (p && ord > 1) {
			ord--;
			p = glist_next(list,p);
		}
		return p;
	}
	else {
		unsigned offset;	/* Offset into array */

		offset = (ord-1) * list->size;
		if (offset < list->count * list->size) {
			return list->first + offset;
		}
		return NULL;
	}
}
/* Mon Nov 26 17:05:40 1990 alan:  rwsystxt and other bugs */
/* Thu Feb 21 12:47:40 1991 alan:  add glist_tail() */
