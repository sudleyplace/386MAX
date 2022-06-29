/*' $Header:   P:/PVCS/MAX/ASQENG/TESTHEAP.C_V   1.1   02 Jun 1997 14:40:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * TESTHEAP.C								      *
 *									      *
 * Heap debugging tools 						      *
 *									      *
 ******************************************************************************/

/* DEAD CODE - saved for print routines only */

#include <stdio.h>
#include <string.h>
#include <dos.h>
#include <malloc.h>

#include <testheap.h>

void heapstat( int status );

int usedOnly = 1;

#define OUTSTREAM stdout

void testheap(void )
{
	int result = _heapchk();

	/* Check heap status. Should be OK at start of heap. */
	heapstat( result );

}

/* Tests each block in the heap */
void heapdump(void)
{
	struct _heapinfo hi;
	int heapstatus;
	int newLine = 1;

	/* Walk through entries, displaying results and checking free blocks. */
	fprintf( OUTSTREAM, "\nHeap dump:\n\n" );
	hi._pentry = NULL;
	while( (heapstatus = _heapwalk( &hi )) == _HEAPOK )
	{

		if( !usedOnly || hi._useflag == _USEDENTRY )
		{
			fprintf( OUTSTREAM, "%s block %Fp size %u\t",
				hi._useflag == _USEDENTRY ? "USED" : "FREE",
				hi._pentry,
				hi._size );
			if( !--newLine)
			{
				newLine=1;
				fprintf( OUTSTREAM, "\n");
			}
		}
	}
	heapstat( heapstatus );
}

/* Reports on the status returned by _heapwalk, _heapset, or _heapchk */
void heapstat( int status )
{
	switch( status )
	{
		case _HEAPBADPTR:
			printf( "\nHeap status: " );
			printf( "ERROR - bad pointer to heap\n\n" );
			heapdump();
			break;
		case _HEAPBADBEGIN:
			printf( "\nHeap status: " );
			printf( "ERROR - bad start of heap\n\n" );
			heapdump();
			break;
		case _HEAPBADNODE:
			printf( "\nHeap status: " );
			printf( "ERROR - bad node in heap\n\n" );
			heapdump();
			break;
	}
}


/*
 *	_fdspmem - display a block of far memory in hex/ascii
 * like DEBUG does.
 */

void _fdspmem(char * text, int addr, void far * vbuf, int n)
{
	int k1,k2;
	char c;
	char far *p;
	char far *buf;
	int all0;
	char far *buf0;

	buf = vbuf;
	if (text) printf("%s\n",text);
	if (n<0) n = _fstrlen(buf);

	buf0 = NULL;
	all0 = 0;

	while (n>0) {
		if (n<16) {
			k1 = n;
			n=0;
		}
		else {
			k1 = 16;
			n -= 16;

			if (buf0 && n > 0 && _fmemcmp(buf0,buf,16) == 0) {
				if (!all0) {
					printf("....\n");
					all0 = 1;
				}
				buf0 = buf;
				buf += 16;
				addr += 16;
				continue;
			}
		}

		all0 = 0;
		buf0 = buf;

		printf("%04X  ",addr);
		addr += k1;
		p = buf;
		for (k2=0; k2<k1; k2++) printf(" %02X",(*p++)&255);
		printf("  ");
		p = buf;
		for (k2=0; k2<k1; k2++) {
			c = *p++;
			if (c<32) c = '.';
			if (c>126) c = '#';
			printf("%c",c);
		}
		buf = p;
		printf("\n");
	}
}
/* Wed Dec 19 17:12:58 1990 alan:  new mapping technique */
