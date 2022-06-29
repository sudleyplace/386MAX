//' $Header:   P:/PVCS/MAX/INCLUDE/WINTERNL.H_V   1.2   25 Sep 1996 10:09:18   BOB  $
//
// WINTERNL.H - Windows internals
//
// This file covers undocumented stuff not covered in WINDOWS.H
//
// Copyright (C) 1995-6 Qualitas, Inc.	All rights reserved.
//

#ifndef WINTERNL_INCLUDED
#define WINTERNL_INCLUDED

#define WM_PAINTICON	0x0026


// Win386 Global Heap structure

typedef struct tagGLOBALHEAP
{

WORD  HeapCheck;		// Set to non-zero to enable heap checking

WORD  HeapFreeze;		// Set to non-zero to prevent heap compaction
WORD  Count;			// # entries in the global heap
DWORD FirstEntry;		// Offset of 1st Global Arena
DWORD LastEntry;		// ...		 last ...
BYTE  nCompact; 		// # heap compactions
BYTE  dislevel; 		// Current discard level
DWORD distotal; 		// Total # bytes discarded so far
WORD  hTable;			// Always 0? (supposed to be handle table list head)
WORD  hFree;			// Always 0? (supposed to be free handle table list head)
WORD  hDelta;			// Always 0? (supposed to be handle delta)
WORD  hExpand;			// Always 0? (supposed to be near procedure to expand tables)
WORD  pstats;			// Always 0? (supposed to be handle to statistics table)
WORD  LRULock;			// Lock-out access to LRU chain from interrupt level (huh?)
DWORD LRUChain; 		// Offset within Global Heap of 1st handle in LRU chain
WORD  LRUCount; 		// # entries in LRU chain
DWORD Reserved; 		// # paras to reserve for discardable code
DWORD disfence; 		// Fence for discardable code
WORD  freecount;		// # free blocks

} GLOBALHEAP;


// Win386 Global Arena structure

typedef struct tagGLOBALARENA
{

DWORD Next; 			// Next Global Arena
DWORD Prev; 			// Prev ...
DWORD Base; 			// Linear base address
DWORD Size; 			// Block size in bytes
WORD  Handle;			// Handle (low-order two bits mark fixed or movable)
WORD  Owner;			// Owner -- this value is one of
						//		Module Handle
						//		Task Handle
						//		PSP
						//		GA32OwnerSentinel
						//		GA32OwnerDPMI
BYTE  count;			// Lock count for movable blocks
BYTE  pglock;			// # times page locked (GlobalPageLock())
BYTE  flags;			// Flags:	04 = DGROUP
						//			08 = Discardable
BYTE  selcount; 		// # selectors required for tiling
DWORD LRUPrev;			// Offset of prev Global Arean in LRU chain
DWORD LRUNext;			// ...		 next ...

} GLOBALARENA;

#define GA32OwnerSentinel -1	// First and last owner entry
#define GA32OwnerDPMI	   -4	// Allocated from DPMI


//******************************************************************************
// NE/PE File Formats
// There are several steps involved in determining
// whether or not a file has this format:
//	1.	Ensure the file is in EXE format
//		('MZ' signature in first two bytes)
//	2.	At offset 18h in the EXE header, the
//		word value is >= 40h.
//	3.	At offset 3Ch in EXE header is the dword offset of
//		the NE/PE file format from the start of the EXE header

//******************************************************************************
// NE File Format
typedef struct tagMODULEBITFLAGS
{
	WORD dgroupType:2,			// 0003:  Bits 0-1:  00 = NOAUTODATA,
								//					 01 = SINGLEDATA,
								//					 10 = MULTIPLEDATA,
								//					 11 = Reserved
		 globalInit:1,			// 0004:  Bit 2:
		 protectedMode:1,		// 0008:	  3:
		 i86Instructions:1, 	// 0010:	  4:
		 i286Instructions:1,	// 0020:	  5:
		 i386Instructions:1,	// 0040:	  6:
		 i87Instructions:1, 	// 0080:	  7:
		 applicationType:3, 	// 0700:  Bits 8-10:
		 familyApplication:1,	// 0800:  Bit 11:  First segment contains loader code
		 unused1:1, 			// 1000:	  12:
		 linkErrors:1,			// 2000:	  13:  Error creating executable (set by linker)
		 unused2:1, 			// 4000:	  14:
		 libraryModule:1;		// 8000:	  15:  Library module
} MODULEBITFLAGS;

