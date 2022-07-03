/*' $Header:   P:/PVCS/MAX/INSTALL/FILES.C_V   1.1   25 Oct 1995 18:50:04   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * FILES.C								      *
 *									      *
 * File I/O routines for INSTALL.EXE					      *
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
#include <malloc.h>
#include <sys\types.h>
#include <sys\stat.h>

#include "commfunc.h"
#include "common.h"
#include "compile.h"
#include "dcache.h"
#include "extn.h"
#include "extsize.h"
#include "intmsg.h"
#include "myalloc.h"
#ifdef STACKER
#include "stacker.h"
#endif

#define FILES_C
#include "instext.h"    /* Message text */
#undef FILES_C

#ifndef PROTO
#include "files.pro"
#include "drve.pro"
#include "install.pro"
#include "misc.pro"
#include "scrn.pro"
#include "security.pro"
#include "serialno.pro"
#include "pd_sub.pro"
#endif

// Singly linked list for reading INSTALL.CFG into memory
typedef struct cfg_struct {
 char flag;		// Flags: 'd' if it should be before MAX,
			// 'p' if partition driver (before MAX IF
			// we install MAX on a drive other than boot).
			// 'm' if EMS 4.0 driver needed before Move'em.mgr
			// 'x' if XMS driver which should go before move'em
 char name[9];		// Basename part of file (w/o extension)
 char ext[5];		// File extension ('.' included)
 struct cfg_struct *next; // pointer to next or NULL if end
} CFG, *CFGp;

CFGp	cfg;			// Head of INSTALL.CFG list

static char
	 *probuf,		// QCACHE command line
	 cfname[21],
	 wrkdrive[_MAX_DRIVE],
	 wrkdir[_MAX_DIR],
	 wrkname[_MAX_FNAME],
	 wrkext[_MAX_EXT],
	 *pszBuff,
	 *cfopen_path;
#define  BUFFSIZE	512

static char *copyfmt = "copy %s %s\n";
CFGTEXT *MAXLine, *InsertLine, *LastLine, *BuffersLine;
char *StacksLine = NULL;
int BatlineTarget; /* 1 for QCACHE, 2 for QMT, 3 for QUTIL.BAT */
int currentdrive; /* Index of current drive/dir prefix in currentdir[] */
char *currentdir[26]; /* Current drive/directory prefixes for all drives */
int ForceReturn; /* Special flag for process_stream: return immediately */
int InSection = 0; /* Flag for place_qutil: we've found our target section */
/* Note that InSection is always re-initialized to 0 each time qutil.bat */
/* is processed (potentially, 2 times). */

FILEDELTA *pQutil = NULL; /* Set by find_batline (QUTIL) */
#define DEFMAXRECURSION 7	/* Max. levels of recursion for batch files */
char *prevlevels[DEFMAXRECURSION];  /* Previously processed files */
int MaxRecursion = DEFMAXRECURSION; /* May be reduced depending on file */
				/* handles available. */

/************************** INIT_FSTAT **************************/
// Initialize static storage for FILES.C
void init_fstat (void)
{
	probuf = get_mem (256);
	pszBuff = get_mem (BUFFSIZE);
	cfopen_path = get_mem (MAXPATH+1);
} // End init_fstat ()

/***************************** CFOPEN **************************************/
// Replacement for fopen().  Saves filename used in open for error messages.
// While this may not always be accurate (as when two files are open), it
// at least gives us a hint where the error took place.
FILE *cfopen (char *filename, char *mode, int abort)
{
  FILE *ret;

  strcpy (cfopen_path, filename);
  ret = fopen (filename, mode);
  if (!ret && abort)	error (-1, MsgFileOpenErr, filename);

  return (ret);

} // cfopen ()

/***************************** CFPRINTF ************************************/
// Replacement for fprintf().  Checks the result; if it's -1, bomb out with
// an error message.
void cfprintf (FILE *fp, char *fmt, ...)
{
  va_list arg_ptr;

  va_start (arg_ptr, fmt);
  if (vfprintf (fp, fmt, arg_ptr) == -1) error (-1, MsgFileRwErr, cfopen_path);

} // cfprintf ()

/****************************** CFGETS ************************************/
// Replacement for fgets().  Checks for error on file stream, since fgets()
// returns NULL when either an error or EOF occurs.  Usually it'll be an
// EOF, but we'll bomb out if an error occurs.  Note that buffsize should
// be sizeof(buff)-1.
char *cfgets (char *buff, size_t buffsize, FILE *fp)
{
  char *ret;

  ret = fgets (buff, buffsize, fp);
  if (ret) {
	buff[buffsize] = '\0';  // Make sure it's NULL-terminated
  } // Read OK
  else {
	if (ferror (fp))	error (-1, MsgFileRwErr, cfopen_path);
  } // Read failed - check for error or EOF

  return (ret);

} // cfgets ()

/****************************** CFPUTS ***********************************/
// Replacement for fputs().  Abort with error message if write failure.
void cfputs (char *buff, FILE *fp)
{
  if (fputs (buff, fp)) 	error (-1, MsgFileRwErr, cfopen_path);
} // cfputs ()

//**************************** READ_CFG *************************************
// Read INSTALL.CFG and set up linked list cfg.
// If fromexe, we look for INSTALL.CFG in the directory INSTALL.EXE
// was started from.  This allows a customized INSTALL.CFG to be placed
// on the distribution floppy or a network directory.
void read_cfg (BOOL fromexe)
{
 FILE *cfgfile;
 char *semicol,*warg1,*warg2;
 CFGp wcfg, pcfg;

 if (fromexe) {
	get_exepath (pszBuff, BUFFSIZE - 1);
 }
 else {
	strcpy (pszBuff, dest_subdir);
 }
 cfg = pcfg = wcfg = NULL;		// Initialize head to NULL
 strcat (pszBuff, INSTALL_CFG);

 if (!(cfgfile = fopen (pszBuff, "r")))        return;

 while (fgets (pszBuff, MAXPATH, cfgfile) != NULL) {

  if ((semicol = strpbrk (pszBuff, QComments)) != NULL)
	*semicol = '\0';        // Kill all semicolons on sight

  warg1 = strtok (pszBuff, CfgKeywordSeps);  // Get keyword or flag
  warg2 = strtok (NULL, CfgKeywordSeps);    // Get argument or filename.ext

  if (!stricmp (warg1, "SNOWCONTROL")) {
	SnowControl = TRUE;
  }
  else if (!stricmp (warg1, "NOLOGO")) {
	GraphicsLogo = 0;
  }
  else if (!stricmp (warg1, "BOOTDRIVE")) {
	if (warg2) boot_drive = *warg2;
  }
  else if (!stricmp (warg1, "USECOLOR")) {
	if (warg2 && !ScreenSet) {
		ScreenSet = TRUE;
		ScreenType = (strchr ("yYtT1", *warg2) ||
			!stricmp (warg2, "ON")) ? SCREEN_COLOR : SCREEN_MONO;
	} /* USECOLOR=x specified */
  }
  else if (warg1 && warg2) {

	_splitpath (warg2, wrkdrive, wrkdir, wrkname, wrkext);

	wcfg = (CFGp) get_mem (sizeof (CFG));

	if (pcfg == NULL)
	 cfg = pcfg = wcfg;	// Initialize head of list
	else
	 pcfg->next = wcfg;	// Link with previous entry

	wcfg->flag = (char) tolower (*warg1);	// Store flag
	strcpy (wcfg->name, wrkname);	// Get basename
	strcpy (wcfg->ext,  wrkext);	// Get extension
	wcfg->next = NULL;		// Mark as end of list
	pcfg = wcfg;			// Keep track of previous entry

  } // fields were not empty

 } // while not EOF

 fclose (cfgfile);

} // read_cfg ()

//**************************** CFG_FLAG ****************************************
// Takes a pathname, gets the basename and extension, and looks for matching
// entries in INSTALL.CFG list.  If found, the flag of the first matching
// entry is returned, otherwise 0 is returned.
char cfg_flag (char *pathname)
{
 CFGp wcfg;
 char retval;

 // Get basename and ext components for search
 _splitpath (pathname, wrkdrive, wrkdir, wrkname, wrkext);

 // Go through the list till end or we get a hit
 for (	wcfg = cfg, retval = 0;
	wcfg != NULL && !retval;
	wcfg = wcfg->next ) {

  if (!strcmpi (wrkname, wcfg->name) && !strcmpi (wrkext, wcfg->ext))
	retval = wcfg->flag;

 } // for ()

 return (retval);

} // cfg_flag()

/**************************** ADD2MAXPRO ************************************/
// Add specified line to 386MAX.PRO structure in memory
// If NewOwner is not specified, set the Owner field to the
// last owner parsed from a section header and append line to
// the end of the file.
// If NewOwner is specified, set Owner to NewOwner, find the
// last line in a section owned by NewOwner and insert the
// new line there.  If there are no sections owned by NewOwner,
// create one.
void add2maxpro (BYTE NewOwner, char *line, ...)
{
  va_list arg_ptr;
  PROTEXT *p, *pn, *n, *n2;
  char buff[256],tokn1[128];
  char *sectname;
  int is_header = 0;
  static BYTE LastOwner = 0; // None parsed yet
  SECTNAME *SRec;

  // Make sure we have a valid default for the start of the profile
  if (!LastOwner) LastOwner = CommonOwner;

  va_start (arg_ptr, line);
  vsprintf (buff, line, arg_ptr);
//  if (MultiBoot) {	// Check for headers in profile even if no MenuItems
	sscanf (buff, "%80s", tokn1);
	if (tokn1[0] == '[' && (sectname = strtok (tokn1, "[]"))) {
	  is_header = 1;
	  if (SRec = find_sect (sectname)) {
	    LastOwner = SRec->OwnerID;
	  } // Found section in CONFIG.SYS
	  else LastOwner = 0xff; // It's a bogus section name with a bogus owner
	} // Line is a valid section header
//  } // MultiBoot is in effect; check for a section header

  // Find a home for the new line.  If a section was specified,
  // find the last non-blank line of the first block owned by the section
  // specified.  If not found and line is not a section header,
  // append a section header and the line specified to the end
  // of the file.
  for ( p = NULL, pn = MaxPro;
	pn && pn->next && (// !MultiBoot || //
			!NewOwner || // No section specified,
			pn->Owner != NewOwner || // not in the section,
			pn->next->Owner == NewOwner); // or not the end of it.
							) {
    pn = pn->next;
    if (pn->text && pn->text[0] && pn->text[0] != '\n') p = pn;
  } // for all lines

  n = get_mem (sizeof (PROTEXT));
  n->text = str_mem (buff);

  // Save a pointer to the last line we're adding
  n2 = n;

  if (NewOwner) {

	n->Owner = NewOwner;

	// If we're starting from scratch, we'll put in an explicit
	// [common] at the top if NewOwner == CommonOwner.
	if (//	MultiBoot && // May have sections even if not MultiConfig
		!is_header &&
		(!pn || pn->Owner != NewOwner) &&
		(SRec = find_ownsect (NewOwner))	) {

	  // If the section exists, the line we're adding
	  // isn't a header, and we didn't find the section,
	  // create one.
	  sprintf (buff, "\n[%s]\n", SRec->name);
	  n = get_mem (sizeof (PROTEXT));
	  n->text = str_mem (buff);
	  n->Owner = NewOwner;
	  n->next = n2;
	  n2->prev = n;
	  p = pn;

	} // No matching section found; add to end of file

  } // NewOwner specified
  else {
	n->Owner = LastOwner;
	p = pn;
  } // If we're adding sequentially, always use the last one

  // If we didn't find a non-blank line, use the EOF
  if (!p) p = pn;

  if (p) n2->next = p->next;
// else n2->next = NULL; // Initialized by get_mem()

  n->prev = p;
  if (p)	p->next = n;
  else		MaxPro = n;
  if (n2->next) n2->next->prev = n2;

} // add2maxpro ()

