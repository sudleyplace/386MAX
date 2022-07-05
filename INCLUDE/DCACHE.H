/*' $Header:   P:/PVCS/MAX/INCLUDE/DCACHE.H_V   1.0   05 Sep 1995 13:30:00   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * DCACHE.H								      *
 *									      *
 * Prototypes for dcache functions					      *
 *									      *
 ******************************************************************************/

void save_dcvid (void); 		// Save character at current position
void rest_dcvid (void); 		// Restore character saved by save_dcvid

void start_twirly (void);		// Display helicopter
void end_twirly (void); 		// Stop the helicopter

int dcache_active (char *fname, 	// Filename for test
		   unsigned int blksiz, // Size of block to test
		   unsigned int max_dly); // Maximum delay in tics
					// Determine whether disk cache active
extern unsigned int dcache_dly; 	// Delay in timer tics before write
					// (-1 if maximum delay expired)
extern unsigned char last_i13_drv;	// Last drive value used in an Int 13
					// function 0-4 call

// Return values:
#define DCACHE_ERR	-1		// Unable to determine
#define DCACHE_NONE	0		// No disk cache at all
#define DCACHE_READ	1		// Reads are buffered
#define DCACHE_WRITE	2		// Write-through cache
#define DCACHE_SMARTDRV 3		// Determined by checking CONFIG.SYS
					// ** NOT a valid return value **
#define DCACHE_WRITEDLY 4		// Delayed write cache; delay in timer
					// tics is in dcache_dly
#define DCACHE_NOWRITE	5		// No writes to disk occurred;
					// probably a RAM disk
