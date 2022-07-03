/*' $Header:   P:/PVCS/MAX/INSTALL/DRVE.C_V   1.7   02 Jun 1997 14:02:22   BOB  $
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * DRVE.C								      *
 *									      *
 * Routines for copying and unarchiving files				      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <malloc.h>
#include <io.h>
#include <dos.h>
#include <graph.h>
#include <conio.h>
#include <stdarg.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>

#include "compile.h"

#include "commfunc.h"
#include "common.h"
#include "dmalloc.h"
#include "extn.h"
#include <implode.h>
#include "intmsg.h"
#include "mbparse.h"
#include "myalloc.h"
#include "package.h"

#define DRVE_C
#include "instext.h"    /* Message text */
#undef DRVE_C

#ifndef PROTO
#include "drve.pro"
#include "files.pro"
#include "install.pro"
#include "misc.pro"
#include "pd_sub.pro"
#include "scrn.pro"
#include "security.pro"
#include "serialno.pro"
#endif

// Local data
int archandle=0, desthandle;	// Archive file handle & dest file handle
long arcbytes;			// Bytes to read from archive file
long arcCRC;			// CRC of data from archive file
extern char archive_fname[];	// Name of current archive file (misc.c)
char dest_fname[80];		// Destination file name
#define XBUFFSIZE	0x4000	// Size needed for explosion
#define RBUFFSIZE	0x8000	// Size needed to buffer reads
char far *xbuff;		// Extract buffer
char	 *rbuff,*rbptr; 	// Read buffer
unsigned int rbuff_left;	// Bytes remaining in rbuff
long	 vfilepos;		// Virtual file position
int	 ParsePass;		// Times we've parsed CONFIG.SYS

//********************************** SET_BACKUP ******************************
// Find a unique directory name for backup of old product and create it
void set_backup (void)
{
 int backupnum;

 for (backupnum=1; backupnum < 1000; backupnum++) {

  sprintf (BackupDir, "%s" OLDMAX ".%d", dest_subdir, backupnum);

  if (access (BackupDir, 0)) {
	if (!mkdir (BackupDir)) // Created successfully
	 break;
  } // BackupDir does not exist

 } // for ()

 do_intmsg (MsgCreateBack, BackupDir);

 strcat (BackupDir, "\\");      // Make it end with "\"

} // set_backup()

//******************************** BACKUP_FILE ******************************
// Backup one file from dest_subdir to BackupDir by renaming it.
void backup_file (char *fname)
{
 char	src[MAXPATH+1],
	dest[MAXPATH+1];
 static int dirset = 0;

 if (!Backup) return;

 if (!dirset) {
	set_backup();
	dirset++;
 } // Backup dir not set

 // Adjust count whether rename works or not; directory has been created
 FilesBackedUp++;

 sprintf (src, "%s%s", dest_subdir, fname);
 sprintf (dest,"%s%s", BackupDir, fname);

 if (access (src, 06))
	chmod (src, S_IREAD | S_IWRITE);	// Force it to read-write

 if (rename (src, dest))
  do_intmsg (MsgRenErr, src, dest, errno);

} // backup_file

#pragma optimize("leg",off)
//********************************** CHKESCAPE *******************************
// If user pressed Esc key, call chkabort() to see if they really want to
// bail out.  Note that we only call this function between creating files,
// so we never need worry about deleting partially extracted files.  We do,
// however, need to ensure that the archive file we've copied to the hard
// disk gets deleted.  We'll do that in abortprep(), which is called from
// chkabort().
void chkescape (void)
{

 _asm {

 mov	ah,1		// Fn 1: check for key pressed
 int	0x16		// Call keyboard services
 jz	chkesc_exit	// Skip out if nothing pressed

 sub	ax,ax		// Fn 0: get key
 int	0x16		// Call keyboard services

 or	ax,ax		// Izit Ctrl-Break?
 jz	short CALL_CHKABORT // Jump if so

 cmp	ax,0x011b	// Izit Esc?
 jne	chkesc_exit	// Leave it in the buffer and skip out if not

CALL_CHKABORT:
 }

 chkabort();		// Confirm that user REALLY wants to abort
			// Note that chkabort() is a one-way street if they
			// DO choose to abort...

chkesc_exit:
 ;

} // chkescape ()
#pragma optimize("",on)

//********************************** OPEN_ARCHIVE ****************************
// Open or close archive file.	If opening and space exists on destination
// drive, copy it there and reopen it.	When closing, if using a copy, delete.
// Handle is assigned to archandle directly.
// We assume that StorageSize has already been calculated.
int open_archive (int action, int extent, int extract)
{
 static int copied;
 int res = 0;
 char temp[80];
 struct diskfree_t free;

 if (action) {		// open file (action is extent #)

	_dos_getdiskfree ((unsigned char) toupper (dest_drive) - 'A' + 1, &free);

	do {

	 chk_flpydrv (MAXDSK, archive (action), action, extent);

	} while ((archandle =
			open (archive (action), O_BINARY|O_RDONLY)) == -1);

	if (extract && !is_fixed (*source_drive) &&
	    StorageSize + 2L * filelength (archandle) + 8192L <
	    ((long)free.avail_clusters * (long)free.sectors_per_cluster
	     * (long)free.bytes_per_sector) ) {

	 close (archandle);
	 archandle = 0; // Mark as closed
	 copied = action;
	 sprintf (temp, "%s.%d", MAX_PRODFILE, action);
	 do_intmsg (MsgCopyArchive, temp);
	 copy_one_file (temp, temp);
	 sprintf (temp, "%s%s.%d", dest_subdir, MAX_PRODFILE, action);
	 if ((archandle = open (temp, O_BINARY|O_RDONLY)) == -1)
		error (-1, MsgFileRwErr, temp);

	} // Space sufficient to copy to hard disk first

	else
	 copied = 0;	// Copying directly from floppy

 }			// open file

 else { 		// close file

	close (archandle);
	archandle = 0;	// Mark as closed

	if (copied) {
	 sprintf (temp, "%s%s.%d", dest_subdir, MAX_PRODFILE, copied);
	 unlink (temp);
	} // File was copied to hard disk -- delete it

 }

 return (res);

} // open_archive

