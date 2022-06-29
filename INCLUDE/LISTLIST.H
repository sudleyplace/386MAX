/*' $Header:   P:/PVCS/MAX/INCLUDE/LISTLIST.H_V   1.1   01 Feb 1996 10:23:30   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * LISTLIST.H								      *
 *									      *
 * Structures for DOS list of lists					      *
 *									      *
 ******************************************************************************/

#ifndef LISTLIST_INCLUDED
#define LISTLIST_INCLUDED

#include <commdef.h>

#pragma pack(1)

/*
 *	F I L E S / F C B S
 */

typedef struct _filehdr {	/* System file table header */
	struct _filehdr far *next;/* pointer to next file table */
	WORD nfiles;		/* Number of files in this table */
      /*FILE?XE entry[];	   Entries begin here */
} FILEHDR;

typedef struct _file2x {	/* DOS 2.x system file table entry */
	BYTE count;		/* 00h	BYTE	number of file handles referring to this file */
	BYTE mode;		/* 01h	BYTE	file open mode (see AH=3Dh) */
	BYTE attr;		/* 02h	BYTE	file attribute */
	BYTE drive;		/* 03h	BYTE	drive (0 = character device, 1 = A, 2 = B, etc) */
	BYTE name[11];		/* 04h 11 BYTEs filename in FCB format (no path,no period,blank-padded) */
	WORD huh1;		/* 0Fh	WORD	??? */
	WORD huh2;		/* 11h	WORD	??? */
	DWORD size;		/* 13h	DWORD	file size??? */
	WORD date;		/* 17h	WORD	file date in packed format (see AX=5700h) */
	WORD time;		/* 19h	WORD	file time in packed format (see AX=5700h) */
	BYTE devattr;		/* 1Bh	BYTE	device attribute (see AX=4400h) */
	union {
		/* ---character device--- */
		void far *ddp;	/* 1Ch	DWORD	pointer to device driver */
		/* ---block device--- */
		struct {
			WORD start;  /* 1Ch	WORD	starting cluster of file */
			WORD last;   /* 1Eh	WORD	relative cluster in file of last cluster accessed */
		} cluster;
	} dc;
	WORD cluster;	/* 20h	WORD	absolute cluster number of current cluster */
	WORD huh3;	/* 22h	WORD	??? */
	DWORD pos;	/* 24h	DWORD	current file position??? */
} FILE2X;

#define F3XMAP "WWBWPWWWDDWWWBC11PWWW"

typedef struct _file3x {	/* DOS 3.x system file table entry */
	WORD count;		/* 00h	WORD	number of file handles referring to this file */
	WORD mode;		/* 02h	WORD	file open mode (see AH=3Dh) */
	BYTE attr;		/* 04h	BYTE	file attribute */
	WORD info;		/* 05h	WORD	device info word (see AX=4400h) */
	void far *ddp;		/* 07h	DWORD	pointer to device driver header if character device */
				/* else pointer to DOS Drive Parameter Block (see AH=32h) */
	WORD start;		/* 0Bh	WORD	starting cluster of file */
	WORD time;		/* 0Dh	WORD	file time in packed format (see AX=5700h) */
	WORD date;		/* 0Fh	WORD	file date in packed format (see AX=5700h) */
	DWORD size;		/* 11h	DWORD	file size */
	DWORD pos;		/* 15h	DWORD	current offset in file */
	WORD last_rel;		/* 19h	WORD	relative cluster within file of last cluster accessed */
	WORD last_abs;		/* 1Bh	WORD	absolute cluster number of last cluster accessed */
				/* 0000h if file never read or written??? */
	WORD dirsect;		/* 1Dh	WORD	number of sector containing directory entry */
	BYTE dirent;		/* 1Fh	BYTE	number of dir entry within sector (byte offset/32) */
	BYTE name[11];		/* 20h 11 BYTEs filename in FCB format (no path/period, blank-padded) */
	void far *prevsft;	/* 2Bh	DWORD	(SHARE.EXE) pointer to previous SFT sharing same file */
	WORD machnum;		/* 2Fh	WORD	(SHARE.EXE) network machine number which opened file */
	WORD owner;		/* 31h	WORD	PSP segment of file's owner (see AH=26h) */
	WORD share_offset;	/* 33h	WORD	offset within SHARE.EXE code segment of */
				/* sharing record (see below)  0000h = none */
} FILE3X;

