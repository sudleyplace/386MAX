/*' $Header:   P:/PVCS/MAX/INSTALL/MISC.C_V   1.5   30 Jan 1996 12:30:56   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * MISC.C								      *
 *									      *
 * Miscellaneous INSTALL routines					      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <io.h>
#include <dos.h>
#include <graph.h>
#include <conio.h>
#include <stdarg.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <process.h>
#include <malloc.h>
#include <memory.h>
#include <sys\types.h>
#include <sys\stat.h>

#include "bioscrc.h"
#include "compile.h"
#include "common.h"
#include "commfunc.h"
#include "extn.h"
#include "intmsg.h"
#include "stackdlg.h"
#include "stacker.h"
#include "svga_inf.h"
#include "video.h"

#include "myalloc.h"

#define MISC_C
#include "instext.h"
#undef MISC_C

#ifndef PROTO
#include "misc.pro"
#include "drve.pro"
#include "install.pro"
#include "scrn.pro"
#include "files.pro"
#include "pd_sub.pro"
#endif

int		 config_done = NO;
static char	 mwork2[MAXPATH+1] = { 0 },
		 archive_fname[MAXPATH+1]; // d:\filename.ext,0

/********************************* GET_MEM **********************************/
// Calls my_malloc() for the requested size.  If successful, allocated memory
// is filled with NULL, otherwise call error(-1).
void *get_mem (size_t s)
{
  void *ret;

  if (ret = my_malloc (s))	memset (ret, 0, s);
  else				error (-1, MsgMallocErr, "get_mem");

  return (ret);
} // get_mem ()

/********************************* STR_MEM *********************************/
// Same as strdup(), but quits if no memory
char *str_mem (char *str)
{ return (strcpy (get_mem (strlen (str)+1), str)); }

/********************************* KEYWORD_PART ****************************/
// Returns keyword (DEVICE, INSTALL, SHELL, DOS, etc)
char *keyword_part (CFGTEXT *p)
{
  char buff[512],*tok1;

  strncpy (buff, p->text, sizeof(buff)-1);
  buff[sizeof(buff)-1] = '\0';
  tok1 = strtok (buff, ValPathTerms);

  if (tok1) {
	strcpy (mwork2, tok1);
	return (mwork2);
  } // Line is not blank
  else	return (NULL);

} // keyword_part ()

/********************************* PATH_PART *******************************/
// Returns the path part of a DEVICE, INSTALL, or SHELL= statement
// If it's 386LOAD, skip to the prog= argument.
char *path_part (CFGTEXT *p)
{
  char buff[512], *tok1, *tok2, *postp, *lf;
  char	fndrive[_MAX_DRIVE],
	fndir[_MAX_DIR],
	fname[_MAX_FNAME],
	fext[_MAX_EXT];

  strncpy (buff, p->text, sizeof(buff)-1);
  buff[sizeof(buff)-1] = '\0';
  if (lf = strchr (buff, '\n')) *lf = '\0'; // Clobber trailing LF
  tok1 = strtok (buff, ValPathTerms);
  tok2 = strtok (NULL, ValPathTerms);

  if (	tok1 && tok2 &&
	(!strnicmp (tok1, "device", 6) ||
	 !stricmp (tok1, "install") ||
	 !stricmp (tok1, "shell")               )       ) {
	postp = strstr (p->text, tok2) + strlen (tok2);
	_splitpath (tok2, fndrive, fndir, fname, fext);
	if (!stricmp (OEM_LoadBase, fname)) {
	  // Find the PROG=
	  strncpy (buff, postp, sizeof (buff)-1);
	  buff[sizeof(buff)-1] = '\0';
	  strlwr (buff);
	  if (postp = strstr (buff, "prog=")) {
	    tok2 = postp+5;
	  } // Found PROG= in 386LOAD line
	} // It's 386LOAD
	strcpy (mwork2, tok2);
	return (mwork2);
  } // Device or INSTALL statement
  else	return (NULL);

} // path_part ()

