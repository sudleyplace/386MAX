/*' $Header:   P:/PVCS/MAX/QUILIB/STACKER.C_V   1.1   30 May 1997 12:09:06   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * STACKER.C								      *
 *									      *
 * Stacker and SuperStor information routines				      *
 *									      *
 ******************************************************************************/

/***
 *
 * Since SuperStor gives us only the blunt method of determining
 * whether a particular drive is a SuperStor drive (via an IOCTL
 * write), we need to set up our translation table only for the
 * drives we are going to need translations for.  To avoid IOCTL
 * writes to non-SuperStor devices, we attempt to screen them out
 * as follows before querying:
 *
 * Walk the device chain in chronological order, looking for block
 * devices.  If the specified drive number is handled by a block
 * device that supports IOCTL, it can't be a SuperStor device, or
 * it's not safe for us to try to find out.  If no block device
 * handles the specified drive number, it can't be a SSTOR drive.
 * Otherwise, we try the SuperStor IOCTL write calls to determine
 * 1) if the specified drive number is a SuperStor drive, and
 * 2) if the specified drive number maps to another drive.
 * INT 24h handling is forced to default to Fail on all IOCTL
 * writes.
 *
***/

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <memory.h>
#include <fcntl.h>
#include <io.h>
#include <sys\types.h>
#include <sys\stat.h>

#include "commfunc.h"
#include "dcache.h"

#define  OWNER
#include "stacker.h"

typedef struct _stackinfo {
	unsigned int sig;		// 0x00: 0xA55A
	unsigned int ver;		// 0x02: Version * 100 decimal
	unsigned char unk[0x3a];	// 0x04: Unknown
	unsigned char unit_offs;	// 0x3e: UNIT_OFFS for IOCTL
	unsigned char unk2[0x13];	// 0x3f: Unknown part 2
	char swapsig[4];		// 0x52: 'SWAP'
	char swapmap[26];		// 0x56: Drive letters from A-Z
} STACKINFO, far *STACKINFOP;

static char far *SWAPSIG = "SWAP";

STACKINFOP stackinfo = NULL;

char SwapTable[26];			// Swapped drives for A-Z (0-25)

#define IOCTL_READ	(char) 0x04	/* IOCTL read subfunction (valid for */
					/* IOCTLDISMOUNT only */
#define IOCTL_WRITE	(char) 0x05	/* IOCTL write subfunction */

#define IOCTLMOUNT	0x00		/* Mount a logical drive */
#define IOCTLDISMOUNT	0x03		/* Dismount compressed drive */
#define IOCTLGETCDPARMS 0x06		/* Get compressed drive parms */
#define IOCTLGETSWAPDRV 0x08		/* Get physical drive number */
#define IOCTLGETVERSION 0x13		/* Get driver version number */

static struct __sstor_ioctl {		/* Offset	Contents */
	unsigned int	hassig; 	/*  0		0xAA55 */
	unsigned char	hprodid;	/*  2		1 */
	unsigned char	hmode;		/*  3		Function */
	unsigned char	rdata[14];	/*  4-17	Varies */
	unsigned char	slop[4];	/*  Leave room for expansion */
} _sstor_ioctl;

#pragma optimize("leg",off)
unsigned int sstor_ioctl (unsigned int dnum, char mode)
// Make IOCTL call to SuperStor using _sstor_ioctl contents and return
// status.  Note that we sandwich this attempt with a "Fail all critical
// errors" call...
{
	unsigned int retval;

	// Ensure we don't trigger our Int 24 handler
	set24_resp (RESP_FAIL);

	_asm {
		mov	ah,0x44 	// IOCTL function
		mov	al,mode 	// 4 = read, 5 = write
		mov	bx,dnum 	// Get unit number
		inc	bl		// Add 1 (A=1, B=2, C=3, etc)
		mov	cx,18		// CX = number of bytes to write
		lea	dx,_sstor_ioctl // DS:DX ==> input structure
		int	0x21		// CF/AX contain status
		jnc	sstor_ioctl_OK	// Jump if no error

		or	ax,0x8000	// Set error flag
		jmp	sstor_ioctl_exit // Join common exit

sstor_ioctl_OK:
		mov	ax,_sstor_ioctl.hassig // Get status returned by SSTOR

sstor_ioctl_exit:
		mov	retval,ax	// Status to return
	}

	// Resume normal Int 24 handling
	set24_resp (0);

	return (retval);

} // sstor_ioctl ()
#pragma optimize("",on)

