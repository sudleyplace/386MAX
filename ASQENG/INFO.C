/*' $Header:   P:/PVCS/MAX/ASQENG/INFO.C_V   1.2   02 Jun 1997 14:40:04   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * INFO.C								      *
 *									      *
 * Exported system information functions				      *
 *									      *
 ******************************************************************************/

/*
 *	These are the functions that the surface calls to get
 *  information about the host system.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#include <hmem.h>		/* Memory handle functions */
#include "info.h"               /* Info structures and functions */
#include <libtext.h>		/* Localized constants */

typedef struct _infotext {	/* Information text structure */
	int width;		/* How many chars in widest line */
	int length;		/* How many lines */
	int color;		/* Coloring code */
	int format;		/* Formatting code */
	int ovfl;		/* Overflow flag */
	/* ----------- */
	WORD  end;		/* End of stored text */
	WORD  limit;		/* Limit of data area */
	char base[1];		/* Base of data area */
} INFOTEXT;

typedef INFOTEXT far *LPINFOTEXT;	/* Far pointer to info text */

/* Local variables */
LPINFOTEXT InfoScratchBuf = NULL; /* Pointer to (big) scratch buffer */
WORD	   InfoScratchSize = 0;   /* How many bytes in scratch buffer */

void info_setbuf(		/* Set info scratch buffer (Optional) */
	LPVOID bigbuf,		/* Pointer to a big buffer if not NULL */
	WORD nbigbuf)		/* How many bytes in buffer if not 0 */
/* Return:  handle if successful, 0 if bigbuf not NULL, or -1 if error */
{
	InfoScratchBuf = bigbuf;
	InfoScratchSize = nbigbuf;
	_fmemset(InfoScratchBuf,'?',InfoScratchSize);
}

HANDLE info_init(void)		/* Set up to build information block */
/* Return:  handle if successful, 0 if error, or -1 if scratch buffer available */
{
	HANDLE handle;		/* Handle to return */
	LPINFOTEXT info;	/* Info structure to fill in */
	LPVOID bigbuf;		/* Pointer to a big buffer */
	WORD nbigbuf;		/* How many bytes in buffer */

	if (!InfoScratchBuf || InfoScratchSize == 0) {
		/* No buffer specified, allocate one */
		nbigbuf = 48000;
		handle = mem_alloc(nbigbuf,0);
		if (!handle) return (HANDLE)-1;
		bigbuf = mem_lock(handle);
	}
	else {
		/* Yes buffer, use it */
		handle = (HANDLE)-1;
		bigbuf = InfoScratchBuf;
		nbigbuf = InfoScratchSize;
	}


	info = (LPINFOTEXT)bigbuf;
	info->end = 0;
	info->limit = nbigbuf;
	info->ovfl = FALSE;
	info->width = 0;
	info->length = 0;
	info->color = 0+CODE_BASE;
	info->format = 0+CODE_BASE;

	if (handle != -1) {
		mem_unlock(handle);
	}
	return handle;
}

HANDLE info_finish(		/* Finish building information block */
	HANDLE handle)		/* Handle to info structure */
{
	if (handle != -1) {
		HANDLE h;		/* Scratch handle */
		WORD end;		/* End of text strings */
		LPINFOTEXT info;	/* Pointer to info structure */

		info = mem_lock(handle);
		end = info->limit = info->end;

		info = NULL;
		mem_unlock(handle);

		h = mem_realloc(handle,end+sizeof(INFOTEXT)-1);
		if (h) handle = h;
	}
	return handle;
}

void info_purge(		/* Purge information block */
	HANDLE handle)		/* Handle to info structure */
{
	if (handle != -1) {
		mem_free(handle);
	}
}

WORD info_seek( 		/* Seek to position in information block */
	HANDLE handle,		/* Handle to info structure */
	int where)		/* Where to go, 0 == first line */
/* Return:  offset for use with info_fetch(), else 0 */
{
	LPINFOTEXT info;/* Pointer to info structure */
	WORD offset;	/* Offset to return */
	LPSTR cp;	/* Scratch pointer */

	if (handle != -1) {
		info = mem_lock(handle);
	}
	else info = InfoScratchBuf;

	offset = 0;
	while (where > 0 && offset < info->end) {
		cp = info->base + offset;
		offset += _fstrlen(cp) + 1;
		where--;
	}
	if (handle != -1) {
		info = NULL;
		mem_unlock(handle);
	}
	if (where > 0) return 0;
	return offset;
}