/*********************************** COPY_MISSING ***************************/
// Copy missing or newer files from the archive disk to the destination
// directory, with the exception of 386max.? and INSTALL.HLP.  This
// supports network installations.
void copy_missing (char *destpath)
{
	char destname[128], srcname[128];
	char cmpname[8+1+3+1], searchspec[128];
	char *digext;
	struct find_t find_str;
	int srcH,destH, docopy;
	unsigned int srcT, srcD, destT, destD;

	sprintf (searchspec, "%s*.*", source_subdir); // What to copy

	if (!_dos_findfirst (searchspec, _A_RDONLY|_A_ARCH, &find_str)) {

	    do	{

		// Don't copy the archive because it's too big.
		// Don't copy INSTALL.HLP because it's open.
		strcpy (cmpname, find_str.name);
		if (	(digext = strrchr (cmpname, '.')) &&
			(digext = strpbrk (digext, "123456789")) )
								*digext = '?';
		if (	stricmp (cmpname, MAX_PRODFILE ".?") &&
			stricmp (cmpname, DOSNAME ".hlp")) {

		  sprintf (srcname, "%s%s", source_subdir, find_str.name);
		  sprintf (destname, "%s%s", destpath, find_str.name);

		  // Copy if destination is missing, or source is newer
		  srcH = open (srcname, O_RDONLY);
		  destH = open (destname, O_RDONLY);
		  docopy = 0; // Assume we're not copying
		  if (destH == -1) docopy = 1;
		  else {
		    _dos_getftime (srcH, &srcD, &srcT);
		    _dos_getftime (destH, &destD, &destT);
		    if (srcD > destD || (srcD == destD && srcT > destT))
								docopy = 1;
		    close (destH);
		  } // Destination file exists
		  close (srcH);

		  if (docopy) {
			copy_file (srcname, destname);
		  }

		} // Not 386MAX.n

	    } while (!_dos_findnext (&find_str));

	} // Found file(s)

} // copy_missing ()

//********************************** EXPLODE_IN ******************************
// Called indirectly by DCL code.  Reads data in from archive.
long vseek (long seek_off)
// Change buffer pointers if possible, otherwise do lseek
{
 long diff, diff2;

 diff = seek_off - vfilepos;
 diff2= rbuff_left - RBUFFSIZE;

 if (diff > (long) rbuff_left || diff < (long) diff2) { // lseek and reset
	rbuff_left = 0;
	rbptr = rbuff;
	return (vfilepos = lseek (archandle, seek_off, SEEK_SET));
 }

 if (diff = (long) rbuff_left) { // move file pointer to end of buffered area
	rbuff_left = 0;
	rbptr = rbuff;
	return (vfilepos += diff);
 }

 // Handle positive and negative seeks within buffered area
 if (diff >= 0 || diff > (long) diff2) {
	rbuff_left -= (WORD) diff;
	rbptr += (WORD) diff;
	return (vfilepos += diff);
 }

 return (-1L);			// shouldn't get here

}

unsigned int buff_read (char _far *buff, unsigned short int size)
// Buffer read from archandle
{
 unsigned int rbuff_copy, rbuff_total = 0;

/*  return (read (archandle, buff, size));  */

 do {

  if (rbuff_left) {	// Try to fill request from buffer
	rbuff_copy = min (size, rbuff_left);
	memcpy (buff, rbptr, rbuff_copy);
	rbptr += rbuff_copy;
	rbuff_left -= rbuff_copy;
	size -= rbuff_copy;
	buff += rbuff_copy;
	rbuff_total += rbuff_copy;
	vfilepos += rbuff_copy;
  }

  if (size && !rbuff_left) {	// Time to fill buffer
	rbptr = rbuff;		// Rewind buffer head
	rbuff_left = read (archandle, rbptr, RBUFFSIZE);
  }

 } while (size && rbuff_left && rbuff_left != 0xffff);

 return (rbuff_left == 0xffff ? rbuff_left : rbuff_total);

} // buff_read ()

unsigned far pascal Explode_In (char far *buff, unsigned short far *size)
{
 unsigned int bytesread;

 bytesread = buff_read (buff, *size);
 if ((long) bytesread > arcbytes)
	bytesread = (unsigned int) arcbytes;
 arcbytes -= (long) bytesread;
 if (bytesread)
  arcCRC = crc32 (buff, &bytesread, &arcCRC);

 return (bytesread);
} // Explode_In ()

void far pascal Explode_Out (char far *buff, unsigned short int far *size)
{
 unsigned byteswritten;

 byteswritten = write (desthandle, buff, *size);

 /* return (byteswritten); */

} // Explode_Out ()

