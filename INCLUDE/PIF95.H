/*
 *  Microsoft Confidential
 *  Copyright (C) Microsoft Corporation 1991-1995
 *  All Rights Reserved.
 *
 *
 *  PIF.H
 *  DOS Program Information File structures, constants, etc.
 */

#ifndef _INC_PIF
#define _INC_PIF

/* XLATOFF */
#ifndef RC_INVOKED
#pragma pack(1)         /* Assume byte packing throughout */
#endif  /* RC_INVOKED */
/* XLATON */

#define PIFNAMESIZE     30
#define PIFSTARTLOCSIZE 63
#define PIFDEFPATHSIZE  64
#define PIFPARAMSSIZE   64
#define PIFSHPROGSIZE   64
#define PIFSHDATASIZE   64
#define PIFDEFFILESIZE  80

#ifndef LF_FACESIZE
#define LF_FACESIZE     32
#endif

#define LARGEST_GROUP   sizeof(PROPPRG)

#define OPENPROPS_NONE          0x0000
#define OPENPROPS_RAWIO         0x0001
#define OPENPROPS_INFONLY       0x0002
#define OPENPROPS_FORCEREALMODE 0x0004
#define OPENPROPS_INHIBITPIF    0x8000

#define GETPROPS_NONE           0x0000
#define GETPROPS_RAWIO          0x0001

#define SETPROPS_NONE           0x0000
#define SETPROPS_RAWIO          0x0001
#define SETPROPS_CACHE          0x0002

#define FLUSHPROPS_NONE         0x0000
#define FLUSHPROPS_DISCARD      0x0001

#define CLOSEPROPS_NONE         0x0000
#define CLOSEPROPS_DISCARD      0x0001

#define CREATEPROPS_NONE        0x0000

#define DELETEPROPS_NONE        0x0000
#define DELETEPROPS_DISCARD     0x0001
#define DELETEPROPS_ABORT       0x0002

#define LOADPROPLIB_DEFER       0x0001

/* XLATOFF */
#ifndef FAR
#define FAR
#endif
/* XLATON */

#ifdef  RECT
#define _INC_WINDOWS
#endif

#ifndef _INC_WINDOWS

/* ASM
RECT    struc
        rcLeft      dw  ?
        rcTop       dw  ?
        rcRight     dw  ?
        rcBottom    dw  ?
RECT    ends
*/

/* XLATOFF */
typedef struct tagRECT {
    int left;
    int top;
    int right;
    int bottom;
} RECT;
typedef RECT *PRECT;
typedef RECT FAR *LPRECT;
/* XLATON */

#endif

/*
 *  Property groups, used by PIFMGR.DLL and VxD interfaces
 *
 *  The structures for each of the pre-defined, ordinal-based groups
 *  is a logical view of data in the associated PIF file, if any -- not a
 *  physical view.
 */

#define GROUP_PRG               1           // program group

#define PRG_DEFAULT             0
#define PRG_CLOSEONEXIT         0x0001      // MSflags & EXITMASK
#define PRG_NOSUGGESTMSDOS      0x0400      // see also: PfW386Flags & fNoSuggestMSDOS

#define PRGINIT_DEFAULT         0
#define PRGINIT_MINIMIZED       0x0001      // see also: PfW386Flags & fMinimized
#define PRGINIT_MAXIMIZED       0x0002      // see also: PfW386Flags & fMaximized
#define PRGINIT_WINLIE          0x0004      // see also: PfW386Flags & fWinLie
#define PRGINIT_REALMODE        0x0008      // see also: PfW386Flags & fRealMode
#define PRGINIT_REALMODESILENT  0x0100      // see also: PfW386Flags & fRealModeSilent
#define PRGINIT_AMBIGUOUSPIF    0x0400      // see also: PfW386Flags & fAmbiguousPIF
#define PRGINIT_NOPIF           0x1000      // no PIF found
#define PRGINIT_DEFAULTPIF      0x2000      // default PIF found
#define PRGINIT_INFSETTINGS     0x4000      // INF settings found
#define PRGINIT_INHIBITPIF      0x8000      // INF indicates that no PIF be created

/*
 *  Real mode option flags.  NOTE: this field is a dword.  The low word
 *  uses these flags to indicate required options.  The high word is used
 *  to specify "nice" but not required options.
 */