/*************************** FIND_PRO **************************************/
// Find profile line containing specified keyword and optional args in a
// Multiboot section we own.  If not found, return NULL.
PROTEXT *find_pro (char *keyword, char *arg1, char *arg2)
{
  PROTEXT *p;
  char buff[512];
  char *tok1, *tok2, *tok3, *semicol;

  for (p = MaxPro; p; p = p->next) {
	if (/* MultiBoot && */ /* CommonOwner == ActiveOwner if no MenuItems */
	    p->Owner != ActiveOwner && p->Owner != CommonOwner)
		continue; // Ignore this line if it's not ours
	strcpy (buff, p->text);
	if (semicol = strpbrk (buff, QComments))       *semicol = '\0';
	tok1 = strtok (buff, CfgKeywordSeps);
	tok2 = strtok (NULL, CfgKeywordSeps);
	tok3 = strtok (NULL, CfgKeywordSeps);
	if (tok1 && !stricmp (tok1, keyword)) {
	  if (	(!arg1 || (tok2 && !stricmp (tok2, arg1))) &&
		(!arg2 || (tok3 && !stricmp (tok3, arg2)))	) break;
	} // keyword matched
  } // for all lines in profile

  return (p);

} // find_pro ()

/*************************** FIND_COMMENT **********************************/
// Find comment matching the first n characters of s
PROTEXT *find_comment (char *s, int n)
{
  PROTEXT *p;

	for (p = MaxPro; p; p = p->next) {

	  if (/* MultiBoot && */ /* ActiveOwner == CommonOwner if no MenuItems*/
		p->Owner != ActiveOwner &&
		p->Owner != CommonOwner) continue;

	  if (!strnicmp (p->text, s, n)) break;

	} // for all lines in profile

  return (p);

} // find_comment ()

/*************************** REMOVE_PRO ************************************/
// Remove line containing specified keyword (and optional args).
void remove_pro (char *keyword, char *arg1, char *arg2)
{
  PROTEXT *p;

  if (p = find_pro (keyword, arg1, arg2)) {
    if (p->prev)	p->prev->next = p->next;
    else		MaxPro = p->next;
    if (p->next)	p->next->prev = p->prev;
    my_free (p->text);
    my_free (p);
  } // Found line to remove

} // remove_pro ()

/**************************** IS_EXCEPTION **********************************/
// Check specified device pathname.  If the IOCTL name is in the exception
// list, or if the IOCTL name is all 0's and there's an "EMM" in the file
// basename, it's an exception to the rule.  MAX can load after this driver,
// so we return 1.  Otherwise, we return 0 (MAX should load before this
// driver).
// We only call this function AFTER we've ascertained that this is NOT
// our OEM_FileName driver, nor is it listed in INSTALL.CFG.
int	is_exception (char *pathname)
{
  char	fdrive[_MAX_DRIVE],
	fdir[_MAX_DIR],
	fname[_MAX_FNAME],
	fext[_MAX_EXT];
  union {
	EXEHDR_STR exe_hdr;
	DRVHDR_STR dev_hdr;
  }	drv_buffer;
  int	fh;
  int	ret = 0;
  char	**exception;
  static int emmfound = 0;

  if (	!emmfound &&
	!access (pathname, 0) &&
	(fh = open (pathname, O_BINARY|O_RDONLY)) != -1) {

    if (read (fh, &drv_buffer, sizeof (drv_buffer)) != -1) {

	if (	drv_buffer.exe_hdr.exe_sign == 0x5a4d ||
		drv_buffer.exe_hdr.exe_sign == 0x4d5a) {
	  if (	lseek (fh, ((DWORD) drv_buffer.exe_hdr.exe_hsiz) << 4,
							SEEK_SET) == -1L ||
		read (fh, &drv_buffer, sizeof (drv_buffer)) == -1)
			goto IS_EXCEPT_CLOSE;
	} // EXE header found

	// Now we should have the actual device header.  Check for a character
	// device.  Allow only one matching either of the following criteria:
	// A. The IOCTL name is all 0's and there's an EMM in the name.
	// B. The IOCTL name is in our exception list.
	if (drv_buffer.dev_hdr.attr & 0x8000) {
	  _splitpath (pathname, fdrive, fdir, fname, fext);
	  strlwr (fname);
	  if (	strstr (fname, "emm") &&
		!memcmp (drv_buffer.dev_hdr.name, "\0\0\0\0\0\0\0\0",
					sizeof (drv_buffer.dev_hdr.name))) {
		emmfound++;
	  } // EMM in name with all 0's in IOCTL name
	  else {
	    for (exception = EXCPTN_LIST; *exception; exception++)
	      if (!strnicmp (drv_buffer.dev_hdr.name, *exception, 8)) {
		emmfound++;
		break;
	      } // Matched an exception
	  } // Check exception list

	  if (emmfound) ret = 1;	// Skip this one

	} // It's a character device

    } // Read device header OK

IS_EXCEPT_CLOSE:
    close (fh);

  } // File exists and was opened OK

  return (ret);

} // is_exception ()

/**************************** EDIT_CONFIG_SUB *******************************/
// Look for an OEM_FileName or OEM_OldName line in CONFIG.SYS.	Also troll
// for the first line that must come after us.
int	edit_config_sub (CFGTEXT *p)
{
  char	*tmp;
  int	foundmax;
  char	fdrive[_MAX_DRIVE],
	fdir[_MAX_DIR],
	fname[_MAX_FNAME],
	fext[_MAX_EXT],
	*device_name, *profile_name, *prepro;
  char	buffer[512], buff2[32];
  FILE	*maxpro;
  FILEDELTA *pF;

  if (!stricmp (keyword_part (p), "device")) {

    foundmax = 0;
    if (!MAXLine) {
	_splitpath (path_part (p), fdrive, fdir, fname, fext);

	if (!stricmp (tmp = fname_part (p), OEM_FileName))	foundmax = 1;
	else if (!stricmp (tmp, OEM_OldName)) {

	  foundmax = 1;

	  // We need to reconstruct the filename part of the line
	  strcpy (fext, strchr (OEM_FileName, '.'));
	  memset (fname, 0, sizeof(fname));
	  strncpy (fname, OEM_FileName, strlen(OEM_FileName)-strlen(fext));

	  // Now reconstruct the CONFIG.SYS line with identical leading
	  // space, DEVICE =, and trailing arguments.
	  strcpy (buffer, p->text);

	  if (device_name = strstr (buffer, path_part (p))) {

		*device_name = '\0'; // Clobber it

	  } // Found original device name
	  else {

		strcpy (buffer, "Device = ");

	  } // Didn't find device name (???)

	  _makepath (&(buffer [strlen (buffer)]), fdrive, fdir, fname, fext);
	  strcat (buffer, strpbrk (strstr (p->text, path_part (p)),
		ValPathTerms));
	  free (p->text);
	  p->text = str_mem (buffer);

	} // Device=386max.sys found but installing Bluemax.sys (or vice versa)

	if (foundmax) {
	  MAXLine = p;
	  device_name = strstr (p->text, path_part (p)); // c:\386max\386max.sys
	  prepro = strpbrk (device_name, ValPathTerms); // " RAM=xxxx PRO=..."
	  if (!(profile_name = pro_part (p))) {
		sprintf (pro_dpfne, "%s%s%s.pro", fdrive, fdir, fname);
	  } // No profile defined
	  else {
		strcpy (pro_dpfne, profile_name);
	  } // Pre-existing profile found
	  adjust_pfne (pro_dpfne, (char) (
#ifdef STACKER
			(SwappedDrive > 0 &&
				MaxConfig != '\0') ? MaxConfig :
#endif
							*fdrive),
				(short) (ADJ_DRIVE | ADJ_PATH | ADJ_FNAME) );
	  if (access (pro_dpfne,0)) add2maxpro (0, ProCreate);

	  // This is where pro_dpfne has been found.  We need to add it
	  // to our list of file deltas.
	  pF = get_filedelta (pro_dpfne);

	  for ( prepro = strtok (prepro, " \t\n");
		prepro;
		prepro = strtok (NULL, " \t\n")) {
	    if (strnicmp (prepro, "pro=", 4)) {
		sprintf (buffer, "%s\n", prepro);
		add2maxpro (0, buffer);
	    } // Not pro= (which we already parsed out)
	  } // for all options on CONFIG.SYS line

	  if (maxpro = cfopen (pro_dpfne, "r", 0)) {
	    pro_fnd = 1;
	    while (cfgets (buffer, sizeof(buffer)-1, maxpro)) {
		add2maxpro (0, buffer);
	    } // while not EOF
	    fclose (maxpro);
	  } // Profile opened successfully

	  *device_name = '\0';          // Terminate "   device = " part
	  sprintf (buffer, "%s%s%s%s%s pro=%s\n", p->text,
				fdrive, fdir, fname, fext,
				pro_dpfne);
	  my_free (p->text);
	  p->text = str_mem (buffer);
	} // Found a 386MAX line

    } // 386MAX/BlueMAX line not found yet

    if (!InsertLine && !foundmax) {

      // If this line is a device not listed in INSTALL.CFG, save it
      switch (cfg_flag (path_part (p))) {
	case 'p':               // Load after this one if not installed on boot
	  sprintf (buff2, "%c:\\*.*", boot_drive);
	  strcpy (buffer, drv_path);
	  truename (buffer);
	  truename (buff2);
	  if (buffer[0] == buff2[0]) goto CFGSUB_INSERT;
	case 'd':               // Always load after this one
	  goto CFGSUB_EXIT;
#if MOVEM
	case 'x':               // Move'EM only: XMS driver (HIMEM.SYS)
	  MoveUMB = TRUE;
	case 'm':               // Move'EM only: EMS hardware driver
	  goto CFGSUB_EXIT;
#endif // if MOVEM
	default:
	  break;
      } // end switch ()

      // Check for IOCTL names matching "EMMXXXX0" or "%INBRDAT", etc.
      // If it's another EMS driver, STRIPMGR will blow it away...
      if (is_exception (path_part (p))) goto CFGSUB_EXIT;

CFGSUB_INSERT:
      InsertLine = p;
    } // InsertLine not set yet

  } // It's a device= line
  else if (!stricmp (keyword_part (p), "stacks")) {
	char *tok2;

	strcpy (buffer, p->text);
	(void) strtok (buffer, ValPathTerms);
	tok2 = strtok (NULL, ValPathTerms);
	if (stricmp (tok2, "0")) {
	  free (p->text);
	  if (!StacksLine) StacksLine = str_mem ("Stacks=0,0\n");
	  p->text = StacksLine;
	} // Found STACKS not equal to 0
	else if (!StacksLine) StacksLine = p->text;
  } // It's a stacks= line

CFGSUB_EXIT:
  LastLine = p;

  return (0);	// Keep on truckin'

} // edit_config_sub ()