typedef struct _file4x {	/* DOS 4.x system file table entry */
	WORD count;		/* 00h	WORD	number of file handles referring to this file */
	WORD mode;		/* 02h	WORD	file open mode, bit 15 set if this file opened via FCB */
	BYTE attr;		/* 04h	BYTE	file attribute */
	WORD info;		/* 05h	WORD	device info word (see AX=4400h) */
				/* bit 15 set if remote file */
				/* bit 14 set means do not set file date/time on closing */
	void far *ddp;		/* 07h	DWORD	pointer to device driver header if character device */
				/* else pointer to DOS Drive Parameter Block (see AH=32h) */
				/* or REDIR data */
	WORD start;		/* 0Bh	WORD	starting cluster of file */
	WORD time;		/* 0Dh	WORD	file time in packed format (see AX=5700h) */
	WORD date;		/* 0Fh	WORD	file date in packed format (see AX=5700h) */
	DWORD size;		/* 11h	DWORD	file size */
	DWORD pos;		/* 15h	DWORD	current offset in file */
	union {
		struct {
			/* ---local file--- */
			WORD last_rel;		/* 19h	WORD	relative cluster within file of last cluster accessed */
			DWORD dirsect;		/* 1Bh	DWORD	number of sector containing directory entry */
			BYTE dirent;		/* 1Fh	BYTE	number of dir entry within sector (byte offset/32) */
		} local;
		struct {
			/* ---network redirector--- */
			void far *redirifs;	/* 19h	DWORD	pointer to REDIRIFS record */
			BYTE huh[3];		/* 1Dh	3 BYTEs ??? */
		} network;
	} ln;
	BYTE name[11];		/* 20h 11 BYTEs filename in FCB format (no path/period, blank-padded) */
	void far *prevsft;	/* 2Bh	DWORD	(SHARE.EXE) pointer to previous SFT sharing same file */
	WORD machnum;		/* 2Fh	WORD	(SHARE.EXE) network machine number which opened file */
	WORD owner;		/* 31h	WORD	PSP segment of file's owner (see AH=26h) */
	WORD share_offset;	/* 33h	WORD	offset within SHARE.EXE code segment of */
				/* sharing record (see below)  0000h = none */
	WORD last_abs;		/* 35h	WORD	(local) absolute cluster number of last clustr accessed */
	void far *ifsdrv;	/* 37h	DWORD	pointer to IFS driver for file, 0000000h if native DOS */
} FILE4X;

/*
 *	B U F F E R S
 */

typedef struct _bufxx	{	/* Generic Buffer header, good for DOS 2.x - 3.x */
	struct _bufxx far *next;/* pointer to next file buffer, offset = FFFFh if last */
} BUFXX;

#define B2XMAP "PBBWBBPWC32"

typedef struct _buf2x { 	/* 2.x Disk buffer header */
	struct _buf2x far *next;/* pointer to next file buffer, offset = FFFFh if last */
	BYTE drive;		/* 04h BYTE drive (0=A,1=B, etc), FFh if not in use */
	BYTE huh[3];		/* 05h	3 BYTEs unused??? (seems always to be 00h 00h 01h) */
	WORD lsn;		/* 08h	WORD	logical sector number */
	BYTE copies;		/* 0Ah	BYTE	number of copies to write (1 for non-FAT sectors) */
	BYTE offset;		/* 0Bh	BYTE	sector offset between copies if multiple copies to be written */
	void far *dpb;		/* 0Ch	DWORD	pointer to DOS Drive Parameter Block (see AH=32h) */
	BYTE data[512]; 	/* 10h	buffered data */
} BUF2X;

#define B3XMAP "PBBWBBPWC32"

typedef struct _buf3x { 	/* 3.x Disk buffer header */
	struct _buf3x far *next;/* pointer to next file buffer, offset = FFFFh if last */
	BYTE drive;		/* 04h BYTE drive (0=A,1=B, etc), FFh if not in use */
	BYTE flags;		/* 05h BYTE flags */
	WORD lsn;		/* 06h WORD logical sector number */
	BYTE copies;		/* 08h	BYTE	number of copies to write (1 for non-FAT sectors) */
	BYTE offset;		/* 09h	BYTE	sector offset between copies if multiple copies to be written */
	void far *dpb;		/* 0Ah	DWORD	pointer to DOS Drive Parameter Block (see AH=32h) */
	WORD unused;		/* 0Eh	WORD	unused??? (almost always 0) */
	BYTE data[512]; 	/* 10h	buffered data */
} BUF3X;

#define B4XSIZE 532
#define S4XSIZE 8

/*
 *	D R I V E   L I S T
 */

