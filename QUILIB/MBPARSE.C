/*' $Header:   P:/PVCS/MAX/QUILIB/MBPARSE.C_V   1.2   30 May 1997 12:09:04   BOB  $ */
/***
 *
 * Multiboot support module
 *
***/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <io.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <share.h>

#include "commdef.h"
#include "dmalloc.h"

#define OWNER
#include "mbparse.h"
#undef OWNER

int pascal getkey(int);

CONFIGLINE _far *Cfg = NULL, _far *CurLine, _far *PrevLine, _far *IncLine,
	_far *NextLine;
SECTNAME _far *CurSect, _far *PrevSect;
BYTE DefOwner;
BYTE MenuOrder;
int (_far *Callback) (CONFIGLINE _far *);
char buff[1000];
int added;
#define NTOK	10	/* Maximum number of tokens to parse */
static char CfgSysSeps[] = " \t=/;,\n"; /* Command separators for CONFIG.SYS */

#ifdef BATPROC
#define STRIPMGR
#endif

#ifdef STRIPMGR
int _farsopen (char _far *fname, int oflag, int shflag, int pmode)
{
 char buff[128];

 _fstrcpy (buff, fname);
 return (sopen (buff, oflag, shflag, pmode));

} // _farsopen ()
#else
FILE *_farfopen (char _far *fname, char *mode)
{
 char buff[128];

 _fstrcpy (buff, fname);
 return (fopen (buff, mode));

} // _farfopen ()
#endif // ifdef STRIPMGR

// Replacement for strdup() using _dmalloc
char _far *_dstrdup (char _far *s)
{
	char _far *tmp;

	if (tmp = _dmalloc(_fstrlen (s) + 1))
		_fstrcpy (tmp, s);

	return (tmp);
} // _dstrdup ()


int fnDOS (char **tok, CONFIGLINE _far *cfg)
// Process DOS=HIGH,UMB
// If UMB argument is not present, make it an Other line.  DOS=UMB can't
// be in an INCLUDE section.  We could care less about DOS=HIGH.
// Always returns 0.
{
	int i;

	for (i=1; tok[i] && i<NTOK; i++)
	    if (!_stricmp (tok[i], "umb"))
		return (0);

	cfg->ID = ID_OTHER;

	return (0);

} // fnDOS ()