/***************************** CHK_SMARTDRV_SUB ******************************/
// Check line in CONFIG.SYS for SMARTDRV.SYS, QCACHE.WIN, or 386CACHE.WIN
// and set flags appropriately.  While we're there, parse SMARTDRV.SYS line.
int	chk_smartdrv_sub (CFGTEXT *p)
{
  char	*tok[10];
  char	*args, *pathp;
  char	buff[512];
  int	i, ntok;

  if (	!(dcache & DCACHE_ANYCACHE) &&
	!stricmp (fname_part (p), "smartdrv.sys")) {

    // Set cache found flag.  Default to no size specified.
    dcache = DCACHE_SMARTDRV | DCF_SD_NOSIZE | (dcache & DCACHE_ANYFLAGS);

    strncpy (buff, p->text, sizeof(buff)-1);
    buff[sizeof(buff)-1] = '\0';

    if (args = strstr (buff, pathp = path_part (p))) {
	args += strlen (pathp); // Skip d:\path\smartdrv.sys
	for (i=ntok=0; i<sizeof(tok)/sizeof(tok[0]); i++) {
	  if (!(tok[i] = strtok (i ? NULL : args, " \t\n")))    break;
	  ntok++;
	} // parse all tokens in line
	for (i=0; i<ntok; i++) {
	  if (isdigit (tok[i][0])) {
		if (dcache & DCF_SD_NOSIZE) {
		  dcache &= ~DCF_SD_NOSIZE;	// Size is specified
		  dcache_arg = atoi (tok[i]);
		} // First SMARTDRV argument
		else {
		  if (dcache_arg2 = atoi (tok[i])) {
			dcache |= DCF_SD_SETLEND;
		  } // Lending argument was nonzero
		} // Second SMARTDRV argument
	  } // Numeric argument
	  else if (!stricmp (tok[i], "/a")) {
		dcache |= DCF_SD_EMS;
	  } // EMS option
	  else	;	// Unknown option
	} // for all tokens parsed
    } // path_part not null

  } // Haven't found a cache, and this one is SMARTDRV.SYS
  else if (	!stricmp (pathp = fname_part (p), QCACHE_WINF QCACHE_WINE) ||
		!stricmp (pathp, OLDQCACHE QCACHE_WINE)) {
	dcache |= DCF_SD_WIN;
  } // Found DEVICE=QCACHE.WIN or 386CACHE.WIN

  return (0);	// Keep on truckin'

} // chk_smartdrv_sub ()

/***************************** REMOVE_XBIOS ********************************/
// Remove the first XBIOS.SYS driver we find in CONFIG.SYS
int	remove_xbios (CFGTEXT *p)
{

  if (!stricmp (keyword_part (p), "device") &&
	!stricmp (fname_part (p), "xbios.sys")) {
	if (p->prev) {
	  p->prev->next = p->next;
	} // Previous entry exists
	else {
	  CfgSys = p->next;
	} // This is the root entry
	if (p->next) {
	  p->next->prev = p->prev;
	} // Next entry exists
	my_free (p->text);
	my_free (p);
	return (1);	// We're done
  } // Found XBIOS.SYS
  else	return (0);	// Keep on truckin'

} // remove_xbios ()

#if !MOVEM
static char *swapfmt = "%c%s" MAX_SWAPNAME;

/***************************** CSWAPSUB ***********************************/
// Subroutine for CHECK_SWAPFILE.  Check to see if a swapfile exists
// or can be created on the specified drive and directory.
// The creatability test is needed on the off chance that there
// are no root directory entries available.
// We'll also use the disk cache test to determine if the drive we're
// suggesting for a SWAPFILE drive is a RAM drive.  The caller should
// invoke save_dcvid() and rest_dcvid() around calls to cswapsub().
// The directory must end in backslash.
int cswapsub (char driveltr, char *directory)
{
	char testpath[128], *pszTemp;
	int fh, len;
	int res = 0;

	putenv ("TMP="); /* Make sure tempnam() doesn't use existing TMP */

	sprintf (testpath, swapfmt, driveltr, directory);
	if (!access (testpath, 04))	res = 1; // Already readable
	else {
		if ((fh = open (testpath, O_RDWR|O_CREAT, S_IREAD|S_IWRITE)) == -1) {
		  return (0); // Bad directory
		} // Not a valid path
		close (fh);
		unlink (testpath);
	} // Try to create it to see if it's a valid directory

	sprintf (testpath, "%c%s", driveltr, directory);
	// Clobber trailing backslash unless we're in the root directory
	if ((len = strlen (testpath)) > 3) testpath[len-1] = '\0';
	if (pszTemp = tempnam (testpath, "SWP")) {
		strcpy (testpath, pszTemp);
		free (pszTemp);
	} // Got a temp name
	else sprintf (testpath, "%c%sSWPTEST.$$$", driveltr, directory);

	if (!res) {

	  if ((fh = open (testpath, O_RDWR|O_CREAT, S_IREAD|S_IWRITE)) != -1) {
		close (fh);
		res = 1; // File can be created
	  } // Created successfully

	} // Try to create it

	if (res) {
	  if (dcache_active (testpath, 2048, 10) == DCACHE_NOWRITE) res = 0;
	  unlink (testpath);
	} // Check for a RAM drive

	return (res);

} // cswapsub ()
#endif // not MOVEM

#if !MOVEM
/***************************** CHECK_SWAPFILE ******************************/
// Find a drive we can put the temporary swapfile on.
// We've already determined that DPMI services will be enabled, and
// that SWAPFILE does not already exist in the MAX profile.
// We'll check the dest_subdir first, then all drives starting
// from the boot drive.  We'll stop at the first local non-removable
// drive with 8MB free space, or use the largest with over 1MB.
// If none are found, we'll add a comment to the profile.
// The comment may already exist, so if we're successful we need to
// remove it, and if we're not we won't add a duplicate.
void	 check_swapfile (void)
{
	char temp[128];
	char curdrive, bestdrive;
	char *maxdir, *rootdir, *bestdir;
	int  bestsize, cursize;
	PROTEXT *p;
	char *comment;

	do_intmsg(MsgCheckSwap);

	do_backslash (dest_subdir);
	maxdir = dest_subdir + 1; // ":\386max\"
	rootdir = ":\\";

	// Fail all critical errors
	set24_resp (RESP_FAIL);

	// First check the destination directory.  If it has at least
	// 8MB, put the swapfile there.
	if (freeMB (dest_subdir[0]) >= 8) {
	  bestdrive = dest_subdir[0];
	  bestdir = maxdir;
	} // Swapfile fits in MAX directory
	else {
	  bestdrive = '\0'; // No drive found
	  save_dcvid (); // Save character at cursor position
	  for (curdrive = (char) toupper (boot_drive), bestsize = 0;
		curdrive <= 'Z';
		curdrive++) {
	    if ((cursize = freeMB (curdrive)) > bestsize) {
		if (cswapsub (curdrive, maxdir)) {
		  bestdir = maxdir;
		  bestsize = cursize;
		  bestdrive = curdrive;
		} // Swap file can go in the MAX directory
		else if (cswapsub (curdrive, rootdir)) {
		  bestdir = rootdir;
		  bestsize = cursize;
		  bestdrive = curdrive;
		} // Swap file can go in the root directory
		// else there's probably no root directory entries free...
	    } // Best size found so far
	  } // Searching for a local drive with sufficient space
	  rest_dcvid ();
	} // Checking all drives for swapfile space

	// Resume normal critical error handling
	set24_resp (0);

	// If we found a drive, we'll need to remove any comments we
	// find matching our "; DPMI swap file not installed"
	// If we didn't find a suitable drive, we won't add the comment
	// if it's already there.
	for (p = MaxPro; p; p = p->next) {
	  if (/* MultiBoot && */ /* ActiveOwner==CommonOwner if no MenuItems */
	      p->Owner != ActiveOwner && p->Owner != CommonOwner)
		continue; // Ignore this line if it's not ours
	  if (comment = strpbrk (p->text, QComments)) {
		if (!strnicmp (comment, ProNoSwapfile, PRONOSWAP_NCMP)) {
		  if (!bestdrive) return; // Don't need to add anything
		  else {
		    *comment = '\0'; // Clobber the comment
		    for (--comment; comment >= p->text &&
				strchr (" \t", *comment); comment--)
			*comment = '\0'; // Clobber trailing whitespace
		  } // Remove this comment
		} // Comment matches
	  } // found comments
	} // for all lines in profile

	// If we found a drive, put the SWAPFILE line in.
	// Otherwise, add the "; DPMI swap file not installed"
	if (bestdrive) {
	  sprintf (temp, swapfmt, bestdrive, bestdir);
	  add2maxpro (ActiveOwner, ProSwapfile, temp);
	} // Found a drive
	else add2maxpro (ActiveOwner, ProNoSwapfile);

} // check_swapfile ()
#endif // if not MOVEM