int sstor_drive (char dnum)
// Return 1 if specified drive number is a SuperStor drive, 0 if not.
// Check the specified block device for the ADDSTOR signature at offset 20h.
// Make the one IOCTL read request supported by SSTOR devices
// (IOCTLDISMOUNT) to see if the device supports IOCTL.
{


	// Make the IOCTL call and check return status
	// First try it with a bogus structure and make sure it doesn't always
	// return success...
	_sstor_ioctl.hassig = 0x1234;		// SSTOR expects AA55
	_sstor_ioctl.hprodid = 1;
	_sstor_ioctl.hmode = IOCTLDISMOUNT;
	*((WORD *)&_sstor_ioctl.rdata[0]) = 0;

	if (sstor_ioctl (dnum, IOCTL_READ) & 0x8000) {

		// Now set it up properly and verify that it succeeds
		_sstor_ioctl.hassig = 0xaa55;
		_sstor_ioctl.hprodid = 1;
		_sstor_ioctl.hmode = IOCTLDISMOUNT;
		// Not in the docs, but byte 5	must be 0 or the call fails.
		*((WORD *)&_sstor_ioctl.rdata[0]) = 0;

		if (!(sstor_ioctl (dnum, IOCTL_READ) & 0x8000))
			return (1);			// Call succeeded

	} // Bogus call failed

	return (0);

} // sstor_drive ()

char sstor_mapping (char dnum)
// Return a number GUARANTEED to map into SwapTable (default for failure
// is dnum).  If drive is swapped, return swapped drive number.
{

  if (sstor_drive (dnum)) {
	_sstor_ioctl.hassig = 0xaa55;
	_sstor_ioctl.hprodid = 1;
	_sstor_ioctl.hmode = IOCTLGETSWAPDRV;

	if (!(sstor_ioctl (dnum, IOCTL_WRITE) & 0x8000)) {
		if (_sstor_ioctl.rdata[0] <= (unsigned char) ('Z' - 'A')) {
			dnum = _sstor_ioctl.rdata[0];
		} // Swapped drive was within range
	} // Call succeeded

  } // dnum is a SuperStor drive

  return (dnum);

} // sstor_mapping ()

#pragma optimize ("leg",off)
int stacked_drive (int driveno)
// Return 1 if specified drive number (0-25 for A-Z) is stacked
// Note that we try numerous times to see if a drive is stacked on the
// off chance that some background disk user changes the unit offset
// 'twixt the cup and the lip.
// Contrary to the example in the Stacker API documentation, we
// set the global unit_offs in the stacker info structure to ff,
// then detect the drive as stacked if unit_offs is changed to
// something OTHER THAN ff.
{
 int i;

	if (!stackinfo && !stacker_present ()) {
		return (sstor_drive ((char) driveno));
	}

	for (i=0; i<8; i++) {

		stackinfo->unit_offs = 0xff;	// Set unit number

		_asm {
			mov	ah,0x30 	// Get DOS version
			int	0x21		// Return with AH=minor, AL=maj
			cmp	ax,0x1f03	// Izit DR DOS or Compaq DOS?

			mov	ax,0x4408	// Removable media check
			jne	not_331 	// Jump if not

			mov	ax,0x440e	// Get logical device
		not_331:
			mov	bx,driveno	// Get drive number
			inc	bx		// Make it 1-based
			int	0x21		// Make IOCTL call
			jc	not_stacked	// Jump if invalid unit
		}

		if (stackinfo->unit_offs != 0xff) return (1);

	} // for ()

not_stacked:
	return (0);

} // stacked_drive
#pragma optimize ("", on)

void swap_logic (char bootdrive,
		char maxdrive,
		BOOL maxcompressed,
		char maxmappedto,
		char bootmappedto)