typedef union
{
	MODULEBITFLAGS b;
	WORD i;
} FLAGWORD;

typedef struct tagNEHEADER
{
	WORD wSign; 		// 00:	'NE' ('N' = low-byte)
	BYTE bLVer; 		// 02:	Linker version #
	BYTE bLRev; 		// 03:	Linker revision #
	WORD npEntry;		// 04:	Offset to Entry table
	WORD cbEntry;		// 06:	Length of Entry table, in bytes
	DWORD dwCRC32;		// 08:	CRC-32 for file load control
	FLAGWORD wFlags;	// 0C:	Flags for executable file
	WORD wAutoSeg;		// 0E:	Automatic data segment # (0=NOAUTODATA)
	WORD cbHeap;		// 10:	Initial size of local heap, in bytes
	WORD cbStack;		// 12:	Initial size of stack, in bytes
	DWORD lpCSIP;		// 14:	Segment:Offset of CS:IP
	DWORD lpSSSP;		// 18:	... 			  SS:SP
	WORD wEntry;		// 1C:	# entries in Entry table
	WORD wModRef;		// 1E:	# entries in Module Reference table
	WORD cbNonResName;	// 20:	Size of Non-Resident Names table, in bytes
						// The following offsets are relative to the
						// start of the NE header
	WORD npSegName; 	// 22:	Offset to start of Segment Name table
	WORD npRsrc;		// 24:	Offset to start of Resource table
	WORD npResName; 	// 26:	Offset to start of Resident Names table
	WORD npModRef;		// 28:	Offset to start of Module Reference table
	WORD npImpName; 	// 2A:	Offset to start of Imported Names table
	DWORD npNonResName; // 2C:	Offset to start of Non-resident names table
	WORD wMoveable; 	// 30:	# moveable entry points
	WORD wShiftCnt; 	// 32:	Logical sector alignment
	WORD wRsrcSegCnt;	// 34:	# resource segments
	BYTE bExeType;		// 36:	Target operating system
	BYTE bFlagsOther;	// 37:	Other .EXE flags
	union
	{
		WORD npRetThunks;// 38:  Offset to return thunks
		WORD wGangStart;// 38:	Offset to start of gangload area (in sectors)
	} x;
	union
	{
		WORD npSegRefBytes;// 3A:  Offset to segment ref. bytes
		WORD wGangLen;	// 3A:	Length of gangload area (in sectors)
	} y;
	WORD wSwapArea; 	// 3C:	Minimum code swap area size
	WORD wExpVer;		// 3E:	Expected windows version #

} NEHEADER;

typedef NEHEADER FAR * LPNEHEADER;


// The offset NEHEADER.npRsrc (from start of NE header) points to
// a word which contains the alignment shift used by RESOURCEENTRY.wOffset
// This word is followed by sets of a RESOURCEHEADER struc followed
// by RESOURCEHEADER.wRsrcCnt number of RESOURCEENTRY strucs.
// This is followed by a word of zero (RESOURCEHEADER.wType == 0)
// to indicate the end of the resource type definitions.
// These are followed by the resource names (if any) which are
// in (Count, Char[]) format.  The end of these entries is indicated
// by a Count byte of zero.

typedef struct tagRESOURCEHEADER  // Resource table header
{
	WORD wType; 			// Type ID or string offset
	WORD wRsrcCnt;			// # of resources to this type
	DWORD dwReserved;		// Reserved DD space
	// These items are followed by wRsrcCnt strucs of type RESOURCEENTRY.
} RESOURCEHEADER;

typedef RESOURCEHEADER FAR * LPRESOURCEHEADER;