#pragma optimize("leg",off)
//********************************** DO_EXTRACT ******************************
// Transfers files from source disk to destination
// Action argument extract, if 0, specifies return size only.
// If 1, extract files and return number of bytes extracted.
// If 2, extract only BCF file(s).
// Files argument is usually "" (extract everything), but is used to extract
// only STRIPMGR.EXE and STRIPMGR.LST when we fail CRC calculation.
// Note that we must specify a destination drive:\directory, which MUST
// end in a trailing slash or backslash.  The drive letter MUST be specified
// and must be the same as the dest_subdir drive.
// After we've extracted everything from a disk, and before we ask for
// the next disk, copy any newer or missing files from the disk (with the
// exception of 386MAX.?).
typedef struct _qdirlst {
   struct _qdirlst *next;		// NULL if end
   word id;		  /* product id */
   long start;		  /* offset from start of file */
   DIRTIME date;	  /* compressed date/time */
   long size;		  /* size of uncompressed file */
   long csiz;		  /* size of uncompressed file */
   word att;		  /* file attribute */
   byte num;		  /* extent that file is in */
   byte comp;		  /* compression format */
   char path[13];	  /* file name (nul terminated) */
} QDIRSTR, *QDIRLST;

long  do_extract (int extract, char *files, int prodmask, char *destpath)
{

static QFHEAD fhead;		// Disk 1 header - note that this is static,
				// so we don't have to read it twice.
static QDIRLST fdir = NULL;	// Disk 1 directory (the only directory)
				// Since this function is called first to
				// get the bytes required, then again
				// to extract, we only build the directory
				// once.
QDIRLST  fprev, fcur;
QDIR	 *ftmp;
auto	 QFHEAD ftemp;		// Current disk header
DIRTIME  ftime;
int	 len;
word	 disk_num, disk_pass;
long	 crc;			// CRC for current file (as read from archive)
unsigned res;
long	 retval = 0L;		// Value to return (bytes extracted)
BOOL	 xmask; 		// Value to AND with extract

	 disableButton (KEY_F1, TRUE);

// Don't copy archive file if we're only extracting a few files or
// using the /o or /n options.
	 xmask = (!(*files) && !(Overwrite || PatchPrep));

// Set the disk number initially to one
	 disk_num = 1;

// Initialize the destination drive -- make sure we have disk 1 mounted
	 dest_drive = (char) toupper ( *destpath );
	 chk_flpydrv (MAXDSK, archive(disk_num), 1, 1);

// Allocate explosion buffer (also used for directory manipulation)
	 if ((xbuff = _dmalloc (XBUFFSIZE)) == NULL ||
	     (rbuff = _dmalloc (RBUFFSIZE)) == NULL)
		error (-1, MsgMallocErr, "file extraction");
	 rbuff_left = 0;

// Open file
	 if (open_archive (disk_num, fhead.ext, extract && xmask) == -1 ||
	    read (archandle, &ftemp, sizeof (ftemp)) != sizeof (ftemp))
		error (-1, MsgFileRwErr, archive (disk_num));

// We have got the first archive disk.	Read the directory into memory if
// we don't already have it.
	 if (fdir == NULL) {

	  memcpy (&fhead, &ftemp, sizeof (fhead));

	  if (	fhead.num != (byte) disk_num || 	// Extent mismatch
		fhead.dir < sizeof (fhead) ||	// Bad dir start or no directory
		!fhead.fnum ||			// No dir entries
		fhead.dlen > XBUFFSIZE) 	// Dir too big
		error (-1, MsgArchiveErr, archive (disk_num),
			"bad data", "header", 0);

	  // Seek to start of directory
	  if (lseek (archandle, (long) fhead.dir, SEEK_SET) == -1)
		error (-1, MsgFilePosErr, archive (disk_num));

	  // Read entire directory into xbuff
	  if (read (archandle, xbuff, fhead.dlen) == -1)
		error (-1, MsgFileRwErr, archive (disk_num));

	  // To maximize the efficiency of our heap allocation, we allocate
	  // (12-5) * number of directory entries + dir size to fdir,
	  // and parcel it out as we go along.	5 is the minimum filename
	  // length (README)
	  fprev= fdir = get_mem (fhead.dlen + fhead.fnum * (12-5));

	  // Walk through directory entries in memory and set up fdir list
	  for ( ftmp=((QDIR *) xbuff),
		fcur=fdir,
		len = fhead.fnum; len; len--) {

	   // Since we copy sizeof (QDIRSTR) bytes, we also copy path and
	   // trailing null.
	   memcpy (fcur, ftmp, sizeof (QDIRSTR));

	   fcur->next = NULL;
	   if (fcur != fprev)
		fprev->next = fcur;
	   fprev = fcur++;

	   ftmp = (QDIR *) ((char *) ftmp + sizeof (QDIR)+ strlen (ftmp->path) + 1);

	  } // for (ftemp...)

	 } // fdir == NULL

	 vfilepos = lseek (archandle, 0L, SEEK_CUR);	// Get current offset
	 for (	disk_pass = disk_num;
		disk_pass <= (word) fhead.ext;
		disk_pass++) {

	  for (fcur = fdir; fcur != NULL; fcur = fcur->next)

	   if ( (fcur->id & prodmask) &&		// Product ID is OK
		(word) fcur->num == disk_pass &&	// In this extent
		(!(*files) || strstr (files, strupr (fcur->path)))) {

	    // Use an overly generous blocking factor when calculating space
	    if (disk_pass == 1)
	     retval += (fcur->size / 8192L + (fcur->size % 8192L ?1:0)) * 8192L;

	    if (!extract)
		continue;

	    sprintf (dest_fname, "%s%s", destpath, fcur->path);

	    // Change disks if necessary
	    if (disk_num != disk_pass) {

		open_archive (0, 0, extract);
					// Close file (& delete if on hard disk)
		rbuff_left = 0; 	// Reset buffer pointers & counter
		rbptr = rbuff;
		vfilepos = 0L;		// Reset virtual file offset
		disk_num = disk_pass;
		open_archive (disk_num, fhead.ext, extract && xmask); // Open next extent

	    } // Needed to change disks

	    // Check to see if file exists
	    ftime.dtime = 0L;
	    if ((desthandle = open (dest_fname, O_BINARY|O_RDONLY)) != -1) {
		_dos_getftime (desthandle, &(ftime.dt.date), &(ftime.dt.time));
		close (desthandle);
	    } // Destination file exists

	    // If the Overwrite flag is set, don't overwrite existing file
	    // with identical or newer time/date unless PatchPrep is also
	    // set.  Overwrite and PatchPrep together have the effect of
	    // extracting newer, older, and missing files.
	    if (Overwrite && !PatchPrep && ftime.dtime >= fcur->date.dtime)
		continue;

	    // If PatchPrep is set and we passed the Overwrite test
	    // above, we should keep going.  Otherwise, if PatchPrep
	    // is set, skip the file only if it is missing or if the
	    // time/date is identical.
	    if (PatchPrep && !Overwrite &&
		(desthandle == -1 || ftime.dtime == fcur->date.dtime))
		continue;

	    do_intmsg (MsgExtFile, fcur->path, fcur->size);

	    // If open did not fail, backup file
	    if (desthandle != -1)
		backup_file (fcur->path);

	    if (vseek (fcur->start) == -1L)
		error (-1, MsgFilePosErr, archive (disk_num));
	    rbuff_left = 0;

	    if (buff_read ((char *) &crc, sizeof (crc)) == 0xffff)
		error (-1, MsgFileRwErr, archive (disk_num));
	    arcCRC = ~0;
	    arcbytes = fcur->csiz - 4L;

	    chkescape ();

	    if ((desthandle =
		 open (dest_fname, O_BINARY|O_RDWR|O_CREAT|O_TRUNC,
				S_IWRITE)) == -1) {
		if (!access (dest_fname, 0))
		 _dos_setfileattr (dest_fname, _A_NORMAL);
		if ((desthandle = open (dest_fname, O_BINARY|O_RDWR|O_CREAT|O_TRUNC, S_IWRITE)) == -1)
		 error (-1, MsgFileRwErr, dest_fname);
	    } // First create attempt failed

	    if (fcur->comp == CMP_NONE)
		while (arcbytes) {
		 if ((long) XBUFFSIZE < arcbytes)
		  len = XBUFFSIZE;
		 else
		  len = (int) arcbytes;
		 if (buff_read (xbuff, len) == -1 ||
			write (desthandle, xbuff, len) == -1)
		   error (-1, MsgFileRwErr, dest_fname);
		 arcbytes -= (long) len;
		} // while (arcbytes)
	    else
	     if ((res = explode (Explode_In, Explode_Out, xbuff)) ||
		~arcCRC != crc)
		error (-1, MsgArchiveErr, archive (disk_num),
		 res ? "bad data" : "CRC failure", dest_fname, res);

	    _dos_setftime (desthandle, fcur->date.dt.date, fcur->date.dt.time);
	    close (desthandle);
	    _dos_setfileattr (dest_fname, fcur->att);

	   } // if it's the product we're looking for, it's in this extent,
	     // and it's in the list or there was no list...

	   // Do the equivalent of xc/n/a from the current disk to the
	   // destination directory, excluding 386MAX.?
	   if (extract == 1) copy_missing (destpath);

	 } // for fcur->next != NULL
	   // for disk_pass <= fhead.ext


// Clean up and prepare to exit
	open_archive (0, 0, extract);
				// Close file (& delete if copied to hard disk)
	_dfree (xbuff);
	_dfree (rbuff);

	disableButton (KEY_F1, FALSE);

// All done.
	return (retval);

} // End do_extract ()
#pragma optimize("", on)

