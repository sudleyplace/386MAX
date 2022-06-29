/***
 *' $Header:   P:/PVCS/MISC/XMSTEST/XMSINFO.H_V   1.1   06 Aug 1992 13:18:10   HENRY  $
 *
 * xmsinfo.h - functions to get XMS information
 *
***/

#ifndef XMSINFO_INCLUDED
#define XMSINFO_INCLUDED

typedef struct _xmsparm {
	int installed;		/* 1 if XMS installed, 0 if not, -1 if error */
	unsigned short version;  /* XMS version number */
	unsigned short driver;	 /* Driver version number */
	unsigned short hmaexist; /* HMA exists flag */
	unsigned short hmaavail; /* HMA available flag */
	unsigned short a20state; /* State of A20 line */
	unsigned short embhand;  /* EMB handles */
	unsigned short embtotal; /* Total Kb EMB free */
	unsigned short embavail; /* Available Kb in largest EMB block */
	unsigned short umbtotal; /* Total Kb UMB free */
	unsigned short umbavail; /* Available Kb in largest UMB block */
} XMSPARM;

/*-asm-*/  int pascal far xmsparm(XMSPARM far *parm);
/*-asm-*/  unsigned short pascal far umballoc(int npara);
/*-asm-*/  int pascal far umbfree(unsigned short umbseg);

#endif /*XMSINFO_INCLUDED*/
