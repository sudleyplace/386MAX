/*
 *' $Header:   P:/PVCS/MAX/MAXIMIZE/MAXSUB.PRV   1.0   05 Sep 1995 16:32:46   HENRY  $
 */

int izit4dos (void);		/* Check for presence of 4DOS */
void reboot (void);		/* Force machine to reboot */
int maxmovpres (void);		/* Check for 386max/Move'em present */
unsigned char far *ramscan (void); /* Scan for available RAM */
void far *maximize (int);	/* (SUMFIT far *) */
int createfile (char *);	/* Create an empty file */
unsigned int FP_LSEG (void far *);
unsigned int FP_LOFF (void far *);
unsigned char readpos32 (int magicval); /* Read POS directly from NVRAM */
/*void writepos32 (int magicval, unsigned char newval);*/ /* Write POS directly to NVRAM */
#if SYSTEM != MOVEM
char far *harpo_pro (void);	/* Harpo_profile[0] == '\0' if none */
void openhigh (void);		/* Set 386LOAD in-progress and link arenas */
void closehigh (void);		/* Clear ... and unlink arenas */
int is_PCI (void);		/* Non-zero if PCI local bus BIOS */
void nogate (void);		/* Flag as GATEWAY system (no WBINVD) */
#endif
