/*' $Header:   P:/PVCS/MAX/INSTALL/DEFN.H_V   1.1   25 Oct 1995 18:49:58   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * DEFN.H								      *
 *									      *
 * Global definition file						      *
 *									      *
 ******************************************************************************/

/*
 *
 * Global definition file to be included with WIN_TEST.C
 *	 Patrick Devlin - December, 1990
 *
 * The following set of variables gets initialized during startup from main:
 *
 */

extern	 outtxt_buf;
char	*EXCPTN_LIST[] = { "EMMXXXX0",
			   "INBRDAT%",
			   "INBRDPC%",
			   NULL
			 };

int	 fUpdate = NO;		// Update or install flag
int	 MONO = NO;		// Recover MDA regions?
int	 BIOS = NO;		// Recover BIOS fill patterns?
int	 VGAWARN = -1;		// MDA recovery warning bits defined in
				// COMMON.H
int	 VGAMEM = 0;		// Memory on SVGA card

FREEROM  mono_mem [32/4];	// There are 8 4K blocks in a 32KB area
int	 cnt_mono;		// Number of entries in mono_mem

char	 *bcf_dpfne;
char	 *con_dpfne;
char	 *pro_dpfne;
char	 *preinst_bat;
char	 *groupname;
WORD	 BIOSCRC;
int	 mcasys;
int	 bcfsys;

unsigned saved_drive;
char	 saved_path [MAXDIR+1];
char	 source_drive [] = "A";
char	 source_subdir [MAXDIR+1];
char	 dest_drive;
char	 dest_subdir [MAXDIR+1] = MAX_INIDIR;
char	 pro_drive;
char	 boot_drive = 'C';
char	 update_subdir [MAXDIR+1] = MAX_INIDIR;

// End of startup variables list

int	 security_crc;
int	 SECURITY_LEN;

WORD	dcache = DCACHE_NONE;		// Disk cache found & flags
WORD	dcache_arg = 0; 		// Size argument to disk cache
int	dcache_arg2 = -1;		// 2nd size argument to disk cache

char	 security_pattern [ 352 ];
char	 drv_drive[ _MAX_DRIVE ];	// parsed device= drive
char	 drv_dir[ _MAX_DIR ];		//  ..			  dir
char	 drv_fname[ _MAX_FNAME ];	//  ..			  name
char	 drv_ext[ _MAX_EXT ];		//  ..			  ext
char	 drv_path[ _MAX_PATH];		// complete path
char	 edit_prolast[80];

enum boolean	   con_fnd = FALSE;
enum boolean change_config = FALSE;
enum boolean	   mgr_fnd = FALSE;
enum boolean	   emm_fnd = FALSE;
enum boolean	   pro_fnd = FALSE;
enum boolean	   drv_fnd = FALSE;
enum boolean	   src_fnd = FALSE;
enum boolean	   bcf_fnd = FALSE;
enum boolean	   win_fnd = FALSE;
enum boolean	     WIN30 = FALSE;
enum boolean	 xbios_fnd = FALSE;
enum boolean	      BACK = FALSE;
enum boolean	 autox_fnd = FALSE;
enum boolean	 qutil_fnd = FALSE;


FILESTRUC inst = { OEM_INSTOVL };
FILESTRUC ident[2][8];

short	 UNDER		= 0x0707;
short	 BLOCK		= 0x0007;
short	 DOUBLE 	= 0x0607;
short	 NOCURSOR	= 0x2000;

int	 MAXDSK 	= 1;
int	 DESTDSK	= 0;

char	 user_name [USER_NAME_LEN+1] = "\0";
char	 user_company [USER_COMPANY_LEN+1] = "\0";
char	 user_number [USER_SERIAL_LEN+1] = "\0";

char *RecallString = NULL;

int ProductSet = FALSE; 	/* TRUE if product (to install) has been set */
int ReInstall = FALSE;		/* TRUE to re-install (no unzip) */
int Overwrite = FALSE;		/* TRUE if we should overwrite only older files
				*  (default is to overwrite everything)
				***/
int GraphicsLogo = TRUE;	/* TRUE to do 'q' logo */
int Backup = TRUE;		/* TRUE to backup existing files */
int VideoReset = FALSE; 	/* TRUE if video system died */
int DiskCacheTest = TRUE;	/* TRUE to test for disk cache */
BOOL SnowControl = FALSE;	/* TRUE to do CGA snow control */
BOOL PatchPrep = FALSE; 	/* TRUE to extract only different files */
BOOL FreshInstall = TRUE;	/* FALSE if MAX was already in CONFIG.SYS */
BOOL InChild = FALSE;		/* TRUE if we're executing a child program */
BOOL AllBCFs = FALSE;		/* TRUE to extract all BCF files */
BOOL NewMachine = FALSE;	/* TRUE if it's a new machine */
BOOL MaxInst;			/* TRUE if qmaxpres() */
int  EMSType = 0;		/* 0 if no EMS, 1 if EMS but no page frame, */
				/* 2 if EMS with page frame */

char *RestoreFile = NULL;	/* Path of /Y file to restore state from */

char	*AltDir = NULL; 	/* Path to update to if split installation */

long	StorageSize;		/* Bytes required to install product */

char	*OEM_ProdName;		/* Name of product (e.g. "386MAX") */
char	*OEM_ProdFile;		/* Name of file w/o ext (e.g. "386MAX") */
char	*OEM_FileName;		/* Name of driver file (e.g. "386MAX.SYS") */
char	*OEM_OldName;		/* Old name of driver file */
char	*OEM_Readme;		// Readme file (Readme.max, readme.blu, readme)
char	*OEM_LoadBase;		// Basename for loader (386load, Move'EM)

int	OEM_IdentLen;		/* Number of products to brand */
int	OEM_IdentReqLen;	/* Number of products which MUST be branded */

char	HelpFullName[MAXPATH+1];
char	BackupDir[MAXPATH+1];	// Dir to put old product into

int	MoveUMB = 0;		// Set if Move'em install and XMS driver found
int	FilesBackedUp = 0;	// Count files backed up

char	*MultiBoot = NULL;	// Name of MultiBoot section to process
char	*OldMMLine = NULL;	// Previous memory manager line from CONFIG.SYS

WORD pascal POVR_MAC = 0xffff;	// Starting MAC in high DOS
CFGTEXT *CfgSys = NULL; 	// Start of CONFIG.SYS linked list in memory
PROTEXT *MaxPro = NULL; 	// Start of 386MAX.PRO linked list

WORD	WindowsVer = 0x300;	// A safe default in case we can't get winver
BOOL	ReadWinVer = FALSE;	// TRUE if we've gotten the version by reading
				// winver.exe; it's then OK to add NoExtraDOS

FILEDELTA *pFileDeltas = NULL;	// Head of changes gotten from STRIPMGR