/******************************* DO_BCFEXTRACT **************************/
// Extract the proper BCF file from the floppy to the destination dir
void do_bcfextract (void)
{
	char destname[128], srcname[128];

	if (bcfsys && BIOSCRC)	// If it's a BCF system and a valid BIOS CRC
	{
	    // Create and display the message text
	    sprintf (destname, MsgCopyBCF, BIOSCRC);
	    do_intmsg (destname);

	    // Create the source and destination names
	    sprintf (srcname, "%sBCF\\@%04X.BCF", source_subdir, BIOSCRC);
	    sprintf (destname, "%s@%04X.BCF", dest_subdir, BIOSCRC);

	    // Copy the BCF file
	    // unless it doesn't exist in which case we just ignore it
	    if (access (srcname, 04) == 0) // Check for readable only
		copy_file (srcname, destname);
	} // IF (BIOSCRC)

} // do_bcfextract()


/******************************* COPY_FILE ******************************/
// Copy a file; if it fails, abort with error message
// Make sure we aren't copying a file over itself; some idiots copy
// the distribution disk files into the c:\386max directory and then
// run INSTALL.
void copy_file (char *srcpath, char *dstpath)
{

  if (truename_cmp (srcpath, dstpath))
	if (!copy (srcpath, dstpath))	error (-1, MsgFileRwErr, dstpath);

} // copy_file ()


/******************************* COPY_ONE_FILE **************************/
// Copy a file from the distribution disk
void copy_one_file(char *name, char *arcfile)
{
	char destname[128], srcname[128];

	chk_flpydrv ( MAXDSK, arcfile, 1, 1);
	sprintf (srcname, "%s%s", source_subdir, name);
	sprintf (destname, "%s%s", dest_subdir, name);

	copy_file (srcname, destname);

} // copy_one_file