#define RMOPT_MOUSE		0x0001	    // Real mode mouse
#define RMOPT_EMS		0x0002	    // Expanded Memory
#define RMOPT_CDROM		0x0004	    // CD-ROM support
#define RMOPT_NETWORK		0x0008	    // Network support
#define RMOPT_DISKLOCK          0x0010      // disk locking required
#define RMOPT_PRIVATECFG        0x0020      // use private configuration (ie, CONFIG/AUTOEXEC)

#define ICONFILE_DEFAULT        "PIFMGR.DLL"
#define ICONINDEX_DEFAULT       0

typedef struct PROPPRG {                    /* prg */
    WORD    flPrg;                          // see PRG_ flags
    WORD    flPrgInit;                      // see PRGINIT_ flags
    char    achTitle[PIFNAMESIZE];          // name[30]
    char    achCmdLine[PIFSTARTLOCSIZE+PIFPARAMSSIZE+1];// startfile[63] + params[64]
    char    achWorkDir[PIFDEFPATHSIZE];     // defpath[64]
    WORD    wHotKey;			    // PfHotKeyScan thru PfHotKeyVal
    char    achIconFile[PIFDEFFILESIZE];    // name of file containing icon
    WORD    wIconIndex;                     // index of icon within file
    DWORD   dwEnhModeFlags;                 // reserved enh-mode flags
    DWORD   dwRealModeFlags;                // real-mode flags (see RMOPT_*)
    char    achOtherFile[PIFDEFFILESIZE];   // name of "other" file in directory
    char    achPIFFile[PIFDEFFILESIZE];     // name of PIF file
} PROPPRG;
typedef PROPPRG *PPROPPRG;
typedef PROPPRG FAR *LPPROPPRG;
typedef const PROPPRG FAR *LPCPROPPRG;

#define GROUP_TSK               2           // tasking group

#define TSK_DEFAULT             (TSK_BACKGROUND)
#define TSK_ALLOWCLOSE          0x0001      // PfW386Flags & fEnableClose
#define TSK_BACKGROUND          0x0002      // PfW386Flags & fBackground
#define TSK_NOWARNTERMINATE     0x0010      // Don't warn before closing
#define TSK_NOSCREENSAVER       0x0020      // Do not activate screen saver

#define TSKINIT_DEFAULT         0

#define TSKIDLESENS_DEFAULT     50          // % (min-max == 0-100)

typedef struct PROPTSK {                    /* tsk */
    WORD    flTsk;                          // see TSK_ flags
    WORD    flTskInit;                      // see TSKINIT_ flags
    WORD    wReserved1;                     // (reserved, must be zero)
    WORD    wReserved2;                     // (reserved, must be zero)
    WORD    wReserved3;                     // (reserved, must be zero)
    WORD    wReserved4;                     // (reserved, must be zero)
    WORD    wIdleSensitivity;               // %, also affects PfW386Flags & fPollingDetect
} PROPTSK;
typedef PROPTSK *PPROPTSK;
typedef PROPTSK FAR *LPPROPTSK;

#define GROUP_VID               3           // video group

#define VID_DEFAULT             (VID_TEXTEMULATE)
#define VID_TEXTEMULATE         0x0001      // PfW386Flags2 & fVidTxtEmulate
#define VID_RETAINMEMORY        0x0080      // PfW386Flags2 & fVidRetainAllo
#define VID_FULLSCREEN          0x0100      // PfW386Flags  & fFullScreen

#define VIDINIT_DEFAULT         0

#define VIDSCREENLINES_MIN      0           // in # lines (0 = use VDD value)
#define VIDSCREENLINES_DEFAULT  0           // in # lines

typedef struct PROPVID {                    /* vid */
    WORD    flVid;                          // see VID_ flags
    WORD    flVidInit;                      // see VIDINIT_ flags
    WORD    wReserved1;                     // (reserved, must be zero)
    WORD    wReserved2;                     // (reserved, must be zero)
    WORD    wReserved3;                     // (reserved, must be zero)
    WORD    cScreenLines;                   // ([NonWindowsApp]:ScreenLines)
} PROPVID;
typedef PROPVID *PPROPVID;
typedef PROPVID FAR *LPPROPVID;

