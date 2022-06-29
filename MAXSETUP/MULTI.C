// $Header:   P:/PVCS/MAX/MAXSETUP/MULTI.C_V   1.5   30 May 1997 11:53:02   BOB  $
//------------------------------------------------------------------
// multi.c
// created by Peter Johnson (PETERJ) 1/19/96
// Copyright (C) 1994-96 Qualitas, Inc. All rights reserved.
// created by stealing it from Henry's DOS version for 386Max install.
// Copyright (C) 1992-96 Qualitas, Inc.  All rights reserved.
//------------------------------------------------------------------
// Install program Multi-config routines.
//------------------------------------------------------------------
#define STRICT
#include <windows.h>
#define WINDOWS_INCLUDED

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <direct.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>

#include <mbparse.h>
#include <myalloc.h>
#include "multicom.h"
#include "messages.h"

#define FILECOUNT 50
#define MBBUFFSIZE 256
#define MAXFILECOUNT 255
#define BUFFSIZE	512

#define DEFMAXRECURSION 7		/* Max. levels of recursion for */
				    /* batch files */
char *prevlevels[DEFMAXRECURSION];  /* Previously processed files */
int MaxRecursion = DEFMAXRECURSION; /* May be reduced depending on file */
				    /* handles available. */

    // Special flag for process_stream: return immediately.
int ForceReturn;

    // Global flag indicating whether we've changed the file
BOOL bConfigChanged = FALSE;

LPSTR szCommon = "common";

LPSTR szDirTemplate="C:\\";

    // new file name
LPSTR szNewFile = "qmconfig";

    // configuration file name
LPSTR  szSetCfg = "setupdos.cfg";

    // Valid pathname terminators
char *ValPathTerms = " \t=\"/[]|;,+<>\n";

    // Comment characters
char *QComments = ";*" ;

    // *.CFG file keyword delimiters
char *CfgKeywordSeps = " \t=,-\n;*";

    // *.PRO file keyword delimiters
char *ProKeywordSeps = " \t=,\n;*" ;

char *EXCPTN_LIST[] = { "EMMXXXX0", "INBRDAT%", "INBRDPC%",  NULL };

    // Name of driver file (e.g. "386MAX.SYS")
char *OEM_FileName=MAX_FILENAME;

    // Name of file w/o ext (e.g. "386MAX")
char *OEM_ProdFile=MAX_PRODFILE;

    // Old name of driver file
char *OEM_OldName=MAX_OLDNAME;

    // Basename for loader (386load, Move'EM)
char *OEM_LoadBase = MAX_LOADBASE;

    // Drive letter to copy changed CONFIG.SYS to.
char CopyBoot = '\0';

    // Drive letter for parallel MAX dir #1.
char CopyMax1 = '\0';

    // Drive letter for parallel MAX dir #2.
char CopyMax2 = '\0';

//------------------------------------------------------------------
// Singly linked list for reading SETUPDOS.CFG into memory
typedef struct cfg_struct {
 char flag;		// Flags: 'd' if it should be before MAX,
		// 'p' if partition driver (before MAX IF
		// we install MAX on a drive other than boot).
		// 'm' if EMS 4.0 driver needed before Move'em.mgr
		// 'x' if XMS driver which should go before move'em
 char name[9];	// Basename part of file (w/o extension)
 char ext[5];	// File extension ('.' included)
 struct cfg_struct *next; // pointer to next or NULL if end
} CFG, *CFGp;

    // Head of SETUPDOS.CFG list
CFGp cfgList= (CFGp)NULL;
//------------------------------------------------------------------

char szBootDir[ _MAX_PATH + 1 ];
char wrkdrive[_MAX_DRIVE];
char wrkdir[_MAX_DIR];
char wrkname[_MAX_FNAME];
char wrkext[_MAX_EXT];
char pszBuff[ _MAX_PATH + 1 ];
char cfopen_path[ _MAX_PATH + 1 ];
char dest_subdir [_MAX_PATH + 1] = MAX_INIDIR;
char drv_path[ _MAX_PATH];		// complete path
static char mwork2[MAXPATH+1] = { 0 };

    // config.sys filename
char con_dpfne[_MAX_PATH + 1];

    // 386max.pro filename
char pro_dpfne[_MAX_PATH + 1];

    // Times we've parsed CONFIG.SYS
int	 ParsePass;

CFGTEXT *CfgSys = NULL; 	// Start of CONFIG.SYS linked list 2 in memory

CFGTEXT *MAXLine, *InsertLine, *LastLine;

BOOL FreshInstall = TRUE;	/* FALSE if MAX was already in CONFIG.SYS */

    // Name of MultiBoot section to process
char *MultiBoot = NULL;

    // Previous memory manager line from CONFIG.SYS
char *OldMMLine = NULL;

    // line for Stacks=0,0
char *StacksLine = NULL;

	// Head of changes gotten from STRIPMGR
FILEDELTA *pFileDeltas = NULL;

char cBootDrive;

extern CONFIGLINE FAR *Cfg;

void edit_batfiles (void);
extern char get_bootdrive(void);
extern void set_exename( char *, char * );
extern void get_exepath( char *, int );
extern void truename( char *path );
extern int truename_cmp( char *, char *);
extern int FileCopy( char *, char * );