/******************************** CHECK_FREESPACE *********************/
// Check for specified bytes of free space on specified drive
// Drive numbers are 0 for current drive or 1..26 for 'A'..'Z'.
// If fatal == FALSE, crap out directly to DOS, otherwise return 1.
// Return 0 means there's enough space.
int check_freespace (int drivenum, DWORD needed, BOOL fatal)
{
DWORD	 freediskspace;
struct	 diskfree_t freedisk;

	 _dos_getdiskfree (drivenum, &freedisk );
	 if ( ( freediskspace = (DWORD) freedisk.avail_clusters
			      * (DWORD) freedisk.sectors_per_cluster
			      * (DWORD) freedisk.bytes_per_sector )
				< needed) {
		char temp1[20];
		char temp2[20];
		char temp3[4];

		sprintf(temp1,"%8ld", needed);
		sprintf(temp2,"%8ld", freediskspace);
		sprintf(temp3,"%c:", drivenum ? '@' + drivenum : dest_drive);
		do_textarg(1,temp1);
		do_textarg(2,temp2);
		do_textarg(3,temp3);
		do_error(fatal ? MsgNoFreeDisk : MsgNoFreeDisk2, 0, FALSE);
		if (fatal) return_to_dos(0);
		return (1); // Indicate failure

	 } // End IF

	 return (0); // There's enough space

} // check_freespace ()

/********************************** FILESIZE ******************************/
// Return file size in bytes, with 4K blocking factor
long	filesize (char *pathname)
{
  long retval = 4096L;
  long seekres;
  int fh;

  if ((fh = open (pathname, O_RDONLY|O_BINARY)) != -1) {

	seekres = lseek (fh, 0L, SEEK_END);

	if (seekres != -1L) {
	  retval = ((seekres + 4096L - 1L) / 4096L) * 4096L;
	} // Got size in bytes

	close (fh);

  } // Opened file

  return (retval);

} // filesize ()

/********************************** CHECK_DEST *****************************/
int	 check_dest ( char *arcfile, BOOL fatal )
{
	 int	 len;

	 if ( adjust_pfne ( dest_subdir, (char)(saved_drive + '@'), ADJ_PATH ) ) { // Ensure valid path
		 do_error(MsgBadDest,0,FALSE);
		 return 1;
	 }
	 dest_drive = (char) toupper ( *dest_subdir );

// Switch to destination disk
	 if ( chdrive (dest_drive)) {
		 len = strlen ( dest_subdir );
		 if ( strlen ( dest_subdir ) > 3 ) { // Delete trailing \ if present
			if ( dest_subdir[ len - 1 ] == '\\')
				dest_subdir[ len - 1 ] = 0;
		 } // End IF

	 // Check to see if the destination drive has enough room to handle
	 //  the program storage requirement.  Add in a fudge factor; ensure
	 //  we have 125% of StorageSize free.	If there's not enough space,
	 //  let 'em enter another destination unless we already have a
	 //  fixed destination directory.

		 // Even with INSTALL /r we need enough space for
		 // .add, backup, and .dif copies of CONFIG, AUTOEXEC,
		 // and the profile;
		 // the STRIPMGR.OUT file (8K max)
		 // the INSTALL.RCL file (4K max)
		 if (ReInstall) {
			StorageSize = 4096L +	// INSTALL.RCL
				8192L + 	// STRIPMGR.OUT
				12288 * 3L +	// 386MAX.PRO, .add, .dif
				filesize (con_dpfne) * 3L +
				filesize (StartupBat) * 3L;
		 } // Calculate space requirements for ReInstall

		 if (check_freespace (0, StorageSize + (StorageSize/4), fatal))
			return (1); // Let 'em try again

	 // Change to the specified subdirectory, make it if it doesn't exist.
		 if ( !set_maxdir (dest_subdir) ||
			chdir ( dest_subdir ) == -1 ) {
				do_error(MsgBadCreatSub,0,FALSE);
				return 1;
		 } // End IF

	 } else { // chdrive failed
		 do_error(MsgBadDest,0,FALSE);
		 return ( 1 );		// Get a new entry
	 } // End ELSE

	 // SUBST'ed drive?  Translate to true path */
	 truename(dest_subdir);

	 // Put a \ on the end
	 do_backslash (dest_subdir);

	 return ( 0 );			// All is cool

} // End check_dest


//******************************** SAVE_PATH **********************************/

void save_path (void)
{
// Save the current drive and path
	 _dos_getdrive( &saved_drive );
	 if ( NULL == getcwd( saved_path, MAXDIR )) {
	     error ( -1, MsgGetCWD);
	 }

} // End SAVE_PATH


//*************************** CHECK_SOURCE ROUTINE *****************************
// We'll just make sure the archive file is there.  If they want to run
// INSTALL from a hard disk or network drive, it's OK.  That's the only
// way to create a bootable floppy.
enum boolean	 check_source ( char *arcfile )
{
	 enum boolean	rc = FALSE;

	 *source_drive = (char)toupper ( *source_drive );
	 if ( chdrive (*source_drive)) {
		if ( access (arcfile, 0 ) == 0 ) {
			rc = TRUE;
		} // End IF
	 } // End IF valid drive

	return ( rc );

}//End of check_source routine


//**************************** RESTORE_PATH **********************************
void	 restore_path ( void )
{
	unsigned drives_available;
	int rc;

// Switch to original drive and path
	_dos_setdrive( saved_drive, &drives_available );
	if ( ( rc = chdir ( saved_path ) ) != 0 ) {
	    error ( -1, MsgChDir);
	} // End IF

} // End restore_path


//******************************* IS_FIXED *************************************
// Is the drive fixed or removable?
//
// Input:  drive letter
// Output: 0 == device is removable
//	   1 == device is fixed
//	0x0f == invalid drive number