#define GROUP_MEM               4           // memory group

#define MEM_DEFAULT             0

#define MEMINIT_DEFAULT         0
#define MEMINIT_NOHMA           0x0001      // PfW386Flags & fNoHMA
#define MEMINIT_LOWLOCKED       0x0002      // PfW386Flags & fVMLocked
#define MEMINIT_EMSLOCKED       0x0004      // PfW386Flags & fEMSLocked
#define MEMINIT_XMSLOCKED       0x0008      // PfW386Flags & fXMSLocked
#define MEMINIT_GLOBALPROTECT   0x0010      // PfW386Flags & fGlobalProtect

#define MEMLOW_MIN              0           // in KB
#define MEMLOW_DEFAULT          0           // in KB
#define MEMLOW_MAX              640         // in KB

#define MEMEMS_MIN              0           // in KB
#define MEMEMS_DEFAULT          0           // in KB
#define MEMEMS_MAX              0xFFFF      // in KB

#define MEMXMS_MIN              0           // in KB
#define MEMXMS_DEFAULT          0           // in KB
#define MEMXMS_MAX              0xFFFF      // in KB

typedef struct PROPMEM {                    /* mem */
    WORD    flMem;                          // see MEM_ flags
    WORD    flMemInit;                      // see MEMINIT_ flags
    WORD    wMinLow;                        // PfW386minmem
    WORD    wMaxLow;                        // PfW386maxmem
    WORD    wMinEMS;                        // PfMinEMMK
    WORD    wMaxEMS;                        // PfMaxEMMK
    WORD    wMinXMS;                        // PfMinXmsK
    WORD    wMaxXMS;                        // PfMaxXmsK
} PROPMEM;
typedef PROPMEM *PPROPMEM;
typedef PROPMEM FAR *LPPROPMEM;

#define GROUP_KBD               5           // keyboard group

#define KBD_DEFAULT             (KBD_FASTPASTE)
#define KBD_FASTPASTE           0x0001      // PfW386Flags & fINT16Paste
#define KBD_NOALTTAB            0x0020      // PfW386Flags & fALTTABdis
#define KBD_NOALTESC            0x0040      // PfW386Flags & fALTESCdis
#define KBD_NOALTSPACE          0x0080      // PfW386Flags & fALTSPACEdis
#define KBD_NOALTENTER          0x0100      // PfW386Flags & fALTENTERdis
#define KBD_NOALTPRTSC          0x0200      // PfW386Flags & fALTPRTSCdis
#define KBD_NOPRTSC             0x0400      // PfW386Flags & fPRTSCdis
#define KBD_NOCTRLESC           0x0800      // PfW386Flags & fCTRLESCdis

#define KBDINIT_DEFAULT         0

#define KBDALTDELAY_MIN             1
#define KBDALTDELAY_DEFAULT         5
#define KBDALTDELAY_MAX             5000

#define KBDALTPASTEDELAY_MIN        1
#define KBDALTPASTEDELAY_DEFAULT    25
#define KBDALTPASTEDELAY_MAX        5000

#define KBDPASTEDELAY_MIN           1
#define KBDPASTEDELAY_DEFAULT       3
#define KBDPASTEDELAY_MAX           5000

#define KBDPASTEFULLDELAY_MIN       1
#define KBDPASTEFULLDELAY_DEFAULT   200
#define KBDPASTEFULLDELAY_MAX       5000

#define KBDPASTETIMEOUT_MIN         1
#define KBDPASTETIMEOUT_DEFAULT     1000
#define KBDPASTETIMEOUT_MAX         5000

#define KBDPASTESKIP_MIN            1
#define KBDPASTESKIP_DEFAULT        2
#define KBDPASTESKIP_MAX            100

#define KBDPASTECRSKIP_MIN          1
#define KBDPASTECRSKIP_DEFAULT      10
#define KBDPASTECRSKIP_MAX          100