/********************************* FNAME_PART *****************************/
// Returns the file basename.ext part of a DEVICE= or INSTALL= statement
// If it's 386LOAD, skip to the prog= argument.
char *fname_part (CFGTEXT *p)
{
  char	*pathp,
	fndrive[_MAX_DRIVE],
	fname[_MAX_FNAME],
	fext[_MAX_EXT];

  if (pathp = path_part (p)) {
	_splitpath (pathp, fndrive, mwork2, fname, fext);
	sprintf (mwork2, "%s%s", fname, fext);
	return (mwork2);
  }
  else	return (NULL);

} // fname_part ()

/********************************* PRO_PART *******************************/
// Returns the pathname of the pro= file on the command line (if any).
// If none found, returns NULL.
char *pro_part (CFGTEXT *p)
{
  char	buff[512];
  char	*ppro, *newln;

  strncpy (buff, p->text, sizeof(buff)-1);
  buff[sizeof(buff)-1] = '\0';
  strlwr (buff);
  if (ppro = strstr (buff, "pro="))     ppro += 4;
  if (newln = strchr (ppro, '\n'))      *newln = '\0';

  return (ppro);

} // pro_part ()

//******************************** ARCHIVE ***********************************
// Construct an archive filename using the supplied extent number and return
// a pointer to archive_fname[0]
char *archive (int extent)
{
 sprintf (archive_fname, "%s%s.%d", source_subdir, OEM_ProdFile, extent);
 return (archive_fname);
} // archive ()

//******************************** ERROR ***************************************
void	 error ( int err_code, char *fmt, ...)
{
va_list  arg_ptr;
char	 buffer[160] = { 0 };

	 reset_video ();

	 va_start (arg_ptr, fmt);
	 vsprintf ( buffer, fmt, arg_ptr);
	 fprintf(stderr,buffer);
	 restore_path ();

	 exit ( err_code );

} // End ERROR


//*************************  Ensure trailing backslash	************************
void	 do_backslash ( char *temp )
{
int	len;

    len = strlen (temp);
    if (temp[len-1] != '\\') {
	temp[len] = '\\';
	temp[len+1] = 0;
    } // End IF

} // End do_backslash


#if REDUIT
//****************************** CALC_CRCINFO **********************************
void	 calc_crcinfo ( void )
{
	 unsigned long result;

// Set various variables
	 MAXPRES();
// Set bcfsys and mcasys
	 bcfsys = Is_BCF();
	 mcasys = Is_MCA();

// Get BIOS CRC
	 if (!MaxInst && Is_VM ())
		BIOSCRC = GETBCRC();
	 else {
	   result = Get_BIOSCRC ();
	   if (HIWORD(result)) {
		BIOSCRC = LOWORD(result);
	   }
	   else {
		BIOSCRC = 0;
	   }
	 } // We're in real mode or MAX is present

} // End calc_crcinfo
#endif

//***************************** ADJUST_PFNE ************************************
int	 adjust_pfne ( char *pfne, char dfltdrv, WORD Mask )
{
	int	 rc = 0;		// Assume the best

	// Be sure the entry conforms to 'Mask' format
	_splitpath ( pfne, drv_drive, drv_dir, drv_fname, drv_ext );
	if ( *drv_drive == '\0' || (Mask & ADJ_DRIVE)) {
		// We always need a drive
		*drv_drive = dfltdrv;
		drv_drive[1] = ':';
		drv_drive[2] = '\0';
	}

	if ( Mask & ADJ_PATH ) {
		if ( *drv_dir == '\0' ) strcat ( drv_dir, "\\" );
		else if (!strchr ("/\\", *drv_dir)) {
		  char *psz;

		  psz = get_mem (_MAX_PATH+strlen(drv_dir)-2);
		  if (getcwd (psz, _MAX_PATH)) {
		    do_backslash (psz); // Add trailing backslash
		    strcat (psz, drv_dir); // Add relative directory
		    strcpy (drv_dir, psz+2); // ...and copy it back, skipping
					// leading D: from getcwd()
		  }
		  free (psz);

		} // Directory relative to current path
	}

	if ( Mask & ADJ_FNAME ) {
		if ( *drv_fname == '\0' ) rc = 1;  // Non-zero (error)
	}

	sprintf ( pfne, "%s%s%s%s",
		drv_drive, drv_dir, drv_fname, drv_ext );
	return ( rc );

} // End adjust_pfne