int	 is_fixed ( unsigned char drive )
{
	 union REGS r;

	 r.x.ax = 0x4408;	     // IOCTL 8, fixed or removable
	 r.h.bl = (BYTE) (toupper (drive) - 'A' + 1); // Drive number (origin 1)
	 intdos( &r, &r );	     // Request DOS service

	 return( r.x.ax );

} // End IS_FIXED


/********************************* CHDRIVE **********************************/
// Switch to specified drive
// Return FALSE if can't be done
// drive is 'A','a','c', etc.
enum boolean chdrive ( unsigned char drive )
{
	 union REGS r;
	 enum boolean rc = YES;

// Switch to specified drive
	 r.h.ah = 0x0E; 		// Function code to select disk
	 drive = (unsigned char) (((unsigned char) toupper (drive)) - 'A');
	 r.h.dl = drive;		// Drive number (origin-0)
	 intdos( &r, &r );		// Request DOS service
	 if (drive >= r.h.al)		// Whoops
		 rc = NO;
/*****	 else
		 chdir ("\\");          // Change to root on that drive
*****/
	 return (rc);

} // End chdrive


//***************************** CHANGE_TO_DEST *********************************
void	 change_to_dest ( void )
{
char	 work [80];
int	 len;

	 strcpy ( work, dest_subdir ); // Copy to delete trailing slash
	 len = strlen ( work );
	 if ( work[len - 1] == '\\' && len > 3 ) // If trailing slash and not "?:\\"
		 work[len - 1] = '\0';  // ...zap it
	 chdrive (dest_drive);		// Change to the destin drive
	 chdir ( work );		// ... and to the destin subdir

} // End change_to_dest


//******************************* CHK_FLPYDRV ********************************
void	 chk_flpydrv (int distdsk, char *arcfile, int num, int numof)
{
int	 flepres;
char	 msgbuff [10];

	 while ( YES ) {
		 if ( chdrive (*source_drive) ) {
			if (
			     ( !( flepres = access ( arcfile, 0 ) ) && distdsk )
			  || ( flepres && !distdsk )
			   ) break;
			if ( distdsk )	{
			 sprintf (msgbuff, numof != 1 ? "%d of %d " : "", num, numof);
			 do_textarg (1, msgbuff);
			 get_srcdrve2(MsgInsertSrc,HELP_SRCDRV,TRUE,num);
			} else		do_advice(MsgInsertDest,0,TRUE);
		 } else {
			do_error(MsgInvalidDrv,0,FALSE);
			return_to_dos(0);;
		 }
	 }
} // End chk_flpydrv


/****************************** SET_MAXDIR ************************************/
/* Recursively setup directory for 386MAX files */
/* This also removes the trailing backslash from the directory name. */
int set_maxdir ( char *destdir )
{
	int len;
	enum boolean rc = YES;	 // Assume success

// Ensure no trailing slash unless it's just "?:\\"
	len = strlen ( destdir );
	if (len > 3 && destdir[len - 1] == '\\') {
		destdir[--len] = 0;
	}

// Handle creating multiple subdirectories
	if ( access ( destdir, 0 ) != 0 ) {
		int kk;
		char *pp;
		char work[80];

		strcpy (work, destdir);

		// Skip to the first character after d: or d:<backslash>
		for (kk = 1; kk < len && strchr (":\\", work[kk]); kk++) ;

		pp = work + kk; // Save pointer to first directory

		// Create a list of ASCIIZ directory names to create
		// (c:\foo.bar\0util\0max)
		for ( ; kk < len; kk++) {
			if (work[kk] == '\\') work[kk] = '\0';
		}

		// Start with the first directory, and gradually restore
		// backslashes:
		// c:\foo.bar
		// c:\foo.bar\util
		// c:\foo.bar\util\max
		for (;;) {

			// Ensure that directory name is OK
			if (strlen (pp) > 12) {
				/* directory name too long */
				rc = NO;
				break;
			}
			_splitpath (pp,
			      drv_drive,
			      drv_dir,
			      drv_fname,
			      drv_ext );
			if (strlen(drv_fname) > 8 || strlen (drv_ext) > 4) {
				/* Bogus directory name, no way dude! */
				rc = NO;
				break;
			}

			// If directory doesn't exist, create it
			if (access(work,0) != 0) {
				if (mkdir(work) == -1) {
					rc = NO;
					break;
				}
			}

			// If we've already restored all the \'s, we're done.
			if ((int)strlen(work) >= len) break;

			pp += strlen(pp); // Skip to separating \0

			*pp++ = '\\'; // Restore backslash

		} // for ()

	 } // End IF

	 return ( rc );

} // End SET_MAXDIR


/**************************  WALK_CFG  *******************************/
// Called recursively.	Starts at a given line and walks through
// CONFIG.SYS, paying attention only to lines that match the current
// owner (MultiBoot only).  INCLUDE= statements are ignored, since
// we've already expanded any INCLUDE or common sections containing
// device drivers.
// Returns 0 if we should continue recursion, otherwise 1.
int	walk_cfg (CFGTEXT *start, int (*walkfn) (CFGTEXT *))
{
  CFGTEXT *p;

  for (p = start; p; p = p->next) {

	if (!MultiBoot) {
		if ((*walkfn) (p)) return (1);
	} // MultiBoot not active
	else if (p->Owner == ActiveOwner || p->Owner == CommonOwner) {
		if ((*walkfn) (p)) return (1);
	} // No MultiBoot, or it's the active owner

  } // for all lines in CONFIG.SYS

  return (0);

} // walk_cfg ()

