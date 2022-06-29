/***
 *' $Header:   P:/PVCS/MAX/INSTALL/PD_SUB.PRV   1.0   05 Sep 1995 15:14:08   HENRY  $
 ***/

void debug (void);
unsigned char far *_RAMSCAN (void);
unsigned int freeMB (char); /* Check for space on local hard drive */
int openhigh (void); /* Link high DOS via 5803 BX=1 */
int closehigh (void); /* Unlink high DOS via 5803 */