WORD info_fetch(		/* Fetch first/next text line */
	HANDLE handle,		/* Handle to info structure */
	WORD current,		/* Current offset in buffer */
	LPSTR str,		/* Where to return text */
	int nstr)		/* Max chars in str */
/* Return:  Offset to next line, or 0 if no more text */
{
	LPINFOTEXT info;	/* Pointer to info structure */
	LPSTR cp;		/* Scratch pointer */

	if (handle != -1) {
		info = mem_lock(handle);
	}
	else info = InfoScratchBuf;

	if (current < info->end) {
		int n;	/* Scratch */

		cp = info->base + current;

		n = _fstrlen(cp);
		if (nstr > 1) {
			if (n > nstr-1) n = nstr-1;
			_fmemcpy(str,cp,n);
			str[n] = '\0';
		}
		current += n + 1;
	}
	else	current = 0;

	if (handle != -1) {
		info = NULL;
		mem_unlock(handle);
	}
	return current;
}

int _cdecl iprintf(		/* Print information */
	HANDLE handle,		/* Handle to info structure */
	char *format,...)	/* printf() style args */
{
	char temp[256];
#if (NUM_DECIMAL != '.') || (NUM_COMMA != ',')
	char *ffmtdec;
#endif

	va_list arglist;

	va_start(arglist, format);

	vsprintf(temp,format,arglist);

#if (NUM_DECIMAL != '.') || (NUM_COMMA != ',')
	/* If a '.' is found, and is surrounded by numbers, */
	/* convert it to a NUM_DECIMAL.  Do the same for ','; */
	/* convert to NUM_COMMA */
	for (ffmtdec = temp; ffmtdec = strpbrk (ffmtdec, ".,"); ffmtdec++) {
		if (isdigit (*(ffmtdec-1)) && isdigit (*(ffmtdec+1))) {
			if (*ffmtdec == '.') {
			    /* Ugly kluge for languages where '.' is also */
			    /* used as a date separator */
			    if (strlen (ffmtdec) > 3 && *(ffmtdec+3) == '.') {
				ffmtdec += 3;
			    }
			    else {
				*ffmtdec = NUM_DECIMAL;
			    }
			}
			else {
				*ffmtdec = NUM_COMMA;
			}
		} /* surrounded by numbers- assume it's supposed to be decimal */
	} /* for () */
#endif

	return iputs(handle,temp);
}

WORD _cdecl iputs(		/* Write string */
	HANDLE handle,		/* Handle to info structure */
	char *text)		/* Text string */
{
	int nc; 		/* Character count */
	LPINFOTEXT info;	/* Pointer to info structure */
	LPSTR cp;		/* Pointer into text buffer */

	if (handle != -1) {
		info = mem_lock(handle);
	}
	else info = InfoScratchBuf;

	nc = strlen(text);
	if (info->ovfl || (info->limit - info->end) < (WORD)nc + IEXTRA+1) {
		info->ovfl = TRUE;
		nc = 0;
		goto bailout;
	}

	cp = info->base + info->end;
	*cp++ = (char)min(nc+CODE_BASE,info->color);
	*cp++ = (char)info->format;
	_fstrcpy(cp,text);

	info->end += nc + IEXTRA+1;
	info->width = max(info->width,nc);
	info->length++;
bailout:
	if (handle != -1) {
		info = NULL;
		mem_unlock(handle);
	}
	return nc;
}

int info_length(			/* Return current length of text block */
	HANDLE handle)		/* Handle to info structure */
{
	LPINFOTEXT info;	/* Pointer to info structure */
	int length;		/* Length to return */

	if (handle != -1) {
		info = mem_lock(handle);
	}
	else info = InfoScratchBuf;

	length = info->length;

	if (handle != -1) {
		info = NULL;
		mem_unlock(handle);
	}
	return length;
}

int info_width( 		/* Return current width of text block */
	HANDLE handle)		/* Handle to info structure */
{
	LPINFOTEXT info;	/* Pointer to info structure */
	int width;		/* Length to return */

	if (handle != -1) {
		info = mem_lock(handle);
	}
	else info = InfoScratchBuf;

	width = info->width;

	if (handle != -1) {
		info = NULL;
		mem_unlock(handle);
	}
	return width;
}