/***
 * Applies rules described in check_swap() comments.
***/
{
	// Set up ActualBoot
	ActualBoot = bootmappedto;

	// Re-initialize defaults
	CopyBoot = CopyMax1 = CopyMax2 = '\0';

	// Apply rules in order.
	// A.	If bootdrive != ActualBoot, CopyBoot = ActualBoot
	if (bootdrive != ActualBoot)	CopyBoot = ActualBoot;

	// B.	If maxdrive is not compressed or (is not 1:1 and !=
	//	ActualBoot), MaxConfig = maxdrive else MaxConfig = bootdrive
	if (maxmappedto != maxdrive ||
			(!maxcompressed && maxdrive != ActualBoot)) {
		MaxConfig = maxdrive;
	}
	else	MaxConfig = bootdrive;

	// C.	If maxdrive == MaxConfig and maxdrive is not
	//	mapped 1:1, CopyMax1 = mapped (maxdrive)
	if (maxdrive == MaxConfig && maxmappedto != maxdrive) {
		CopyMax1 = maxmappedto;
	}

	// D.	If maxdrive == ActualBoot and bootdrive != ActualBoot,
	//	CopyMax1 = bootdrive
	if (maxdrive == ActualBoot && bootdrive != ActualBoot) {
		CopyMax1 = bootdrive;
	}

	// E.	If maxdrive is compressed, maxdrive is 1:1,
	//	maxdrive != bootdrive and maxdrive != ActualBoot,
	//	CopyMax1 = ActualBoot
	if (maxdrive != ActualBoot && maxdrive != bootdrive &&
			maxcompressed && maxdrive == maxmappedto) {
		CopyMax1 = ActualBoot;
		// F.	If E holds true and bootdrive != ActualBoot,
		//  CopyMax2 = bootdrive
		if (bootdrive != ActualBoot)	CopyMax2 = bootdrive;
	}

} // swap_logic ()