//**************************** EDIT_CONFIG ************************************
void	 edit_config ( void )
{
char	 dest_config[128],
	 *buffer = NULL;
WORD	 extmax;
CFGTEXT *n, *p, *inspoint;

	 buffer = get_mem ( 256 );

// Ensure destination directory ends with backslash
	 do_backslash ( dest_subdir );

// If the user specified a MultiConfig section that doesn't exist,
// make sure it appears at the end.
	if (MultiBoot) {
	  for (inspoint = CfgSys; inspoint && inspoint->Owner != ActiveOwner;
			inspoint = inspoint->next) LastLine = inspoint;
	  if (!inspoint) {
		inspoint = get_mem (sizeof(CFGTEXT));
		inspoint->prev = LastLine;
		LastLine->next = inspoint;
		sprintf (dest_config, "\n[%s]\n", MultiBoot);
		inspoint->text = str_mem (dest_config);
		inspoint->Owner = ActiveOwner;
	  } // No section found; create one
	} // MultiBoot

// Create a form of dest_subdir which we can use in all CONFIG.SYS references
	 strcpy (dest_config, dest_subdir);
#ifdef STACKER
	 if (SwappedDrive > 0 && MaxConfig) dest_config[0] = MaxConfig;
#endif

// Read INSTALL.CFG into memory.  We might have read it directly from the
// floppy.  If we didn't, read it from the destination directory now.
	 if (!cfg) read_cfg (FALSE);

// Look for a 386MAX.sys line in CONFIG.SYS.  Also find a line we can
// insert ourselves before.  We'll also replace STACKS=n with STACKS=0,0
// (We've already ensured they're not in a common or include area).
	MAXLine = InsertLine = NULL;
	(void) walk_cfg (CfgSys, edit_config_sub);

// Initialize buffer with the appropriate DEVICE= line
//  to be placed in CONFIG.SYS if none found.
	if (!MAXLine) {

	  sprintf ( buffer, "Device=%s%s pro=%s%s.PRO\n",
			dest_config, OEM_FileName, dest_config, OEM_ProdFile);
	  strlwr ( &buffer[1] );  // Convert to lowercase all but the first char
	  n = get_mem (sizeof (CFGTEXT));
	  n->text = str_mem (buffer);
//	  n->next = NULL;
	  if (InsertLine) {
		p = InsertLine->prev;
		n->prev = p;
		n->next = InsertLine;
		InsertLine->prev = n;
		if (p) p->next = n;
		else CfgSys = n;
	  } // Put new MAX line in before InsertLine
	  else {
		// Note that we may be appending to a MultiConfig section,
		// in which case LastLine isn't the last line in CONFIG.SYS;
		// it's the last line in the section.
		n->next = LastLine->next;
		if (n->next) n->next->prev = n;
		LastLine->next = n;
		n->prev = LastLine;
		LastLine = n;
	  } // No InsertLine defined; add to the end of CONFIG.SYS or section
	  edit_config_sub (n);	// Parse profile
	} // No MAX line found
	else	FreshInstall = FALSE; // MAX was already installed

	// Make sure we have Stacks=0,0
	if (!StacksLine) {
	  StacksLine = str_mem ("Stacks=0,0\n");
	  n = get_mem (sizeof (CFGTEXT));
	  n->text = StacksLine;
	  // Get an insertion point after the first header for our section
	  for (inspoint = CfgSys; inspoint && inspoint->Owner != ActiveOwner;
			inspoint = inspoint->next) LastLine = inspoint;
	  if (inspoint) {
		p = inspoint->next;
		n->prev = inspoint;
		n->next = p;
		inspoint->next = n;
		if (p) p->prev = n;
		else CfgSys = n;
	  } // found an insertion point
	  else {
		n->next = LastLine->next;
		if (n->next) n->next->prev = n;
		LastLine->next = n;
		n->prev = LastLine;
		LastLine = n;
	  } // Add to end
	} // Didn't find a Stacks statement

	// Set global flags if SMARTDRV found
	(void) walk_cfg (CfgSys, chk_smartdrv_sub);

	// Delete the first XBIOS.SYS driver we find
	(void) walk_cfg (CfgSys, remove_xbios);

#if MOVEM
	  if (MoveUMB) {	// Found an XMS driver before Move'em
	    if (!find_pro ("UMB", NULL, NULL))
		add2maxpro (ActiveOwner, "UMB%s", ProMoveUMB);
	  } // Move'em has XMS
#else // Normal MAX/BlueMAX install
	   // If the maximum of extsize() and extcmos() is < 512,
	   // insert NODPMI
	   if (!find_pro (NODPMI, NULL, NULL)) {
	     if (	(extmax = max (extsize(), extcmos())) < 512 &&
			!find_pro (NODPMI, NULL, NULL)) {
		add2maxpro (ActiveOwner, ProNoDPMI, extmax);
	     } // less than 512K extended memory; disable DPMI services
	     else {
		if (!find_pro (SWAPFILE, NULL, NULL)) check_swapfile ();
	     } // DPMI services enabled; put in SWAPFILE keyword
	   } // DPMI services not already disabled

	   // If a version of MAX prior to the current release is
	   // installed, put an IGNOREFLEXFRAME in the profile so
	   // they won't get FLEXed on the first reboot in Maximize.
	   // If they don't run MAXIMIZE... well, we warned 'em.
	   // They can still get in trouble if they ran INSTALL
	   // without MAX in the system (i.e. they held down the
	   // Alt key).
	   if (MAXPRES() && ISPREVIOUS (MAXINFOVER)) {
		add2maxpro (ActiveOwner, ProIgnoreFlex);
	   } // Previous MAX version

	if (NewMachine) {
	  PROTEXT *proline;

	  while ((proline = find_pro (UseRam[0], NULL, NULL)) ||
		 (proline = find_pro (VGASWAP, NULL, NULL))) {
	    if (proline->prev) proline->prev->next = proline->next;
	    else MaxPro = proline->next;
	    if (proline->next) proline->next->prev = proline->prev;
	    my_free (proline->text);
	    my_free (proline);
	  } // Clobber all USE and VGASWAP statements

	  // Kill NOROMSRCH and NOVGASWAP
	  edit_maxcfg ("NOVGASWAP", NULL, FALSE);
	  edit_maxcfg ("NOROMSRCH", NULL, FALSE);

	} // NewMachine; comment out all USE= statements and VGASWAP
	  // Note that Maximize will clobber all RAM= statements.
#endif // IF/ELSE MOVEM

	// If another memory manager line was found, add it to the
	// profile as a comment.  It should already have a trailing LF.
	if (OldMMLine) {
		PROTEXT *p, *n;

		if (p = find_comment (ProOldMMLine, 20)) {

		  n = get_mem (sizeof (PROTEXT));
		  n->text = get_mem (strlen (OldMMLine) + 2);
		  sprintf (n->text, "; %s", OldMMLine);
		  n->next = p->next;
		  p->next = n;

		} // Found existing comment
		else {

		  add2maxpro (ActiveOwner, ProOldMMLine);
		  add2maxpro (ActiveOwner, "; %s", OldMMLine);

		} // Add comment and line

		free (OldMMLine);
		OldMMLine = NULL;

	} // Add old memory manager line

	my_free ( buffer );

} // End EDIT_CONFIG

//****************************** LOCATE_WINFLES ********************************
// Search the path for WINVER.EXE
//	 Return 1 if found, 0 otherwise.
enum boolean locate_winfles (char *sysini_path)
{
	enum boolean rc = FALSE;

	_searchenv ("WINVER.EXE", "PATH", pszBuff);
	 if ( pszBuff[0] != '\0' ) {
		_splitpath ( pszBuff, drv_drive, drv_dir, drv_fname, drv_ext );
		sprintf (sysini_path, "%s%s", drv_drive, drv_dir );
		rc = TRUE;
	 } // Found SYSTEM.INI

	 return ( rc );

} // End locate_winfles


/******************************* RESET_BATCH ********************************/
void reset_batch (int newtarget)
// Reset batch processing data
{
  int i;
  char buff[5];

  BatlineTarget = newtarget;
  for (i='A'; i<='Z'; i++) {
	sprintf (buff, "%c:\\", i);
	currentdir[i-'A'] = str_mem (buff);
  } // Set initial values for all current drive/directory combinations
  currentdrive = toupper (boot_drive) - 'A';

} // reset_batch ()

/******************************* CLEAR_BATCH ********************************/
// Free array of current directory pointers allocated by reset_batch()
void clear_batch (void)
{
  int i;

  for (i='A'; i<='Z'; i++)
    if (currentdir[i-'A']) {
	free (currentdir[i-'A']);
	currentdir[i-'A'] = NULL;
    } // For all allocated directories

} // clear_batch ()

/******************************* PROCESS_STREAM ******************************/
int process_stream (
	char *infile,				// File to process
	char *outfile,				// Output filename or NULL
	int (*output_unit) (FILE *,		// Output unit:
				char *, 	  // Line to send
				long))		  // Input file read offset
// Open file for input.  If outfile is NULL, send output to
// temporary file and when we're done, copy it to infile and
// delete it.
// Read lines of input from infile.  Pass each line to output_unit, including
// the NULL we get at the end of the file.
// If output_unit returns a non-zero value, return it.
// Note that batch file output units may call this function recursively
// when processing called and chained batch files.  We'll only allow
// 10 levels of recursion in case someone does something stupid like
// In autoexec.bat:
// foobar.bat
// In foobar.bat:
// autoexec.bat
{
  FILE *input, *output;
  char	tempout[80];
  int	ret, i;
  long	curfpos;
  static int RecursionLevel = 0;

  // If we've exceeded the maximum nesting level, return quietly
  // Note that we're limited by the number of available file handles
  // (INSTALL.HLP is already open)
  if (RecursionLevel >= MaxRecursion) return (0);

  // To avoid constructs like
  // In foo1:
  // call foo2
  // In foo2:
  // foo1
  // we quietly ignore any batch filename we've already opened.
  for (i = RecursionLevel; i > 0; i--)
	if (!stricmp (prevlevels[i], infile)) return (0);

  // If we're trying to process nested batch files and we run out
  // of handles, we'll quietly fail.
  input = cfopen (infile, "rt", RecursionLevel-1);
  if (!input) return (0);

  if (outfile) {
	output = cfopen (outfile, "wt", RecursionLevel-1);
  } // OK to open NUL device
  else {
	tmpnam (tempout);
	output = cfopen (tempout, "wt", RecursionLevel-1);
  } // outfile is NULL
  if (!output) {
	fclose (input);
	return (0);
  } // Open failed on a nested call

  prevlevels[RecursionLevel] = str_mem (infile);

  RecursionLevel++;
  ForceReturn = 0;

  do {
	// Get the input offset for comparison with STRIPMGR output
	curfpos = ftell (input);

	// Bug out if it's the end of the file
	if (!cfgets (pszBuff, BUFFSIZE-2, input)) break;

	// We'll always ensure there's an ending LF
	if (!strchr (pszBuff, '\n')) strcat (pszBuff, "\n");

	if (ret = (*output_unit) (output, pszBuff, curfpos))
		goto PROCESS_STCLOSE;

	/* If we've encountered a chained batch file, we may need */
	/* to ignore all subsequent lines. */
	if (ForceReturn) goto PROCESS_STCLOSE;

  } while (1); // while not EOF

  ret = (*output_unit) (output, NULL, -1L);

PROCESS_STCLOSE:
  if (RecursionLevel) RecursionLevel--;
  free (prevlevels[RecursionLevel]);
  prevlevels[RecursionLevel] = NULL;

  fclose (input);
  if (output) fclose (output);

  if (!outfile && ret != -1) {
	copy_file (tempout, infile);
	(void) unlink  (tempout);
  } // Copy output back to input; no errors occurred

  return (ret);

} // process_stream ()

/****************************** CPREINST_SUB *********************************/
// Add a line to PREINST.BAT to restore the specified file.  One or more
// alternate drives are substituted for the copy destination, if specified.
void cpreinst_sub (	char *backup_fname,
			char *fname,
			char altdrive,
			char altdrive2)
{
  char olddrive;
  FILE *fp;

	fp = cfopen (preinst_bat, "at", 1);

#ifdef STACKER
	if (SwappedDrive > 0 && altdrive) {
		olddrive = *fname;
		*fname = altdrive;
		cfprintf (fp, copyfmt, backup_fname, fname);
		if (altdrive2) {
			*fname = altdrive2;
			cfprintf (fp, copyfmt, backup_fname, fname);
		}
		*fname = olddrive;
	}
#endif
	cfprintf (fp, copyfmt, backup_fname, fname);

	fclose (fp);

} // cpreinst_sub ()

//***************************** CREATE_PREINST_FILE ****************************
// Create the basic preinst.bat, and initialize global preinst_bat.
// cpreinst_sub() adds lines to restore individual files.
void	 create_preinst_file (void)
{
FILE	*batfile;

	do_backslash ( dest_subdir );
	sprintf (preinst_bat, "%spreinst.bat", dest_subdir );

	batfile = cfopen (preinst_bat, "wt", 1);

	cfprintf (batfile, MsgPreInst, dest_subdir, dest_subdir);
	if ( FilesBackedUp ) {
		cfprintf (batfile, "if exist %s*.* copy %s. %s.\n",
					BackupDir, BackupDir, dest_subdir );
	}
	fclose (batfile);

} // End of create_preinst_file routine