#ifdef __cplusplus
extern "C" {
#endif

//------------------------------------------------------------------
// Calls my_malloc() for the requested size.  If successful, allocated memory
// is filled with NULL, otherwise call error(-1).
//------------------------------------------------------------------
void *get_mem (size_t s)
{
  void *ret;

  if (ret = my_malloc (s))	{
      memset (ret, 0, s);
  } else {
      MessageBox( NULL, szMsg_Mem, NULL, MB_OK );
  }

  return (ret);
} // get_mem ()
//------------------------------------------------------------------

//------------------------------------------------------------------
// Same as strdup(), but quits if no memory
char *str_mem (char *str)
{ return (strcpy (get_mem (strlen (str)+1), str)); }
//------------------------------------------------------------------

//------------------------------------------------------------------
void	 do_backslash ( char *temp )
{
int	len;

    len = strlen (temp);
    if (temp[len-1] != '\\') {
	temp[len] = '\\';
	temp[len+1] = 0;
    } // End IF

} // End do_backslash

//------------------------------------------------------------------
// Strip trailing LF.  Used by parse_restore ().
//------------------------------------------------------------------
static void near clobber_lf (char *buff)
{
  char *lf;

  if (lf = strrchr (buff, '\n')) *lf = '\0';

} // clobber_lf ()

//------------------------------------------------------------------
// Replacement for fopen().  Saves filename used in open for error messages.
// While this may not always be accurate (as when two files are open), it
// at least gives us a hint where the error took place.
//------------------------------------------------------------------
FILE *cfopen (char *filename, char *mode, int abort)
{
    FILE *ret;

    strcpy (cfopen_path, filename);
    ret = fopen (filename, mode);
    if (!ret && abort) {
	char szT[_MAX_PATH + 80 ];
	wsprintf( szT, szFmt_RWErr, cfopen_path );
	MessageBox( NULL, szT, NULL, MB_OK );
    }

    return (ret);

} // cfopen ()


//------------------------------------------------------------------
// Replacement for fgets().  Checks for error on file stream, since fgets()
// returns NULL when either an error or EOF occurs.  Usually it'll be an
// EOF, but we'll bomb out if an error occurs.  Note that buffsize should
// be sizeof(buff)-1.
//------------------------------------------------------------------
char *cfgets (char *buff, size_t buffsize, FILE *fp)
{
  char *ret;

  ret = fgets (buff, buffsize, fp);
  if (ret) {
	buff[buffsize] = '\0';  // Make sure it's NULL-terminated
  } // Read OK
  else {
	if (ferror (fp)) {
	char szT[_MAX_PATH + 80 ];
	wsprintf( szT, szFmt_RWErr, cfopen_path );
	MessageBox( NULL, szT, NULL, MB_OK );
    }
  } // Read failed - check for error or EOF

  return (ret);

} // cfgets ()

//------------------------------------------------------------------
// Replacement for fputs().  Abort with error message if write failure.
//------------------------------------------------------------------
void cfputs (char *buff, FILE *fp)
{
    if (fputs (buff, fp)) {
	if (ferror (fp)) {
	    char szT[_MAX_PATH + 80 ];
	    wsprintf( szT, szFmt_RWErr, cfopen_path );
	    MessageBox( NULL, szT, NULL, MB_OK );
	}
    }
} // cfputs ()

//------------------------------------------------------------------
// Return 1 if another FILEDELTA record has a matching .add or backup file,
// otherwise returns 0.
//------------------------------------------------------------------
int ext_exists (char *addname, FILEDELTA *pExcept)
{
  FILEDELTA *pF;

  for (pF = pFileDeltas; pF; pF = pF->pNext)
    if (pF != pExcept &&
	pF->pszOutput &&
	(!stricmp (addname, pF->pszOutput) ||
	 !stricmp (addname, pF->pszBackup))	)
			return (1);

  return (0);

} // ext_exists ()

//------------------------------------------------------------------
// Copy a file; if it fails, abort with error message
// Make sure we aren't copying a file over itself; some idiots copy
// the distribution disk files into the c:\386max directory and then
// run INSTALL.
//------------------------------------------------------------------
void copy_file (char *srcpath, char *dstpath)
{
    if (truename_cmp (srcpath, dstpath)) {
	if ( FileCopy( dstpath, srcpath ) < 0) {
	    char szT[_MAX_PATH + 80 ];
	    wsprintf( szT, szFmt_RWErr, srcpath );
	    MessageBox( NULL, szT, NULL, MB_OK );
	}
    }
} // copy_file ()

//------------------------------------------------------------------
// Construct *.add and *.dif names for a file (if they don't already exist).
// Return a pointer we can use for stream processing; NULL
// if the .add filename has been created already, otherwise
// the name of the .add file.
// This function should NOT be called unless we ARE GOING TO
// write to the file.
// dest_subdir MUST be valid!!!
//------------------------------------------------------------------
char *get_outname (FILEDELTA *pF)
{
  char buff[128];
  int extoff;
  char fdrive[_MAX_DRIVE], fdir[_MAX_DIR], fname[_MAX_FNAME], fext[_MAX_EXT];
  char *smem, *osmem;
  int smemavail, osmemavail;
  int smemalloc;
  int ext;

  if (!pF->pszOutput) {
	do_backslash (dest_subdir);
	_splitpath (pF->pszPath, fdrive, fdir, fname, fext);
	sprintf (buff, "%s%s.", dest_subdir, fname);
	extoff = strlen (buff); // Get offset of '\0'
	strcat (buff, "ADD");

	osmem = smem = pF->pszBackup;	// Get memory we set aside for paths
	osmemavail = smemavail = (MAXPATH+1)*3; // How much space remains

	// Now that we're handling other batch files, we need
	// to avoid conflicts between file basenames.
	// Murphy sez:	If there's a dumb trick you think no
	// one will use and you therefore don't need to support,
	// someone will use it.
	for (ext=0; ext_exists (buff, pF) && ext < 100; ext++) {
	  sprintf (&buff[extoff], "A%02d", ext);
	} // Find a .add extension not already in use

	strcpy (pF->pszOutput = smem, buff);
	smemalloc = strlen (buff) + 1;	// Number of bytes we'll use
	smem += smemalloc;
	smemavail -= smemalloc;

	if (ext) sprintf (&buff[extoff], "D%02d", ext);
	else	strcpy (&buff[extoff], "DIF");
	strcpy (pF->pszDiff = smem, buff);
	smem += smemalloc;
	smemavail -= smemalloc;

	// Use .SAV for backup extension the first time around
	strcpy (&buff[extoff], "SAV");
	if (ext_exists (buff, pF) || !access (buff, 0)) {
	  for (ext=0; ext < 1000; ext++) {
	   sprintf (&buff[extoff], "%03d", ext);
	   // Make sure it's not used by another, and it doesn't
	   // exist on disk.
	   if (!ext_exists (buff, pF) && access (buff, 0)) break;
	  } // Find a backup extension we can use
	} // .SAV exists or is used by another file
	strcpy (pF->pszBackup = smem, buff);
	smemavail -= smemalloc;

	// Ignore the result - we're shrinking to release the part
	// we didn't need.
	if (smemavail > 0) realloc (osmem, osmemavail - smemavail);

	return (pF->pszOutput);

  } // Create .add, .dif and backup filenames

  return (NULL);

} // get_outname ()

//------------------------------------------------------------------
// Returns keyword (DEVICE, INSTALL, SHELL, DOS, etc)
//------------------------------------------------------------------
char *keyword_part (CFGTEXT *p)
{
  char buff[512],*tok1;

  strncpy (buff, p->text, sizeof(buff)-1);
  buff[sizeof(buff)-1] = '\0';
  tok1 = strtok (buff, ValPathTerms);

  if (tok1) {
	strcpy (mwork2, tok1);
  } // Line is not blank
  else {
	strcpy (mwork2, "");
  }
  return (mwork2);
} // keyword_part ()

//------------------------------------------------------------------
// Returns the path part of a DEVICE, INSTALL, or SHELL= statement
// If it's 386LOAD, skip to the prog= argument.
//------------------------------------------------------------------
char *MBpath_part (CFGTEXT *p)
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

} // MBpath_part ()