typedef struct PROPKBD {                    /* kbd */
    WORD    flKbd;                          // see KBD_ flags
    WORD    flKbdInit;                      // see KBDINIT_ flags
    WORD    msAltDelay;                     // ([386Enh]:AltKeyDelay)
    WORD    msAltPasteDelay;                // ([386Enh]:AltPasteDelay)
    WORD    msPasteDelay;                   // ([386Enh]:KeyPasteDelay)
    WORD    msPasteFullDelay;               // ([386Enh]:KeyBufferDelay)
    WORD    msPasteTimeout;                 // ([386Enh]:KeyPasteTimeOut)
    WORD    cPasteSkip;                     // ([386Enh]:KeyPasteSkipCount)
    WORD    cPasteCRSkip;                   // ([386Enh]:KeyPasteCRSkipCount)
} PROPKBD;
typedef PROPKBD *PPROPKBD;
typedef PROPKBD FAR *LPPROPKBD;

#define GROUP_MSE               6           // mouse group

/* No VxD currently pays attention to PROPMSE. VMDOSAPP should know how to
 * handle all cases resulting from a change in these flags.
 *
 * Note that MSE_WINDOWENABLE corresponds to the Windows NT "QuickEdit"
 * property, except backwards.
 */

#define MSE_DEFAULT             (MSE_WINDOWENABLE)
#define MSE_WINDOWENABLE        0x0001      // ([NonWindowsApp]:MouseInDosBox)
#define MSE_EXCLUSIVE           0x0002      //

#define MSEINIT_DEFAULT         0           // default flags

typedef struct PROPMSE {                    /* mse */
    WORD    flMse;                          // see MSE_ flags
    WORD    flMseInit;                      // see MSEINIT_ flags
} PROPMSE;
typedef PROPMSE *PPROPMSE;
typedef PROPMSE FAR *LPPROPMSE;

#define GROUP_FNT               8           // font group

#define FNT_DEFAULT             (FNT_BOTHFONTS | FNT_AUTOSIZE)
#define FNT_RASTERFONTS         0x0004      // allow raster fonts in dialog
#define FNT_TTFONTS             0x0008      // allow truetype fonts in dialog
#define FNT_BOTHFONTS           (FNT_RASTERFONTS | FNT_TTFONTS)
#define FNT_AUTOSIZE            0x0010      // enable auto-sizing
#define FNT_RASTER              0x0400      // specified font is raster
#define FNT_TT                  0x0800      // specified font is truetype

#define FNT_FONTMASK            (FNT_BOTHFONTS)
#define FNT_FONTMASKBITS        2           // # of bits shifted left

#define FNTINIT_DEFAULT         0
#define FNTINIT_NORESTORE       0x0001      // don't restore on restart

typedef struct PROPFNT {                    /* fnt */
    WORD    flFnt;                          // see FNT_ flags
    WORD    flFntInit;                      // see FNTINIT_ flags
    WORD    cxFont;                         // width of desired font
    WORD    cyFont;                         // height of desired font
    WORD    cxFontActual;                   // actual width of desired font
    WORD    cyFontActual;                   // actual height of desired font
    char    achRasterFaceName[LF_FACESIZE]; // name to use for raster font
    char    achTTFaceName[LF_FACESIZE];     // name to use for tt font
    WORD    wCurrentCP;                     // Current Codepage
} PROPFNT;
typedef PROPFNT *PPROPFNT;
typedef PROPFNT FAR *LPPROPFNT;

#define GROUP_WIN               9          // window group

#define WIN_DEFAULT             (WIN_SAVESETTINGS | WIN_TOOLBAR)
#define WIN_SAVESETTINGS        0x0001      // save settings on exit (default)
#define WIN_TOOLBAR             0x0002      // enable toolbar

#define WININIT_DEFAULT         0
#define WININIT_NORESTORE       0x0001      // don't restore on restart

typedef struct PROPWIN {                    /* win */
    WORD    flWin;                          // see WIN_ flags
    WORD    flWinInit;                      // see WININIT flags
    WORD    cxCells;                        // width in cells
    WORD    cyCells;                        // height in cells
    WORD    cxClient;                       // width of client window
    WORD    cyClient;                       // height of client window
    WORD    cxWindow;                       // width of entire window
    WORD    cyWindow;                       // height of entire window
#ifdef WPF_SETMINPOSITION                   // if windows.h is included
    WINDOWPLACEMENT wp;                     // then use WINDOWPLACEMENT type
#else                                       // else define equivalent structure
    WORD    wLength;
    WORD    wShowFlags;
    WORD    wShowCmd;
    WORD    xMinimize;
    WORD    yMinimize;
    WORD    xMaximize;
    WORD    yMaximize;
    RECT    rcNormal;
#endif
} PROPWIN;
typedef PROPWIN *PPROPWIN;
typedef PROPWIN FAR *LPPROPWIN;