/*************************** REMOVE_SMARTDRV *****************************/
// If current line is DEVICE=smartdrv.sys, save as InsertLine
int	remove_smartdrv (CFGTEXT *p)
{
  if (	!strnicmp (keyword_part (p), "device", 6) ) {
    if (!stricmp (fname_part (p), "smartdrv.sys") ) {
	InsertLine = p; // This is the line to replace
	return (1);	// Return to sender
    } // Line is DEVICE[high] = [d:\path]smartdrv.sys
  } // Line is DEVICE[high]

  return (0);	// Continue

} // remove_smartdrv ()

/*************************** FIND_CBUFFERS *******************************/
// If buffers= is in a common area, find it so we can scatter it.
int	find_cbuffers (CFGTEXT *p)
{
  if (!BuffersLine && p->Owner != ActiveOwner &&
		!stricmp (keyword_part (p), "buffers")) {
	BuffersLine = p; // Save for later
	return (1);	// Return to sender
  } // Line is first instance of BUFFERS=

  return (0);	// Continue

} // find_cbuffers ()

/*************************** CHANGE_BUFFERS ******************************/
// If Buffers= statement found, replace it with BUFFERS=QCACHE_BUF.  Also
// set LastLine and InsertLine.
int	change_buffers (CFGTEXT *p)
{
  char *parg, *pkey;

  if (!stricmp (pkey = keyword_part (p), "buffers")) {
	// Discard the old text; it might be multireferenced
	// if we had to scatter BUFFERS= out of the common area
	p->text = str_mem (p->text);
	parg = strstr (p->text, pkey) + strlen (pkey);
	parg += strspn (parg, ValPathTerms);
	strcpy (parg, QCACHE_BUF "\n"); // It had BETTER be one character!
	dcache |= DCF_SD_BUFF;		// Found BUFFERS=
  } // Found BUFFERS=
  else if (!strnicmp (pkey, "device", 6) &&
	   !stricmp (fname_part (p), MAX_HARPO_EXE) && !InsertLine) {
	InsertLine = p; // Insert before the first instance of ExtraDOS
  } // Found DEVICE[high] = [d:\path\]extrados.max

  // We'll be processing common and active lines.  Don't save a common
  // line unless there's nothing else.
  if (!MultiBoot || p->Owner == ActiveOwner || !LastLine) LastLine = p;

  return (0);

} // change_buffers ()

/**************************** QUTIL_LABEL *******************************/
// The :section->name label isn't in Qutil.BAT -- put it in before :end
int qutil_label (FILE *fp, char *line, long streampos)
{
  char	buff[256];
  char	*command;

  if (line) {
	strncpy (buff, line, sizeof(buff)-1);
	buff[sizeof(buff)-1] = '\0';
	// Skip over leading @; we can't use strtok() since it may be in the
	// pathname (it is a valid filename component).
	for (command = buff; *command && strchr (" \n\t@", *command); command++) ;
	if ((command = strtok (command, ValPathTerms)) && probuf[0]) {
	  if (command[0] == ':') {
		if (!stricmp (command+1, "end")) {
			cfputs (probuf, fp);
			probuf[0] = '\0';
		} // Found the end; put our label in
	  } // Found a label
	} // Got a command
	cfputs (line, fp);
  } // not EOF

  return (0);

} // qutil_label ()

/************************** PROCESS_QUTIL *****************************/
// Process QUTIL.BAT, which we can assume is in the following format:
// @echo off
// goto %CONFIG%
// :section1
// goto end
// :section2
// goto end
// :end
// We'll scan for :%CONFIG%, then look for the specified target
// between the label and the first goto we find.
// If we insert a new label into QUTIL.BAT, we'll add it immediately after
// the first goto end statement we find, or before :end (whichever
// comes first).  If we're adding a command to an existing label, we'll
// add it after the label and before the next goto, label, or QCACHE
// (whichever comes first).  This ensures that QMT will be inserted
// before QCACHE.
// If chklabel is not NULL, just look for it.
int process_qutil (char *pathname, char *chklabel)
{
  int ret = 0;
  FILE *fin;
  char buff[256], label[80];
  int FoundQutilSect = 0; /* Found our MultiBoot section in QUTIL.BAT */


  if (fin = fopen (pathname, "rt")) {

    while (fgets (buff, sizeof(buff)-1, fin) && !ret) {

	sscanf (buff, "%s", label);
	if (chklabel) {
	  if (label[0] == ':') ret = !stricmp (label+1, chklabel);
	} // Checking for a label
	else if (!FoundQutilSect && label[0] == ':' &&
			!stricmp (label+1, MultiBoot)) {
	  FoundQutilSect = 1; // Begin processing lines
	} // Found our section
	else if (FoundQutilSect && !stricmp (label, "goto")) {
	  goto PQ_EXIT; // End of the line...
	} // Section ended by a goto
	else if (FoundQutilSect) ret = find_batline (NULL, buff, 0L);

    } // not EOF

  } // File opened successfully
PQ_EXIT:
  if (fin) fclose (fin);

  return (ret);

} // process_qutil ()

/************************** FIND_BATLINE ******************************/
// Search AUTOEXEC.BAT and its descendents for a line containing
// QCACHE.  Return 1 if we find it.
// Also return 1 if we find SMARTDRV.EXE.  This may mean we don't put
// QCACHE in some configurations, but it's either that or take TS calls
// because we put QCACHE in when SMARTDRV's already there.
// We need to search chained and CALLed batch files as well. QUtil.BAT
// is the only batch file we'll actually parse conditional expressions
// for, since we need to determine if QCACHE was loaded for another
// MultiBoot section.
// A fundamental limitation here is that we rely on the current path.
// It's not intended to be as thorough as STRIPMGR.
// reset_batch() MUST be called before, and clear_batch() called
// afterward to allocate and clear the array of current directories.
// Chained batch files are always treated as if they were CALLed,
// since we don't process conditional jumps.
#pragma optimize("leg",off)
int find_batline (FILE *fp, char *line, long streampos)
{
/********************************************************************/
/*!*!*!*!*!*!*!* This function is called recursively. *!*!*!*!*!*!*!*/
/*!************* Don't add local variables unless they ************!*/
/*!************* really need to be automatic and local. ***********!*/
/********************************************************************/
  char	*command, *arg1, *arg2, *batchcmd;
  int	tmp,isQutil;
/////// int tmpForce; // Force return from chained batch file
  static char *pszBuff2 = NULL;
  char *qutil_path;

  if (!pszBuff2) pszBuff2 = get_mem (256);
  if (line) {
	strncpy (pszBuff2, line, 255);
	pszBuff2[255] = '\0';
	// Skip over leading @; we can't use strtok() since it may be in the
	// pathname (it is a valid filename component).
	for (command = pszBuff2; *command && strchr (" \n\t@", *command);
					command++) ;
	if (command = strtok (command, ValPathTerms)) {
	  arg1 = strtok (NULL, ValPathTerms);	// "c" in "/C"
	  arg2 = strtok (NULL, ValPathTerms);	// Possible batch file name
	  // Weed out LH
	  if (!stricmp (command, "LH") || !stricmp (command, "LOADHIGH") ||
		(BatlineTarget == BT_PATH && !stricmp (command, "SET"))) {
		command = arg1;
		arg1 = arg2;
		arg2 = strtok (NULL, ValPathTerms);
	  } // Command is preceded by LOADHIGH syntax

///////   tmpForce = 1; // Assume it's a chained batch command

	  // If it's CALL batchnname or COMMAND/c batchname we need to get
	  // the actual batch command
	  _splitpath (command, wrkdrive, wrkdir, wrkname, wrkext);
	  if (!stricmp (command, "CALL")) {
		batchcmd = arg1;
/////// 	tmpForce = 0;
	  } // CALLed batch file
	  else if ((!stricmp (wrkname, "COMMAND") ||
		    !stricmp (command, "%COMSPEC%")) &&
		  !stricmp (arg1, "c")) {
		  batchcmd = arg2;
/////// 	  tmpForce = 0;
	  } // COMMAND /c batchname
	  else batchcmd = command;
	  _splitpath (batchcmd, wrkdrive, wrkdir, wrkname, wrkext);

	  if (!stricmp (wrkname, QUTIL) && (!wrkext[0] ||
						  !stricmp (wrkext, ".bat"))) {
	    qutil_path = get_mem (MAXPATH);
	    _makepath (qutil_path, wrkdrive, wrkdir, wrkname, ".BAT");
	    pQutil = get_filedelta (qutil_path);
	    free (qutil_path);
	    isQutil =  1;
	  } // Found QUTIL line
	  else isQutil = 0;

	  switch (BatlineTarget) {
	    case BT_QCACHE:	/* QCACHE or SMARTDRV */
		if (	!stricmp (wrkname, QCACHE) ||
			!stricmp (wrkname, OLDQCACHE) ||
			!stricmp (wrkname, "SMARTDRV")) {
			if (!(wrkext[0]) || !stricmp (wrkext, ".exe"))
						return (1);
		} // Name matches
		break;

	    case BT_QMT:	/* QMT */
		if (!stricmp (wrkname, QMT) || !stricmp (wrkname, RAMEXAM)) {
			if (!(wrkext[0]) || !stricmp (wrkext, ".exe"))
						return (1);
		} // Name matches
		break;

	    case BT_QUTIL:	/* QUTIL.BAT */
		if (isQutil) return (1);
		break;

	    case BT_PATH:	/* Find PATH */
		if (!stricmp (command, "path")) {
		  int ncomp = strlen (dest_subdir)-1;

		  // arg1 and arg2 are the first two paths.
		  // We can continue calling strtok (NULL, ValPathTerms);
		  // ';' is one of the delimiters.
		  // Note that we can't assume there is or isn't a trailing
		  // backslash on a path element.
		  if (arg1 && !strnicmp (arg1, dest_subdir, ncomp)) return (1);
		  while (arg2) {
			if (!strnicmp (arg2, dest_subdir, ncomp)) return (1);
			arg2 = strtok (NULL, ValPathTerms);
		  } // while arg2
		} // Found a [set] path statement
		break;

	  } // switch ()

	  // We need to watch for drive and directory changes.
	  // Rather than execute them, we'll look in the current
	  // drive/directory first before searching the path.
	  if (strchr (":\\", command[strlen(command)-1])) {

		if (isalpha (command[0])) currentdrive = toupper (command[0]) - 'A';

	  } // Got a drive change (c: or c:\386max\)
	  else if (arg1 && (!stricmp (command, "CD") || !stricmp (command, "CHDIR"))) {
		int thedrive;

		// We rely on _splitpath appending a '\' to fdir
		_splitpath (arg1, wrkdrive, wrkdir, wrkname, wrkext);
		strupr (wrkdrive);
		if (isalpha (wrkdrive[0]))	thedrive = wrkdrive[0] - 'A';
		else				thedrive = currentdrive;
		free (currentdir[thedrive]);
		sprintf (pszBuff2, "%s%s", wrkdrive, wrkdir);
		currentdir[thedrive] = str_mem (pszBuff2);

	  } // Got a directory change
	  else {
	  // Check for a batch file.  We can afford
	  // to ignore the distinction between .BAT, .COM and .EXE
	  // files- the worst case is we get a false positive.
		sprintf (pszBuff2, "|%s|", wrkname);
		strlwr (pszBuff2);
		if (wrkext[0] || (!strstr (ValidCmdTokens, pszBuff2) &&
				!strstr (ValidCmdTokens2, pszBuff2))) {
		  // If there's an extension, make sure it's .BAT
		  if (wrkext[0] && stricmp (wrkext, ".bat")) return (0);
		  strcpy (wrkext, ".BAT");

		  // We need to handle all of the following:
		  // 1. batname
		  // 2. d:batname
		  // 3. d:reldir\batname
		  // 4. d:\absdir\batname
		  // 5. reldir\batname
		  // 6. \absdir\batname

		  if (wrkdrive[0] || wrkdir[0]) {

		    // Reduce cases 5 and 6 to 3 & 4
		    if (!wrkdrive[0])
				sprintf (wrkdrive, "%c:", currentdrive+'A');

		    // For cases 2, 3 and 5, append the relative pathname
		    // to the current directory
		    if (wrkdir[0] != '\\') {
		      sprintf (pszBuff2, "%s%s", currentdir[currentdrive],
				wrkdir);
		      strcpy (wrkdir, pszBuff2);
		    } // directory is relative or nonexistent

		    // If we don't find it, tough
		    _makepath (pszBuff2, wrkdrive, wrkdir, wrkname, wrkext);
		    if (access (pszBuff2, 0)) return (0);
		    else goto READ_BATCH_FILE;

		  } // Not case 1

		  // First try the current drive/directory
		  sprintf (pszBuff2, "%s%s.BAT", currentdir[currentdrive],
				wrkname);
		  set24_resp (RESP_FAIL); // Fail all critical errors
		  tmp = access (pszBuff2, 0);
		  set24_resp (0); // Resume normal critical error handling
		  if (!tmp) goto READ_BATCH_FILE; // Found our boy
		  sprintf (wrkdir, "%s.BAT", wrkname);
		  _searchenv (wrkdir, "PATH", pszBuff2);
		  if (!pszBuff2[0]) return (0); // Didn't find it
READ_BATCH_FILE:
		  // pszBuff2 contains the fully qualified pathname
		  // Process the batch file.  If we're too far gone
		  // in recursion, process_stream() will return without
		  // doing anything.
		  _splitpath (pszBuff2, wrkdrive, wrkdir, wrkname, wrkext);
		  if (!stricmp	(wrkname, QUTIL))
			tmp = process_qutil (pszBuff2, NULL);
		  else	tmp = process_stream (pszBuff2, "nul", find_batline);

		  // If we didn't find anything, we may need to return
		  // forcibly (if it was chained rather than called).
/////// 	  if (!tmp) ForceReturn = tmpForce;
/////// 	  else return (tmp);
		  if (tmp) return (tmp);

		} // Not an internal command

	  } // Check for a chained batch file

	} // Got a command
  } // not EOF

  return (0);	// Target not found

} // find_batline ()
#pragma optimize("",on)

