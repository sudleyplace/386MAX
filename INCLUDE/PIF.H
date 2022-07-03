/*' $Header:   P:/PVCS/MAX/INCLUDE/PIF.H_V   1.1   02 Jun 1997 14:37:32   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1992-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * PIF.H								      *
 *									      *
 * Windows .PIF structure and equates					      *
 *									      *
 ******************************************************************************/

#ifndef _INC_WINDOWS
#define STRICT			// Enable strict type checking
#define NOCOMM			// Avoid inclusion of comm driver stuff
#define OEMRESOURCE		// Include OBM_xxx
#include <windows.h>
#endif	/* #ifndef _INC_WINDOWS */

typedef struct _PIFHDR {	// Windows 2.x section taken from TopView
    BYTE	Reserved0;	// 000: Reserved
    BYTE	CheckSum;	// 001: Checksum of bytes 002 thru 170
    char	Title[30];	// 002: Program title padded with blanks
    WORD	DosMaxS;	// 020: Low DOS max /S
    WORD	DosMinS;	// 022: Low DOS min /S
    char	PgmName[63];	// 024: Program name ASCIZ
    BYTE	Flags1; 	// 063: Microsoft behavior bits
				//	0x01 Modifies memory (fResident)
				//	0x02 Video mode graphics /S (fGraphics)
				//	0x04 Prevent pgm switch /S (fNoSwitch)
				//	0x08 No screen exchange /S (fNoGrab)
				//	0x10 Close window on exit (fDestroy)
				//	0x40 Modify COM2 /S (fCOM2)
				//	0x80 Modify COM1 /S (fCOM1)
    BYTE	Reserved1;	// 064: Reserved
    char	StartupDir[64]; // 065: Startup directory ASCIZ
    char	CmdLineS[64];	// 0A5: Optional parameters ASCIZ /S
    BYTE	ScreenType;	// 0E5: Windows doesn't use this
    BYTE	ScreenPages;	// 0E6: Windows doesn't use this (always 1)
    BYTE	IntVecLow;	// 0E7: Low bound of INT vectors (always 0)
    BYTE	IntVecHigh;	// 0E8: High bound of INT vectors (always FF)
    BYTE	ScrnRows;	// 0E9: Windows doesn't use this
    BYTE	ScrnCols;	// 0EA: Windows doesn't use this
    BYTE	RowOffs;	// 0EB: Windows doesn't use this
    BYTE	ColOffs;	// 0EC: Windows doesn't use this
    WORD	SystemMem;	// 0ED: System memory (7 - text, 23 - graphics)
    char	SharedProg[64]; // 0EF: Windows doesn't use this
    char	SharedData[64]; // 12F: Windows doesn't use this
    BYTE	Flags2; 	// 16F: BehavByte
				//	0x80 fFullScreen
				//	0x10 Modify keyboard /S
    BYTE	SystemFlags;	// 170: TopView behavior bits
				// 171:
} PIFHDR, * PPIFHDR, FAR * LPPIFHDR;

typedef struct _PIFSIG {
    char	Signature[16];	// 00: "MICROSOFT PIFEX", 0
				// 00: "WINDOWS 286 3.0", 0
				// 00: "WINDOWS 386 3.0", 0
				// 00: "WINDOWS VMM 4.0", 0
    WORD	NextOff;	// 10: Lseek offset to next signature, or -1
    WORD	DataOff;	// 12: Lseek offset to data section
    WORD	DataLen;	// 14: Length of data section
				// 16:
} PIFSIG, * PPIFSIG, FAR * LPPIFSIG;


typedef struct _PIF286 {
    WORD	XmsMax; 	// 00: XMS max
    WORD	XmsMin; 	// 02: XMS min
    BYTE	Flags1; 	// 04: Flags 1
				//     0x01 Alt-Tab reserved
				//     0x02 Alt-Esc reserved
				//     0x04 Alt-Prtsc reserved
				//     0x08 Prtsc reserved
				//     0x10 Ctrl-Esc reserved
				//     0x20 No save screen
    BYTE	Flags2; 	// 05: Flags 2
				//     0x40 Modify COM3
				//     0x80 Modify COM4
				// 06:
} PIF286, * PPIF286, FAR * LPPIF286;