#define GROUP_ENV               10          // environment/startup group

#define ENV_DEFAULT             0

#define ENVINIT_DEFAULT         0

#define ENVSIZE_MIN             0
#define ENVSIZE_DEFAULT         0
#define ENVSIZE_MAX             4096

#define ENVDPMI_MIN             0           // in KB
#define ENVDPMI_DEFAULT         0           // in KB (0 = Auto)
#define ENVDPMI_MAX             0xFFFF      // in KB

typedef struct PROPENV {                    /* env */
    WORD    flEnv;                          // see ENV_ flags
    WORD    flEnvInit;                      // see ENVINIT_ flags
    char    achBatchFile[PIFDEFFILESIZE];   //
    WORD    cbEnvironment;                  // ([386Enh]:CommandEnvSize)
    WORD    wMaxDPMI;                       // (NEW)
} PROPENV;
typedef PROPENV *PPROPENV;
typedef PROPENV FAR *LPPROPENV;

#define MAX_GROUP               0x0FF

/*
 *  PIF "file" structures, used by .PIFs
 */

#define PIFEXTSIGSIZE   16                  // Length of extension signatures
#define MAX_GROUP_NAME  PIFEXTSIGSIZE       //
#define STDHDRSIG       "MICROSOFT PIFEX"   // extsig value for stdpifext
#define LASTHDRPTR      0xFFFF              // This value in the
                                            //  extnxthdrfloff field indicates
                                            //   there are no more extensions.
#define W286HDRSIG30     "WINDOWS 286 3.0"
#define W386HDRSIG30     "WINDOWS 386 3.0"
#define WENHHDRSIG40     "WINDOWS VMM 4.0"  //

#define CONFIGHDRSIG40   "CONFIG  SYS 4.0"  //
#define AUTOEXECHDRSIG40 "AUTOEXECBAT 4.0"  //

#define MAX_CONFIG_SIZE     4096
#define MAX_AUTOEXEC_SIZE   4096

#define CONFIGFILE      "\\CONFIG.SYS"      // normal filenames
#define AUTOEXECFILE    "\\AUTOEXEC.BAT"

#define MCONFIGFILE     "\\CONFIG.APP"      // msdos-mode temp filenames
#define MAUTOEXECFILE   "\\AUTOEXEC.APP"

#define WCONFIGFILE     "\\CONFIG.WOS"      // windows-mode temp filenames
#define WAUTOEXECFILE   "\\AUTOEXEC.WOS"

typedef struct PIFEXTHDR {                  /* peh */
    char    extsig[PIFEXTSIGSIZE];
    WORD    extnxthdrfloff;
    WORD    extfileoffset;
    WORD    extsizebytes;
} PIFEXTHDR;
typedef PIFEXTHDR *PPIFEXTHDR;
typedef PIFEXTHDR FAR *LPPIFEXTHDR;

/* Flags for MSflags
 */

#define fResident       0x01    // Directly Modifies: Memory
#define fGraphics       0x02    // Screen Exchange: Graphics/Text
#define fNoSwitch       0x04    // Program Switch: Prevent
#define fNoGrab         0x08    // Screen Exchange: None
#define fDestroy        0x10    // Close Window on exit
#define fCOM2           0x40    // Directly Modifies: COM2
#define fCOM1           0x80    // Directly Modifies: COM1

#define MEMMASK         fResident
#define GRAPHMASK       fGraphics
#define TEXTMASK        ((BYTE)(~GRAPHMASK))
#define PSMASK          fNoSwitch
#define SGMASK          fNoGrab
#define EXITMASK        fDestroy
#define COM2MASK        fCOM2
#define COM1MASK        fCOM1

/* Flags for behavior
 */
#define fScreen         0x80    // Directly Modifies: Screen
#define fForeground     0x40    // Set same as fScreen (alias)
#define f8087           0x20    // No PIFEDIT control
#define fKeyboard       0x10    // Directly Modifies: Keyboard

#define SCRMASK         (fScreen + fForeground)
#define MASK8087        f8087
#define KEYMASK         fKeyboard

