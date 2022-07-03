/*' $Header:   P:/PVCS/MAX/INSTALL/PACKAGE.H_V   1.0   05 Sep 1995 15:14:06   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * PACKAGE.H								      *
 *									      *
 * Definitions and structures used by the INSTALL packaging utility	      *
 *									      *
 ******************************************************************************/

#ifndef word
#define word unsigned int
#endif

#ifndef ulong
#define ulong unsigned long
#endif

#ifndef byte
#define byte unsigned char
#endif

#define CMP_NONE 2

#ifdef PACKAGE_SRC

#define BLUE	1
#define GREEN	2
#define CYAN	3
#define RED	4
#define MAGENTA 5
#define BROWN	6
#define WHITE	7
#define BOLD	8
#define YELLOW	 0x0e
#define INVGREEN 0x2f

#define KBDIO 0x16
#define BIOSDATA 0x40
#define TIMERTIC 0x6c

#define SUCCESS 0

typedef struct
   {
   int row;
   int col;
   int att;
   char *msg;
   } MESSAGE;

typedef struct
   {
   int items;	      /* number of rows of text */
   int mstart;	      /* starting line of menu */
   int sels;	      /* number of menu items */
   int last;	      /* last selected menu item */
   MESSAGE msgs[];    /* strings for menu */
   } MENU;

#endif		// PACKAGE_SRC (not INSTALL)

typedef struct		  /* compressed file header */
   {
   long crc;		  /* 32 bit CRC for header */
   word dir;		  /* offset of the start of directory (0=none)*/
   word dlen;		  /* length to the dir */
   word ver;		  /* archive/compression program version */
   word fnum;		  /* number of files in the directory */
   byte num;		  /* file extent (1 relative) */
   byte ext;		  /* number of extents (1-n) */
   } QFHEAD;

typedef struct		  /* date/time used by _dos_[sg]etftime () */
   {
   word time;		  /* low order word: packed time */
   word date;		  /* high order word: packed date */
   } DOSTIME;

typedef struct		  /* bit fields used by date/time */
   {
   word sec2	: 5;	  // Seconds div 2 (0-29)
   word minutes : 6;	  // Minutes (0-59)
   word hours	: 5;	  // Hours (0-23)
   word day	: 5;	  // Day of month (1-31)
   word month	: 4;	  // Month (1-12)
   word year	: 7;	  // Year-1980 (0-119)
   } DOSTIMEB;

typedef union		  /* date/time represented in three ways: */
   {
   unsigned long stime;   /* date/time as returned by stat (seconds
			   * elapsed since 1/1/1970) */
   unsigned long dtime;   /* date/time for comparison, DOS style */
   DOSTIME dt;		  /* packed date/time (per _dos_[sg]etftime) */
   DOSTIMEB dtb;	  /* date/time bit fields */
   } DIRTIME;

typedef struct		  /* directory entry */
   {
   long next;		  /* offset of next directory entry */
   word id;		  /* product id */
   long start;		  /* offset from start of file */
   DIRTIME date;	  /* compressed date/time */
   long size;		  /* size of uncompressed file */
   long csiz;		  /* size of uncompressed file */
   word att;		  /* file attribute */
   byte num;		  /* extent that file is in */
   byte comp;		  /* compression format */
   char path[]; 	  /* path and file name (nul terminated) */
   } QDIR;

typedef struct		  /* compressed data header */
   {
   long crc;		  /* 32 bit crc for compressed data */
   byte data[]; 	  /* compressed data */
   } QCHEAD;

typedef struct
   {
   word num;	      /* number of files in product */
   word att;	      /* product attribute bit */
   char name[32];     /* produce label */
   char fnp[6];       /* file name prefix */
   char *file[256];   /* list of file names for this product */
   } PRODUCTLIST;

typedef struct
   {
   word size;
   char type[32];
   char name[6];
   } DISKTYPE;

typedef struct
   {
   long crc;		  /* crc of the compressed data */
   long date;		  /* orginal date and time */
   long size;		  /* size of uncompressed file */
   long csiz;		  /* size of compressed file */
   word loc;		  /* set non-zero = archive location */
   word index;		  /* product file index */
   word att;		  /* orginal file attribute */
   word id;		  /* product id */
   byte comp;		  /* compression format */
   char fname[14];	  /* name of source file (nul terminated) */
   char name[14];	  /* name of compressed file (nul terminated) */
   } FDIR;