//------------------------------------------------------------------
// Returns the file basename.ext part of a DEVICE= or INSTALL= statement
// If it's 386LOAD, skip to the prog= argument.
//------------------------------------------------------------------
char *MBfname_part (CFGTEXT *p)
{
  char	*pathp,
	fndrive[_MAX_DRIVE],
	fname[_MAX_FNAME],
	fext[_MAX_EXT];

  if (pathp = MBpath_part (p)) {
	_splitpath (pathp, fndrive, mwork2, fname, fext);
	sprintf (mwork2, "%s%s", fname, fext);
	return (mwork2);
  }
  else	return (NULL);

} // MBfname_part ()

//------------------------------------------------------------------
// Returns the pathname of the pro= file on the command line (if any).
// If none found, returns NULL.
//------------------------------------------------------------------
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

//------------------------------------------------------------------
// Read SETUPDOS.CFG and set up linked list cfg.
// If fromexe, we look for SETUPDOS.CFG in the directory SETUP.EXE
// was started from.  This allows a customized SETUPDOS.CFG to be placed
// on the distribution floppy or a network directory.
//------------------------------------------------------------------
void read_cfg (BOOL fromexe)
{
    FILE *cfgfile;
    char *semicol,*warg1,*warg2;
    CFGp wcfg, pcfg;

    if (fromexe) {
	get_exepath (pszBuff, BUFFSIZE - 1);
    } else {
	strcpy (pszBuff, dest_subdir);
    }

    cfgList = pcfg = wcfg = NULL;		// Initialize head to NULL
    strcat (pszBuff, szSetCfg );

    if (!(cfgfile = fopen (pszBuff, "r")))
	return;

    while (fgets (pszBuff, MAXPATH, cfgfile) != NULL) {

		// Kill all semicolons on sight
	if ((semicol = strpbrk (pszBuff, QComments)) != NULL)
	    *semicol = '\0';

	    // Get keyword or flag
	warg1 = strtok (pszBuff, CfgKeywordSeps);

	    // Get argument or filename.ext
	warg2 = strtok (NULL, CfgKeywordSeps);

	    // if we have a valid line...
	if (warg1 && warg2) {
	    _splitpath (warg2, wrkdrive, wrkdir, wrkname, wrkext);

		// get one CFGp unit of memory.
	    wcfg = (CFGp)get_mem(sizeof (CFG));

	    if ( pcfg == NULL) {
		cfgList = pcfg = wcfg;	// Initialize head of list
		pcfg->next = NULL;
	    } else {
		pcfg->next = wcfg;	// Link with previous entry
	    }

	    wcfg->flag = (char) tolower (*warg1);	// Store flag
	    strcpy (wcfg->name, wrkname);	// Get basename
	    strcpy (wcfg->ext,	wrkext);	// Get extension
	    wcfg->next = NULL;		// Mark as end of list
	    pcfg = wcfg;			// Keep track of previous entry

	} // fields were not empty
    } // while not EOF
    fclose (cfgfile);
} // read_cfg ()