/* Flags for sysflags
 */

#define SWAPMASK        0x20
#define PARMMASK        0x40

/*
 * All strings in the STDPIF are in the OEM character set.
 */
typedef struct STDPIF {                     /* std */ //Examples
    BYTE    unknown;                        // 0x00     0x00
    BYTE    id;                             // 0x01     0x78
    char    appname[PIFNAMESIZE];           // 0x02     'MS-DOS Prompt'
    WORD    maxmem;                         // 0x20     0x0200 (512Kb)
    WORD    minmem;                         // 0x22     0x0080 (128Kb)
    char    startfile[PIFSTARTLOCSIZE];     // 0x24     "COMMAND.COM"
    BYTE    MSflags;                        // 0x63     0x10
    BYTE    reserved;                       // 0x64     0x00
    char    defpath[PIFDEFPATHSIZE];        // 0x65     "\"
    char    params[PIFPARAMSSIZE];          // 0xA5     ""
    BYTE    screen;                         // 0xE5     0x00
    BYTE    cPages;                         // 0xE6     0x01 (ALWAYS!)
    BYTE    lowVector;                      // 0xE7     0x00 (ALWAYS!)
    BYTE    highVector;                     // 0xE8     0xFF (ALWAYS!)
    BYTE    rows;                           // 0xE9     0x19 (Not used)
    BYTE    cols;                           // 0xEA     0x50 (Not used)
    BYTE    rowoff;                         // 0xEB     0x00 (Not used)
    BYTE    coloff;                         // 0xEC     0x00 (Not used)
    WORD    sysmem;                         // 0xED   0x0007 (Not used; 7=>Text, 23=>Grfx/Mult Text)
    char    shprog[PIFSHPROGSIZE];          // 0xEF     0's  (Not used)
    char    shdata[PIFSHDATASIZE];          // 0x12F    0's  (Not used)
    BYTE    behavior;                       // 0x16F    0x00
    BYTE    sysflags;                       // 0x170    0x00 (Not used)
} STDPIF;
typedef STDPIF *PSTDPIF;
typedef STDPIF FAR *LPSTDPIF;

/* Flags for PfW286Flags
 */

#define fALTTABdis286   0x0001
#define fALTESCdis286   0x0002
#define fALTPRTSCdis286 0x0004
#define fPRTSCdis286    0x0008
#define fCTRLESCdis286  0x0010
#define fNoSaveVid286   0x0020              // New for 3.10
#define fCOM3_286       0x4000
#define fCOM4_286       0x8000

typedef struct W286PIF30 {                  /* 286 */ //Examples
    WORD    PfMaxXmsK;                      // 0x19D    0x0000
    WORD    PfMinXmsK;                      // 0x19F    0x0000
    WORD    PfW286Flags;                    // 0x1A1    0x0000
} W286PIF30;
typedef W286PIF30 *PW286PIF30;
typedef W286PIF30 FAR *LPW286PIF30;

/* Flags for PfW386Flags
 */

#define fEnableClose    0x00000001          //
#define fEnableCloseBit             0       //
#define fBackground     0x00000002          //
#define fBackgroundBit              1       //
#define fFullScreen     0x00000008          //
#define fFullScreenBit              3       //
#define fALTTABdis      0x00000020          //
#define fALTTABdisBit               5       //
#define fALTESCdis      0x00000040          //
#define fALTESCdisBit               6       //
#define fALTSPACEdis    0x00000080          //
#define fALTSPACEdisBit             7       //
#define fALTENTERdis    0x00000100          //
#define fALTENTERdisBit             8       //
#define fALTPRTSCdis    0x00000200          //
#define fALTPRTSCdisBit             9       //
#define fPRTSCdis       0x00000400          //
#define fPRTSCdisBit                10      //
#define fCTRLESCdis     0x00000800          //
#define fCTRLESCdisBit              11      //
#define fPollingDetect  0x00001000          //
#define fPollingDetectBit           12      //
#define fNoHMA          0x00002000          //
#define fNoHMABit                   13      //
#define fHasHotKey      0x00004000          //
#define fHasHotKeyBit               14      //
#define fEMSLocked      0x00008000          //
#define fEMSLockedBit               15      //
#define fXMSLocked      0x00010000          //
#define fXMSLockedBit               16      //
#define fINT16Paste     0x00020000          //
#define fINT16PasteBit              17      //
#define fVMLocked       0x00040000          //
#define fVMLockedBit                18      //
#define fGlobalProtect  0x00080000          //  New for 4.00
#define fGlobalProtectBit           19      //  New for 4.00
#define fMinimized      0x00100000          //  New for 4.00
#define fMinimizedBit               20      //  New for 4.00
#define fMaximized      0x00200000          //  New for 4.00
#define fMaximizedBit               21      //  New for 4.00
#define fRealMode       0x00800000          //  New for 4.00
#define fRealModeBit                23      //  New for 4.00
#define fWinLie         0x01000000          //  New for 4.00
#define fWinLieBit                  24      //  New for 4.00
#define fNoSuggestMSDOS 0x04000000          //  New for 4.00
#define fNoSuggestMSDOSBit          26      //  New for 4.00
#define fRealModeSilent 0x10000000          //  New for 4.00
#define fRealModeSilentBit          28      //  New for 4.00
#define fAmbiguousPIF   0x40000000          //  New for 4.00
#define fAmbiguousPIFBit            30      //  New for 4.00