//******************************* EXEC_STRIPMGR ********************************
// Chain to STRIPMGR with /E scriptfile.
// Note that we first change to the STRIPMGR drive/directory so
// we don't run out of command line.
// We'll regain control when we're reinvoked with the /Y restorefile option.
WORD	 exec_stripmgr ( char *dir)
{
 WORD	rc;
 char	except[14];		// Space for ~ + max file basename + NULL
 char	*arglst[9];
 int	argidx = 0;		// Index into arglst[] for initialization
 int	i;
 FILE	*script;
/***	Maximum possible contents of arglst:
	"STRIPMGR.EXE", // 0: drive:\path\filename.exe
	"d:",           // 1: drive
	"/E",           // 2: Create script file
	pszStripmgrOut, // 3: "STRIPMGR.OUT"
	"/A",           // 4: /A
	MultiBoot,	// 5: MultiBoot section name
	except, 	// 6: ~*MAX
	mwork2, 	// 7: stripmgr.lst
	NULL		// 8: Terminator
***/

	// Tell the user what's happening
	do_intmsg (MsgRunStripmgr);

	// We've saved the startup drive/directory.  We'll restore
	// it after we return from STRIPMGR.
	chdrive (*dir); 	// Make it the current drive
	if (dir[i=strlen(dir)-1] == '\\') dir[i] = '\0';
	chdir (dir);		// Make it the current directory

	do_backslash (dir);	// Restore the trailing backslash

	arglst[argidx++] = STRIPMGR ".EXE";

	arglst[argidx  ] = "?:";       // d:
	arglst[argidx++][0] = boot_drive;

	arglst[argidx++] = "/E";        // Create script file
	arglst[argidx++] = pszStripmgrOut; // "STRIPMGR.OUT"

	if (MultiBoot) {
		arglst[argidx++] = "/A";
		arglst[argidx++] = MultiBoot;
	} // MultiBoot present

	sprintf (arglst[argidx++] = except, "~%s", OEM_FileName);

	arglst[argidx++] = STRIPMGR ".LST";

	arglst[argidx] = NULL;		// Terminate the list

	// Truncate the script file, and write the recall
	// line to it.
	script = cfopen (pszStripmgrOut, "w", 1);
	cfprintf (script, "%s" OEM_INSTOVL " /Y " DOSNAME ".rcl\n", dir);
	fclose (script);

	// Create the restore file.
	create_restore (dir);

	// Unhook interrupts, but don't touch the screen...
	endHelp ();	// Close INSTALL.HLP
	end_input ();	// Restore Int 9
	done2324 ();	// Restore Ints 23h and 24h
	closehigh ();	// Unlink high DOS

	// If we come back, something's wrong.
	rc = execv (*arglst, arglst);

	// To display our warning, we need to re-initialize the help system
	inst2324 ();
	set_video (FALSE);

	do_error(MsgStripMgrErr,0,FALSE);
	return_to_dos(0);

	return ( rc );

} // End exec_stripmgr

