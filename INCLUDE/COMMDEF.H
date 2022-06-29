/*' $Header:   P:/PVCS/MAX/INCLUDE/COMMDEF.H_V   1.1   13 Oct 1995 12:14:00   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * COMMDEF.H								      *
 *									      *
 * Common definitons							      *
 *									      *
 ******************************************************************************/

#ifndef COMMDEF_INCLUDED
#define COMMDEF_INCLUDED

#ifdef _INC_WINDOWS
#define	WINDOWS_INCLUDED
#endif

#ifndef WINDOWS_INCLUDED
#ifndef NEAR
#define NEAR _near
#endif
#ifndef FAR
#define FAR _far
#endif
#define PASCAL _pascal
#define CDECL _cdecl

#define APIENTRY pascal far	/* Exported API function entry */
#define INTENTRY pascal near	/* Internal API function entry */

typedef unsigned char BYTE;	/* Generic 8-bit data */

#ifndef TYPE_WORD
#define TYPE_WORD
typedef unsigned short WORD;	/* Generic 16-bit data */
#endif

typedef unsigned long DWORD;	/* Generic 32-bit data */
typedef int BOOL;		/* Boolean value */

typedef char near	*PSTR;
typedef char near	*NPSTR;
typedef char far	*LPSTR;
typedef BYTE near	*PBYTE;
typedef BYTE far	*LPBYTE;
typedef int near	*PINT;
typedef int far 	*LPINT;
typedef WORD near	*PWORD;
typedef WORD far	*LPWORD;
typedef long near	*PLONG;
typedef long far	*LPLONG;
typedef DWORD near	*PDWORD;
typedef DWORD far	*LPDWORD;
typedef void far	*LPVOID;

typedef WORD		HANDLE;
typedef HANDLE		*PHANDLE;
typedef HANDLE NEAR	*SPHANDLE;
typedef HANDLE FAR	*LPHANDLE;
typedef HANDLE		GLOBALHANDLE;
typedef HANDLE		LOCALHANDLE;

typedef int (far pascal *FARPROC)();
typedef int (near pascal *NEARPROC)();

#define MAKELONG(a, b)	((LONG)(((WORD)(a)) | ((DWORD)((WORD)(b))) << 16))
#define LOWORD(l)	((WORD)(l))
#define HIWORD(l)	((WORD)(((DWORD)(l) >> 16) & 0xFFFF))
#define LOBYTE(w)	((BYTE)(w))
#define HIBYTE(w)	((BYTE)(((WORD)(w) >> 8) & 0xFF))

#endif /*WINDOWS_INCLUDED*/

#ifndef KEYBOARD_INCLUDED
typedef unsigned short KEYCODE; /* Keystroke codes */
typedef unsigned short KEYFLAG; /* Keyboard flags */
typedef unsigned long  EXTKEY;	/* Extended keystroke info */
#endif

#ifndef TYPE_WINDESC
#define TYPE_WINDESC
typedef struct _windesc {	/* Window descriptor */
	int row;		/* Starting row, from 0 */
	int col;		/* Starting column, from 0 */
	int nrows;		/* Number of rows */
	int ncols;		/* Number of columns */
} WINDESC;
#endif /*TYPE_WINDESC*/

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef MAXFILELENGTH
#define MAXFILELENGTH (2+63+12+1)	/* Maximium DOS file length */
#endif

/* Calculate length of an array */
#define LENGTHOF(x) (sizeof(x)/sizeof(x[0]))

/* Make an address anywhere in memory */
#define FAR_PTR(h,l) ((void far *)((DWORD)(((WORD)(l)) | ((DWORD)((WORD)(h))) << 16)))

/* Get pointer to end of string */
#define stpend(a)	((a)+strlen(a))

/* Make a 'flat' address from a 'segmented' address */
#define FLAT_ADDR(p) (((((DWORD)(p))>>12)&0xffff0) + (((DWORD)(p))&0xffff))

/* Make a 'segmented' address from a 'flat' address */
#define SEG_ADDR(p) ((void far *)(((((DWORD)(p))&0xffff0)<<12)+(((DWORD)(p))&0x0f)))

/* Convert bytes to kilobytes */
#define KB(n) ((int)((n)/1024))

/* Convert bytes to kilobytes, rounded */
#define KBR(n) ((int)(((n)+512)/1024))

/*#define SYSROM 0xF000*/	/* Where we assume the system ROM to be */

#define SUB_VERSION ".19"        /* Pre-release sub-version number */

/* Undefine isascii() and toascii() to work with international versions */
#ifdef isascii
#undef isascii
#endif

#ifdef toascii
#undef toascii
#endif

#define isascii(_c)	1
#define toascii(_c)	_c

#endif /* COMMDEF_INCLUDED */