/* Flags for PfW386Flags2
 *
 *  NOTE THAT THE LOW 16 BITS OF THIS DWORD ARE VDD RELATED
 *  NOTE THAT ALL OF THE LOW 16 BITS ARE RESERVED FOR VIDEO BITS
 *
 *  You cannot monkey with these bits locations without breaking
 *  all VDDs as well as all old PIFs. SO DON'T MESS WITH THEM.
 */

#define fVDDMask        0x0000FFFF          //
#define fVDDMinBit                  0       //
#define fVDDMaxBit                  15      //

#define fVidTxtEmulate  0x00000001          //
#define fVidTxtEmulateBit           0       //
#define fVidNoTrpTxt    0x00000002          // Obsolete
#define fVidNoTrpTxtBit             1       // Obsolete
#define fVidNoTrpLRGrfx 0x00000004          // Obsolete
#define fVidNoTrpLRGrfxBit          2       // Obsolete
#define fVidNoTrpHRGrfx 0x00000008          // Obsolete
#define fVidNoTrpHRGrfxBit          3       // Obsolete
#define fVidTextMd      0x00000010          // Obsolete
#define fVidTextMdBit               4       // Obsolete
#define fVidLowRsGrfxMd 0x00000020          // Obsolete
#define fVidLowRsGrfxMdBit          5       // Obsolete
#define fVidHghRsGrfxMd 0x00000040          // Obsolete
#define fVidHghRsGrfxMdBit          6       // Obsolete
#define fVidRetainAllo  0x00000080          //
#define fVidRetainAlloBit           7       //

typedef struct W386PIF30 {                  /* 386 */ //Examples
    // These new maxmem/minmem fields allow values
    // that will not conflict with the 286-specific values
    WORD    PfW386maxmem;                   // 0x1B9    0xFFFF (-1)
    WORD    PfW386minmem;                   // 0x1BB    0xFFFF (-1)
    WORD    PfFPriority;                    // 0x1BD    0x0064 (100)
    WORD    PfBPriority;                    // 0x1BF    0x0032 (50)
    WORD    PfMaxEMMK;                      // 0x1C1    0x0000 (0)
    WORD    PfMinEMMK;                      // 0x1C3    0x0000 (0)
    WORD    PfMaxXmsK;                      // 0x1C5    0x0800 (2048)
    WORD    PfMinXmsK;                      // 0x1C7    0x0000 (0)
    DWORD   PfW386Flags;                    // 0x1C9    0x00021003
    DWORD   PfW386Flags2;                   // 0x1CD    0x0000001F
    WORD    PfHotKeyScan;                   // 0x1D1    Scan code in lower byte
    WORD    PfHotKeyShVal;                  // 0x1D3    Shift state
    WORD    PfHotKeyShMsk;                  // 0x1D5    Mask for shift states interested in
    BYTE    PfHotKeyVal;                    // 0x1D7    Enhanced flags
    BYTE    PfHotKeyPad[9];                 // 0x1D8    Pad Hot key section to 16 bytes
    char    PfW386params[PIFPARAMSSIZE];    // 0x1E1
} W386PIF30;
typedef W386PIF30 *PW386PIF30;
typedef W386PIF30 FAR *LPW386PIF30;