//********************************* SCAN_MDA ***********************************
// Check from B000-B800 in 4KB blocks for RAM.	The original offset is A000.
// (B000 - A000)/4KB == 16, 16 + 32/4 == 24 ==> B800
int scan_mda (void)
{
int	 i;
WORD	 strt_para;
unsigned char far *p;
PROTEXT  *proptr;
char	 buff[256];
char	 *keyword, *arg1, *arg2;
DWORD	 rstart, rend;
int	 starti,endi;

	 if ( ( p = _RAMSCAN () ) != NULL ) {
		// In case MAX is installed but not currently active,
		// get any RAM and USE statements from the profile and
		// mask off the corresponding bytes in p[].
		// This ensures we won't blow away a RAM statement in
		// the monochrome area (e.g. Cabletron NIC) or duplicate
		// existing USE= statements.
		for (i=0; i < sizeof(UseRam)/sizeof(UseRam[0]); i++) {
		  for (proptr = MaxPro; proptr; proptr = proptr->next) {
			if (MultiBoot && proptr->Owner != ActiveOwner &&
						proptr->Owner != CommonOwner)
				continue; // Ignore this line if it's not ours
			strcpy (buff, proptr->text);
			if (keyword = strpbrk (buff, QComments))
				*keyword = '\0';
			keyword = strtok (buff, CfgKeywordSeps);
			arg1 = strtok (NULL, CfgKeywordSeps);
			arg2 = strtok (NULL, CfgKeywordSeps);
			if (keyword && !stricmp (keyword, UseRam[i]) && arg1 &&
				arg2) {
			  sscanf (arg1, "%lx", &rstart);
			  sscanf (arg2, "%lx", &rend);
			  if ((rstart >= 0xB000 || rend > 0xB000) &&
				rend > rstart) {
			    starti = (int) ((max (rstart, 0xB000) - 0xA000) / 0x0100);
			    endi = (int) ((min (rend-1, 0xFFFFL) - 0xA000) / 0x0100);
			    while (starti <= endi) p[starti++] |= 0x01;
			  } // It's a valid range infringing on the MDA
			} // Got a USE or RAM statement
		  } // for all lines in profile
		} // For USE, RAM statements

		 for ( i = 16, strt_para = 0xB000;
		       i < 16 + 32/4;
		       i++, strt_para += 0x0100 )
		 {
			if ( !(p[i] & 0x01 ) ) { // Then we've got a hole
				if ( cnt_mono != 0
				  && mono_mem[cnt_mono - 1].end_blk ==
				     strt_para ) {
					mono_mem[cnt_mono - 1].end_blk += 0x0100;
				} else {
					mono_mem[cnt_mono].strt_blk = strt_para;
					mono_mem[cnt_mono].end_blk = strt_para + 0x0100;
					cnt_mono ++;
				}
			}
		 }
	 }

	 return (cnt_mono);

}//End of scan_mda routine

//********************************* EXEC_MAXIMIZE ******************************
void	 exec_maximize (char *optlist)
// If optlist is specified, build a complete MAXIMIZE /... line
{
 char	mwork1[MAXPATH+1];
 char	*arglst[] = {
	mwork1, 	// 0: drive:\path\filename.exe
	"/d:",          // 1: drive
	"/C",           // 2: color switch (default to color)
	NULL,		// 3: Space for /V or /Z
	NULL,		// 4: Space for /Z or recall string
	NULL,		// 5: Space for recall string
	NULL,		// 6: Space for /Kd
	NULL,		// 7: Space for /A
	NULL,		// 8: MultiBoot section to process
	NULL		// 9: Terminator
	};
int	argptr=3;

// Capture just the startup drive letter in a string
	 arglst[1][1] = boot_drive;

	 if ( ScreenType == SCREEN_MONO )
		strcpy ( arglst[2], "/B" );

	 if (!GraphicsLogo)
		arglst[argptr++] = "/V";

	 if (RecallString) {
		arglst[argptr++] = "/Z";
		arglst[argptr++] = RecallString;
	 } // RecallString not NULL

#ifdef STACKER
	 if (SwappedDrive > 0) {
		arglst[argptr++] = make_stackopts ();
	 } // Drive swapping in effect
#endif // ifdef STACKER

	 if (MultiBoot) {
		arglst[argptr++] = "/A";
		arglst[argptr++] = MultiBoot;
	 } // RecallString not NULL

	 // Setup name of executable to run
	 sprintf (mwork1, "%sMAXIMIZE.EXE", dest_subdir);

	 if (optlist) {
		int i;

		for (i=0; arglst[i]; i++) {
			if (i)	strcat (optlist, " ");
			else	optlist[0] = '\0';
			strcat (optlist, arglst[i]);
		} // for all options
	 }
	 else {

		reset_video ();

		execv ( mwork1, 	// d:\path\filename.ext
			arglst);	// Command list
		error ( -1, MsgMAXExecFail);

	 } // No option list building; execute MAXIMIZE now.

} // End exec_maximize