//------------------------------------------------------------------
// Takes a pathname, gets the basename and extension, and looks for matching
// entries in SETUPDOS.CFG list.  If found, the flag of the first matching
// entry is returned, otherwise 0 is returned.
//------------------------------------------------------------------
char cfg_flag (char *pathname)
{
    CFGp wcfg;
    char retval;

	// Get basename and ext components for search
    _splitpath (pathname, wrkdrive, wrkdir, wrkname, wrkext);

	// Go through the list till end or we get a hit
    for (	wcfg = cfgList, retval = 0;
	    wcfg != NULL;
	    wcfg = wcfg->next ) {

	if (!strcmpi (wrkname, wcfg->name) && !strcmpi (wrkext, wcfg->ext)) {
	    retval = wcfg->flag;
	    break;
	}
    } // for ()

    return (retval);
} // cfg_flag()
//------------------------------------------------------------------

//------------------------------------------------------------------
// Find the record for this file or add it if it doesn't exist already.
//------------------------------------------------------------------
FILEDELTA *get_filedelta (char *pszPath)
{
  FILEDELTA *pRet;
  FILEDELTA *pFLast;

	    // Search the list (if it exists) for a matching file
    for ( pRet = pFLast = pFileDeltas;
	  pRet && stricmp (pszPath, pRet->pszPath); pRet = pRet->pNext) {
	  pFLast = pRet;
    }

    if (!pRet) {
	    // Initial FILEDELTA creation happens here.
	pRet = get_mem( sizeof(FILEDELTA) );

	pRet->pszPath = str_mem (pszPath);

	    // For the show changes screen
	_strupr (pRet->pszPath);

	if (pFLast)	{
	    pFLast->pNext = pRet;
	} else {
	    pFileDeltas = pRet;
	}
	    // Allocate space for all paths now to avoid heap fragmentation later
	    // pszOutput, pszDiff, and pszBackup -- we'll shrink it later
	pRet->pszBackup = get_mem ((MAXPATH+1)*3);
    } // Didn't find a match

    return (pRet);
} // get_filedelta ()

//---------------------------------------------------------
// Check specified device pathname.  If the IOCTL name is in the exception
// list, or if the IOCTL name is all 0's and there's an "EMM" in the file
// basename, it's an exception to the rule.  MAX can load after this driver,
// so we return 1.  Otherwise, we return 0 (MAX should load before this
// driver).
// We only call this function AFTER we've ascertained that this is NOT
// our OEM_FileName driver, nor is it listed in SETUPDOS.CFG.
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