/************************** PLACE_QCACHE ******************************/
// Search AUTOEXEC.BAT for a place to put QCACHE or QMT and drop it there.
// If we don't find a home for it, put it at the end.
// If we're activating it only for a particular MultiBoot section,
// we've already created or updated qutil.bat with the correct
// line; here we just need to put the qutil.bat line in.  If we
// found it previously existing, we won't call this function.
int place_qcache (FILE *fp, char *line, long streampos)
{
  char	buff[256];
  char	*command;
  char	fdrive[_MAX_DRIVE],
	fdir[_MAX_DIR],
	fname[_MAX_FNAME],
	fext[_MAX_EXT];
  static placed = 0;

  if (line) {
	strncpy (buff, line, sizeof(buff)-1);
	buff[sizeof(buff)-1] = '\0';
	// Skip over leading @; we can't use strtok() since it may be in the
	// pathname (it is a valid filename component).
	for (command = buff; *command && strchr (" \n\t@", *command); command++) ;
	if ((command = strtok (command, ValPathTerms)) && probuf[0]) {
	  _splitpath (command, fdrive, fdir, fname, fext);
	  sprintf (buff, "|%s|", fname);
	  strlwr (buff);
	  if (fext[0] || !strstr (ValidCmdTokens, buff)) {
		cfputs (probuf, fp);
		probuf[0] = '\0';
	  } // Not in our list of valid command tokens
	} // Got a command
	cfputs (line, fp);
  } // not EOF
  else if (!placed) {
	cfputs (probuf, fp);
  } // EOF and we didn't place it yet

  return (0);

} // place_qcache ()

/**************************** PLACE_QUTIL *******************************/
// Find a home in QUTIL.BAT for probuf.
// If we find a label matching MultiBoot, we'll insert it immediately
// afterwards.	Otherwise, if we stumble on the :end label (or the
// end of the file) we'll create a labeled section and stick it in.
// We'll put the line after the label but before the first goto or
// QCACHE, whichever comes first.
int place_qutil (FILE *fp, char *line, long streampos)
{
  char	buff[256];
  char	*command;

  if (line) {
	strncpy (buff, line, sizeof(buff)-1);
	buff[sizeof(buff)-1] = '\0';
	// Skip over leading @; we can't use strtok() since it may be in the
	// pathname (it is a valid filename component).
	for (command = buff; *command && strchr (" \n\t@", *command); command++) ;
	if ((command = strtok (command, ValPathTerms)) && probuf[0]) {
	  if (command[0] == ':') {
		if (InSection && probuf[0]) {
		  cfputs (probuf, fp);
		  probuf[0] = '\0';
		} // Unexpected new section; place our line
		else if (!stricmp (command+1, MultiBoot)) {
		  InSection = 1;
		} // Found our label
		else if (!stricmp (command+1, "end")) {
		  // End label found
		  cfprintf (fp, ":%s\n" /* :section1 */
				"%s"    /* C:\386max\qmt ... */
				"goto end\n", MultiBoot, probuf);
		  probuf[0] = '\0';
		} // Found the end; put our label and line in
	  } // Found a label
	  else if (!stricmp (command, "goto")) {
		if (InSection && probuf[0]) {
		  cfputs (probuf, fp);
		  probuf[0] = '\0';
		} // End of section
		InSection = 0;
	  } // End of a section
	  else if (command && InSection) {
		// If we're placing QMT after QCACHE is already there,
		// make sure we come before QCACHE.  If it's QCACHE
		// we're placing, we don't care.
		_splitpath (command, wrkdrive, wrkdir, wrkname, wrkext);
		if (!stricmp (wrkname, QCACHE) && probuf[0]) {
		  cfputs (probuf, fp);
		  probuf[0] = '\0';
		} // Found QCACHE; put it in here
	  } // Got a command; check for QCACHE
	} // Got a command
	cfputs (line, fp);
  } // not EOF
  else {
    if (probuf[0]) {
	cfputs (probuf, fp);
	probuf[0] = '\0';
    } // EOF and we didn't place it yet
    InSection = 0;
  } // EOF

  return (0);

} // place_qutil ()

/************************** install_qmt () ***************************/
// Put a c:\386max\qmt /{b|c} QUICK=1 line in AUTOEXEC.BAT.  We'll
// do this after install_qcache(), so we make sure it's the first
// thing.
// key is either RESP_YES for all sections or RESP_THIS for this
// Multiboot section only.
void install_qmt (KEYCODE key)
{
  FILEDELTA *pF;
  char *pszInName;

  pF = get_filedelta (StartupBat);

 // We need to cruise through AUTOEXEC.BAT twice.  First, we check for
 // QMT present.  If not found, we go through a second time, looking for
 // an unrecognized command to stick QMT in front of.
 sprintf (probuf, "%s" QMT " /%c QUICK=1\n", dest_subdir,
		ScreenType == SCREEN_MONO ? 'B' : 'C');

 // If key == RESP_THIS, we need to add our line to QUtil.bat,
 // creating it if necessary.
 // probuf contains the QCACHE line.  If we are to put it in QUtil.bat,
 // (possibly creating QUtil in the process) we'll plunk it in there
 // now and construct a new probuf.  If Qutil is not already in
 // AUTOEXEC, we need to stick it in there.
 if (key == RESP_THIS) {
	update_qutil (BT_QMT);
 } // Put QMT in this section only

 if (autox_fnd) {
   reset_batch (key == RESP_THIS ? BT_QUTIL : BT_QMT);
   if (!process_stream (pszInName = get_inname(pF), "nul", find_batline)) {
	(void) process_stream (pszInName, get_outname (pF), place_qcache);
   } // QMT not found in AUTOEXEC.BAT
   clear_batch ();
 } // AUTOEXEC.BAT exists
 else {
	FILE *fp;

	(void) get_outname (pF); // AUTOEXEC.ADD or NULL
	fp = cfopen (pF->pszOutput, "at", 1);
	cfprintf (fp, probuf);
	fclose (fp);
 } // No AUTOEXEC.BAT

} // install_qmt ()

/************************** add2cfg () *******************************/
// Insert a new record into the CONFIG.SYS linked list.
// If Multiboot is active, set ownership to the specified value.
// If necessary, create a section header.
// Return the address of the new record.
CFGTEXT *add2cfg (CFGTEXT *prev, CFGTEXT *next, BYTE NewOwner)
{
  CFGTEXT *ret, *hdr;
  BYTE PrevOwner, NextOwner;
  SECTNAME *sect;
  char buffer[80];

  ret = get_mem (sizeof(CFGTEXT));
  ret->prev = prev;
  ret->next = next;
  if (prev) {
	prev->next = ret;
	PrevOwner = prev->Owner;
  } else {
	CfgSys = ret;
	PrevOwner = CommonOwner;
  } // if (prev) / else
  if (next) {
	next->prev = ret;
	NextOwner = next->Owner;
  } // if next
  else NextOwner = NewOwner;

  ret->Owner = NewOwner;

  if (MultiBoot) {
	if (PrevOwner != NewOwner) {
	  ret->Owner = PrevOwner; // Tell a lie
	  if (next) next->Owner = PrevOwner;
	  hdr = add2cfg (prev, ret, PrevOwner); // Insert new line before
	  ret->Owner = NewOwner; // Retract nose
	  if (next) next->Owner = NextOwner;
	  sect = find_ownsect (NewOwner); // Find the section record
	  sprintf (buffer, "\n[%s]\n", sect->name);
	  hdr->text = str_mem (buffer);
	} // Owner of previous line is different
	if (NextOwner != NewOwner && next && next->ltype != ID_SECT) {
	  ret->Owner = NextOwner; // Tell a lie
	  hdr = add2cfg (ret, next, NextOwner); // Insert new line after
	  ret->Owner = NewOwner; // Retract nose
	  sect = find_ownsect (NextOwner);
	  sprintf (buffer, "\n[%s]\n", sect->name);
	  hdr->text = str_mem (buffer);
	} // Owner of next line is different and is not already a section header
  } // MultiBoot active

  // Recalculate LastLine; we may have changed it
  for (hdr = ret; hdr->next; hdr = hdr->next)
	LastLine = hdr;

  return (ret);

} // add2cfg ()

