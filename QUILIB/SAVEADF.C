/*' $Header:   P:/PVCS/MAX/QUILIB/SAVEADF.C_V   1.1   13 Oct 1995 12:13:14   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SAVEADF.C								      *
 *									      *
 * Functions to save a copy of .ADF files				      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <direct.h>
#include <dos.h>
#include <io.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>

#include "commfunc.h"
#include "libtext.h"
#include "myalloc.h"
#include "saveadf.h"
#define STACKER 	// This should go in LIBTEXT.H
#ifdef STACKER
#include "stacker.h"
#endif

#define ADFDIR	      "ADF"
#define ADFSIGFILE    "ADFSIG.DAT"
#define ADFSIGVERSION 0x701

/* Local variables */
static char *whatfiles[] = {	"@%04X.ADF",    /* ADF text (adapter) */
				"C%04X.ADF",    /* ADP binary (adapter) */
				"D%04X.ADF",    /* ADF text (planar RAM) */
				"P%04X.ADF",    /* ADF text (system board) */
				"S%04X.ADF"     /* ADP binary (system board) */
						};
static char *abiosfiles[] = {	"ABIOS.SYS",    /* Contains image filename */
				"*.BIO"         /* ABIOS image file */
//				"IBMBIO.COM",   /* OS files for boot disk */
//				"IBMDOS.COM",
//				"IO.SYS",
//				"MSDOS.SYS"
						};

/* Local Functions */
static void get_adf_signature(ADFSIG *info);
static BOOL compare_adf_signature(void);
static void save_adf_signature(void);

/*
 *	adf_dir - Get or set directory for .ADF files
 *
 *	Return pointer to static ADF directory path.
 *	If path is specified, use it to construct a path
 *	for all subsequent requests for ADF directory.
 *	If path is NULL, construct path using get_exepath ()
 */
char *adf_dir(			/* Get/set ADF directory */
	char *path)		/* Path to use or NULL */
{
	static char *prev_adf_dir = NULL;
	static char dirname[MAXFILELENGTH];
	int len;

	if (path) {		/* Path was specified */

	  strcpy (dirname, path);
	  prev_adf_dir = dirname;

	}

	if (prev_adf_dir) {
		return (prev_adf_dir);
	}

	/* Allow space for directory and filename with \ and \0 */
	get_exepath (dirname, sizeof(dirname)-(12+1+12+1));

	len = strlen (dirname);

	/* Ensure directory name ends with \ */
	if (!strchr ("/\\", dirname [len-1])) {
		strcat (dirname, "\\");
	}

	/* Add ADF\ to directory name */
	strcat (dirname, ADFDIR "\\");

	return (prev_adf_dir = dirname);

} /* adf_dir () */

/*
 *	check_adf_files - Check for valid .ADF files
 *
 *	Returns TRUE if .ADF files are in sync with hardware.
 */

BOOL check_adf_files(		/* Check for valid .ADF files */
	char *path,		/* ADF path filled in */
	int npath)		/* Max chars in path */
{
	strncpy (path, adf_dir (NULL), npath);
	path [npath-1] = '\0';  /* Truncate if necessary */

	return (compare_adf_signature());
}

///***
// *	get_bootsect - Read boot sector from floppy
// *
// *	Returns 0 if successful, or error code.
//***/
//
//#pragma optimize("leg", off)
//int _loadds get_bootsect (int drivenum, char *buff)
//{
//  _asm {
//	mov	ax,0x0201;	/* Read 1 sector */
//	mov	cx,0x0001;	/* Head 0, sector 1 */
//	mov	dx,drivenum;	/* Drive number in DL */
//	mov	dh,0;		/* Track 0 */
//	les	bx,buff;	/* Address buffer */
//	int	0x13;		/* CF=1 if failure, error code in AL */
//	mov	ah,0;		/* Clear high byte of result */
//	jc	gb_exit;	/* Jump if failure */
//
//	sub	ax,ax;		/* Indicate success */
//gb_exit:
//  }
//
//} /* get_bootsect() */
//#pragma optimize("", on)

