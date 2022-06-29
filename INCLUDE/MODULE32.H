// $Header:   P:/PVCS/MAX/INCLUDE/MODULE32.H_V   1.0   25 Sep 1996 09:53:00   BOB  $
//==================================
// WIN32WLK - Matt Pietrek 1995
// FILE: MODULE32.H
//==================================
#pragma pack(1)

typedef struct _MODREF
{
    struct _MODREF *pNextModRef;    // 00h
    DWORD	    un1;	    // 04h
    DWORD	    un2;	    // 08h
    DWORD	    un3;	    // 0Ch
    WORD	    mteIndex;	    // 10h
    WORD	    un4;	    // 12h
    DWORD	    un5;	    // 14h
    PVOID	    ppdb;	    // 18h Pointer to process database
    DWORD	    un6;	    // 1Ch
    DWORD	    un7;	    // 20h
    DWORD	    un8;	    // 24h
} MODREF, *PMODREF;

typedef struct _IMTE
{
    DWORD	    un1;	    // 00h
    PIMAGE_NT_HEADERS	pNTHdr;     // 04h
    DWORD	    un2;	    // 08h
    PSTR	    pszFileName;    // 0Ch
    PSTR	    pszModName;     // 10h
    WORD	    cbFileName;     // 14h
    WORD	    cbModName;	    // 16h
    DWORD	    un3;	    // 18h
    DWORD	    cSections;	    // 1Ch
    DWORD	    un5;	    // 20h
    DWORD	    baseAddress;    // 24h
    WORD	    hModule16;	    // 28h
    WORD	    cUsage;	    // 2Ah
    DWORD	    un7;	    // 2Ch
    PSTR	    pszFileName2;   // 30h
    WORD	    cbFileName2;    // 34h
    DWORD	    pszModName2;    // 36h
    WORD	    cbModName2;     // 3Ah
} IMTE, *PIMTE;

#pragma pack()