/**************************  FIND_UPDATE_SUB  ************************/
// Subfunction to find_update_dest().  Check each line as we walk through
// CONFIG.SYS.	Since we are called from walk_cfg(), we can assume that
// any line we see is in the correct Multiboot section.
// If INSTALL or UPDATE is run from a floppy (i.e. not with /R) we
// need to check for MAXIMIZE.EXE.  If not found, assume we have a
// mirror directory and we need to hunt for a parallel directory on
// higher drive letters.  Note that this will only be the case if
// MAX is installed on a compressed drive, and a mirror directory
// with essential files was created on the boot drive.
int	find_update_sub (CFGTEXT *p)
{
char	fdrive[_MAX_DRIVE],
	fdir[_MAX_DIR],
	fname[_MAX_FNAME],
	fext[_MAX_EXT],
	temp[_MAX_PATH],
	*devpath;

  if (	!stricmp (devpath = fname_part (p), OEM_FileName) ||
	!stricmp (devpath, OEM_OldName)) {
	_splitpath (path_part (p), fdrive, fdir, fname, fext);
	sprintf (update_subdir, "%s%s", fdrive, fdir);
	do_backslash (update_subdir);
	mgr_fnd = TRUE;
	sprintf (temp, "%s" MAX_MAXIMIZE, update_subdir);
	set24_resp (RESP_FAIL); // Fail all critical errors
	for (strupr (temp); temp[0] <= 'Z'; temp[0]++) {
	  if (!access (temp, 0)) {
		update_subdir[0] = temp[0]; // Save the drive letter
		break;
	  } // Found the actual directory
	} // Hunting for MAXIMIZE.EXE
	set24_resp (0); // Resume normal critical error handling
	return (1);
  } // Device is 386max.sys (so what if it's INSTALL=?)

  return (0);

} // find_update_sub ()

//*************************  FIND_UPDATE_DEST  ************************
// -Look for our device= line in CONFIG.SYS.  If we find it then
//  store the drive and path as the default destination directory,
// -If we are unable to get a drive and path from CONFIG.SYS AND it's
//  UPDATE (not INSTALL) then prompt the user for a drive and path
void	find_update_dest ( void )
{
  int res = walk_cfg (CfgSys, find_update_sub);

	if (fUpdate) {
		if (res != 1) get_updatedir ();
	} // UPDATE.EXE not yet branded
	else
	if (ReInstall) {
	    get_exepath (update_subdir, 127);
	}

} // End find_update_dest

/**************************** MOVE_OLD_FILES *********************************/
// This function moves old files into the backup directory (creating it
// if necessary).  README.EXE is not wanted at all, since it will conflict
// with README.BAT.  386CACHE.EXE and 386CACHE.WIN are overwritten by
// copies of QCACHE.EXE and QCACHE.WIN respectively.
void move_old_files (void)
{
 int anymoved = 0;

 change_to_dest ();	// Make destination dir current

 if (!access (OLDREADME, 0)) {
	backup_file (OLDREADME);	// Get rid of README.EXE
	anymoved++;
 }

#if QCACHE_TEST
 if (!access (OLDQCACHE_EXE, 0)) {
	backup_file (OLDQCACHE_EXE);	// Save old 386CACHE.EXE
	copy_file (QCACHE_EXE, OLDQCACHE_EXE); // Copy over it with QCACHE.EXE
	anymoved++;
 } // OLDQCACHE_EXE was found

 if (!access (OLDQCACHE_WIN, 0)) {
	backup_file (OLDQCACHE_WIN);	// Save old 386CACHE.WIN
	copy_file (QCACHE_WIN, OLDQCACHE_WIN); // Copy over it with QCACHE.WIN
	anymoved++;
 } // OLDQCACHE_WIN was found

 if (!access (OLDQCACHE ".doc", 0)) {
	backup_file (OLDQCACHE ".doc"); // Get rid of old 386CACHE.DOC
	anymoved++;
 }

 if (Overwrite && !anymoved)
	Backup = FALSE;
#endif // Installing QCACHE

} // move_old_files ()