//------------------------------------------------------------------
// Look for an OEM_FileName or OEM_OldName line in CONFIG.SYS.	Also troll
// for the first line that must come after us.
//------------------------------------------------------------------
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

  if (!stricmp (keyword_part (p), "device")) {

    foundmax = 0;
    if (!MAXLine) {
	_splitpath (MBpath_part (p), fdrive, fdir, fname, fext);

	if (!stricmp (tmp = MBfname_part (p), OEM_FileName))	foundmax = 1;
	else if (!stricmp (tmp, OEM_OldName)) {

	  foundmax = 1;

	  // We need to reconstruct the filename part of the line
	  strcpy (fext, strchr (OEM_FileName, '.'));
	  memset (fname, 0, sizeof(fname));
	  strncpy (fname, OEM_FileName, strlen(OEM_FileName)-strlen(fext));

	  // Now reconstruct the CONFIG.SYS line with identical leading
	  // space, DEVICE =, and trailing arguments.
	  strcpy (buffer, p->text);

	  if (device_name = strstr (buffer, MBpath_part (p))) {

		*device_name = '\0'; // Clobber it

	  } // Found original device name
	  else {

		strcpy (buffer, "Device = ");

	  } // Didn't find device name (???)

	  _makepath (&(buffer [strlen (buffer)]), fdrive, fdir, fname, fext);
	  strcat (buffer, strpbrk (strstr (p->text, MBpath_part (p)),
		ValPathTerms));
	  free (p->text);
	  p->text = str_mem (buffer);
      bConfigChanged = TRUE;

	} // Device=386max.sys found but installing Bluemax.sys (or vice versa)

	if (foundmax) {
	  MAXLine = p;

	  device_name = strstr (p->text, MBpath_part (p)); // c:\386max\386max.sys
	  prepro = strpbrk (device_name, ValPathTerms); // " RAM=xxxx PRO=..."
	  if (!(profile_name = pro_part (p))) {
		sprintf (pro_dpfne, "%s%s%s.pro", fdrive, fdir, fname);
	  } // No profile defined
	  else {
		strcpy (pro_dpfne, profile_name);
	  } // Pre-existing profile found

	  *device_name = '\0';          // Terminate "   device = " part
	  sprintf (buffer, "%s%s%s%s%s pro=%s\n", p->text,
				fdrive, fdir, fname, fext,
				pro_dpfne);
	  my_free (p->text);
	  p->text = str_mem (buffer);
      bConfigChanged = TRUE;
	} // Found a 386MAX line

    } // 386MAX/BlueMAX line not found yet

    if (!InsertLine && !foundmax) {

      // If this line is a device not listed in SETUPDOS.CFG, save it
      switch (cfg_flag (MBpath_part (p))) {
	case 'p':               // Load after this one if not installed on boot
	  sprintf (buff2, "%c:\\*.*", cBootDrive);
	  strcpy (buffer, drv_path);
	  truename (buffer);
	  truename (buff2);
	  if (buffer[0] == buff2[0]) goto CFGSUB_INSERT;
	case 'd':               // Always load after this one
	  goto CFGSUB_EXIT;
	default:
	  break;
      } // end switch ()

      // Check for IOCTL names matching "EMMXXXX0" or "%INBRDAT", etc.
      // If it's another EMS driver, STRIPMGR will blow it away...
      if (is_exception (MBpath_part (p))) goto CFGSUB_EXIT;

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


//------------------------------------------------------------------
// Called recursively.	Starts at a given line and walks through
// CONFIG.SYS, paying attention only to lines that match the current
// owner (MultiBoot only).  INCLUDE= statements are ignored, since
// we've already expanded any INCLUDE or common sections containing
// device drivers.
// Returns 0 if we should continue recursion, otherwise 1.
//------------------------------------------------------------------
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



//------------------------------------------------------------------
// Add a line from the STRIPMGR /e output file to our list of deltas.
// We'll use these in parsing CONFIG.SYS, and to edit batch files.
//------------------------------------------------------------------
void add_stripdelta (	char *pszPath,		// File path
			char *pszMatch, 	// What to find
			char *pszReplace,	// What to replace with
			DWORD dLine)		// Original line offset
{
    FILEDELTA *pF;
    LINEDELTA *pL, *pLNew;

	// creates FILEDELTA on the first try.
    pF = get_filedelta( pszPath );

    pL = pF->pLines;
    pLNew = get_mem (sizeof(LINEDELTA));
    if ( !pL ) {
	pF->pLines = pLNew;
    } // List is empty
    else {
	    // We'll keep everything sorted by logical offset.
	while (pL->pNext && dLine >= pL->dLine) pL = pL->pNext;
	pLNew->pNext = pL->pNext;	// NULL unless we're inserting
	pL->pNext = pLNew;
    }	   // Find end of line delta list or an insertion point

    pLNew->pszMatch = str_mem (pszMatch);
    if (pszReplace) pLNew->pszReplace = str_mem (pszReplace);
	// else pLNew->pszReplace = NULL;
    pLNew->dLine = dLine;

} // add_stripdelta ()


//------------------------------------------------------------------
// parse the stripmgr.out file.
//------------------------------------------------------------------
#define PS_BUFFSIZE 512
void parse_striplist( LPSTR stripmgrlist )
{
    FILE *fin;

    char buff[ PS_BUFFSIZE + 1];

    char pathname[ _MAX_PATH + 1];
    char stripaction;
    char *matchline, *replaceline;
    WORD lineoff;

    fin = cfopen ( stripmgrlist, "r", 1 );

    while ( cfgets (buff, PS_BUFFSIZE, fin )) {

    sscanf (buff, "%s %c %u\n", pathname, &stripaction, &lineoff);

    if (pathname[0] == '*') break;

	  // We have two types of lines we're interested in:
	  // pathname c lineoff
	  // pathname r lineoff
	  // If c is specified, two lines follow, a match and a replacement.
	  // If r is specified, one line follows, containing a match.
	  // All matches are case sensitive.
	  // The original logical line offset is used for processing
	  // batch files, and the match / replace strings are used for
	  // confirmation and length matching.
	  // In CONFIG.SYS, line offsets are ignored since we might be
	  // relocating all over the place.
    cfgets (buff, PS_BUFFSIZE, fin);
    clobber_lf (buff);
    matchline = str_mem (buff);

    if (stripaction == 'c') {
	    cfgets(buff, PS_BUFFSIZE, fin);
	    clobber_lf (buff);
	    replaceline = str_mem (buff);
    } // Get line to change to
    else replaceline = NULL;

	  // Add to list of file changes
    add_stripdelta (pathname, matchline, replaceline, lineoff);

	} // Not end of file

    fclose (fin);
}

//------------------------------------------------------------------
/* Callback query function for config_parse() */
/* We need to relocate all DEVICE= statements. */
/* We'll parse CONFIG.SYS twice: once to find a preexisting MAX line, */
/* and a second time to relocate all DEVICE= statements if MAX wasn't found */
/* or if MAX was found in an INCLUDE= or COMMON= section. */
/* If we find a STACKS= other than 0 in the common section, we'll need */
/* to relocate it. */
/* If we have any changes for CONFIG.SYS from STRIPMGR /e, this is */
/* the place to apply them. */
//------------------------------------------------------------------

int MBCallBack (CONFIGLINE FAR *pcfg)
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

	// Copy original CONFIG.SYS line into a buffer...
    strncpy (buffer, pcfg->line, sizeof (buffer)-1);
	// and ensure a null termination.
    buffer[sizeof (buffer)-1] = '\0';

MBC_Restart:
	// get the first word...
    tok1 = strtok (buffer, ValPathTerms); // Get DEVICE or STACKS token

	// and the second word...
    tok2 = strtok (NULL, ValPathTerms); // Get first argument

	// assume tok2 has a path and disect it.
    _splitpath (tok2, drive, dir, name, ext);

	// put the extension back on the name
	// 386MAX.SYS or BLUEMAX.SYS?
    strcat (name, ext);

	// A return value, based on Multiboot.
    Truth = ( MultiBoot ? 1 : 0 );

	// if this is the second pass
	// and the line has not been "processed"...
    if ( ParsePass && !pcfg->processed) {

	    // Check for STRIPMGR changes
	pF = get_filedelta ( con_dpfne );

	if ( pL = pF->pLines ) {

		// Found CONFIG.SYS
	    for ( pL = pF->pLines;
		  pL && !(psz = strstr (pcfg->line, pL->pszMatch));
		  pL = pL->pNext) ;

	    if ( pL ) {
		    // Found a line to change
		    // Perform substitution
		retval = Truth; // Relocate this line
		pcfg->processed = 1;
		bConfigChanged = TRUE;

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

		} else {

			// if This is a "device=" line,
			// and we have not saved an old Mem Mgr line...
			// and this line is not "HIMEM.SYS"...
		    if (pcfg->ID == ID_DEVICE && !OldMMLine
				&& stricmp (name, "HIMEM.SYS")) {

			    // Save old memory manager line if not HIMEM.SYS
			    // ( for some unknown reason... )
			OldMMLine = str_mem (pcfg->line);
		    }
			// Delete line altogether
		    pcfg->killit = 1;
		    bConfigChanged = TRUE;
		}
	    }
	}
    }

    if (!(MAXFound & MAXNotInclude) && pcfg->line && pcfg->ID == ID_DEVICE) {

	if (tok1 && !strnicmp (tok1, "device", 6) && tok2) {

		// if this is the second pass...
	    if (ParsePass) {

		    // if type is 'D' then it's not one we go after
		    // in that case we're done with this line.
		if ( cfg_flag (tok2) != 'd') return (Truth);

	    } // Now we're looking for a place to put MAX

	    if (!stricmp (name, OEM_FileName)  ||
		!stricmp (name, OEM_OldName)) {

		MAXFound = 1;
		if (pcfg->Owner != ActiveOwner) MAXNotInclude = 0;

	    } // Found 386MAX.SYS or BlueMAX.sys

	} // Found DEVICE=something
    } else {
	if (pcfg->ID == ID_STACKS) {
		// Relocate if not STACKS=0[,0]
	    if (strcmp (tok2, "0")) return (Truth);
	}
    }
	// Relocate line if STRIPMGR changes made
    return (retval);

} // MBCallBack ()