/* AssociateProperties associations
 */

#define HVM_ASSOCIATION         1
#define HWND_ASSOCIATION        2

/* SHEETTYPEs for AddPropertySheet/EnumPropertySheets
 */

#define SHEETTYPE_SIMPLE    0
#define SHEETTYPE_ADVANCED  1

/*  External function ordinals and prototypes
 */

#define ORD_OPENPROPERTIES      2
#define ORD_GETPROPERTIES       3
#define ORD_SETPROPERTIES       4
#define ORD_EDITPROPERTIES      5
#define ORD_FLUSHPROPERTIES     6
#define ORD_ENUMPROPERTIES      7
#define ORD_ASSOCIATEPROPERTIES 8
#define ORD_CLOSEPROPERTIES     9
#define ORD_LOADPROPERTYLIB     10
#define ORD_ENUMPROPERTYLIBS    11
#define ORD_FREEPROPERTYLIB     12
#define ORD_ADDPROPERTYSHEET    13
#define ORD_REMOVEPROPERTYSHEET 14
#define ORD_LOADPROPERTYSHEETS  15
#define ORD_ENUMPROPERTYSHEETS  16
#define ORD_FREEPROPERTYSHEETS  17
#define ORD_CREATESTARTUPPROPERTIES 20
#define ORD_DELETESTARTUPPROPERTIES 21

typedef UINT PIFWIZERR;

#define PIFWIZERR_SUCCESS	    0
#define PIFWIZERR_GENERALFAILURE    1
#define PIFWIZERR_INVALIDPARAM	    2
#define PIFWIZERR_UNSUPPORTEDOPT    3
#define PIFWIZERR_OUTOFMEM	    4
#define PIFWIZERR_USERCANCELED	    5

#define WIZACTION_UICONFIGPROP	    0
#define WIZACTION_SILENTCONFIGPROP  1
#define WIZACTION_CREATEDEFCLEANCFG 2

/* XLATOFF */

#ifdef WINAPI
PIFWIZERR WINAPI AppWizard(HWND hwnd, int hProps, UINT action);

int  WINAPI OpenProperties(LPCSTR lpszApp, LPCSTR lpszPIF, int hInf, int flOpt);
int  WINAPI GetProperties(int hProps, LPCSTR lpszGroup, LPVOID lpProps, int cbProps, int flOpt);
int  WINAPI SetProperties(int hProps, LPCSTR lpszGroup, const VOID FAR *lpProps, int cbProps, int flOpt);
int  WINAPI EditProperties(int hProps, LPCSTR lpszTitle, UINT uStartPage, HWND hwnd, UINT uMsgPost);
int  WINAPI FlushProperties(int hProps, int flOpt);
int  WINAPI EnumProperties(int hProps);
long WINAPI AssociateProperties(int hProps, int iAssociate, long lData);
int  WINAPI CloseProperties(int hProps, int flOpt);
int  WINAPI CreateStartupProperties(int hProps, int flOpt);
int  WINAPI DeleteStartupProperties(int hProps, int flOpt);

#ifdef  PIF_PROPERTY_SHEETS
int  WINAPI LoadPropertyLib(LPCSTR lpszDLL, int fLoad);
int  WINAPI EnumPropertyLibs(int iLib, LPHANDLE lphDLL, LPSTR lpszDLL, int cbszDLL);
BOOL WINAPI FreePropertyLib(int hLib);
int  WINAPI AddPropertySheet(const PROPSHEETPAGE FAR *lppsi, int iType);
BOOL WINAPI RemovePropertySheet(int hSheet);
int  WINAPI LoadPropertySheets(int hProps, int flags);
int  WINAPI EnumPropertySheets(int hProps, int iType, int iSheet, LPPROPSHEETPAGE lppsi);
int  WINAPI FreePropertySheets(int hProps, int flags);
#endif  /* PIF_PROPERTY_SHEETS */

#endif  /* WINAPI */

#ifndef RC_INVOKED
#pragma pack()          /* Revert to default packing */
#endif  /* RC_INVOKED */

/* XLATON */

#endif // _INC_PIF