/* Callback query function for config_parse() */
/* We need to relocate all DEVICE= statements. */
/* We'll parse CONFIG.SYS twice: once to find a preexisting MAX line, */
/* and a second time to relocate all DEVICE= statements if MAX wasn't found */
/* or if MAX was found in an INCLUDE= or COMMON= section. */
/* If we find a STACKS= other than 0 in the common section, we'll need */
/* to relocate it. */
/* If we have any changes for CONFIG.SYS from STRIPMGR /e, this is */
/* the place to apply them. */
int MBCallBack (CONFIGLINE *pcfg)
{
 char buffer[512], *tok1, *tok2;
 char drive[_MAX_DRIVE], dir[_MAX_DIR], name[_MAX_FNAME+_MAX_EXT],
	ext[_MAX_EXT];
 static int MAXFound = 0;
 static int MAXNotInclude = 1;
 int retval = 0;
 int Truth;
 FILEDELTA *pF;
 LINEDELTA *pL;
 char *psz;

 // Copy original CONFIG.SYS line
 strncpy (buffer, pcfg->line, sizeof (buffer)-1);
 buffer[sizeof (buffer)-1] = '\0';
MBC_Restart:
 tok1 = strtok (buffer, ValPathTerms); // Get DEVICE or STACKS token
 tok2 = strtok (NULL, ValPathTerms); // Get first argument
 _splitpath (tok2, drive, dir, name, ext);
 strcat (name, ext);	// 386MAX.SYS or BLUEMAX.SYS
 Truth = (MultiBoot ? 1 : 0);

 if (ParsePass && !pcfg->processed) {

	pF = get_filedelta (con_dpfne);

	if (pL = pF->pLines) {

	  for ( pL = pF->pLines;
			pL && !(psz = strstr (pcfg->line, pL->pszMatch));
			pL = pL->pNext) ;

	  if (pL /* && psz */ ) {

	    retval = Truth;	// Relocate this line
	    pcfg->processed = 1;

	    // The changes we get from STRIPMGR may be limited to
	    // part of the line.  This is not true for CONFIG.SYS,
	    // but we'll play it safe...
	    if (pL->pszReplace) {
		char oldC;

		oldC = *psz;	// Save previous contents
		*psz = '\0';    // Terminate old line
		sprintf (buffer, "%s%s%s", pcfg->line, pL->pszReplace,
			psz + strlen (pL->pszMatch));
		*psz = oldC;	// Restore
		pcfg->newline = str_mem (buffer);
		goto MBC_Restart;

	    } // Perform substitution
	    else {

		if (pcfg->ID == ID_DEVICE && !OldMMLine &&
					stricmp (name, "HIMEM.SYS")) {
			OldMMLine = str_mem (pcfg->line);
		} // Save old memory manager line if not HIMEM.SYS
		pcfg->killit = 1;

	    } // Delete line altogether

	  } // Found a line to change

	} // Found CONFIG.SYS

 } // Check for STRIPMGR changes

 if (!(MAXFound & MAXNotInclude) && pcfg->line && pcfg->ID == ID_DEVICE) {

	if (tok1 && !strnicmp (tok1, "device", 6) && tok2) {

		if (ParsePass) {
		  if (cfg_flag (tok2) != 'd') return (Truth); // Not one we go after
		} // Now we're looking for a place to put MAX

		if (!stricmp (name, OEM_FileName)  ||
		    !stricmp (name, OEM_OldName)) {

			MAXFound = 1;
			if (pcfg->Owner != ActiveOwner) MAXNotInclude = 0;

		} // Found 386MAX.SYS or BlueMAX.sys

	} // Found DEVICE=something
 }
 else if (pcfg->ID == ID_STACKS) {
	if (strcmp (tok2, "0")) return (Truth); // Relocate if not STACKS=0[,0]
 }

 return (retval); // Relocate line if STRIPMGR changes made

} // MBCallBack ()

void parse_config (void)
// Select a MultiBoot section (if necessary) and parse CONFIG.SYS into memory
// Initialize con_dpfne.  We'll set up con_add when we're ready to write,
// since we don't yet know the destination directory.
{
	FILE *config;
	char buff[1024];
	char *tempname;
	char *pbuff;
	CFGTEXT *p, *n;

	if (!RestoreFile) {
	  StartupBat[0] = boot_drive;	// Make sure we have an AUTOEXEC name
	  sprintf (con_dpfne, "%c:\\config.sys", boot_drive);
	} // Not restoring after STRIPMGR /e

	// For our temporary file directory, use a directory we know we can
	// write to.
	sprintf (buff, "%c:\\", boot_drive);
	tempname = tempnam (buff, "MB");
	strcpy (buff, tempname);

	pbuff = buff;
	if (!menu_parse (boot_drive, 0)) {
		if (!RestoreFile)
			MultiBoot = mboot_select (MsgMBMenu, HELP_MBMENU);
		if (MultiBoot) {
		  set_current (MultiBoot);
		  // Parse it to find preexisting MAX line
		  ParsePass=0;
		  config_parse (boot_drive, ActiveOwner, NULL, 0, MBCallBack);
		  ParsePass=1;
		  // Now parse it, relocate DEVICE lines if needed, and
		  // save the parsed file.
		  if (config_parse (boot_drive, ActiveOwner, buff, 0,
			MBCallBack)) error (-1, MsgFileRwErr, con_dpfne);
		  else pbuff = buff+2;
		} // mboot_select() succeeded
		// Find startup batch file for 4DOS / NDOS
		else {
		  ParsePass=1;
		  if (config_parse (boot_drive, '@', buff, 0, MBCallBack))
			strcpy (buff, con_dpfne);
		  else pbuff = buff+2;
		} // Get MAX line and apply STRIPMGR changes to CONFIG.SYS
	} // menu_parse() succeeded
	else strcpy (buff, con_dpfne);

	autox_fnd = !access (StartupBat, 0);
	con_fnd = !access (con_dpfne, 0);

	// Add CONFIG.SYS and AUTOEXEC to the FILEDELTA list now so we can
	// control the order.
	(void) get_filedelta (con_dpfne);
	(void) get_filedelta (StartupBat);

	if (con_fnd) {
	  config = cfopen (buff, "r", 1);
	  p = NULL;			// Previous record
	  while (cfgets (buff, sizeof(buff)-1, config)) {
	    n = get_mem (sizeof (CFGTEXT));
	    if (MultiBoot) {
		n->ltype = buff[0];
		n->Owner = buff[1];
	    }
	    n->text = str_mem (pbuff);
	    n->prev = p;
//	    n->next = NULL;	// In case this is the end of the file...
	    if (p)	p->next = n;
	    else	CfgSys = n;
	    p = n;
	  } // while not EOF
	  fclose (config);

	} // Opened CONFIG.SYS
	else {
	  // Create a CONFIG.SYS with an empty line
	  CfgSys = get_mem (sizeof (CFGTEXT));
	  CfgSys->prev = NULL;
	  CfgSys->next = NULL;
	  CfgSys->text = "";
	} // No CONFIG.SYS - create one

	unlink (tempname);	// May not exist, but no harm done...
	free (tempname);

} // parse_config()