#define D3XMAP "C67WDWWWW"
#define D4XMAP "C67WDWWWWBDW"
#define D3XSIZE 0x51
#define D4XSIZE 0x58

typedef struct _drv3x { 	/* 3.x+ Drive list entry */
	char path[67];		/* 00h Current path in ASCIIZ */
	WORD flags;		/* 43h Bit flags (see below) */
	void far *dpb;		/* 45h Pointer to DPB for this drive */
	union {
	  struct {		/* Local drives */
	    WORD dirclst;	/* 49h Starting cluster of current directory */
	    WORD huh1;		/* 4Bh Always FFFFh (?) */
	    WORD huh2;		/* 4Dh Always FFFFh (?) */
	  } local;
	  struct {		/* Network drives */
	    void far *redir;	/* 49h Pointer to redirector/REDIRIFS record, else FFFFFFFFh */
	    WORD huh3;		/* 4Dh Stored parameter from INT 21 / 5F03 (?) */
	  } net;
	} ln;
	WORD rootpath;		/* 4Fh Offset of '\' in current path field representing root */
				/* directory of logical drive (2 if not SUBST'ed or JOIN'ed, */
				/* Otherwise number of bytes in SUBST/JOIN path */
} DRV3X;

typedef struct _drv4x { 	/* 4.x+ Drive list entry EXTENSION */
	BYTE huh1;		/* 51h Used by network (?) */
	void far *ifs;		/* 52h Pointer IFS driver, or NULL if native DOS */
	WORD huh2;		/* 56h (?) */
} DRV4X;

/* Drive list bit flags */
#define DRVFLAG_NET   0x8000	/* Network drive \ IFS if both set */
#define DRVFLAG_PHYS  0x4000	/* Phyical drive / Invalid drv if neither set */
#define DRVFLAG_JOIN  0x2000	/* JOIN'ed drive, path is actual path */
#define DRVFLAG_SUBST 0x1000	/* SUBST'ed drive, path is actual path */

/*
 *	S U B S E G
 */

typedef struct _sub4x { 	/* 4.x subsegment header */
	BYTE type;		/* 00h BYTE subsegment type (blocks typically appear in this order) */
				/* "D"  device driver */
				/* "E"  device driver appendage */
				/* "I"  IFS (Installable File System) driver */
				/* "F"  FILES=  control block storage area (for FILES>5) */
				/* "X"  FCBS=   control block storage area, if present */
				/* "C"  BUFFERS EMS workspace area (if BUFFERS /X option used) */
				/* "B"  BUFFERS=  storage area */
				/* "L"  LASTDRIVE=  current directory structure array storage area */
				/* "S"  STACKS=  code and data area, if present (see below) */
	WORD start;		/* 01h	WORD	paragraph of subsegment start (usually the next paragraph) */
	WORD size;		/* 03h	WORD	size of subsegment in paragraphs */
	BYTE huh[3];		/* 05h	3 BYTEs unused */
	BYTE name[8];		/* 08h	8 BYTEs for types "D" and "I", base name of file from which the driver */
				/* was loaded (unused for other types) */
} SUB4X;

/*
 *	B A S E
 */

#define BASEMAP "WWPWWPPPP"
typedef struct _listbase {	/* Base part of List of Lists */
	WORD retry_count;	/* -12	WORD	(DOS 3.1-3.3) sharing retry count (see AX=440Bh) */
	WORD retry_delay;	/* -10	WORD	(DOS 3.1-3.3) sharing retry delay (see AX=440Bh) */
	void far *cur_buf;	/*  -8	DWORD	(DOS 3.x) pointer to current disk buffer */
	WORD unr_con;		/*  -4	WORD	(DOS 3.x) pointer in DOS code segment of unread CON input */
	WORD first_mac; 	/*  -2	WORD	segment of first memory control block */
	void far *drives;	/* 00h	DWORD	pointer to first DOS Drive Parameter Block (see AH=32h) */
	void far *files;	/* 04h	DWORD	pointer to list of DOS file tables (see below) */
	void far *clock;	/* 08h	DWORD	pointer to CLOCK$ device driver, resident or installable */
	void far *act_con;	/* 0Ch	DWORD	pointer to actual CON device driver, resident or installable */
} LISTBASE;

typedef struct _list2x {	/* DOS 2.x part of List of Lists */
	BYTE ndrv;		/* 10h	BYTE	number of logical drives in system */
	WORD bytblk;		/* 11h	WORD	maximum bytes/block of any block device */
	void far *bufp; 	/* 13h	DWORD	pointer to first disk buffer (see below) */
	BYTE nuldev[18];	/* 17h 18 BYTEs actual NUL device driver header (not a pointer!) */
} LIST2X;