/************************** UPDATE_QUTIL ****************************/
// Dump the contents of probuf to Qutil.bat (creating it if necessary)
// and reset probuf to a qutil line to put in AUTOEXEC.BAT (if it's
// not already there).
void update_qutil (int btval)
{
	char *qutil_in;
	int i;
	SECTNAME *section; /* Current section to add to qutil.bat */
	FILEDELTA *pF;
	char qutil_path[MAXPATH];

	pF = get_filedelta (StartupBat);

	// Construct a path if none found
	if (autox_fnd) {
	  reset_batch (BT_QUTIL);
	  (void) process_stream (get_inname (pF), "nul", find_batline);
	  clear_batch ();
	} // AUTOEXEC.BAT exists

	if (!pQutil) {
	  sprintf (qutil_path, "%s" QUTIL_BAT, dest_subdir);
	  pQutil = get_filedelta (qutil_path);
	} // Didn't find QUTIL line in AUTOEXEC.BAT
	pF = pQutil;
	qutil_in = get_inname (pF);

	// Create the file if it doesn't already exist
	qutil_fnd = !access (qutil_in, 0);
	if (!qutil_fnd) {
	  FILE *fnew;
	  int i;

	  fnew = cfopen (get_outname (pF), "wt", 1);
	  fprintf (fnew, "echo off\n"
			"goto %%CONFIG%%\n"
			":%s\n"         /* :section1 */
			"%s"            /* c:\386max\qcache ... */
			"goto end\n", MultiBoot, probuf);
	  // Create an empty section for each section in CONFIG.SYS
	  for (section = FirstSect, i=0; i < MenuCount && section;
				section = section->next, i++)
	    if (stricmp (section->name, MultiBoot)) {
		fprintf (fnew,	":%s\ngoto end\n", section->name);
	    } // For all sections other than ours
	  fprintf (fnew, ":end\n");
	  fclose (fnew);
	} // Create file
	else {

	  // The qutil.bat file may already have our boy in it, but it
	  // wasn't present in AUTOEXEC.  Check to see if our line is
	  // already there.
	  reset_batch (btval);
	  if (!process_qutil (qutil_in, NULL)) {
			process_stream (qutil_in, get_outname(pF), place_qutil);
			qutil_in = get_inname (pF);
	  } // Didn't find our line in Qutil.bat
	  clear_batch ();
	  // Ensure that every section is represented in Qutil.bat
	  for (section = FirstSect, i=0; i < MenuCount && section;
				section = section->next,  i++)
		if (!process_qutil (qutil_in, section->name)) {
			sprintf (probuf,":%s\n" /* :section1 */
					"goto end\n", section->name);
			process_stream (qutil_in, get_outname(pF), qutil_label);
			qutil_in = get_inname (pF);
		} // Found a section not in Qutil.bat

	} // Insert our line in Qutil.bat

	// Create a line to call Qutil from AUTOEXEC.BAT
	sprintf (probuf, "    call %s" QUTIL "\n", dest_subdir);

} // update_qutil ()

/************************** SCATTER_LINE () ***************************/
// Remove CONFIG.SYS line from present position (presumably in a [common]
// section) and stick a copy of it at the start of every SUBSEQUENT section.
// If there are sections that don't have headers following this line,
// create new ones at the end of CONFIG.SYS.
// This is copied from check_common() in MBPARSE.C.  We can't use
// common code because the structures are different.
void scatter_line (CFGTEXT *p)
{
  CFGTEXT *c, *cline, *newline, *cpline;
  SECTNAME *s;
  int unhooked, i;
  BYTE cowner;
  char buff[256];

	c = p;			// Save current line
	if (p->prev) p = p->prev; // Start with previous line if there is one,
	else p = p->next;	// otherwise start with next line
	s = FirstSect;		// Start with first section
	if (!s) return; 	// Shouldn't happen

	for (unhooked = i = 0; s && (i < MenuCount); s = s->next, i++) {

		cowner = s->OwnerID;	// Owner value to look for

		// Starting with p, find the first line
		// belonging to cowner (it should be a section name).
		for (	cpline = cline = p;
			cline && cline->Owner != cowner;
			cpline = cline, cline = cline->next) ;

		if (!cline) {
			sprintf (buff, "\n[%s]\n", s->name);
			cline = get_mem (sizeof (CFGTEXT));
			cline->text = str_mem (buff);
			cline->Owner = cowner;
			cline->ltype = ID_SECT;
			cline->prev = cpline;
			cpline->next = cline;
		} // Add new section to end of file

		// Find a record we can insert this one after
		while (cline->next && cline->next->Owner == cowner)
				cline = cline->next;

		// Unhook the original if we haven't done so already;
		// otherwise make a copy.
		if (!unhooked) {

			newline = c;
			if (c->prev) c->prev->next = c->next;
			if (c->next) c->next->prev = c->prev;
			if (c == CfgSys) CfgSys = p;
			unhooked = 1;

		} // Original still hooked up
		else {

			newline = get_mem (sizeof (CFGTEXT));
			newline->text = c->text; // We only copy the pointer
			newline->ltype = c->ltype;

		} // Copied from original

		newline->Owner = cowner;
		newline->prev = cline;

		if (newline->next = cline->next)
				newline->next->prev = newline;

		cline->next = newline;

	} // for all sections

} // scatter_line ()

//************************* install_qcache () *************************
// Replace smartdrv with QCACHE, or install QCACHE.
// 1. Replace DEVICE=SMARTDRV.SYS with DEVICE=QCACHE_WIN.
//    If QCACHE_WIN already exists, leave it alone.
//    (location does not at this point seem critical)
//    If a BUFFERS= statement is found, change it to QCACHE_BUF.
//    If neither SMARTDRV nor QCACHE.WIN is found, add to end of CONFIG.SYS
// 2. Find the first unrecognized statement in AUTOEXEC.BAT and
//    insert QCACHE before that line.
// The replace argument indicates that we are to remove an existing
// SMARTDRV.SYS.  In all cases we need to put QCACHE.WIN in CONFIG.SYS.
// key is either RESP_YES for all sections or RESP_THIS for this
// Multiboot section only.
//#pragma optimize ("leg",off)    /* Global optimization precludes ... */
void install_qcache (int replace, KEYCODE key)
{
int	sdfound = 0;
WORD	cachesize=0;
int	lendsize=0;
char	cfg_dest[128];	// dest_subdir modified by MaxConfig
CFGTEXT *temp;
BYTE	NewOwner;
FILEDELTA *pF;
char	*pszInName;

 // Create a form of the MAX directory to use within CONFIG.SYS
 strcpy (cfg_dest, dest_subdir);
#ifdef STACKER
 if (SwappedDrive > 0 && MaxConfig)	cfg_dest[0] = MaxConfig;
#endif

 // 1. Replace DEVICE=SMARTDRV.SYS with DEVICE=QCACHE_WIN
 InsertLine = NULL;
 if (replace) (void) walk_cfg (CfgSys, remove_smartdrv);

 // If BUFFERS= is in the [common] area, move it to all the individual
 // sections.  We'll ignore included issues.
 NewOwner = ActiveOwner;	// Default case
 if (MultiBoot) {
   if (key == RESP_THIS) {

	// Find the first occurrence of BUFFERS= in a section other than
	// the active one.
	BuffersLine = NULL;
	(void) walk_cfg (CfgSys, find_cbuffers);

	if (BuffersLine) scatter_line (BuffersLine);

   } // Adding to this section only
   else {
	NewOwner = CommonOwner;
   } // Adding to all sections
 } // MultiBoot active and we're adding to this section only

 // Find LastLine and replace BUFFERS= with QCACHE_BUF
 (void) walk_cfg (CfgSys, change_buffers);

 // InsertLine is a line we can replace with DEVICE=QCACHE.WIN
 // If we're not replacing, it's a line we need to put QCACHE.WIN before
 if (InsertLine && replace) {
	char *pstart;

	pstart = strstr (InsertLine->text, path_part (InsertLine));
	*pstart = '\0';
	sprintf (pszBuff, "%s%s" QCACHE_WIN "\n", InsertLine->text, cfg_dest);
	my_free (InsertLine->text);
	temp = InsertLine; // Save old line so we can free it
	// This ensures that we put it in the correct section
	InsertLine = add2cfg (InsertLine->prev, InsertLine->next, NewOwner);
	my_free (temp);
 } // Found a line to replace with QCACHE.WIN
 // If we're installing Windows support and it's not already there,
 // append qcache.win.
 else if (WIN30 && !(dcache & DCF_SD_WIN)) {
	if (InsertLine) InsertLine = add2cfg (InsertLine->prev, InsertLine, NewOwner);
	else InsertLine = add2cfg (LastLine, LastLine->next, NewOwner);
	sprintf (pszBuff, "Device = %s" QCACHE_WIN "\n", cfg_dest);
 } // Add line to end of CONFIG.SYS
 InsertLine->text = str_mem (pszBuff);

 // Make sure we put in Buffers=8 if there is no buffers statement
 // (DOS' default is 8, but don't believe it)
 if (!(dcache & DCF_SD_BUFF)) {
	InsertLine = add2cfg (LastLine, LastLine->next, NewOwner);
	sprintf (pszBuff, "Buffers = " QCACHE_BUF "\n");
	InsertLine->text = str_mem (pszBuff);
 } // No Buffers= statement

 // 2. Find the first unrecognized statement in AUTOEXEC.BAT and
 //    insert QCACHE before that line.	Note that we use dest_subdir,
 //	which is what we currently recognize as the main install
 //	directory, and we don't need to do any cute tricks.  CONFIG.SYS
 //	and AUTOEXEC.BAT will get copied to wherever they belong if
 //	drive swapping is in effect...
 sprintf (probuf, "\n%s" QCACHE, dest_subdir);

 if (!replace) {
  // Usually we'll take extcmos(), ignoring other users of XMS
  cachesize = max (max (extsize (), extcmos ()), xmsmax ());
  cachesize = (cachesize >= WINENHEXTMIN ?
	min (cachesize >> 2, QCACHE_MAX) :
	(cachesize >> 2) - WINEXTDIV4FLOOR + 256);
  dcache = 0;		// Clear all other flags
 } // Need to calculate size
 else
  cachesize = (dcache & DCF_SD_NOSIZE) ? DCF_SD_DEFSIZE : dcache_arg;

 sprintf (pszBuff, " /s:%u", cachesize);
 strcat (probuf, pszBuff);
 if ((dcache & DCF_SD_SETLEND) && (lendsize = dcache_arg - dcache_arg2) > 0) {
	sprintf (pszBuff, " /l:%d", lendsize);
	strcat (probuf, pszBuff);
 }
 strcat (probuf, "\n");

 // Make sure we have an entry for StartupBat
 pF = get_filedelta (StartupBat);

 // probuf contains the QCACHE line.  If we are to put it in QUtil.bat,
 // (possibly creating QUtil in the process) we'll plunk it in there
 // now and construct a new probuf.  If Qutil is not already in
 // AUTOEXEC, we need to stick it in there.
 if (key == RESP_THIS) {
	update_qutil (BT_QCACHE);
 } // Put QCACHE in this section only

 // We need to cruise through AUTOEXEC.BAT twice.  First, we check for
 // QCACHE or OLDQCACHE present.  If not found, we go through a second
 // time, looking for an unrecognized command to stick QCACHE in front of.
 // The first time through is really unnecessary paranoia; if QCACHE or
 // SMARTDRV is already there, we wouldn't be here.  Besides, we don't
 // handle converting from all sections to this section (and vice versa).
 if (autox_fnd) {
   reset_batch (key == RESP_THIS ? BT_QUTIL : BT_QCACHE);
   if (!process_stream (pszInName = get_inname (pF), "nul", find_batline)) {
	(void) process_stream (pszInName, get_outname (pF), place_qcache);
   } // Neither QCACHE nor OLDQCACHE found in AUTOEXEC.BAT
   clear_batch ();
 } // AUTOEXEC.BAT exists
 else {
	FILE *fp;

	(void) get_outname (pF);
	fp = cfopen (pF->pszOutput, "at", 1);
	cfprintf (fp, probuf);
	fclose (fp);
 } // No AUTOEXEC.BAT

} // install_qcache ()
#pragma optimize ("",on)