//------------------------------------------------------------------
// Writes a copy of the edited config.sys into a unique filename in the
// Boot directory. The user can then choose to have it automatically
// replaced or to do it manually from the copy.
// bChanged = Return flag TRUE=a new file was written.
// szExe = the path\name of this executable.
// szFigFile = the path\name of the Config.sys file to edit.
// szStrip = stripmgr.out file.
// szMenu = the multiconfig section. Empty string implies [common].
// szDst = The MAX installation directory.
// szTempFile = Returned path\name string for changes.
//------------------------------------------------------------------
int CALLBACK
MultiCfgEdit( BOOL *bChanged, LPSTR szExe, LPSTR szFigFile, LPSTR szStrip, LPSTR szMenu, LPSTR szDst, LPSTR szTempFile )
    {
    int fhOut;
    int retval = 0;
    int con_fnd;
    int nI;
    char *pText, *pEOL;

	FILE *config;
    FILEDELTA *fd;
	char buff[1024];
    char buffer[ 265 ];
    char dest_config[ _MAX_PATH + 1];
	char *pbuff;
    char *pszOutName;
	CFGTEXT *p, *n, *inspoint;

    bConfigChanged = FALSE;
    *bChanged = FALSE;

    set_exename( szExe, "setup.exe" );

    _fstrcpy( (LPSTR)con_dpfne, (LPSTR)szFigFile );

    _fstrcpy( (LPSTR)dest_subdir, (LPSTR)szDst );
    do_backslash( dest_subdir );

	// verify that a config.sys file exists.
    if( !(con_fnd = !access (con_dpfne, 0))) {
	    // no, then go where we can make one.
	goto MB_ReadII;
    }

    if( !szMenu || (szMenu[0] == '\0') )
	{
	szMenu = szCommon;
	MultiBoot = NULL;
	}
    else
	{
	MultiBoot = szMenu;
	}

	// Get boot drive
    cBootDrive = get_bootdrive();

	// set up the root boot.
    _fstrcpy( szBootDir, szDirTemplate );
    szBootDir[0] = cBootDrive;

	// construct the temp file names.
    fd = get_filedelta( szFigFile );
	pszOutName = get_outname ( fd );
    _fstrcpy( (LPSTR)szTempFile, (LPSTR)pszOutName );

	// Parse menu - Construct the list.
	// If successful then memory has been allocated and
	// config_free is required.
    if (menu_parse( cBootDrive, TRUE ) != 0)
	{
	// Parse failed
	*bChanged = bConfigChanged = FALSE;
	return -1;
	}

	// Set current section
    if ( set_current( szMenu ) != 0 )
	{
	*bChanged = bConfigChanged = FALSE;
	config_free();
	return -1;
	} // Set common and active sections failed

    read_cfg( TRUE );

    parse_striplist( szStrip );

	// Perform the callback stuff.
    ParsePass=0;
    if ( config_parse( cBootDrive, ActiveOwner, szTempFile,
					TRUE, MBCallBack ) != 0)
	{
	    // Parse failed
	*bChanged = bConfigChanged = FALSE;
	config_free();
	return -1;
	}

	// Perform the callback stuff, phase 2.
    ParsePass=1;
    if ( config_parse( cBootDrive, ActiveOwner, szTempFile, FALSE, MBCallBack ) != 0)
	{
	    // Parse failed
	*bChanged = bConfigChanged = FALSE;
	config_free();
	return -1;
	}

	// Second config_parse should have emptied Cfg memory, but...
    if( Cfg != NULL ) {
	config_free();
    }

	// Add CONFIG.SYS and AUTOEXEC to the FILEDELTA list now so we can
	// control the order.
    (void) get_filedelta (con_dpfne);

MB_ReadII:
	// read the temp file into memory, type II.
    pbuff = buff + 2;

    if (con_fnd)
	{
	config = cfopen ( szTempFile, "r", 1);
	p = NULL;			// Previous record
	while (cfgets ( buff, sizeof(buff)-1, config ))
	    {
	    n = get_mem (sizeof (CFGTEXT));
	    if (MultiBoot)
		{
		n->ltype = buff[0];
		n->Owner = buff[1];
		}

	    n->text = str_mem (pbuff);
	    n->prev = p;
	    if (p)
		{
		p->next = n;
		}
	    else
		{
		CfgSys = n;
		}
	    p = n;
	    } // while not EOF
	fclose (config);
	} // Opened CONFIG.SYS
	else
	{
	    // Create a CONFIG.SYS with an empty line
	CfgSys = get_mem (sizeof (CFGTEXT));
	CfgSys->prev = NULL;
	CfgSys->next = NULL;
	CfgSys->text = "";
	    // set the write flag.
	bConfigChanged = TRUE;
	} // No CONFIG.SYS - create one


	// If the user specified a MultiConfig section that doesn't exist,
	// make sure it appears at the end.
    if (MultiBoot)
	{
	for (inspoint = CfgSys; inspoint && inspoint->Owner != ActiveOwner;
	     inspoint = inspoint->next)
	    {
	    LastLine = inspoint;
	    }

	if (!inspoint)
	    {
		// No section found; create one
	    inspoint = get_mem (sizeof(CFGTEXT));
	    inspoint->prev = LastLine;
	    LastLine->next = inspoint;
	    sprintf (dest_config, "\n[%s]\n", MultiBoot);
	    inspoint->text = str_mem (dest_config);
	    inspoint->Owner = ActiveOwner;
	    }
	} // MultiBoot

    MAXLine = InsertLine = NULL;
    (void) walk_cfg (CfgSys, edit_config_sub);

	// Initialize buffer with the appropriate DEVICE= line
	//  to be placed in CONFIG.SYS if none found.
    if (!MAXLine)
	{

	if( InsertLine ) {
	    for( nI=0, buff[0] = '\0';
		 ( nI < 80 ) &&
		 ( InsertLine->text[ nI ] != '\0' ) &&
		 (( InsertLine->text[ nI ] == ' ' ) ||
		 ( InsertLine->text[ nI ] == '\t' )) ; nI++ ) {
		buff[ nI ] = InsertLine->text[ nI ];
	    }
	    buff[ nI ] = '\0';
	} else {
	    buff[ 0 ] = '\0';
	}

	sprintf ( buffer, "%sDEVICE=%s%s pro=%s%s.PRO\n", buff,
		    dest_subdir, OEM_FileName, dest_subdir, OEM_ProdFile);

	    // Convert to lowercase all but the first char
	strlwr ( &buffer[ strlen(buff) + 1 ] );

	n = get_mem (sizeof (CFGTEXT));
	n->text = str_mem (buffer);
	if (InsertLine)
	    {
	    p = InsertLine->prev;
	    n->prev = p;
	    n->next = InsertLine;
	    InsertLine->prev = n;
	    if (p) p->next = n;
	    else CfgSys = n;
	    } // Put new MAX line in before InsertLine
	else
	    {
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
	bConfigChanged = TRUE;
	} // No MAX line found
    else
	{
	FreshInstall = FALSE; // MAX was already installed
	}

	// Make sure we have Stacks=0,0
    if (!StacksLine)
	{
	n = get_mem (sizeof (CFGTEXT));

	    // Get an insertion point after the first header for our section
	for (inspoint = CfgSys; inspoint && inspoint->Owner != ActiveOwner;
	     inspoint = inspoint->next)
	    {
	    LastLine = inspoint;
	    }

	if (inspoint)
	    {
	    p = inspoint->next;
	    n->prev = inspoint;
	    n->next = p;
	    if (p) {
		for( nI=0,  buff[0] = '\0';
		     ( nI < 80 ) &&
		     ( p->text[ nI ] != '\0' ) &&
		     (( p->text[nI] == ' ' ) ||
		     ( p->text[nI] == '\t' )) ; nI++ ) {
		    buff[ nI ] = p->text[ nI ];
		}
		buff[nI]='\0';
	    } else {
		buff[0]='\0';
	    }
	    sprintf ( buffer, "%sStacks=0,0\n", buff);
	    n->text = str_mem ( buffer );;
	    inspoint->next = n;
	    if (p) p->prev = n;
	    else CfgSys = n;
	    } // found an insertion point
	else
	    {
	    n->next = LastLine->next;
	    if (n->next) n->next->prev = n;
	    n->text = str_mem ( "Stacks=0,0\n" );;
	    LastLine->next = n;
	    n->prev = LastLine;
	    LastLine = n;
	    } // Add to end

	    bConfigChanged = TRUE;
	} // Didn't find a Stacks statement

	// Report the state of change.
    *bChanged = bConfigChanged;

	// If no changes....exit.
    if ( !bConfigChanged )
	{
	_unlink( szTempFile );
	szTempFile[0] = '\0';
	retval = 0;
	goto MB_Cleanup;
	}

	// Now write modified version of CONFIG.SYS from memory.
    fhOut = _open( szTempFile, _O_CREAT | _O_BINARY | _O_RDWR | _O_TRUNC,
						    _S_IWRITE | _S_IREAD );
    if (fhOut < 0)
	{
	    // Couldn't create output file
	config_free();
	retval =  -1;
	goto MB_Cleanup;
	}

	// for all lines...
    for (p = CfgSys; p; p = p->next)
	{
	pText = p->text;

	    // remove cr/lf before writing.
	if (pEOL = strpbrk( pText, "\r\n\x1a" ))
	    {
	    *pEOL = '\0';
	    }

	_write( fhOut, pText, strlen( pText ) );
	_write( fhOut, "\r\n", 2 );
	}

    _close( fhOut );

MB_Cleanup:

    if ( CfgSys ) {
	    // move p to the end.
	for( p=CfgSys; p->next ; ) {
	    if( p->next ) {
		p = p->next;
	    }
	} // end of first for.

	    // p now points to the last element.
	for( ; p != CfgSys ; ) {
		n=p;
		p= n->prev;
		my_free( n );
	} // end of second for.
	my_free( CfgSys );
	CfgSys = NULL;
    }

    return retval;
    }

//------------------------------------------------------------------
// PROCESS_STREAM
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
//------------------------------------------------------------------
int process_stream (
	char *infile,				// File to process
	char *outfile,				// Output filename or NULL
	int (*output_unit) (FILE *,		// Output unit:
				char *, 	  // Line to send
				long))		  // Input file read offset
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

static LINEDELTA *pEditCB;

//------------------------------------------------------------------
// process_stream () callback for applying STRIPMGR changes
// to batch files.
//------------------------------------------------------------------
int edit_batsub (FILE *output, char *line, long streampos)
{
  LINEDELTA *pL;
  char *psz;

  if (!line) return (0); // Ignore EOF; we are here to take, not to give

  // Check for any changes for this line
  for ( pL = pEditCB;
	pL && pL->dLine != (DWORD) streampos;
	pL = pL->pNext) ; // for all LINEDELTA records

  if (pL && (psz = strstr (line, pL->pszMatch))) {

	if (pL->pszReplace) {

	  *psz = '\0';  // Cut out the part we're replacing
	  cfputs (line, output); // Dump start of line
	  cfputs (pL->pszReplace, output); // Dump the replacement
	  cfputs (psz + strlen (pL->pszMatch), output); // Dump what's left,
				// including trailing LF

	} // Replacing part of the line
	// else swallow the line

  } // Found a delta
  else cfputs (line, output);

  return (0);

} // edit_batsub ()

//------------------------------------------------------------------
// If we got back any changes to batch files from STRIPMGR, apply
// them before we make any other changes to batch files.
//------------------------------------------------------------------
void edit_batfiles( )
{
  FILEDELTA *pF;
  char *pszInName, *pszOutName;
  char fdrive[_MAX_DRIVE],fdir[_MAX_DIR],fname[_MAX_FNAME],fext[_MAX_EXT];

  // We've already made our changes to CONFIG.SYS
  for (pF = pFileDeltas; pF; pF = pF->pNext)
    if (stricmp (pszInName = pF->pszPath, con_dpfne) &&
	(pEditCB = pF->pLines)) {

	// Set up the .add name and create the .dif and backup names
	pszOutName = get_outname (pF);
	process_stream (pszInName, pszOutName, edit_batsub);

    } // For all files other than CONFIG.SYS with line deltas

  // Set swap parameters for CONFIG.SYS, StartupBat, and MAX.PRO
  pF = get_filedelta (con_dpfne);
  pF->swap1 = CopyBoot;

  // We won't attempt to copy StartupBat to alternate drive unless
  // it's in the root directory.
  pF = get_filedelta (StartupBat);
  _splitpath (pF->pszPath, fdrive, fdir, fname, fext);
  if (!strcmp (fdir, "\\")) pF->swap1 = CopyBoot;

  pF = get_filedelta (pro_dpfne);
  pF->swap1 = CopyMax1;
  pF->swap2 = CopyMax2;

} // edit_batfiles ()