/*
 *	save_adf_files - Make copies of .ADF files, etc.
 *
 *	Returns TRUE if successful.
 */

BOOL save_adf_files(		/* Save (copy) .ADF files */
	char *src,		/* Source path, usually "A:" */
	char *dst)		/* Destination path, usually "C:\386MAX\ADF" */
{
	int kk;
	int count,scount;
	int nsrc;
	int ndst;
	char srcpath[MAXFILELENGTH];
	char dstpath[MAXFILELENGTH];
	MCAID slots[MCASLOTS];
	int slotnum;
	struct find_t find;
//	char bootsect[512];
#ifdef STACKER
	char altdstpath[MAXFILELENGTH];
#endif

	/* Set up source and dest pathspecs */
	strcpy(srcpath,src);
	nsrc = strlen(srcpath);
	if (nsrc > 0 && srcpath[nsrc-1] != '\\') {
		srcpath[nsrc++] = '\\';
		srcpath[nsrc] = '\0';
	}

	/* Make sure they put a disk in the drive and it's really */
	/* an ADF disk */
	sprintf (srcpath+nsrc, "*.ADF");
	if (_dos_findfirst (srcpath, _A_ARCH|_A_RDONLY, &find)) goto BAD_ADF_DISK;

	strcpy(dstpath,dst);
	ndst = strlen(dstpath);
	if (ndst > 0 && dstpath[ndst-1] == '\\') {
		dstpath[--ndst] = '\0';
	}

	_mkdir(dstpath);
#ifdef STACKER
	strcpy (altdstpath, dstpath);
	if (SwappedDrive > 0) {
	    *altdstpath = MaxConfig;
	    if (MaxConfig && _stricmp (altdstpath, dstpath)) _mkdir(altdstpath);
	    else if ((*altdstpath = ActualBoot) && _stricmp (altdstpath, dstpath)) _mkdir (altdstpath);
	} /* Create directory on swapped drive also */
	else *altdstpath = '\0';
#endif /* ifdef STACKER */
	dstpath[ndst++] = '\\';
	dstpath[ndst] = '\0';

	/* Copy ABIOS.SYS and any *.BIO ABIOS image files */
	/* We need to copy 'em to the alternate CONFIG.SYS drive as well */
	for (kk = 0; kk < LENGTHOF(abiosfiles); kk++) {

	    sprintf (srcpath+nsrc, abiosfiles[kk]);

	    if (!_dos_findfirst (srcpath, _A_ARCH|_A_RDONLY, &find)) {

		do {

		    strcpy (srcpath+nsrc, find.name);
		    strcpy (dstpath+ndst, find.name);
		    count++;

		    if (truename_cmp (srcpath,dstpath) && /* Not the same */
				!copy(srcpath,dstpath)) {
				/* Copy error of some sort */
			return FALSE;
		    }
#ifdef STACKER
		    if (*altdstpath) {
			strcpy (altdstpath+1, dstpath+1);
			/* Rather than copy from the floppy twice, use the */
			/* copy we just made on (supposedly) the hard disk */
			if (truename_cmp (dstpath, altdstpath) && /* Not the same */
			    !copy (dstpath, altdstpath)) {
				/* Copy error */
				return (FALSE);
			} /* Copy to swapped drive failed */
		    } /* Copy to swapped drive also */
#endif /* ifdef STACKER */

		} while (!_dos_findnext (&find));

	    } /* Found ABIOS image files */

	} /* Copy ABIOS image files */

//	/* Get boot sector and save it away only if ref disk is in drive A */
//	*src = toupper (*src);
//	if (*src == 'A' && !get_bootsect (0, bootsect)) {
//	  int fh;
//
//	  strcpy (dstpath+ndst, "REFBOOT.IMG");
//	  if ((fh = _open (dstpath, O_BINARY|O_RDWR|O_CREAT, S_IWRITE)) != -1) {
//		_write (fh, bootsect, 512);
//		_close (fh);
//	  }
//	}

	/* Get list of adapter and system board ID's */
	mca_pos (slots);

	count = scount = 0;
	for (kk = 0; kk < LENGTHOF(whatfiles); kk++) {

	    for (slotnum = 0; slotnum < MCASLOTS; slotnum++)
	      if (slots[slotnum].aid != 0xffff) {

		sprintf (srcpath+nsrc, whatfiles[kk], slots[slotnum].aid);
		sprintf (dstpath+ndst, whatfiles[kk], slots[slotnum].aid);

		if (slotnum) {
			/* Currently, we only care about adapters other than */
			/* the motherboard... */
			scount++;
		}

		if (!_access (srcpath, 0)) {	/* File exists */

			count++;

			if (truename_cmp (srcpath,dstpath) && /* Not the same */
					!copy(srcpath,dstpath)) {
				/* Copy error of some sort */
				return FALSE;
			}

		} /* File exists */

	    } /* for (slotnum;;) */

	} /* for (kk;;) */

	if (scount && !count) {
BAD_ADF_DISK:
		/* Adapter(s) are present and no .ADF files found. */
		errorMessage(233);
		return FALSE;
	} /* No files found */

	save_adf_signature();

	return TRUE;
}