/********************** FIND_SETPATH **********************************/
// Look through AUTOEXEC.BAT for a PATH or SET PATH= statement.  If found,
// insert probuf immediately after it.
int find_setpath (FILE *fp, char *line, long streampos)
{
  static int ret = 0;
  char	buff[256];
  char	*pbuff, *command, *arg;

  if (line) {
	strncpy (buff, line, sizeof(buff)-1);
	buff[sizeof(buff)-1] = '\0';
	cfputs (line, fp);
	// Skip over leading @; we can't use strtok() since it may be in the
	// pathname (it is a valid filename component).
	for (pbuff = buff; *pbuff && strchr (" \n\t@", *pbuff); pbuff++) ;
	if (	(command = strtok (pbuff, ValPathTerms)) &&
		(arg = strtok (NULL, ValPathTerms))) {
	  if (	!ret &&
		(!stricmp (command, "path") ||
		 (!stricmp (command, "set") && !stricmp (arg, "path")) ) ) {
		ret = 1;	// Found our boy
		cfputs (probuf, fp);
	  } // Name matches
	} // Got a command
	return (0);	// Keep on truckin'
  } // not EOF
  else return (ret);	// Return saved result

} // find_setpath ()

/********************** CHECK_MAXPATH **********************************/
// Make sure we're on the path.
// Search environment variable PATH for OEM_FileName.  If found,
// we're OK.
// Search AUTOEXEC.BAT for a PATH or set PATH= statement.  If we find one,
// put a PATH %PATH%;c:\386max after it.  If we don't find one, put a PATH
// statement in via place_qcache()
// Note that if there are multiple MAX directories, we'll only put in a
// path to the first one unless there's no active PATH statement at this
// time.
void check_maxpath (void)
{
  char *infile, *outfile;
  char dirname[_MAX_DIR];
  char *lastchar;
  FILEDELTA *pF;
  int res;

  pF = get_filedelta (StartupBat);
  (void) chdir ("\\");
  _searchenv (OEM_FileName, "PATH", pszBuff);
  if (!(pszBuff[0])) {

	// Check to ensure there's not a PATH statement that didn't get
	// processed (perhaps we booted with F5).
	reset_batch (BT_PATH);
	res = process_stream (StartupBat, "nul", find_batline);
	clear_batch ();
	if (res) return;

	// We're committed to making changes now.
	infile = get_inname (pF);	// AUTOEXEC.BAT or AUTOEXEC.ADD
	outfile = get_outname (pF);	// AUTOEXEC.ADD or NULL

	// If there's an existing PATH or SET PATH, we'll insert
	// PATH %PATH%;c:\386max after it.  Otherwise, we need to
	// blast a PATH statement in.
	strcpy (dirname, dest_subdir);

	// Clobber trailing backslash
	lastchar = dirname + strlen(dirname) - 1;
	if (*lastchar == '\\') *lastchar = '\0';
	sprintf (probuf, "PATH %%PATH%%;%s\n", dirname);
	if (!autox_fnd || !process_stream (infile, outfile, find_setpath)) {

	  if (!autox_fnd) {
		FILE *fp;

		fp = cfopen (pF->pszOutput, "at", 1);
		cfprintf (fp, probuf);
		fclose (fp);
	  } // No StartupBat exists
	  else {
		sprintf (probuf, "PATH %s\n", dirname);
		(void) process_stream (infile, outfile, place_qcache);
	  } // Add PATH statement to existing StartupBat

	} // Didn't find existing PATH or no StartupBat

  } // Didn't find 386max.sys in the path

} // check_maxpath ()

//********************* check_rdonly () **********************************
// Issues error message and returns 1 if target file is read-only on either
// actual or swapped boot drive.
int check_rdonly (char *pathname)
{
	int rtn, i;
	struct find_t info;
	char filespec[80];

	strcpy (filespec, pathname);
	for (i=0; i<2; i++) {

#ifdef STACKER
		if (i)	filespec[0] = CopyBoot;
		else
#endif
			filespec[0] = boot_drive;

		strupr(filespec);
		rtn = _dos_findfirst(filespec,_A_HIDDEN | _A_RDONLY |
				_A_SYSTEM,&info);
		if (rtn == 0 && (info.attrib & _A_RDONLY)) {
			do_textarg(1,filespec);
			do_error(MsgFileRdOnly,0,FALSE);
			return 1;
		}

#ifdef STACKER
		if (SwappedDrive <= 0 || !CopyBoot)
#endif
			break;

	} // for ()

	return 0;
} // check_rdonly()

//********************* edit_maxcfg () *********************************
// Check maximize.cfg for the specified keyword.  If it exists and add
// is true, do nothing.  If it exists and add is false, delete it.
// Add it with the specified comment if it does not exist and add is true.
// If add is false and file does not exist, return quietly.
void edit_maxcfg (char *keyword, char *comment, int add)
{
 char	temp[MAXPATH+1],	// Input pathname
	temp2[MAXPATH+1];	// Output pathname
 char	*kwd;
 FILE	*fin, *fout;
 int	ren_file;

 sprintf (temp,  "%s" MAXIMIZE_CFG, dest_subdir);
 sprintf (temp2, "%smaximize.$$$", dest_subdir);

 // If file does not exist, create it or ignore it as the case may be...
 if (!(fin = cfopen (temp, "r", 0))) {

	if (add) {

		fout = cfopen (temp, "w", 1);
		cfprintf (fout, "%s%s", keyword, comment);
		fclose (fout);

	} // Adding line to MAXIMIZE.CFG

	return;

 } // File does not exist


 // Copy lines.  If keyword is found, either don't add it or don't copy it.
 fout = cfopen (temp2, "w", 1);
 ren_file = 0;
 while (cfgets (pszBuff, BUFFSIZE-2, fin)) {
	if (!strchr (pszBuff, '\n')) strcat (pszBuff, "\n");
	for (kwd = pszBuff; *kwd && strchr (" \t\n", *kwd); kwd++) ;
	if (!strnicmp (kwd, keyword, strlen (keyword))) {
	  if (add) goto EDIT_MCEXIT;
	} // Matched our keyword
	else cfputs (pszBuff, fout);
 } // while not EOF
 ren_file = 1;
 if (add) cfprintf (fout, "%s%s", keyword, comment);

EDIT_MCEXIT:
 fclose (fin);
 fclose (fout);

 if (ren_file) {
	(void) unlink (temp);
	if (rename (temp2, temp)) error (-1, MsgFileRwErr, temp);
 } // Changes made; rename output
 else (void) unlink (temp2);

} // edit_maxcfg()

typedef struct tagRECT
{
    int left;
    int top;
    int right;
    int bottom;
} RECT;

typedef struct tagPOINT
{
    int x;
    int y;
} WPOINT;

typedef struct tagGroupHeader {
  char cIdentifier[4];		// Should be "PMCC"
  WORD wCheckSum;		// Negative checksum on all words in file
  WORD cbGroup; 		// Offset within file of tail structure
  WORD nCmdShow;		// Display mode (SW_HIDE, SW_SHOWNORMAL, etc)
  RECT rcNormal;		// Group window coordinates
  WPOINT ptMin; 		// Location of lower left corner w.r.t. parent
  WORD pName;			// Offset within file of ASCIIZ group name
  WORD wLogPixelsX;		// Horizontal res of display icons created for
  WORD wLogPixelsY;		// Vertical res ...
  BYTE wBitsPerPixel;		// Bits per pixel of icon bitmaps
  BYTE wPlanes; 		// NUMPLANES in icon bitmaps
  WORD wUnk;			// Who the hell knows?
  WORD cItems;			// Number of ITEMDATA offsets in rgiItems[]
  WORD rgiItems[0];		// ITEMDATA structure offsets (valid if != 0)
} GROUPHEADER;

// Values for TAGDATA.wID:
#define TWID_EXTID	0x8000	// Extension ID
#define TWID_PATH	0x8101	// rgb[] contains ASCIIZ startup directory
				// (with trailing backslash)
#define TWID_HOTKEY	0x8102	// rgb[] contains WORD shortcut key
#define TWID_SHOWMIN	0x8103	// rgb is empty; show minimized
#define TWID_EOF	0xffff	// End of tag structures

typedef struct tagTagData {
  WORD wID;			// Values defined above
  WORD wItem;			// Index of ITEMDATA structure
  WORD cb;			// Size of TAGDATA structure in bytes
  BYTE rgb[0];			// Array of length cb - sizeof (TAGDATA)
} TAGDATA;

typedef struct tagItemData {
 WPOINT pt;			// Coordinates for lower left corner of icon
 WORD iIcon;			// Index for icon within .EXE file
 WORD cbResource;		// Bytes in icon resource header
 WORD cbANDPlane;		// Bytes in AND mask for icon
 WORD cbXORPlane;		// Bytes in XOR mask for icon
 WORD pHeader;			// Offset within file of resource header for icon
 WORD pANDPlane;		// Offset within file of AND mask for icon
 WORD pXORPlane;		// Offset of XOR mask for icon
 WORD pName;			// Offset within file of ASCIIZ item name
 WORD pCommand; 		// Offset within file of ASCIIZ executable
 WORD pIconPath;		// Offset within file of ASCIIZ icon resource
} ITEMDATA;

// Update negative checksum
WORD ud_csum (WORD seed, BYTE *data, WORD len)
{
  WORD wi;

  for (wi=0; wi < len; wi += 2, data += 2) seed -= *((WORD *) data);

  return (seed);
} // ud_csum ()

// Write a resource to file and update pointer
int wwrite (int fh, char *fdata, WORD *pwOff, WORD len, WORD *pwCsum)
{
  WORD fpos;
  int ret;

  // If len == 0, calculate length of ASCIIZ string (including NULL)
  if (!len) len = strlen (fdata + *pwOff) + 1;

  // Get bytes to write, padding to word boundary
  len = (len + 1) & 0xfffe;

  fpos = (WORD) tell (fh);			// Get new file position
  ret = write (fh, fdata + *pwOff, len);	// Write it out
  *pwCsum = ud_csum (*pwCsum, fdata + *pwOff, len); // Update checksum
  *pwOff = fpos;				// Save new resource offset

  return (ret);
} // wwrite ()

#pragma optimize("",on)

