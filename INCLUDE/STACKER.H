/***
 *' $Header:   P:/PVCS/MAX/INCLUDE/STACKER.H_V   1.1   02 Jun 1997 14:37:32   BOB  $
 *
 * Prototypes for STACKER.C and SSTOR.ASM
 *
***/

#ifndef STACKER_INCLUDED
#define STACKER_INCLUDED

#include <commdef.h>		     /*      Get standard definitions */

#ifdef OWNER
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL
  #define GLINIT
#else
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL extern
#endif /*  OWNER  */

/* (SSTOR.ASM) Return 1 if IOCTL supported on specified block device */
/* extern int ioctl_supported (int dnum); */

/* (SSTOR.ASM) Return version * 100 if Stacker present, otherwise 0 */
extern int stacker_present (void);

/* Apply rules to construct values */
GLOBAL void swap_logic (char bootdrive, char maxdrive,
		BOOL maxcompressed,	/* Is maxdrive compressed? */
		char maxmappedto,	/* What does maxdrive map to? */
		char bootmappedto);	/* What does bootdrive map to? */

/* Based on perceived boot drive and actual MAX drive, set other drives */
GLOBAL void check_swap (char bootdrive, char maxdrive);

/* If specified drive (A=0, B=1, C=2, etc) is compressed, return 1 */
GLOBAL int stacked_drive (int driveno);

#define SWAPPEDDRIVE_UNSET	-1	// SwappedDrive not set
#define SWAPPEDDRIVE_FALSE	0	// None detected
#define SWAPPEDDRIVE_STACKER	1	// Stacker detected
#define SWAPPEDDRIVE_SSTOR	2	// SuperStor detected

GLOBAL int SwappedDrive 	/* TRUE if swapped drive environment */
#ifdef GLINIT
= SWAPPEDDRIVE_UNSET
#endif
;

GLOBAL char MaxConfig		/* Drive letter to use for references to */
#ifdef GLINIT			/* MAX directory in CONFIG.SYS */
= '\0'
#endif
;

GLOBAL char ActualBoot		/* Drive letter to use for access to the */
#ifdef GLINIT			/* actual boot drive */
= '\0'
#endif
;

GLOBAL char CopyBoot		/* Drive letter to copy changed CONFIG.SYS to */
#ifdef GLINIT
= '\0'
#endif
;

GLOBAL char CopyMax1		/* Drive letter for parallel MAX dir #1 */
#ifdef GLINIT
= '\0'
#endif
;

GLOBAL char CopyMax2		/* Drive letter for parallel MAX dir #2 */
#ifdef GLINIT
= '\0'
#endif
;

GLOBAL BOOL AdvancedOpts	/* Enable Advanced options dialog */
#ifdef GLINIT
= FALSE
#endif
;

#endif	/* ifndef STACKER_INCLUDED */