typedef struct _list30 {	/* DOS 3.0 part of List of Lists */
	BYTE nblkdev;		/* 10h	BYTE	number of block devices */
	WORD bytblk;		/* 11h	WORD	maximum bytes/block of any block device */
	void far *bufp; 	/* 13h	DWORD	pointer to first disk buffer (see below) */
	void far *curdir;	/* 17h	DWORD	pointer to array of current directory structures (see below) */
	BYTE lastdrive; 	/* 1Bh	BYTE	value of LASTDRIVE command in CONFIG.SYS (default 5) */
	void far *string;	/* 1Ch	DWORD	pointer to STRING= workspace area */
	WORD nstring;		/* 20h	WORD	size of STRING area (the x in STRING=x from CONFIG.SYS) */
	void far *fcbs; 	/* 22h	DWORD	pointer to FCB table */
	WORD fcby;		/* 26h	WORD	the y in FCBS=x,y from CONFIG.SYS */
	BYTE nuldev[18];	/* 28h 18 BYTEs actual NUL device driver header (not a pointer!) */
} LIST30;

#define L3XMAP "WPPPWBBPWWWC8B"

typedef struct _list3x {	/* DOS 3.1-3.3 part of List of Lists */
	WORD bytblk;		/* 10h	WORD	maximum bytes/block of any block device */
	BUF3X far *bufp;	/* 12h	DWORD	pointer to first disk buffer (see below) */
	void far *curdir;	/* 16h	DWORD	pointer to array of current directory structures (see below) */
	void far *fcbs; 	/* 1Ah	DWORD	pointer to FCB table (if CONFIG.SYS contains FCBS=) */
	WORD fcby;		/* 1Eh	WORD	number of protected FCBs (the y in FCBS=x,y) */
	BYTE nblkdev;		/* 20h	BYTE	number of block devices */
	BYTE lastdrive; 	/* 21h	BYTE	value of LASTDRIVE command in CONFIG.SYS (default 5) */
	BYTE nuldev[18];	/* 22h 18 BYTEs actual NUL device driver header (not a pointer!) */
	BYTE njoin;		/* 34h	BYTE	number of JOIN'ed drives */
} LIST3X;

typedef struct _list4x {	/* DOS 4.x part of List of Lists */
	WORD bytblk;		/* 10h	WORD	maximum bytes/block of any block device */
	void far *bufp; 	/* 12h	DWORD	pointer to disk buffer info (see below) */
	void far *curdir;	/* 16h	DWORD	pointer to array of current directory structures (see below) */
	void far *fcbs; 	/* 1Ah	DWORD	pointer to FCB table (if CONFIG.SYS contains FCBS=) */
	WORD fcby;		/* 1Eh	WORD	number of protected FCBs (the y in FCBS=x,y) */
	BYTE nblkdev;		/* 20h	BYTE	number of block devices */
	BYTE lastdrive; 	/* 21h	BYTE	value of LASTDRIVE command in CONFIG.SYS (default 5) */
	BYTE nuldev[18];	/* 22h 18 BYTEs actual NUL device driver header (not a pointer!) */
	BYTE njoin;		/* 34h	BYTE	number of JOIN'ed drives??? */
	WORD names;		/* 35h	WORD	pointer within IBMDOS code segment to list of special program names (see below) */
	void far *utility;	/* 37h	DWORD	pointer to FAR routine for utility functions (see below) */
	void far *ifs;		/* 3Bh	DWORD	pointer to chain of IFS (installable file system) drivers */
	WORD buffer_x;		/* 3Fh	WORD	the x in BUFFERS x,y (rounded up to multiple of 30 if in EMS) */
	WORD buffer_y;		/* 41h	WORD	the y in BUFFERS x,y */
	BYTE bootdrv;		/* 43h	BYTE	boot drive (1=A:) */
	BYTE huh;		/* 44h	BYTE	??? */
	WORD extmem;		/* 45h	WORD	extended memory size in K */
} LIST4X;

typedef struct _listlist {	/* Master List of Lists structure */
	LISTBASE base;		/* Base list */
	union {
		LIST2X v2x;		/* 2.x extension */
		LIST30 v30;		/* 3.0 extension */
		LIST3X v3x;		/* 3.x extension */
		LIST4X v4x;		/* 4.x extension */
	} ext;
} LISTLIST;

#pragma pack()

#endif /*LISTLIST_INCLUDED*/
