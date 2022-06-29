
; Begin of file toolhelp.h
MAX_DATA		EQU		11
MAX_PATH		EQU		255
MAX_MODULE_NAME 	EQU		000000009h
MAX_CLASSNAME		EQU		255

tagGLOBALINFO	struc

GI_dwSize	dd	?
GI_wcItems	dw	?
GI_wcItemsFree	dw	?
GI_wcItemsLRU	dw	?

tagGLOBALINFO	ends


tagGLOBALENTRY	struc

GE_dwSize	dd	?
GE_dwAddress	dd	?
GE_dwBlockSize	dd	?
GE_hBlock	dw	?
GE_wcLock	dw	?
GE_wcPageLock	dw	?
GE_wFlags	dw	?
GE_wHeapPresent dw	?
GE_hOwner	dw	?
GE_wType	dw	?
GE_wData	dw	?
GE_dwNext	dd	?
GE_dwNextAlt	dd	?

tagGLOBALENTRY	ends


GLOBAL_ALL	EQU	0
GLOBAL_LRU	EQU	1
GLOBAL_FREE	EQU	2
GT_UNKNOWN	EQU	0
GT_DGROUP	EQU	1
GT_DATA 	EQU	2
GT_CODE 	EQU	3
GT_TASK 	EQU	4
GT_RESOURCE	EQU	5
GT_MODULE	EQU	6
GT_FREE 	EQU	7
GT_INTERNAL	EQU	8
GT_SENTINEL	EQU	9
GT_BURGERMASTER EQU	10
GD_USERDEFINED	EQU	0
GD_CURSORCOMPONENT EQU	1
GD_BITMAP	EQU	2
GD_ICONCOMPONENT EQU	3
GD_MENU 	EQU	4
GD_DIALOG	EQU	5
GD_STRING	EQU	6
GD_FONTDIR	EQU	7
GD_FONT 	EQU	8
GD_ACCELERATORS EQU	9
GD_RCDATA	EQU	10
GD_ERRTABLE	EQU	11
GD_CURSOR	EQU	12
GD_ICON 	EQU	14
GD_NAMETABLE	EQU	15
GD_MAX_RESOURCE EQU	15
GF_PDB_OWNER	EQU	000000100h


tagLOCALINFO	struc

LI_dwSize	dd	?
LI_wcItems	dw	?

tagLOCALINFO	ends


tagLOCALENTRY	struc

LE_dwSize	dd	?
LE_hHandle	dw	?
LE_wAddress	dw	?
LE_wSize	dw	?
LE_wFlags	dw	?
LE_wcLock	dw	?
LE_wType	dw	?
LE_hHeap	dw	?
LE_wHeapType	dw	?
LE_wNext	dw	?

tagLOCALENTRY	ends


NORMAL_HEAP	EQU	0
USER_HEAP	EQU	1
GDI_HEAP	EQU	2
LF_FIXED	EQU	1
LF_FREE 	EQU	2
LF_MOVEABLE	EQU	4
LT_NORMAL	EQU	0
LT_FREE 	EQU	0000000ffh
LT_GDI_PEN	EQU	1
LT_GDI_BRUSH	EQU	2
LT_GDI_FONT	EQU	3
LT_GDI_PALETTE	EQU	4
LT_GDI_BITMAP	EQU	5
LT_GDI_RGN	EQU	6
LT_GDI_DC	EQU	7
LT_GDI_DISABLED_DC EQU	8
LT_GDI_METADC	EQU	9
LT_GDI_METAFILE EQU	10
LT_GDI_MAX	EQU	00000000ah
LT_USER_CLASS	EQU	1
LT_USER_WND	EQU	2
LT_USER_STRING	EQU	3
LT_USER_MENU	EQU	4
LT_USER_CLIP	EQU	5
LT_USER_CBOX	EQU	6
LT_USER_PALETTE EQU	7
LT_USER_ED	EQU	8
LT_USER_BWL	EQU	9
LT_USER_OWNERDRAW EQU	10
LT_USER_SPB	EQU	11
LT_USER_CHECKPOINT EQU	12
LT_USER_DCE	EQU	13
LT_USER_MWP	EQU	14
LT_USER_PROP	EQU	15
LT_USER_LBIV	EQU	16
LT_USER_MISC	EQU	17
LT_USER_ATOMS	EQU	18
LT_USER_LOCKINPUTSTATE EQU 19
LT_USER_HOOKLIST EQU	20
LT_USER_USERSEEUSERDOALLOC EQU 21
LT_USER_HOTKEYLIST EQU	22
LT_USER_POPUPMENU EQU	23
LT_USER_HANDLETABLE EQU 32
LT_USER_MAX	EQU	000000020h


tagSTACKTRACEENTRY struc