int info_color( 		/* Set text coloring */
	HANDLE handle,		/* Handle to info structure */
	int color)		/* Coloring code */
{
	LPINFOTEXT info;	/* Pointer to info structure */
	int oldcolor;		/* Previous color returned */

	if (handle != -1) {
		info = mem_lock(handle);
	}
	else info = InfoScratchBuf;

	oldcolor = info->color-CODE_BASE;
	info->color = color+CODE_BASE;

	if (handle != -1) {
		info = NULL;
		mem_unlock(handle);
	}
	return oldcolor;
}

int info_format(		/* Set text formatting columns */
	HANDLE handle,		/* Handle to info structure */
	int format)		/* Formatting code */
{
	LPINFOTEXT info;	/* Pointer to info structure */
	int oldformat;		/* Previous format returned */

	if (handle != -1) {
		info = mem_lock(handle);
	}
	else info = InfoScratchBuf;

	oldformat = info->format-CODE_BASE;
	info->format = format+CODE_BASE;

	if (handle != -1) {
		info = NULL;
		mem_unlock(handle);
	}
	return oldformat;
}

/*
 *	iwraptext - print wrapped text
 */

int _cdecl iwraptext(		/* Print wrapped text */
	HANDLE handle,		/* Handle to info structure */
	char *format1,		/* Format for first line */
	char *format2,		/* Leader for continuation lines */
	char *string,		/* String to print */
	int width,		/* Wrap width */
	int contin)		/* Flag for continuation lines */
{
#ifdef TEXTWRAP
	int nlines;		/* Line count */
	int n0,n1,n2;		/* Scratch */
	int oldcolor;		/* Old color mode */
	char line[MAX_WIDTH+1]; /* Scratch text */

	/* Set up */
	if (width > MAX_WIDTH) width = MAX_WIDTH;
	oldcolor = info_color(handle,0);
	info_color(handle,oldcolor);
	nlines = 0;
	strcpy(line,format1);

	/* Process text */
	n0 = n1 = strlen(line);
	while (*string) {
#if 0		/* This is the code that wraps text at convenient chars */
		/* In case you want to turn it back on */
		char *p;

		p = strpbrk(string," ;,\\$");
		if (p) n2 = (p - string) + 1;
		else   n2 = strlen(string);
#else
		n2 = strlen(string);
#endif

		if (n1+n2 < width) {
			memcpy(line+n1,string,n2);
			n1 += n2;
			line[n1] = '\0';
			string += n2;
		}
		else if (n1 == n0) {
			n2 = width - n1;
			memcpy(line+n1,string,n2);
			n1 += n2;
			line[n1] = '\0';
			string += n2;
		}
		else {
			iputs(handle,line);
			nlines++;
			strcpy(line,format2);
			n0 = n1 = strlen(line);
			info_color(handle,contin);
		}
	}
	if (n1 != n0) {
		iputs(handle,line);
		nlines++;
	}
	info_color(handle,oldcolor);

	return nlines;
#else	/* TEXTWRAP*/
	/* No text wrapping in windows */
	char temp[256]; /* Scratch text */

	/* Set up */
	strcpy(temp,format1);
	strcat(temp,string);

	if (format2 || contin || width);
	iputs(handle,temp);
	return 1;
#endif	/* TEXTWRAP*/
}

/*
 *	ictrtext - print centered text
 */

void _cdecl ictrtext(
	HANDLE handle,		/* Handle to info structure */
	char *string,		/* String to print */
	int width)		/* Width of line */
{
#if 0
	int nc;
	int fill;
	char temp[MAX_WIDTH+1];

	if (width > MAX_WIDTH) width = MAX_WIDTH;
	nc = strlen(string);
	if (nc > width) nc = width;

	fill = (width - nc) / 2;
	if (fill > 0) {
		memset(temp,' ',fill);
	}
	memcpy(temp+fill,string,nc);
	temp[fill+nc] = '\0';
	iprintf(handle,temp);
#else
	/* Caller will handle centering */
	int fmtsave;
	LPINFOTEXT info;	/* Pointer to info structure */

	if (width);

	if (handle != -1) {
		info = mem_lock(handle);
	}
	else info = InfoScratchBuf;

	fmtsave = info->format;
	info->format = CODE_BASE+CENTER_LINE;
	iputs(handle,string);
	info->format = fmtsave;
#endif /* TEXTWRAP */
}
/* Mon Nov 26 17:05:33 1990 alan:  rwsystxt and other bugs */