void check_swap (char bootdrive, char maxdrive)
/***
 * bootdrive	Gotten from DOS or COMSPEC and confirmed by user
 *
 * maxdrive	The drive where the MAIN MAX installation is supposed
 *		to go.	The caller needs to determine this.  Usually
 *		it can be gotten from argv[0].	In the case of A:INSTALL
 *		where a preexisting directory is specified in CONFIG.SYS,
 *		some special checking is needed to look for a previously
 *		created split installation.  Here's the pseudo-code:
 *
 *		Get MAX destdrive from user or from CONFIG.SYS.
 *		IF not INSTALL run from a floppy,
 *		THEN BEGIN
 *			IF argv[0] drive != destdrive,
 *			THEN maxdrive = argv[0] drive
 *			ELSE maxdrive = destdrive
 *			ENDIF
 *		     END
 *		ELSE
 *			IF destdrive NOT in CONFIG.SYS,
 *			THEN maxdrive = destdrive
 *			ELSE	BEGIN
 *				    newdrive = 0
 *				    FOR drive = destdrive+1 to Z
 *					IF drive has the MAX directory
 *					with 386MAX.COM, newdrive = drive
 *				    END FOR
 *				    IF newdrive != 0
 *				    THEN maxdrive = newdrive
 *				    ELSE maxdrive = destdrive
 *				    ENDIF
 *				END
 *			ENDIF
 *		ENDIF
 *
 * MaxConfig	Drive letter to use in all CONFIG.SYS references to MAX
 *		drive:\directory.
 *
 * ActualBoot	Drive letter to use when accessing the real boot drive.
 *
 * CopyBoot	Drive letter to copy changed CONFIG.SYS/AUTOEXEC.BAT to.
 *
 * CopyMax1	Drive letter for parallel MAX directory #1.  Changes to
 *		386MAX.PRO need to be copied here.
 *
 * CopyMax2	Drive letter for second parallel MAX directory.  Profile
 *		changes need to be copied here also.
 *
 * Applicable rules are indicated by (Rx)
 * We ask three questions:
 * Q1: Is maxdrive compressed?
 * Q2: What is the actual drive for maxdrive?
 * (if maxdrive != bootdrive) Q3: What is ActualBoot?
 *
 * Cases we handle (drives with '-' are set to '\0'):
 * Case boot	max	Actual	Max	Copy	Copy	Copy	Q  Q   Q
 *  #	drive	drive	Boot	Config	Boot	Max1	Max2	1  2   3
 * -----------------------------(Rb)----(Ra)-----------------------------
 *  1	C	C	D	C	D	D(Rc)	-	Y  D  (D)
 *  2	C	D	D	C	D	C(Rd)	-	N  C   D
 *  3	C	D	C	C	-	C(Re)	-	Y  D   C
 *  4	C	E	D	C	D	D(Re,f) C(Re,f) Y  E   D
 *  5	C	D	C	C	-	C(Re)	-	Y  D   C
 *  6	C	E	D	C	D	D(Re,f) C(Re,f) Y  E   D
 *  7	C	C	C	C	-	-	-	N  C  (C)
 *  8	C	E	C	E	-	-	-	N  E   C
 *  9	C	D	F	D	F	G(Rc)	-	Y  G   F
 * ======================================================================
 *
 * Cases 3&4 and 5&6 differ only in that maxdrive is derived
 * differently.  See notes under definition of maxdrive above.
 *
 * An important assumption to apply rule C in case 9 above is that
 * if a drive is not mapped 1:1, the drive it maps to will be available
 * in CONFIG.SYS using the lower drive letter.
 *
 * Rules (applied in order):
 * A.	If bootdrive != ActualBoot, CopyBoot = ActualBoot
 * B.	If maxdrive is not compressed or (maxdrive is not 1:1 and maxdrive
 *	!= ActualBoot), MaxConfig = maxdrive else MaxConfig = bootdrive
 * C.	If maxdrive == MaxConfig and maxdrive is not mapped 1:1,
 *	CopyMax1 = mapped (maxdrive)
 * D.	If maxdrive == ActualBoot and bootdrive != ActualBoot,
 *	CopyMax1 = bootdrive
 * E.	If maxdrive is compressed, maxdrive is mapped 1:1,
 *	maxdrive != bootdrive and maxdrive != ActualBoot,
 *	CopyMax1 = ActualBoot
 * F.	If E holds true and bootdrive != ActualBoot, CopyMax2 = bootdrive
 *
 * Drive swapping and compressed drives affect each program differently:
 * INSTALL: Alternate directories on SwappedDriveLtr and possibly
 *	SwappedDrive2 need to be created, and essential files must
 *	be copied over.  Special detection of cases D & E is needed
 *	when INSTALL is run from a floppy.  When the user specifies
 *	a destination drive, we need to check for cases B and C to
 *	see if we must convert maxdrive.
 * MAXIMIZE: Path references are needed for maxdrive, and updated
 *	CONFIG.SYS, AUTOEXEC.BAT, and 386MAX.PRO must be copied over.
 *	POSFILE.BIN must also be copied over.
 * MAX shell: Changes to CONFIG.SYS and AUTOEXEC.BAT need to be
 *	copied to the actual boot drive if it's swapped.  Changes
 *	to 386MAX.PRO need to be copied to all alternate directories.
 * ASQ (future): Report information only.
***/
{
	int	i;

	// Re-initialize swap table... make everything 1:1
	for (i=0; i < sizeof(SwapTable); i++)	SwapTable[i] = (char) i;

	// Convert input drive letters to uppercase
	maxdrive = (char) (toupper (maxdrive) - 'A');
	bootdrive = (char) (toupper (bootdrive) - 'A');

	// If Stacker's not present check for SuperStor...
	if (!stacker_present ()) {
		if (sstor_drive (maxdrive) || sstor_drive (bootdrive)) {
			char dnum;

			// Set mappings in drive table for all drives
			// we MIGHT need mapping info for.
			dnum = sstor_mapping (maxdrive);
			SwapTable[maxdrive] = dnum;
			SwapTable[dnum] = maxdrive;
			if (bootdrive != maxdrive) {
				dnum = sstor_mapping (bootdrive);
			}
			SwapTable[bootdrive] = dnum;
			SwapTable[dnum] = bootdrive;

			// Check for the one case we can't support-
			// maxdrive is compressed and 1:1, and
			// (bootdrive == maxdrive or (bootdrive is
			// compressed and 1:1)).  We COULD dismount
			// the drives in question, but then we'd have
			// no way to get back on the horse...
			if (	stacked_drive (maxdrive) &&
				maxdrive == SwapTable[maxdrive] &&
				(maxdrive == bootdrive ||
				 (stacked_drive (bootdrive) &&
				  bootdrive == SwapTable[bootdrive]))) return;

			// Set return code
			SwappedDrive = SWAPPEDDRIVE_SSTOR;
		} // SuperStor present
	} // Stacker not present
	else {
		SwappedDrive = SWAPPEDDRIVE_STACKER;
		if (!_fstrncmp (stackinfo->swapsig, SWAPSIG,
					_fstrlen (SWAPSIG))) {
			_fmemcpy (SwapTable, stackinfo->swapmap,
					sizeof(stackinfo->swapmap));
		} // Stacker drive swapping map is valid
	} // Stacker present

	// If nothing to do, go home
	if (SwappedDrive <= SWAPPEDDRIVE_FALSE) return;

	swap_logic (	(char) (bootdrive+'A'),
			(char) (maxdrive+'A'),
			stacked_drive (maxdrive),
			(char) (SwapTable[maxdrive]+'A'),
			(char) (SwapTable[bootdrive]+'A'));

	// Eliminate cases 7 & 8 (no action needed)
	if (!CopyBoot && !CopyMax1) {
		SwappedDrive = SWAPPEDDRIVE_FALSE;
	}

} // check_swap ()

