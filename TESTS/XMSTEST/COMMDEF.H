/***
 *' $Header:   P:/PVCS/MISC/XMSTEST/COMMDEF.H_V   1.1   06 Aug 1992 13:17:54   HENRY  $
 *
 * commdef.h - Common definitons
 *
***/

#ifndef COMMDEF_INCLUDED
#define COMMDEF_INCLUDED

typedef unsigned char BYTE;	/* Generic 8-bit data */
typedef unsigned int  WORD;	/* Generic 16-bit data */
typedef unsigned long DWORD;	/* Generic 32-bit data */
typedef int BOOL;		/* Boolean value */

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

/* Make an address anywhere in memory */
#define FAR_PTR(h,l) ((void far *)((DWORD)(((WORD)(l)) | ((DWORD)((WORD)(h))) << 16)))

/* Make a 'flat' address from a 'segmented' address */
#define FLAT_ADDR(p) (((((DWORD)(p))>>12)&0xffff0) + (((DWORD)(p))&0xffff))

/* Make a 'segmented' address from a 'flat' address */
#define SEG_ADDR(p) ((void huge *)(((((DWORD)(p))&0xffff0)<<12)+(((DWORD)(p))&0x0f)))

/* Convert bytes to kilobytes */
#define KB(n) ((int)((n)/1024))

/* Convert bytes to kilobytes, rounded */
#define KBR(n) ((int)(((n)+512)/1024))

#define SYSROM 0xF000		/* Where we assume the system ROM to be */

#endif /* COMMDEF_INCLUDED */
