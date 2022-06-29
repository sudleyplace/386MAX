/*' $Header:   P:/PVCS/MAX/INCLUDE/MBPARSE.H_V   1.1   13 Oct 1995 12:14:12   HENRY  $ */
/***
 *
 * MultiBoot parse header
 *
 * Defines structures and values used in MultiBoot parsing
 *
***/

#ifdef __cplusplus
extern "C" {
#endif

#ifndef MBPARSE_INCLUDED

#define MBPARSE_INCLUDED
#define MULTIBOOT	/* Enable Multiboot support for MAX 7 */

#ifdef OWNER
#define GLOBAL
#define GLINIT
#else
#define GLOBAL extern
#undef	GLINIT
#endif	/* ifdef OWNER */

/* Externs from MBOOT.ASM */
extern char far * pascal far CurrentMboot (WORD starthigh);

/* Defined in MBOOTSEL.C */
char _far *mboot_select (char _far *helptext, int helpnum);
void set_mbs_callback (int (*callback) (BYTE, char *));

/***
 * MBPARSE.OUT contains lines in the following format:
 * toLINE
 * where:
 *	t is the type of line (ID_BUFFERS, ID_DEVICE, ...)
 *	o is the owner of the line (A-Z corresponding to lines in header)
 *	LINE is the actual line data, including leading and/or trailing spaces
***/

typedef enum {
	ID_BUFFERS = 'B',
	ID_DEVICE = 'D',
	ID_MENUDEFAULT = 'E',
	ID_FILES = 'F',
	ID_DOS = 'H',
	ID_INSTALL = 'I',
	ID_STACKS = 'K',
	ID_INCLUDE = 'L',
	ID_MENUITEM = 'M',
	ID_SECT = 'N',
	ID_OTHER = 'O',
	ID_REM = 'R',
	ID_SHELL = 'S',
	ID_SUBMENU = 'U',
	ID_FCBS = 'X'
} CFGID;

/***
 * Parse CONFIG.SYS on the specified drive for menu items only.
 * MenuCount contains number of menu items (not sections) parsed into
 * the following structure, rooted in DefSect.	Menu items always appear
 * before non-menu section names.  SectCount contains the total number
 * of sections.  There's one initially, since FirstSect is already set up.
 * If keepmem is non-zero, the entire CONFIG.SYS will be kept in memory
 * so it doesn't have to be parsed again for config_parse().  The
 * disadvantage of keeping CONFIG.SYS in memory is that subsequent
 * heap allocations may create far heap subsegments in the middle
 * of memory that won't go away.  The CONFIG.SYS structure is freed
 * before returning from config_parse ().
 * Returns 0 if no errors occur.
***/
GLOBAL int menu_parse (char bootdrive, int keepmem);
GLOBAL int MenuCount;
GLOBAL int SectCount
#ifdef GLINIT
 = 1
#endif	/* ifdef GLINIT */
;

typedef struct _ConfigLine {
 struct _ConfigLine _far *prev, _far *next;
 CFGID	ID;		/* type of line */
 BYTE	Owner;		/* @ for common or 'A'... for a multiboot section */
 BYTE	processed;	// if != 0, line has already been processed
 BYTE	askrelocate;	/* need to ask callback if we should relocate */
 WORD	relocate:1,	/* relocate this one out of any INCLUDEd blocks */
	remark:1,	/* convert this one to a remark when we write to disk */
	fromcommon:1,	/* moved here from a [common] block */
	killit:1,	/* don't write this line to disk */
	:12;
 char _far *line;	/* Pointer to original line */
 char _far *newline;	// pointer to modified line
} CONFIGLINE;

typedef struct _SectName {
  struct _SectName _far *next;
  BYTE	OwnerID;	/* '@' for [common], etc.  Matches ConfigLine.Owner */
  BYTE	MenuItem;	/* Used temporarily for ordering */
  char _far *name;	/* Section identifier */
  char _far *text;	/* Full text displayed in menu */
} SECTNAME;

#ifdef GLINIT
SECTNAME DefSect = {NULL, '@', ' ', "common", ""};
#endif	/* ifdef GLINIT */

SECTNAME GLOBAL _far *FirstSect
#ifdef GLINIT
 = &DefSect
#endif	/* ifdef GLINIT */
;

/* Find record for named section.  Section names are passed WITHOUT [] */
GLOBAL SECTNAME _far *find_sect (char _far *mname);

/* Find section record by owner. */
GLOBAL SECTNAME _far *find_ownsect (char owner);

/* Startup batch file name.  Usually boot:\autoexec.bat, unless /K specified. */
/* Set by menu_parse ().  Sufficient space is needed for a complete path. */
GLOBAL char _far *StartupBat
#ifdef GLINIT
 = "c:\\autoexec.bat\0                                                                "
#endif	/* ifdef GLINIT */
;

/* CONFIG.SYS name.  All we do is blast in the boot drive letter.  After */
/* config_parse(), it can be re-used as the name of the file to read. */
GLOBAL char _far *ConfigSys
#ifdef GLINIT
 = "c:\\config.sys"
#endif	/* ifdef GLINIT */
;

/* Parse CONFIG.SYS into specified output file for selected section owner. */
/* Use callback to determine if a line can stay in a common or included */
/* section.  Calls menu_parse() if not already done. */
/* Returns 0 if successful. */
GLOBAL int config_parse (char bootdrive,
			BYTE selowner,
			char _far *output,
			int keepmem,
			int (_far *callback) (CONFIGLINE _far *));

/* OwnerIDs for active MultiBoot section and for common section */
GLOBAL BYTE ActiveOwner
#ifdef GLINIT
 = '@'
#endif	/* ifdef GLINIT */
;

GLOBAL BYTE CommonOwner
#ifdef GLINIT
 = '@'
#endif	/* ifdef GLINIT */
;

/* Set ActiveOwner and CommonOwner.  Return 0 if sectname found. */
GLOBAL int set_current (char _far *sectname);

GLOBAL int Parsed4DOS
#ifdef GLINIT
 = 0
#endif	/* ifdef GLINIT */
;

/* Returns TRUE if section is a MenuItem= section */
GLOBAL int is_menusect (char _far *mname);

/* Parse SHELL= line (used by QMTSETUP) */
GLOBAL int fnShell (CONFIGLINE _far *cfg);

/* Release memory allocated by menu_parse () */
void config_free (void);

#endif	/* ifndef MBPARSE_INCLUDED */

#ifdef __cplusplus
}
#endif