typedef struct _PIF386 {
    WORD	DosMax; 	// 00: DOS max
    WORD	DosMin; 	// 02: DOS min
    WORD	ForePrio;	// 04: Foreground priority
    WORD	BackPrio;	// 06: Background priority
    WORD	EmsMax; 	// 08: EMS max
    WORD	EmsMin; 	// 0A: EMS min
    WORD	XmsMax; 	// 0C: XMS max
    WORD	XmsMin; 	// 0E: XMS min

// WinFlags, TaskFlags, and Flags are a DWORD called pifW386Flags internally
// The bit definitions are in \WIN386\INCLUDE\STATUSFL.INC

//  DWORD	StatusFlags	// 10: PfW386Flags

#define fEnableClose	0x00000001
#define fNewBackgrnd	0x00000002
#define fNewExclusive	0x00000004
#define fNewFullScr	0x00000008

#define fALTTABdis	0x00000020
#define fALTESCdis	0x00000040
#define fALTSPACEdis	0x00000080
#define fALTENTERdis	0x00000100
#define fALTPRTSCdis	0x00000200
#define fPRTSCdis	0x00000400
#define fCTRLESCdis	0x00000800
#define fPollingDetect	0x00001000
#define fNoHMA		0x00002000
#define fPifHasHotKey	0x00004000
#define fEMSLocked	0x00008000
#define fXMSLocked	0x00010000
#define fINT16Paste	0x00020000
#define fVMLocked	0x00040000

    BYTE	WinFlags;	// 10: Enhanced mode window flags
				//     0x01 Allow close when active
				//     0x02 Background
				//     0x04 Exclusive
				//     0x08 Full-screen
				//     0x20 Alt-Tab disabled
				//     0x40 Alt-Esc disabled
				//     0x80 Alt-Space disabled
    WORD	TaskFlags;	// 11: Enhanced mode task flags
				//     0x0001 Alt-Enter disabled
				//     0x0002 Alt-Prtsc disabled
				//     0x0004 Prtsc disabled
				//     0x0008 Ctrl-Esc disabled
				//     0x0010 Detect idle time on
				//     0x0020 Disable HMA use for VM
				//     0x0040 Has a Hot Key
				//     0x0080 EMS is locked
				//     0x0100 XMS is locked
				//     0x0200 Allow fast paste
				//     0x0400 Lock application memory
    BYTE	Flags;		// 13: More flags

// VidFlags and the next unknown byte are called VD_Flags2 internally and
// probably include the following two unknown bytes as well.
// These are defined in \WIN386\INCLUDE\STATUSFL.INC and VDD.INC

    BYTE	VidFlags;	// 14: Enhanced mode video flags
				//     This is passed to VDD_PIF_State in AX
				//     They are defined in VDD.INC
				//     0x01 Emulate text mode
				//     0x02 Monitor port text off
				//     0x04 Monitor port low graphics off
				//     0x08 Monitor port high graphics off
				//     0x10 Video mode text
				//     0x20 Video mode low graphics
				//     0x40 Video mode high graphics
				//     0x80 Retain video memory
    BYTE	unk2[3];	// 15:
    WORD	Hotkey; 	// 18: Scancode of user hotkey
    BYTE	HotkeyShift;	// 1A: Shift state of user hotkey
				//     0x01 Shift
				//     0x02 Shift
				//     0x04 Ctrl
				//     0x08 Alt
    BYTE	unk4;		// 1B:
    BYTE	Hotkey3;	// 1C: 0x0F if any hotkey defined
    BYTE	unk5;		// 1D:
    BYTE	HotkeyBits;	// 1E: Bits 24-31 of WM_KEYDOWN
    BYTE	unk6[9];	// 1F:
    char	CmdLine3[64];	// 28: Optional parameters ASCIZ
				// 68:
} PIF386, * PPIF386, FAR * LPPIF386;

typedef struct _PIF {
	PIFHDR	pifHdr; 	// Old-style .PIF and header
	PIFSIG	pifSigEX;	// "MICROSOFT PIFEX" signature
	PIFSIG	pifSig286;	// "WINDOWS 286 3.0" signature
	PIF286	pif286; 	// Standard mode data
	PIFSIG	pifSig386;	// "WINDOWS 386 3.0" signature
	PIF386	pif386; 	// Enhanced mode data
} PIF, * PPIF, FAR * LPPIF;