STE_dwSize	dd	?
STE_hTask	dw	?
STE_wSS 	dw	?
STE_wBP 	dw	?
STE_wCS 	dw	?
STE_wIP 	dw	?
STE_hModule	dw	?
STE_wSegment	dw	?
STE_wFlags	dw	?

tagSTACKTRACEENTRY ends


FRAME_FAR	EQU	0
FRAME_NEAR	EQU	1

tagMODULEENTRY	struc

ME_dwSize	dd	?
ME_szModule	db	10 DUP (?)
ME_hModule	dw	?
ME_wcUsage	dw	?
ME_szExePath	db	256 DUP (?)
ME_wNext	dw	?

tagMODULEENTRY	ends


tagTASKENTRY	struc

TE_dwSize	dd	size tagTASKENTRY
TE_hTask	dw	?
TE_hTaskParent	dw	?
TE_hInst	dw	?
TE_hModule	dw	?
TE_wSS		dw	?
TE_wSP		dw	?
TE_wStackTop	dw	?
TE_wStackMinimum dw	?
TE_wStackBottom dw	?
TE_wcEvents	dw	?
TE_hQueue	dw	?
TE_szModule	db	10 DUP (?)
TE_wPSPOffset	dw	?
TE_hNext	dw	?

tagTASKENTRY	ends


tagCLASSENTRY	struc

CE_dwSize	dd	?
CE_hInst	dw	?
CE_szClassName	db	256 DUP (?)
CE_wNext	dw	?

tagCLASSENTRY	ends


tagMEMMANINFO	struc

MMI_dwSize	dd	?
MMI_dwLargestFreeBlock dd ?
MMI_dwMaxPagesAvailable dd ?
MMI_dwMaxPagesLockable dd ?
MMI_dwTotalLinearSpace dd ?
MMI_dwTotalUnlockedPages dd ?
MMI_dwFreePages dd	?
MMI_dwTotalPages dd	?
MMI_dwFreeLinearSpace dd ?
MMI_dwSwapFilePages dd	?
MMI_wPageSize	dw	?

tagMEMMANINFO	ends


tagSYSHEAPINFO	struc

SHI_dwSize	dd	?
SHI_wUserFreePercent dw ?
SHI_wGDIFreePercent dw	?
SHI_hUserSegment dw	?
SHI_hGDISegment dw	?

tagSYSHEAPINFO	ends


INT_DIV0	EQU	0
INT_1		EQU	1
INT_3		EQU	3
INT_UDINSTR	EQU	6
INT_STKFAULT	EQU	12
INT_GPFAULT	EQU	13
INT_BADPAGEFAULT EQU	14
INT_CTLALTSYSRQ EQU	256
NFY_UNKNOWN	EQU	0
NFY_LOADSEG	EQU	1

tagNFYLOADSEG	struc

NFLS_dwSize	dd	?
NFLS_wSelector	dw	?
NFLS_wSegNum	dw	?
NFLS_wType	dw	?
NFLS_wcInstance dw	?
NFLS_lpstrModuleName dd ?

tagNFYLOADSEG	ends


NFY_FREESEG	EQU	2
NFY_STARTDLL	EQU	3

tagNFYSTARTDLL	struc

NFSD_dwSize	dd	?
NFSD_hModule	dw	?
NFSD_wCS	dw	?
NFSD_wIP	dw	?

tagNFYSTARTDLL	ends


NFY_STARTTASK	EQU	4
NFY_EXITTASK	EQU	5
NFY_DELMODULE	EQU	6
NFY_RIP 	EQU	7

tagNFYRIP	struc

NFYRIP_dwSize	dd	?
NFYRIP_wIP	dw	?
NFYRIP_wCS	dw	?
NFYRIP_wSS	dw	?
NFYRIP_wBP	dw	?
NFYRIP_wExitCode dw	?

tagNFYRIP	ends


NFY_TASKIN	EQU	8
NFY_TASKOUT	EQU	9
NFY_INCHAR	EQU	10
NFY_OUTSTR	EQU	11
NFY_LOGERROR	EQU	12

tagNFYLOGERROR	struc

NFLE_dwSize	dd	?
NFLE_wErrCode	dw	?
NFLE_lpInfo	dd	?

tagNFYLOGERROR	ends


NFY_LOGPARAMERROR EQU	13

tagNFYLOGPARAMERROR struc

NFLPE_dwSize	dd	?
NFLPE_wErrCode	dw	?
NFLPE_lpfnErrorAddr dd	?
NFLPE_lpBadParam dd	?

tagNFYLOGPARAMERROR ends


NF_NORMAL	EQU	0
NF_TASKSWITCH	EQU	1
NF_RIP		EQU	2
UAE_BOX 	EQU	0
NO_UAE_BOX	EQU	1

tagTIMERINFO	struc

TI_dwSize	dd	?
TI_dwmsSinceStart dd	?
TI_dwmsThisVM	dd	?

tagTIMERINFO	ends

; End of file toolhelp.h