int fnShell (CONFIGLINE _far *cfg)
// Called from check_reloc ()
// Process SHELL= statement.  Always returns 0.
// If a SHELL= statement appears both in the active and common sections,
// we'll get whichever came last.  We need to ensure that the startup
// batch file name has a full drive, path and extension.
{
  char	pdrv [_MAX_DRIVE],
	ppath[_MAX_PATH],
	npath[_MAX_PATH],
	pfnam[_MAX_FNAME],
	pfext[_MAX_EXT];
  char	*tok1, *tok;
//  char _far *Path4Start = NULL;
  char _far *PathAuto = NULL;
#ifdef STRIPMGR
  extern int getline(int, char *, int);
  int	inifile;
#else
  FILE	*inifile;
#endif

	// Figure out whether it's 4DOS, NDOS, or COMMAND.COM
	// Note that using CfgSysSeps means we can't distinguish
	// shell = command.com /k from shell=command.com k.
	_fstrcpy (npath, cfg->line);
	tok1 = strtok (npath, CfgSysSeps); // SHELL
	tok1 = strtok (NULL, CfgSysSeps); // c:\command.com
	_splitpath (tok1, pdrv, ppath, pfnam, pfext);

	if (!_stricmp (pfnam, "command") && !_stricmp (pfext, ".com")) {

	  // Clear 4DOS/NDOS flag (used by MAXIMIZE)
	  Parsed4DOS = 0;

	  // If COMMAND.COM, check for /K option
	  while (tok = strtok (NULL, CfgSysSeps))
	    if (!_stricmp (tok, "k") && (tok = strtok (NULL, CfgSysSeps)))
		_fstrcpy (StartupBat, tok);

	} // It's COMMAND.COM
	else {

	  // Set 4DOS/NDOS flag for MAXIMIZE
	  Parsed4DOS = 1;

	  // If 4DOS/NDOS:
	  // 1. Open 4DOS.INI.	If not found, it's autoexec.bat.
	  _makepath (buff, pdrv, ppath, pfnam, ".ini");
	  _fstrcpy (StartupBat, buff);

	  // Check for explicit @initfile.ini syntax and /k (supported
	  // by newer versions of 4DOS/NDOS).  /K takes precedence over
	  // AutoexecPath in the 4DOS.INI file.
	  while (tok = strtok (NULL, CfgSysSeps))
		if (tok[0] == '@') {
		  _fstrcpy (StartupBat, tok+1);
		} // Found an @initfile on the 4DOS/NDOS line
		else if (!_stricmp (tok, "k") &&
			 (tok = strtok (NULL, CfgSysSeps))) {
		  _fstrcpy (StartupBat, tok);
		  goto FNSHELL_GOTPATH;
		} // /K batchfilename

	  strcpy (pfnam, "autoexec");   /* Assume default */
	  pfext[0] = '\0';

#ifdef STRIPMGR
	  if ((inifile = _farsopen(StartupBat,(O_RDONLY | O_BINARY),SH_COMPAT,0)) != -1) {

	    while (getline(inifile, buff, sizeof(buff)-1)) {
#else
	  if (inifile = _farfopen (StartupBat, "r")) {

	    while (fgets (buff, sizeof(buff)-1, inifile)) {
#endif
		buff[sizeof(buff)-1] = '\0';
		tok = strtok (buff, CfgSysSeps);

// We're not interested in 4START.BAT; it's a mechanism to be invoked
// EVERY time the command processor starts up.
/*****		if (!_stricmp (tok, "4startpath")) {
		  // Get 4StartPath.  Default is 4DOS path.
		  Path4Start = _dstrdup (strtok (NULL, CfgSysSeps));
		} // Keyword was 4StartPath
		else
*****/
		if (!_stricmp (tok, "autoexecpath")) {
		  // Get AutoExecPath.	Default is root of boot.
		  PathAuto = _dstrdup (strtok (NULL, CfgSysSeps));
		} // Keyword was AutoExecPath

	    } // not EOF

#ifdef STRIPMGR
	    close(inifile);
#else
	    fclose (inifile);
#endif

/**************
	    // If 4START.BAT exists, it's our boy
	    if (Path4Start) {
		_fstrcpy (StartupBat, Path4Start);
		_dfree (Path4Start);
		if (!strchr ("/\\", StartupBat[_fstrlen(StartupBat)-1]))
				_fstrcat (StartupBat, "\\");
		_fstrcat (StartupBat, "4start.bat");
		_fstrcpy (npath, StartupBat);
		if (!_access (npath, 0)) goto FNSHELL_GOTPATH;
	    } // 4STARTPATH specified
	    _makepath (buff, pdrv, ppath, "4start", ".bat");
	    _fstrcpy (StartupBat, buff);
	    if (!_access (buff, 0)) goto FNSHELL_GOTPATH;
******************/

	    // If AutoExecPath specified, see if it's valid
	    // If it ends in / or \, append AUTOEXEC.BAT
	    if (PathAuto) {
		_fstrcpy (StartupBat, PathAuto);
		if (strchr ("/\\", StartupBat[_fstrlen(StartupBat)-1]))
				_fstrcat (StartupBat, "autoexec.bat");
		_fstrcpy (buff, StartupBat); // Make it near addressable
		if (!_access (buff, 0)) goto FNSHELL_GOTPATH;
	    } // AutoExecPath specified

	  } // Opened 4DOS.INI file OK

	  StartupBat[0] = *ConfigSys;
	  _fstrcpy (StartupBat+1, ":\\autoexec.bat");

	} // It's 4DOS or NDOS

FNSHELL_GOTPATH:
	if (PathAuto) _dfree (PathAuto);
	/* Make sure it has the default .BAT extension */
	_fstrcpy (buff, StartupBat);
	_splitpath (buff, pdrv, ppath, pfnam, pfext);
	if (!*pdrv) sprintf (pdrv, "%c:", *ConfigSys);
	if (!*ppath) strcpy (ppath, "\\");
	if (!*pfnam) strcpy (pfnam, "autoexec");
	if (!*pfext) strcpy (pfext, ".bat");
	_makepath (buff, pdrv, ppath, pfnam, pfext);
	_fstrcpy (StartupBat, buff);

  return (0);

} // fnShell ()


int fnMenuItem (char **tok, CONFIGLINE _far *cfg)
// Process MENUITEM= statement
// tok[0] == "MENUITEM" or NULL if []
// tok[1] == section_name
// tok[2] == "Long description of section" or NULL
{
	/* Find the matching entry in the section name list */
	/* If none, add it to the end */
	for (	PrevSect = NULL, CurSect = FirstSect;
		CurSect && _fstricmp (CurSect->name, tok[1]);
		CurSect = CurSect->next)
			PrevSect = CurSect;

	if (!CurSect) { /* Add to end of list */
		if (!(CurSect = _fmalloc (sizeof (SECTNAME))) ||
		    !(CurSect->name = _fstrdup (tok[1])))	return (-1);
		CurSect->OwnerID = (BYTE) (PrevSect->OwnerID + 1);
		CurSect->next = NULL;
		CurSect->MenuItem = ' ';
		CurSect->text = NULL;
		PrevSect->next = CurSect;
		SectCount++;
		added = 1;
	} // Section name not already in list

	// If we have menuitem=common, we'll need to grab the text...
	if (tok[0] && (!CurSect->text || !CurSect->text[0])) {
	  char _far *t2pos;

	  /* Find where MENUITEM starts (after whitespace) */
	  if (t2pos = _fstrstr (cfg->line, tok[0])) {
	    if (tok[2]) {
	      if (t2pos = _fstrstr (t2pos + strlen (tok[0]) + 1 +
					strlen (tok[1]) + 1, tok[2])) {
		if (!(CurSect->text = _fstrdup (t2pos)))	return (-1);
		if (t2pos = _fstrchr (CurSect->text, '\n')) *t2pos = '\0';
	      } // Found tok[2] in original line
	    } // text description was specified
	  } // Found tok[0] in original text line

	} // text line not already set up

	return (0);

} // fnMenuItem ()


typedef struct _SrchRec {
 char	*token; 	/* DEVICE, INSTALL, etc. */
 CFGID	CfgID;		/* 'D' for device, 'I' for INSTALL, 'L' for INCLUDE */
 int	(*fn) (char **, CONFIGLINE _far *); /* Special processing function */
} SRCHREC;

SRCHREC Keywords[] = {
	{	"rem",          ID_REM,         NULL    },
	{	"device",       ID_DEVICE,      NULL    },
	{	"install",      ID_INSTALL,     NULL    },
	{	"include",      ID_INCLUDE,     NULL    },
	{	"buffers",      ID_BUFFERS,     NULL    },
	{	"menudefault",  ID_MENUDEFAULT, NULL    },
	{	"files",        ID_FILES,       NULL    },
	{	"dos",          ID_DOS,         fnDOS   },
	{	"stacks",       ID_STACKS,      NULL    },
	{	"menuitem",     ID_MENUITEM,    fnMenuItem },
	{	"shell",        ID_SHELL,       NULL    },
	{	"submenu",      ID_SUBMENU,     NULL    },
	{	"fcbs",         ID_FCBS,        NULL    },
	{	"break",        ID_OTHER,       NULL    },
	{	"lastdrive",    ID_OTHER,       NULL    }
};
#define NKEYWORDS	(sizeof(Keywords)/sizeof(Keywords[0]))


SECTNAME _far *find_sect (char _far *mname)
// Find record for named section.  Section names are passed WITHOUT []
{
 SECTNAME _far *ret;

 for (ret = FirstSect; ret; ret = ret->next) {
	if (!_fstricmp (ret->name, mname))
		break;
 }

 return (ret);

} // find_sect ()


SECTNAME _far *find_ownsect (char owner)
// Find section record by owner.
{
 SECTNAME _far *ret;

 for (ret = FirstSect; ret; ret = ret->next) {
	if (ret->OwnerID == (BYTE) owner)
		break;
 }

 return (ret);

} // find_ownsect ()

int is_menusect (char _far *mname)
// Returns 1 if section is in the menu, 0 otherwise
{
 SECTNAME _far *tmp;
 int i;

 for (tmp = FirstSect, i=0; tmp && (i < MenuCount); tmp = tmp->next, i++) {
	if (!_fstricmp (tmp->name, mname)) return (1);
 }

 return (0);

} // is_menusect ()

void order_menus (char _far *mname)
// Set menuitem order for specified menu.  Calls itself recursively.
{
 BYTE mowner;
 SECTNAME _far *mrec;
 CONFIGLINE _far *cfg;
 char *t1, *t2;

 if (!(mrec = find_sect (mname)))	return;

 mowner = mrec->OwnerID;	// Get target ID to search for
 for (cfg = Cfg; cfg; cfg = cfg->next) {
	if (cfg->Owner == mowner) {
	   /* Parse out the second argument */
	   _fstrcpy (buff, cfg->line);
	   t1 = strtok (buff, CfgSysSeps);
	   t2 = strtok (NULL, CfgSysSeps);
	   if (t2 && (mrec = find_sect (t2))) {
		if (cfg->ID == ID_MENUITEM && mrec->MenuItem == ' ') {
		    mrec->MenuItem = MenuOrder++;
		}
		else if (cfg->ID == ID_SUBMENU) {
		    if (mrec->MenuItem == ' ') {
		      mrec->MenuItem = '\0';
		      order_menus (t2);
		    } // Haven't processed this submenu yet
		}
	   } // Found section record for menu item
	} // Found a target record
 } // for ()

} // order_menus ()


CONFIGLINE _far *create_line (void)
// Allocate and initialize a new CONFIGLINE record
{
	CONFIGLINE _far *ret;

	ret = _dmalloc (sizeof (CONFIGLINE));

	if (ret) {
		ret->next = NULL;
		ret->processed = 0;
		ret->askrelocate = 0;
		ret->relocate = 0;
		ret->remark = 0;
		ret->killit = 0;
		ret->fromcommon = 0;
		ret->Owner = '@';
		ret->newline = NULL;
	}

	return (ret);

} // create_line ()


CONFIGLINE _far *dup_line (CONFIGLINE _far *src)
// Duplicate a line
{
	CONFIGLINE _far *ret;

	ret = create_line ();

	if (ret) {

		ret->askrelocate = src->askrelocate;
		ret->relocate = src->relocate;
		ret->remark = src->remark;
		ret->killit = src->killit;
		ret->processed = src->processed;
		ret->Owner = src->Owner;
		ret->ID = src->ID;
		ret->line = src->line;	// Note that we only copy the pointer

	} // if (ret)

	return (ret);

} // dup_line ()


CONFIGLINE _far *find_first (char _far *sectname)
// Find the first line belonging to a named section
{
  CONFIGLINE _far *ret;
  SECTNAME _far *sect;

  ret = NULL;
  if (sect = find_sect (sectname)) {
	for (ret = Cfg; ret; ret = ret->next) {
		if (ret->Owner == sect->OwnerID)
			break;
	}
  }

  return (ret);

} // find_first ()


int check_reloc (CONFIGLINE _far *cfg)
// If line needs relocation from INCLUDE or COMMON, set appropriate flags
// and return 1.  Otherwise, return 0.
// This is also a convenient place to call fnShell only for lines we
// know we're interested in.
{

  switch (cfg->ID) {

     case ID_SHELL:
	fnShell (cfg);
	// Fall through and pass it to callback as well

     case ID_DEVICE:
     case ID_INSTALL:
     case ID_DOS:
     case ID_STACKS:
     case ID_FCBS:
     case ID_FILES:
     case ID_BUFFERS:
     case ID_OTHER:
#ifndef BATPROC
	if (!cfg->askrelocate && (*Callback)(cfg)) {
		// We don't want to relocate anything if we're processing
		// [common], but we still rely on the callback to ask us.
		cfg->relocate = (ActiveOwner != CommonOwner);
	} // Line can't be in an include section
#endif
	(cfg->askrelocate)++;
	break;

   } // end switch ()

   return (cfg->relocate);

} // check_reloc ()


void config_free(void)
// Free the copy of CONFIG.SYS we stashed away in memory
{
	for (CurLine = Cfg; CurLine; CurLine = CurLine->next) {
	    if (CurLine->line)
		_dfree (CurLine->line);
	    if (CurLine->newline)
		_dfree (CurLine->newline);
	    _dfree (CurLine);
	} // for (CurLine...)

	Cfg = NULL;

} // config_free


int read_config (void)
// Return -1 if error occurred, otherwise number of menu items added
{
#ifdef STRIPMGR
	extern int getline(int, char *, int);
	int fcfg;
#else
	FILE *fcfg;
#endif
	char *tok[NTOK];
	int i, ret = -1;
	char _far *tmp;

/* If keepmem is false, we may be reading all of CONFIG.SYS into memory,
 * making a few permanent allocations, then returning all the allocations
 * we made for CONFIG.SYS.  We'll be using DOS function 48 for the CONFIG.SYS
 * lines, but section names will be allocated using malloc().  We need to
 * ensure that malloc() has grown enough heap segments so that malloc() won't
 * grow new segments after we've allocated numerous DOS segments...
***/
	if (tmp = _fmalloc (10240))
		_ffree (tmp);

#ifdef STRIPMGR
	if ((fcfg = _farsopen(ConfigSys,(O_RDONLY | O_BINARY),SH_COMPAT, 0)) == -1)
		goto READ_CONFIG_EXIT;
#else
	if (!(fcfg = _farfopen (ConfigSys, "r")))
		goto READ_CONFIG_EXIT;
#endif

	  PrevLine = NULL;

	  /* First, read everything into memory */
	  /* Set up list of section names and set ownerships for section */
	  /* names only. */
	  added = 0;
#ifdef STRIPMGR
	  while (getline(fcfg, buff, sizeof(buff)-1)) {
#else
	  while (fgets (buff, sizeof(buff)-1, fcfg)) {
#endif
		buff[sizeof(buff)-1] = '\0';
		/* Allocate space for copy */
		if (!(tmp = _dmalloc (strlen (buff) + 1)))
			goto READ_CONFIG_EXIT;
		_fstrcpy (tmp, buff);	/* Save before strtok () */

		tok[0] = strtok (buff, CfgSysSeps); /* Get DEVICE, INCLUDE, etc */
		tok[1] = strtok (NULL, CfgSysSeps); /* Argument 1 */
		for (i=2; i < NTOK; i++)
			tok[i] = strtok (NULL, CfgSysSeps); /* Argument 2 - 9 */

		if (!(CurLine = create_line ()))
			goto READ_CONFIG_EXIT;

		CurLine->line = tmp;
		CurLine->prev = PrevLine;

		if (PrevLine)
			PrevLine->next = CurLine;
		else
			Cfg = CurLine;

		if (!tok[0])
			CurLine->ID = ID_REM;
		else {

		  for (i=0; i < NKEYWORDS; i++) {
			if (!_stricmp (tok[0], Keywords[i].token)) {
			    CurLine->ID = Keywords[i].CfgID;
			    if (Keywords[i].fn) {
				if ((*Keywords[i].fn) (tok, CurLine))
					goto READ_CONFIG_EXIT;
			    } /* Function defined */
			    goto LINE_DONE;
			} // Keyword matched
		  } // for all keywords in list

		  if (tok[0] && tok[0][0] == '[') { /* Process section name */

			tok[1] = strtok (tok[0], "[]"); /* Get name */
			/* tok[0] = "MENUITEM" */
			tok[2] = NULL;
			if (fnMenuItem (tok, CurLine))
				goto READ_CONFIG_EXIT;

			/* Note that CurSect points to the new or existing */
			/* entry. */
			CurLine->Owner = CurSect->OwnerID;
			CurLine->ID = ID_SECT;

		  } /* Section name */
		  else
			CurLine->ID = ID_DEVICE; // Make sure we pass all lines to STRIPMGR

		} // line was not blank

LINE_DONE:
		PrevLine = CurLine;

	  } // not EOF

	 ret = added;
READ_CONFIG_EXIT:
#ifdef STRIPMGR
	 if (fcfg)
		close(fcfg);
#else
	 if (fcfg)
		fclose(fcfg);
#endif

	 return (ret);

} // read_config ()


int menu_parse (char bootdrive, int keepmem)
// Parse CONFIG.SYS on specified drive to get menu
{
	int ret = -1;
	int ordered, added;

	ConfigSys[0] = bootdrive;

	if ((added = read_config ()) == -1)
		goto MENU_PARSE_EXIT;

	  /* Now that we've parsed everything, set ownerships */
	  DefOwner = DefSect.OwnerID; /* Default owner of subsequent lines */
	  for (CurLine = Cfg; CurLine; CurLine = CurLine->next) {
		if (CurLine->ID == ID_SECT)
			DefOwner = CurLine->Owner;
		else
			CurLine->Owner = DefOwner;
	  } // for ()

	  ret = 0;

	  if (!added) goto MENU_PARSE_EXIT;

	  /* Initialize MenuItem to ' ' in case we've already been here */
	  for (CurSect = FirstSect; CurSect; CurSect = CurSect->next)
		CurSect->MenuItem = ' ';

	  /* Determine menuitem order with submenu nesting */
	  MenuOrder = 'A';
	  order_menus ("menu");
	  MenuCount = MenuOrder - 'A';

	  /* Order the remaining sections (the ones that don't appear as */
	  /* menuitem statements) so there are no conflicts */
	  for (CurSect = FirstSect; CurSect; CurSect = CurSect->next)
		if (CurSect->MenuItem == ' ' || !CurSect->MenuItem)
			CurSect->MenuItem = MenuOrder++;

	  /* Convert all Owner fields to MenuItem */
	  for (CurLine = Cfg; CurLine; CurLine = CurLine->next) {
	    for (CurSect = FirstSect; CurSect; CurSect = CurSect->next) {
		if (CurLine->Owner == CurSect->OwnerID) {
			CurLine->Owner = CurSect->MenuItem;
			break;
		} /* Found a match */
	    } /* for all menu sections */
	  } /* for all lines */

	  /* Convert all OwnerID fields to MenuItem */
	  for (CurSect = FirstSect; CurSect; CurSect = CurSect->next) {
		CurSect->OwnerID = CurSect->MenuItem;
		CurSect->MenuItem = ' ';        /* Clear for debugging */
	  } /* for all sections */

	  /* Put menu items in order */
	  do {
		SECTNAME _far *NextSect;

		for (	CurSect = FirstSect, PrevSect = NULL, ordered = 1;
			CurSect && CurSect->next;
			PrevSect = CurSect, CurSect = CurSect->next) {
		  NextSect = CurSect->next;
		  if (CurSect->OwnerID > NextSect->OwnerID) {
			CurSect->next = NextSect->next;
			NextSect->next = CurSect;
			if (PrevSect)
				PrevSect->next = NextSect;
			else
				FirstSect = NextSect;
			ordered = 0;
		  } // Pair is out of order
		} // for all possible pairs
	  } while (!ordered);

	  // Set CommonOwner
	  if (CurSect = find_sect ("common"))
		CommonOwner = CurSect->OwnerID;
	  else
		CommonOwner = '@';

MENU_PARSE_EXIT:
	  if (!keepmem) { // Set your chickens free...
		config_free ();
	  } // if (!keepmem)

	  return (ret);

} // menu_parse()


int check_include (BYTE selowner, BYTE cowner)
// Check for illegal INCLUDEs.	Return 0 if OK, -1 otherwise
// We'll always expand an INCLUDE the target of which is a section name,
// if at any level a preceding common section contained any line which
// might require relocation in check_common().
{
	int forcereloc = 0;

	for (CurLine = Cfg; CurLine; CurLine = CurLine->next) {

	    if ((CurLine->Owner == cowner) || (CurLine->Owner == CommonOwner)) {

		// Check for a DEVICE= or INSTALL= in the common section
		if (CurLine->Owner == CommonOwner && check_reloc (CurLine)) forcereloc = 1;

		if (CurLine->ID == ID_INCLUDE && !(CurLine->remark || CurLine->killit)) {
		    char *t1, *t2;

		    _fstrcpy (buff, CurLine->line);
		    t1 = strtok (buff, CfgSysSeps);
		    t2 = strtok (NULL, CfgSysSeps);

		    // We need to process the current line if
			// - it is owned by selowner or CommonOwner; or
			// - the section referenced is owned by selowner; or
			// - the section referenced is a menu section and
			//   forcereloc == TRUE
		    if (t2 && (IncLine = find_first (t2)) &&
			( CurLine->Owner == CommonOwner ||
			  CurLine->Owner == selowner ||
			  IncLine->Owner == selowner ||
			  (forcereloc && is_menusect (t2)) ) ) {

			CONFIGLINE _far *curinc, _far *cpyinc;
			int needcopy = 0;

			for (curinc = IncLine;
			     curinc && curinc->Owner == IncLine->Owner;
			     curinc = curinc->next) {
			      needcopy += check_reloc (curinc);
			} // for (include section lines)

			if (needcopy || (forcereloc && is_menusect (t2))) {

			    if (CurLine->Owner == CommonOwner) forcereloc = 1;

			    CurLine->remark = 1;
			    PrevLine = CurLine;
			    NextLine = CurLine->next;

			    for (curinc = IncLine;
				 curinc && curinc->Owner == IncLine->Owner;
				 curinc = curinc->next) {
				if (curinc->ID == ID_SECT)
					continue;
				if (!(cpyinc = dup_line (curinc)))
					return (-1);
				PrevLine->next = cpyinc;
				cpyinc->prev = PrevLine;
				PrevLine = cpyinc;
				cpyinc->Owner = CurLine->Owner;

				if (cpyinc->Owner == selowner) {
				    cpyinc->newline = curinc->newline;
				    curinc->newline = NULL;
				}

			    } // for lines in INCLUDE section

			    PrevLine->next = NextLine;
			    NextLine->prev = PrevLine;

			} // INCLUDE section duplicated

		    } // Found first line of INCLUDE section

		} // Line is an INCLUDE statement
		else if (CurLine->Owner == selowner) {
		    // line is in parent section; make sure it's processed
		    check_reloc(CurLine);
		}

	   } // Owner matches current one
	} // for all lines

	return (0);

} // check_include ()


int check_common (BYTE selowner)
// Check for lines that shouldn't be in common section.  Return 0 if OK,
// -1 if error occurred.  CurLine is the line to process.
// If a line doesn't belong in the common section, we'll move it
// (or a copy of it) after the last line of the set {section header,
// any line with fromcommon == 1} in each section.  Even if the
// [common] section header ends up empty, we'll leave it alone.
// If relocation occurred, CurLine will point to the old previous
// line on return.
// If there is no instance of the section after the common section,
// we'll add a new instance of that section at the end of the file.
{
	int i, ret = -1;
	BYTE cowner;
	CONFIGLINE _far *NewCurLine;

	if ((check_reloc (CurLine)) && (MenuCount > 0)) {
	    CONFIGLINE _far *cline, _far *newline, _far *cpline;
	    int unhooked;

	    // Save the value to assign to CurLine when we return
	    if (PrevLine)	NewCurLine = PrevLine;
	    else		NewCurLine = CurLine->next;

	    CurSect = FirstSect;	// Start with first section
	    if (!CurSect)
		goto CHECK_COM_EXIT; // Shouldn't happen

	    for (unhooked = i = 0;
		 CurSect && (i < MenuCount);
		 CurSect = CurSect->next, i++) {

		cowner = CurSect->OwnerID;	// Owner value to look for
		if (cowner == CommonOwner) continue;

		// Starting after NewCurLine, find the first line
		// belonging to cowner (it should be a section name).
		for (	cpline = cline = NewCurLine->next;
			cline && cline->Owner != cowner;
			cpline = cline, cline = cline->next) ;

		if (!cline) {
			sprintf (buff, "[%Fs]\n", CurSect->name);
			if (	!(cline = create_line ()) ||
				!(cline->line = _dstrdup (buff)))
					goto CHECK_COM_EXIT;
			cline->ID = ID_SECT;
			cline->Owner = cowner;
			cline->prev = cpline;
			cpline->next = cline;
		} // Add new section to end of file

		// Find a record we can insert this one after
		while (cline->next && cline->Owner == cowner &&
						cline->next->fromcommon)
				cline = cline->next;

		// Unhook the original if we haven't done so already;
		// otherwise make a copy.
		if (!unhooked) {

			newline = CurLine;
			if (CurLine->prev) CurLine->prev->next = CurLine->next;
			if (CurLine->next) CurLine->next->prev = CurLine->prev;
			if (CurLine == Cfg) Cfg = NewCurLine;
			unhooked = 1;

		} // Original still hooked up
		else {

			if (!(newline = dup_line (CurLine)))
					goto CHECK_COM_EXIT;

		} // Copied from original

		newline->Owner = cowner;
		newline->fromcommon = 1;
		newline->prev = cline;

		if (newline->next = cline->next)
				newline->next->prev = newline;

		cline->next = newline;

	    } // for all sections

	    CurLine = NewCurLine;

	} // Line needs to be relocated

	ret = 0;

CHECK_COM_EXIT:
	return (ret);

} // check_common ()

int config_parse (	char bootdrive,
			BYTE selowner,
			char _far *output,
			int keepmem,
			int (_far *callback)(CONFIGLINE _far *))
// Parse CONFIG.SYS into output file.  Returns 0 if successful.
{
#ifdef STRIPMGR
  extern int qprintf(int, char *, ...);
  int fcfg;
#else
  FILE *fcfg;
#endif
  int i;
  int ret = -1;

  Callback = callback;

  // Read CONFIG.SYS and get list of menu names if we don't already have 'em
  if ((bootdrive != '\0') && (menu_parse (bootdrive, 1)))
	goto CONFIG_PARSE_EXIT;

  // Check to see if caller wants us to calculate the current section
  if (selowner == 0xff) {

	set_current (output);
	output = NULL;
	selowner = ActiveOwner;

  } // Set selowner

	StartupBat[0]='\0';                                     // Init startup name

	// clear the "askrelocate" bit
	for (CurLine = Cfg; CurLine; CurLine = CurLine->next)
		CurLine->askrelocate = 0;

	// Check for illegal INCLUDE sections.	We only need to check INCLUDE
	// sections where owner == selowner or CommonOwner, and for INCLUDE=
	// statements where the owner of the INCLUDE statement is selowner.
	/* Check for device and install statements in INCLUDE sections. */
	/* If the callback tells us they can't stay there, we'll copy 'em */
	/* to immediately after the INCLUDE line, and REM out the INCLUDE */
	for (CurSect = FirstSect, i=0; CurSect && (i < MenuCount);
			i++, CurSect = CurSect->next) {
		if (check_include (selowner, CurSect->OwnerID))
			goto CONFIG_PARSE_EXIT;
	} // for all sections

	// Check for statements not allowed in common section.	Unlike INCLUDE,
	// we can't limit this to the selowner (target) section.
	/* Check for device and install statements in common sections */
	/* All statements that the callback tells us can't stay in a */
	/* common block are moved, in the order they are found, to */
	/* the beginning of every section in CONFIG.SYS.  This keeps */
	/* us out of the business of adding section names before */
	/* their previous first instance.  This can throw off the */
	/* INCLUDE= mechanism, which takes only the first block */
	/* found. */
	/* Note that we've already fully expanded any INCLUDEd sections */
	/* in the common area. */
	PrevLine = NULL;

	for (CurLine = Cfg; CurLine; CurLine = CurLine->next) {

	    if (CurLine->Owner == CommonOwner)
		check_common(selowner);

	    PrevLine = CurLine;
	    if (!CurLine) break;	// May have changed in check_common()

	} // Checking all common lines

  // Create output file
	/* Write out list of sections in menuitem order */

	if (output != NULL) {
#ifdef STRIPMGR
	  if ((fcfg = _farsopen(output,O_WRONLY | O_BINARY | O_CREAT,SH_COMPAT,S_IREAD | S_IWRITE)) == -1)
		goto CONFIG_PARSE_EXIT;

	  /* Now write out remainder of file */
	  for (CurLine = Cfg; CurLine; CurLine = CurLine->next)
	    if (!CurLine->killit)
		qprintf (fcfg, "%s%Fs", CurLine->remark ? "REM " : "", CurLine->line);

	  close(fcfg);
#else
	  if (!(fcfg = _farfopen (output,"w"))) {
		goto CONFIG_PARSE_EXIT;
	  }

#if 0
	  fprintf (fcfg, "%d %d %Fs %s\n", MenuCount, SectCount, current,
			StartupBat);

	  for (CurSect = FirstSect; CurSect; CurSect = CurSect->next) {
		fprintf (fcfg, "%c %s\n", CurSect->OwnerID, CurSect->name);
	  }
#endif
	  /* Now write out remainder of file */
	  /* INSTALL may have made changes; use the changed form only */
	  /* for the active owner. */
	  for (CurLine = Cfg; CurLine; CurLine = CurLine->next)
	    if (!CurLine->killit || CurLine->Owner != ActiveOwner)
		fprintf (fcfg, "%c%c%s%Fs",
			CurLine->remark ? ID_REM : CurLine->ID,
			CurLine->Owner, CurLine->remark ? "REM " : "",
			(CurLine->newline && CurLine->Owner == ActiveOwner) ?
				CurLine->newline : CurLine->line);

	  fclose (fcfg);
#endif
	}

	ret = 0;

CONFIG_PARSE_EXIT:
	// Free copy of CONFIG.SYS in memory
	if (keepmem == 0)
		config_free ();

	// Note that if we're called repeatedly with bootdrive=='\0'
	// (as in QMTSETUP) the caller will have to bung in the boot
	// drive letter.
	if ( ! StartupBat[0] ) {	// If we didn't parse a startup batch,
					// use the default.
		StartupBat[0] = bootdrive;
		_fstrcpy (StartupBat+1, ":\\autoexec.bat");

	} // Didn't find a /K startup batch file

	return (ret);

} // config_parse ()


int set_current (char _far *sectname)
/* Set ActiveOwner and CommonOwner.  Return 0 if specified section found. */
/* Assumes menu_parse() has already been called. */
{
 SECTNAME _far *tmpsect, _far *comsect;

  // Read CONFIG.SYS and get list of menu names if we don't already have 'em
  if (!(tmpsect = find_sect(sectname)) || !(comsect = find_sect("common")))
	return (-1);

  ActiveOwner = tmpsect->OwnerID;
  CommonOwner = comsect->OwnerID;

  return (0);

} // set_current ()


/* End of file MBPARSE.C */