/*
 *	get_adf_signature - Get signature for adf files.
 *
 *	The signature consists of:
 *
 *	1)  A two byte version number (currently 0x602)
 *	2)  A word of flags indicating whether CMOS POS data is valid.
 *	3)  The current adapter POS data, MCASLOTS*sizeof(MCAID) bytes.
 *	4)  The CMOS POS data, MCASLOTS*sizeof(CMOSPOS) bytes.
 *
 *	Note that MCASLOTS is defined in mca_pos.h as 8+1
 *	to accomodate system board POS info.
 *
 *	Note also that we ignore the subaddress value, as this
 *	is meaningless on most adapters and may change randomly
 *	as a result of our putting the adapter into and out of
 *	setup mode.
 *
 *	All of this is written to a binary file, ADFSIG.DAT.
 */

static void get_adf_signature(ADFSIG *info)
{
	int i;

	memset(info,0,sizeof(ADFSIG));

	info->version = ADFSIGVERSION;
	mca_pos(info->apos);
	info->cmos_valid = Get_CMOS_POS(info->cpos);

	/* Rather than comparing all but the subaddress, we ensure */
	/* the subaddress is always constant before saving the file */
	for (i = 0; i < MCASLOTS; i++) {
		info->apos[i].suba = 0xffff;
	}

	info->apos[0].pos[0] = 0xFF;
	info->apos[0].pos[1] = 0xFF;
	info->apos[0].pos[2] = 0xFF;
	info->apos[0].pos[3] = 0xFF;

}

/*
 *	compare_adf_signature - Compare ADF signature with previous version.
 *
 *	Return:  TRUE if no change.
 */

static BOOL compare_adf_signature(void)
{
	FILE *fp;
	BOOL rtn = FALSE;
	ADFSIG info1;
	ADFSIG info2;
	char filename[MAXFILELENGTH];

	get_adf_signature(&info1);

	memset(&info2,0,sizeof(ADFSIG));

	sprintf(filename, "%s%s", adf_dir (NULL), ADFSIGFILE);

	fp = fopen(filename,"r");
	if (fp) {
		if (fread(&info2,sizeof(ADFSIG),1,fp) != 1) {
			goto error;
		}
		fclose(fp);
		rtn = (info1.version != info2.version) ? FALSE :
		      (memcmp(&info1,&info2,
			(info1.cmos_valid && info2.cmos_valid) ||
			(info1.version < 0x602) ?
				ADFSIG_CLEN : ADFSIG_XCLEN) == 0);

	}

error:
	return rtn;
}

/*
 *	save_adf_signature - Save ADF signature to a file.
 */

static void save_adf_signature(void)
{
	FILE *fp;
	ADFSIG info;
	char filename[MAXFILELENGTH];

	get_adf_signature(&info);

	sprintf(filename, "%s%s", adf_dir (NULL), ADFSIGFILE);

	fp = fopen(filename,"w");
	if (fp) {
		fwrite(&info,sizeof(ADFSIG),1,fp);
		fclose(fp);
	}
	else {
		/* Unable to create file */
		errorMessage(560);
	}
}
