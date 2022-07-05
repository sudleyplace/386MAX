/*' $Header:   P:/PVCS/MAX/INSTALL/EXTN.H_V   1.1   25 Oct 1995 18:50:02   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * EXTN.H								      *
 *									      *
 * Global referencing declaration file					      *
 *									      *
 ******************************************************************************/

/*
 * Global definition file to be included with WIN_TEST.C
 *	 Patrick Devlin - December, 1990
 * Removed extra space and ruler lines from this file  -HG
 *
 * The following set of variables gets initialized during startup from main:
 *
 */

extern	 char	 *EXCPTN_LIST[];

extern	 int	  fUpdate;		 // Update or install flag
extern	 int	  MONO; 		 // Recover MDA regions?
extern	 int	  BIOS; 		 // Recover BIOS fill patterns?
extern	 int	  VGAWARN;		 // VGASWAP / recovery warning flags
extern	 int	  VGAMEM;		 // VGA installed memory

extern	 FREEROM  mono_mem [];
extern	 int	  cnt_mono;		 // Number of entries in mono_mem

extern	 char	  *bcf_dpfne;
extern	 char	  *con_dpfne;
extern	 char	  *pro_dpfne;
extern	 char	  *preinst_bat;
extern	 char	  *groupname;
extern	 WORD	  BIOSCRC;
extern	 int	  mcasys;
extern	 int	  bcfsys;

extern	 unsigned saved_drive;
extern	 char	  saved_path [];
extern	 char	  source_drive [];
extern	 char	  source_subdir [];
extern	 char	  dest_drive;
extern	 char	  dest_subdir [];
extern	 char	  pro_drive;
extern	 char	  boot_drive;
extern	 char	  update_subdir [];

// End of startup variables list

extern	 int	  security_crc;
extern	 int	  SECURITY_LEN;

extern	 WORD	 dcache;
extern	 WORD	 dcache_arg;
extern	 int	 dcache_arg2;

extern	 char	  security_pattern [];
extern	 char	  drv_drive[];			 // parsed device= drive
extern	 char	  drv_dir[];			 //  ...	   dir
extern	 char	  drv_fname[];			 //  ...	   name
extern	 char	  drv_ext[];			 //  ...	   ext
extern	 char	  drv_path[];			 // complete path
extern	 char	  edit_prolast[];

extern	 enum boolean	    con_fnd;
extern	 enum boolean change_config;
extern	 enum boolean	    mgr_fnd;
extern	 enum boolean	    emm_fnd;
extern	 enum boolean	    pro_fnd;
extern	 enum boolean	    drv_fnd;
extern	 enum boolean	    src_fnd;
extern	 enum boolean	    bcf_fnd;
extern	 enum boolean	    win_fnd;
extern	 enum boolean	      WIN30;
extern	 enum boolean	  xbios_fnd;
extern	 enum boolean	       BACK;
extern	 enum boolean	  autox_fnd;
extern	 enum boolean	  qutil_fnd;

extern	 FILESTRUC inst;

extern	 FILESTRUC ident[2][8];

extern	 int	  MAXDSK;
extern	 int	  DESTDSK;

extern	 char	  user_name [];
extern	 char	  user_company [];
extern	 char	  user_number [];

extern	 char	*RecallString;

extern	 int	VideoMode;
extern	 int	VideoSet;

extern	 int	ProductSet;
extern	 int	ReInstall;
extern	 int	Overwrite;
extern	 int	GraphicsLogo;
extern	 int	Backup;
extern	 int	VideoReset;
extern	 int	DiskCacheTest;
extern	 BOOL	SnowControl;
extern	 BOOL	PatchPrep;
extern	 BOOL	FreshInstall;
extern	 BOOL	InChild;
extern	 BOOL	AllBCFs;
extern	 BOOL	NewMachine;
extern	 BOOL	MaxInst;
extern	 int	EMSType;

extern	 char	*RestoreFile;

extern	 char	*AltDir;

extern	 long	StorageSize;

extern	 char	*OEM_ProdName;
extern	 char	*OEM_ProdFile;	  /* Name of file w/o ext (e.g. "386MAX") */
extern	 char	*OEM_FileName;
extern	 char	*OEM_OldName;
extern	 char	*OEM_Archive;	  /* Basename of archive file (.# added) */
extern	 char	*OEM_Readme;
extern	 char	*OEM_LoadBase;

extern	 int	OEM_IdentLen;	  /* Number of products to brand */
extern	 int	OEM_IdentReqLen;  /* Number of products which MUST be branded */

extern	 char	HelpFullName[];
extern	 char	BackupDir[];

extern	 int	MoveUMB;
extern	 int	FilesBackedUp;

extern	 char	*MultiBoot;
extern	 char	*OldMMLine;

extern	 WORD	pascal POVR_MAC;
extern	 CFGTEXT *CfgSys;
extern	 PROTEXT *MaxPro;

extern	 WORD	WindowsVer;
extern	 BOOL	ReadWinVer;

/* Variables and functions from RAMSCAN.ASM */
extern	 char	MAXINFOVER[];	/* "6;03" */
extern	 int	MAXPRES(void);

extern FILEDELTA *pFileDeltas;