#if REDUIT
//****************************** PROFILE_ADD ***********************************
void	 profile_add ( void )
{
FILESTRUC temp;
char	 *buffer;

	 buffer = get_mem (MAXPATH+1+strlen(MsgBcfFind));
	 do_backslash ( dest_subdir );
	 sprintf ( buffer, "%sprofile.add", dest_subdir );
	 temp.fname = buffer;

	 if ( -1 != ( temp.fhandle = open (temp.fname,
		O_BINARY|O_WRONLY|O_CREAT|O_TRUNC, S_IREAD | S_IWRITE ) ) ) {
		 if ( bcfsys ) {
			if ( BIOSCRC && !access ( bcf_dpfne, 0 ) ) {
				bcf_fnd = YES;
				sprintf ( buffer, MsgBcfFind,
					OEM_ProdFile, bcf_dpfne,
					OEM_ProdFile);
			} else {
				sprintf ( buffer, MsgNoBcf, BIOSCRC );
			}
		 } else {
			sprintf ( buffer, MsgNoBcfSys );
		 }
		 if ( -1 == ( write ( temp.fhandle, buffer, strlen ( buffer ) ) ) ) {
			error ( -1, MsgFileRwErr, temp.fname );
		 }
		 close ( temp.fhandle );
		 my_free ( buffer );

	 } else {
		 error ( -1, MsgFileRwErr, temp.fname );
	 }
} // End of profile_add
#endif

/******************************** CHECK_SHELL_SUB ***************************/
// Process lines for check_shell()
int	check_shell_sub (CFGTEXT *p)
{
  char	buff[512];
  char	fdrive[_MAX_DRIVE],
	fdir[_MAX_DIR],
	fname[_MAX_FNAME],
	fext[_MAX_EXT];
  char	*keyword,*progname,*preload, *reload;

  if (	!stricmp (keyword_part (p), "shell") &&
	!stricmp (fname_part (p), "command.com")) {

	// Check for COMSPEC reload path specified
	strncpy (buff, p->text, sizeof(buff)-1);
	buff[sizeof(buff)-1] = '\0';
	keyword = strtok (buff, ValPathTerms);
	progname = strtok (NULL, ValPathTerms);

	// To check for a reload path, we need to look at the
	// raw SHELL= line.  strtok() will render expressions like
	//	SHELL=c:\command.com/p
	// meaningless.
	for (	reload = preload = strstr (p->text, progname) +
			strlen (progname);
		reload && strchr (" \t", *reload); reload++) ;

	if (!reload || *reload == '/') {

		char savechar;

		_splitpath (path_part (p), fdrive, fdir, fname, fext);
		savechar = *preload;
		*preload = '\0';
		do_backslash (fdir);
		sprintf (buff, "%s %s%s%c%s", p->text, fdrive, fdir,
			savechar, preload+1);
		my_free (p->text);
		p->text = str_mem (buff);

	} // No COMSPEC reload path specified

  } // Statement is SHELL=COMMAND.COM

  return (0);

} // check_shell_sub ()

//******************************* CHECK_SHELL **********************************
// Make sure that the SHELL statement, if it exists, has a second path
// specified.  I'm not completely sure why we do this, but it may be
// because COMMAND.COM is reloaded more when 386LOAD is running because
// of the filler pattern corrupting the transient portion.  There's
// probably some DOS version out there that doesn't properly reload
// COMMAND.COM unless the reload path is specified...
void	check_shell (void)
{
	(void) walk_cfg (CfgSys, check_shell_sub);
} // End check_shell

