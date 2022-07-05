/*' $Header:   P:/PVCS/MAX/QUILIB/HELPBACK.C_V   1.2   02 Jun 1997 11:12:04   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * HELPBACK.C								      *
 *									      *
 * Stubs for call-back routine						      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <io.h>
#include <fcntl.h>
#include <share.h>
#include <dos.h>
#include <string.h>

#include "commdef.h"
#include "commfunc.h"
#include "myalloc.h"
#include "help.h"
#include "qhelp.h"

#define MAXHANDLES 200

/* Fake handle table */
static BOOL FakeInitDone = FALSE;
static void far *FakeHandleTable[MAXHANDLES];

static unsigned long _dos_lseek(int fh,unsigned long fpos,int loc);

/************************************************************************
**
** OpenFileOnPath - Open a file located somewhere on the PATH
**
** Purpose:
**
** Entry:
**  pszName	- far pointer to filename to open
**  mode	- read/write mode
**
** Exit:
**  returns file handle
**
** Exceptions:
**  return 0 on error.
**
** This version looks for the file ONLY on the execution path of the program.
*/
int pascal far OpenFileOnPath(
char far *pszName,
int	mode)
{
	int fh;
	char temp[80];

	if(mode);
	_fstrcpy(temp,pszName);
	if (_dos_open(temp,O_RDONLY | O_NOINHERIT | SH_DENYWR,&fh) != 0) return 0;
	return fh;
}

/************************************************************************
**
** HelpCloseFile - Close a file
**
** Purpose:
**
** Entry:
**  fh		= file handle
**
** Exit:
**  none
**
*/
void pascal far HelpCloseFile(
int	fh )
{
	_dos_close(fh);
}

/************************************************************************
**
** ReadHelpFile - locate and read data from help file
**
** Purpose:
**  reads cb bytes from the file fh, at file position fpos, placing them in
**  pdest. Special case of pdest==0, returns file size of fh.
**
** Entry:
**  fh		= File handle
**  fpos	= position to seek to first
**  pdest	= location to place it
**  cb		= count of bytes to read
**
** Exit:
**  returns length of data read
**
** Exceptions:
**  returns 0 on errors.
**
*/
unsigned long pascal far ReadHelpFile (
	unsigned fh,
	unsigned long fpos,
	char far *pdest,
	unsigned short cb)
{
	unsigned nread;
	unsigned long lpos;

	if (!pdest) {
		return _dos_lseek(fh,0L,2);
	}
	lpos = _dos_lseek(fh,fpos,0);
	if (fpos != lpos) return (unsigned long)-1;

	if (_dos_read(fh,pdest,cb,&nread) != 0) return (unsigned long)-1;
	return nread;
}
/************************************************************************
**
** HelpAlloc - Allocate a segment of memory for help
**
** Purpose:
**
** Entry:
**  size	= size of memory segment desired
**
** Exit:
**  returns handle on success
**
** Exceptions:
**  returns NULL on failure
*/
unsigned pascal far HelpAlloc(
	unsigned size)
{
	unsigned handle;

	if (!FakeInitDone) {
		memset(FakeHandleTable,0,sizeof(FakeHandleTable));
		FakeInitDone = TRUE;
	}

	/* Find an open handle */
	for (handle = 0; handle < MAXHANDLES; handle++) {
		if (!FakeHandleTable[handle]) {
			FakeHandleTable[handle] = my_fmalloc(size);
			if (!FakeHandleTable[handle]) {
				/* Out of memory in HelpAlloc */
				nomem_bailout(401);
			}
			return handle+1;
		}
	}
	/* Out of handles in HelpAlloc */
	nomem_bailout(402);
	return 0;	/* Never get here */
}

void far * pascal far HelpLock(
mh	handle)
{
	if (!handle || !FakeInitDone) return NULL;

	if (handle > MAXHANDLES) {
		/* Invalid handle in HelpLock() */
		nomem_bailout(403);
	}
	return FakeHandleTable[handle-1];
}

void pascal far HelpUnlock(
mh	handle)
{
	if(handle);
}

void pascal far HelpDealloc(
mh	handle)
{
	if (handle > 0 && handle <= MAXHANDLES) {
		if (FakeHandleTable[handle-1]) {
			my_ffree(FakeHandleTable[handle-1]);
			FakeHandleTable[handle-1] = NULL;
		}
	}
}

void freeCallbackHelp( void )	/*	Release the low level alloc */
{
	unsigned handle;

	/* Find an open handle */
	for (handle = 0; handle < MAXHANDLES; handle++) {
		if (FakeHandleTable[handle]) {
			my_ffree(FakeHandleTable[handle]);
			FakeHandleTable[handle] = NULL;
		}
	}
	return;

}

#pragma optimize ("leg",off)

/* For some reason, this isn't in <dos.h> */
static unsigned long _dos_lseek(int fh,unsigned long fpos,int loc)
{
	unsigned long lpos;

	_asm {
		mov ah,42h		; func=seek
		mov al,byte ptr loc	; ...relative to
		mov bx,fh		; file handle
		mov dx,word ptr fpos	; LOWORD(fpos)
		mov cx,word ptr fpos+2	; HIWORD(fpos)
		int 21h;
		mov word ptr lpos,ax
		mov word ptr lpos+2,dx
	}
	return lpos;
}
#pragma optimize ("",on)