typedef struct tagRESOURCEENTRY  // Resource entry
{
	WORD wOffset;			// Offset to resource in units of the 2 **
							// alignment shift -- this offset is relative
							// to the start of the file, not the NE header
	WORD wLen;				// Size of resource in units of the
							// alignment shift
	WORD reserved1:4,		// Reserved
		 movable:1, 		// Resource is moveable
		 pure:1,			// Resource can be shared (is pure)
		 preload:1, 		// Resource is preloaded
		 reserved2:5,		// Reserved
		 discardPriority:4; // ???
	WORD wRsrcID;			// Resource ID if 0x8000 set
							// otherwise offset from start of resource table
							// to the resource name
	WORD wHandle;			// Resource handle (placeholder used in module table)
	WORD wUsage;			// Reference count (...)

} RESOURCEENTRY;

typedef RESOURCEENTRY FAR * LPRESOURCEENTRY;


typedef struct tagSEGENTRECORD	// Segment Name table entry
{
	WORD sectoroffset;		// Offset to logical sector
	WORD segmentlength; 	// Size in bytes of segment
	WORD segmenttype :3,	// Segment type identification
		 iterated	 :1,	// Segment is iterated
		 movable	 :1,	// Segment is movable
		 pure		 :1,	// Segment is sharable
		 preload	 :1,	// Segment is not demand loaded
		 readonly	 :1,	// Segment is read-only
		 relocinfo	 :1,	// Segment has reloc info
		 debuginfo	 :1,	// Segment has debug info
		 dplbits	 :2,	// 80286 DPL bits
		 discard	 :4;	// Segment Discard Priority
	WORD allocsize; 		// Segment allocation size

} SEGMENTRECORD;

typedef struct tagMOVENTRY	// Basic entry record
{
	BYTE eflags;		// Export and Share Flags
	WORD int3f; 		// INT 03fh  (0xcd 0x3f)
	BYTE segnumber; 	// Segment number
	WORD offset;		// Segment offset

} MOVENTRY;

typedef struct tagFIXENTRY	// Basic entry record
{
	BYTE eflags;		// Export and Share Flags
	WORD offset;		// Segment offset

} FIXENTRY;


//******************************************************************************
// PE File Format
//
// See WINNT.H for more details

#ifndef _WINNT_
typedef struct tagIMAGE_NT_HEADERS
{
	DWORD Signature;
/// IMAGE_FILE_HEADER FileHeader;
/// IMAGE_OPTIONAL_HEADER OptionalHeader;
} IMAGE_NT_HEADERS, *PIMAGE_NT_HEADERS;

#define IMAGE_SIZEOF_SHORT_NAME 			 8

typedef struct tagIMAGE_SECTION_HEADER
{
	BYTE	Name[IMAGE_SIZEOF_SHORT_NAME];
	union {
			DWORD	PhysicalAddress;
			DWORD	VirtualSize;
	} Misc;
	DWORD	VirtualAddress;
	DWORD	SizeOfRawData;
	DWORD	PointerToRawData;
	DWORD	PointerToRelocations;
	DWORD	PointerToLinenumbers;
	WORD	NumberOfRelocations;
	WORD	NumberOfLinenumbers;
	DWORD	Characteristics;
} IMAGE_SECTION_HEADER, *PIMAGE_SECTION_HEADER;

typedef char IMAGE_RESOURCE_DIRECTORY;
typedef  IMAGE_RESOURCE_DIRECTORY		FAR *  PIMAGE_RESOURCE_DIRECTORY;
typedef char IMAGE_RESOURCE_DIRECTORY_ENTRY;
typedef  IMAGE_RESOURCE_DIRECTORY_ENTRY FAR *  PIMAGE_RESOURCE_DIRECTORY_ENTRY;
typedef char IMAGE_RESOURCE_DATA_ENTRY;
typedef  IMAGE_RESOURCE_DATA_ENTRY		FAR *  PIMAGE_RESOURCE_DATA_ENTRY;

#endif

#ifndef _WIN32			// Note that _WIN16 hasn't been defined as yet
#define IMAGE_OS2_SIGNATURE 				0x454E		// NE
#define IMAGE_VXD_SIGNATURE 				0x454C		// LE
#define IMAGE_NT_SIGNATURE					0x00004550	// PE00
#endif

typedef IMAGE_NT_HEADERS		 PEHEADER;
typedef IMAGE_NT_HEADERS FAR * LPPEHEADER;

#endif