/********************* WRITEFILES *****************************************/
// Write the CONFIG.SYS and 386MAX.PRO in memory to CONFIG.ADD and 386MAX.ADD
// Free the lists as we go so we'll have some room for the browser.
void writefiles (void)
{
  FILE	*f;
  CFGTEXT *p, *pn;
  PROTEXT *m, *mn;
  FILEDELTA *pF;

  pF = get_filedelta (con_dpfne);
  (void) get_outname (pF);	// Force creation of .ADD and backup names
  f = cfopen (pF->pszOutput, "w", 1);
  for (p = CfgSys; p; p = pn) {
	  cfputs (p->text, f);
	  pn = p->next;
	  free (p->text);
	  free (p);
  } // for all lines in CONFIG.SYS
  fclose (f);

  pF = get_filedelta (pro_dpfne);
  (void) get_outname (pF);
  f = cfopen (pF->pszOutput, "w", 1);
  for (m = MaxPro; m; m = mn) {
	  cfputs (m->text, f);
	  mn = m->next;
	  free (m->text);
//	  free (m->keyword); // Doesn't get allocated?
	  free (m);
  } // for all lines in MAX.PRO
  fclose (f);

  // As long as we're freeing things up, let's lose INSTALL.CFG

} // writecfg ()

/********************* WARN_B8 () ***************************************/
// Return a value based on potential problems with recovering MDA buffer
// area.  Return values are defined as bits in common.h (VW_*)
// Calls to SVGA_VENDOR(), SVGA_MODEL(), and SVGA_MEMSIZE() must be
// made IN THAT ORDER until I can change the interface. -HG
unsigned int warn_b8 ( void )
{
 unsigned int rval = 0;
 int svendor, smodel;

 svendor = SVGA_VENDOR ();
 smodel = SVGA_MODEL ();
 if ((VGAMEM = SVGA_MEMSIZE ()) > 256 || svendor == STB || svendor == VESA) {

  switch (svendor) {

	case ATI:
		rval |= VW_NOSWAP;	// OK to recover MDA, but VGASWAP
		break;			// doesn't work with MACH32

	case TRIDENT:
		if (smodel == TRIDENT_8800)
		 rval |= VW_UNSAFE;	// Uses 128K segments by default
		else
		 rval |= VW_RISKY;
		break;

	case PARADISE:
	case GENOA:
		rval |= VW_RISKY;
		break;

	case STB:
		if (smodel == STB_ET4000 || smodel == STB_S3) {
			rval |= VW_UNSAFE;
		} else {
			rval |= VW_RISKY;
		}
		break;

	case VESA:
		if (smodel == VESA_128) rval |= VW_RISKY;
		// else fall through

	case VIDEO7:	// Fully bank switched
	case TSENG:	// Capable of linear addressing only in protected mode
	case CHIPS:	// Fully bank switched
	case AHEAD:	// Paged mode only
	case ORCHID:
	case CIRRUS:
	case DIAMOND:
	default:
		/* rval |= 0 */ ;

  } // switch (SVGA_VENDOR ()) ...

 } // > 256K

 return (rval);

} // warn_b8 ()

/************************** READ_DOSHELP *************************************/
// Read DOSHELP.ADD from the MAX/Move'EM directory.
// Parse lines and allocate DosHelpText.
// Return number of HELP ITEMS read (not lines - some items have >1 lines)
int read_doshelp (void)
{
 char buff[256],buff2[256];
 FILE *helpadd;
 unsigned int i,blen,b2len,linecount;

 sprintf (buff, "%sDOSHELP.ADD", dest_subdir);
 if ((helpadd = cfopen (buff, "r", 0)) == NULL)
	return (0);

 // First, count all the lines that don't begin with ' ', '\t' or '@'.
 for (linecount = 0; cfgets (buff, sizeof (buff)-1, helpadd) != NULL; )
  if (*buff && strchr (" \t@", *buff) == NULL)
	linecount++;

 if (!linecount ||
     (DosHelpText = (char **) malloc (sizeof (char *) * linecount)) == NULL) {
	fclose (helpadd);
	return (linecount);
 } // linecount == 0

 // Go back to the beginning and read them in for real.
 fseek (helpadd, 0L, SEEK_SET);
 memset (*DosHelpText, linecount * sizeof (char *), 0);

 i = b2len = 0;
 while (cfgets (buff, sizeof(buff)-1, helpadd)) {

	if (!strchr ("@\n", buff[0])) {

	 blen = strlen (buff);

	 if (strchr (" \t", buff[0])) { // Add to previous
	  // Ensure we don't overrun buff2
	  blen = min (sizeof (buff2) - 1 - b2len, blen);
	  strncat (buff2, buff, blen);
	  // If truncated, ensure it has an end
	  buff2 [blen + b2len] = '\0';
	  b2len = strlen (buff2);	// Save length
	 } // Concatenate

	 else { 			// New item
	  if (b2len) {
		DosHelpText [i++] = str_mem (buff2);
		buff2 [0] = '\0';
	  }
	  b2len = strlen (strcpy (buff2, buff));
	  if (i >= linecount)
		break;
	 } // New item

	} // Ignore comments and blank lines

 } // !EOF

 if (b2len)
	DosHelpText [i++] = str_mem (buff2);

 fclose (helpadd);

 return (linecount);

} // read_doshelp ()

#ifdef STACKER
/************************** CHECK_ALTSUB *************************************/
// Called by check_altpath ().	If docopy, copy specified source file to
// identical path/filename on altdrive if the time/date is different.
// If missing is TRUE, copy even if destination file does not exist.
// Return the rounded up size of the destination file.
DWORD check_altsub (char *src, char altdrive, BOOL missing, BOOL docopy)
{
 char dest[MAXPATH+1];
 int srcH,destH;
 unsigned int srcT, srcD, destT, destD;
 DWORD fsize = 0L;

 strcpy (dest, src);
 dest[0] = altdrive;

 srcH = open (src, O_RDONLY);
 destH = open (dest, O_RDONLY);

 if (srcH != -1) {
	_dos_getftime (srcH, &srcD, &srcT);
	close (srcH);
 }

 if (destH != -1) {
	_dos_getftime (destH, &destD, &destT);
	fsize = lseek (destH, 0L, SEEK_END); // Get file size in bytes
	fsize = (fsize + 4096L-1) & ~(4096L-1); // Round up in blocking units
	close (destH);
 }
 else if (!missing) return (0L);
 if (srcH == -1 && docopy) return (0L); // Nothing to copy

 if ((destH == -1 || srcT != destT || srcD != destD) && docopy) {
	(void) copy (src, dest);
 }

 return (fsize);

} // check_altsub ()
#endif // ifdef STACKER

#ifdef STACKER
/**************************** CHECK_ALTFILES ********************************/
// Check specified file(s) and copy from dest_subdir to AltDir on drive altdrive
// Return total space occupied on destination.
DWORD check_altfiles (char *fmt, char *arg1, char *arg2,
			char altdrive, int attr, BOOL docopy)
{
 char temp[MAXPATH+1];
 struct find_t find_str;
 DWORD fsize = 0L;

 sprintf (temp, fmt, arg1, arg2);

 if (!_dos_findfirst (temp, attr, &find_str)) {

	do {
		if (!stricmp (find_str.name, DOSNAME ".hlp")) continue;
		sprintf (temp, "%s%s", dest_subdir, find_str.name);
		fsize += check_altsub (temp, altdrive, attr&_A_RDONLY, docopy);
	} while (!_dos_findnext (&find_str));

 } // Found file(s)

 return (fsize);

} // check_altfiles ()
#endif // ifdef STACKER

#ifdef STACKER
/*************************** CHECK_ALTPATH ************************************/
// Check AltPath (if SwappedDrive) for any files to be copied over in a split
// installation.  Source of copy is dest_subdir for all except CONFIG.SYS,
// AUTOEXEC.BAT, and 386MAX.PRO, which are copied to the corresponding path
// on the AltPath drive.
// Files are:
// CONFIG.SYS
// AUTOEXEC.BAT
// 386MAX.PRO
// dest_subdir\386MAX.SYS
// dest_subdir\XLAT.COM
// dest_subdir\@xxxx.BCF
// dest_subdir\386MAX.VXD
// dest_subdir\386LOAD.SYS
// dest_subdir\386LOAD.CFG
// dest_subdir\QCACHE.WIN
// dest_subdir\EXTRADOS.MAX
// dest_subdir\*.PRO
// dest_subdir\*.LOD
// Any other files existing in AltPath with a different time/date stamp
DWORD CopyMax2Size;
DWORD check_altpath (BOOL docopy)
{
 char	*Altfmt1 = "%s%s";
#if REDUIT
 char	bcftext[5];
#endif
 char	fdrive[_MAX_DRIVE],
	fdir[_MAX_DIR],
	fname[_MAX_FNAME],
	fext[_MAX_EXT];
 char *Altfmts[][2] = {
	{Altfmt1, OEM_FileName},	// 386max.sys
	{Altfmt1, MAX_XLAT},		// XLAT.COM
#if REDUIT
	{"%s@%s.BCF", bcftext},         // @xxxx.BCF
#endif
	{"%s%s.VXD", OEM_ProdFile},     // 386MAX.VXD
	{"%s%s.SYS", OEM_LoadBase},     // 386LOAD.SYS
	{"%s%s.CFG", OEM_LoadBase},     // 386LOAD.CFG
	{Altfmt1, QCACHE_WIN},		// QCACHE.WIN
	{"%s%s", MAX_HARPO_EXE},        // EXTRADOS.MAX
	{"%s%s.PRO", "*"},              // *.PRO (386SWAT, EXTRADOS)
	{"%s%s.LOD", "*"},              // *.LOD
	{NULL, NULL}
 };

 int i;
 DWORD fsize = 0L;

 CopyMax2Size = 0L;

 if (SwappedDrive < 1)	return (fsize);

 // Ensure that directory exists.  set_maxdir() will do this recursively.
 *AltDir = CopyMax1;
 if (docopy) {
	(void) set_maxdir (AltDir);
	if (CopyMax2) {
	  *AltDir = CopyMax2;
	  (void) set_maxdir (AltDir);
	} // Other alternate drive exists
 } // We're copying files

 do_backslash (AltDir);

 // Handle special cases first
 if (*con_dpfne && CopyBoot) {
	fsize += check_altsub (con_dpfne, CopyBoot, TRUE, docopy);
 } // Update CONFIG.SYS

 if (*pro_dpfne && CopyMax1) {
	fsize += check_altsub (pro_dpfne, CopyMax1, TRUE, docopy);
 } // Update MAX profile

 if (*StartupBat && CopyBoot) {
	// Only copy startup batch file if it's in the root directory
	_splitpath (StartupBat, fdrive, fdir, fname, fext);
	if (!strcmp (fdir, "\\")) fsize += check_altsub (StartupBat, CopyBoot, TRUE, docopy);
 } // Update AUTOEXEC.BAT

#if REDUIT
 sprintf (bcftext, "%04x", BIOSCRC);    // Convert CRC to string
#endif

 for (i=0; Altfmts[i][0]; i++) {

	fsize += check_altfiles (Altfmts[i][0], dest_subdir, Altfmts[i][1], CopyMax1,
		_A_ARCH|_A_RDONLY, docopy);

	if (CopyMax2) {
		CopyMax2Size += check_altfiles (Altfmts[i][0], dest_subdir,
			Altfmts[i][1], CopyMax2, _A_ARCH|_A_RDONLY, docopy);
	}

 } // for ();

 // Now check all programs found in AltDir.  We won't try to
 // overwrite anything that's read-only.  Note that we won't add
 // these to our count of existing files; these have already been
 // counted, or have nothing to do with the basic files that need
 // to be there.
 *AltDir = CopyMax1;
 (void) check_altfiles ("%s%s", AltDir, "*.*", *AltDir, _A_NORMAL, docopy);

 if (CopyMax2) {
	*AltDir = CopyMax2;
	(void) check_altfiles ("%s%s", AltDir, "*.*", *AltDir, _A_NORMAL, docopy);
 }

 return (fsize);

} // check_altpath ()
#endif // ifdef STACKER
