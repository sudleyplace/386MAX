//' $Header:   P:/PVCS/MAX/INCLUDE/PROCDB.H_V   1.0   25 Sep 1996 10:38:24   BOB  $

//==================================
// WIN32WLK - Matt Pietrek 1995
// FILE: PROCDB.H
//==================================
#pragma pack(1)

typedef struct _ENVIRONMENT_DATABASE
{
PSTR	pszEnvironment; 	// 00h Pointer to Environment
DWORD	un1;				// 04h
PSTR	pszCmdLine; 		// 08h Pointer to command line
PSTR	pszCurrDirectory;	// 0Ch Pointer to current directory
LPSTARTUPINFOA pStartupInfo;// 10h Pointer to STARTUPINFOA struct
HANDLE	hStdIn; 			// 14h Standard Input
HANDLE	hStdOut;			// 18h Standard Output
HANDLE	hStdErr;			// 1Ch Standard Error
DWORD	un2;				// 20h
DWORD	InheritConsole; 	// 24h
DWORD	BreakType;			// 28h
DWORD	BreakSem;			// 2Ch
DWORD	BreakEvent; 		// 30h
DWORD	BreakThreadID;		// 34h
DWORD	BreakHandlers;		// 38h
} ENVIRONMENT_DATABASE, *PENVIRONMENT_DATABASE;

typedef struct _HANDLE_TABLE_ENTRY
{
	DWORD	flags;		// Valid flags depend on what type of object this is
	PVOID	pObject;	// Pointer to the object that the handle refers to
} HANDLE_TABLE_ENTRY, *PHANDLE_TABLE_ENTRY;

typedef struct _HANDLE_TABLE
{
	DWORD	cEntries;				// Max number of handles in table
	HANDLE_TABLE_ENTRY array[1];	// An array (number is given by cEntries)
} HANDLE_TABLE, *PHANDLE_TABLE;

typedef struct _PROCESS_DATABASE
{
DWORD	Type;				// 00h KERNEL32 object type (5)

DWORD	cReference; 		// 04h Number of references to process

DWORD	un1;				// 08h

DWORD	someEvent;			// 0Ch An event object (What's it used for???)

DWORD	TerminationStatus;	// 10h Returned by GetExitCodeProcess

DWORD	un2;				// 14h

DWORD	DefaultHeap;		// 18h Address of the process heap

DWORD	MemoryContext;		// 1Ch pointer to the process's context

DWORD	flags;				// 20h
							// 0x00000001 - fDebugSingle
							// 0x00000002 - fCreateProcessEvent
							// 0x00000004 - fExitProcessEvent
							// 0x00000008 - fWin16Process
							// 0x00000010 - fDosProcess
							// 0x00000020 - fConsoleProcess
							// 0x00000040 - fFileApisAreOem
							// 0x00000080 - fNukeProcess
							// 0x00000100 - fServiceProcess
							// 0x00000800 - fLoginScriptHack
								
DWORD	pPSP;				// 24h Linear address of PSP?

WORD	PSPSelector;		// 28h

WORD	MTEIndex;			// 2Ah

WORD	cThreads;			// 2Ch

WORD	cNotTermThreads;	// 2Eh

WORD	un3;				// 30h

WORD	cRing0Threads;		// 32h number of ring 0 threads

HANDLE	HeapHandle; 		// 34h Heap to allocate handle tables out of
							//	   This seems to always be the KERNEL32 heap

HTASK	W16TDB; 			// 38h Win16 Task Database selector

DWORD	MemMapFiles;		// 3Ch memory mapped file list (?)

PENVIRONMENT_DATABASE pEDB; // 40h Pointer to Environment Database

PHANDLE_TABLE pHandleTable; // 44h Pointer to process handle table

struct _PROCESS_DATABASE * ParentPDB;	// 48h Parent process database

PMODREF MODREFlist; 		// 4Ch Module reference list

DWORD	ThreadList; 		// 50h Threads in this process

DWORD	DebuggeeCB; 		// 54h Debuggee Context block?

DWORD	LocalHeapFreeHead;	// 58h Head of free list in process heap

DWORD	InitialRing0ID; 	// 5Ch

CRITICAL_SECTION	crst;	// 60h

DWORD	un4[3]; 			// 78h

DWORD	pConsole;			// 84h Pointer to console for process

DWORD	tlsInUseBits1;		// 88h	// Represents TLS indices 0 - 31

DWORD	tlsInUseBits2;		// 8Ch	// Represents TLS indices 32 - 63

DWORD	ProcessDWORD;		// 90h

struct _PROCESS_DATABASE * ProcessGroup;	// 94h

DWORD	pExeMODREF; 		// 98h pointer to EXE's MODREF

DWORD	TopExcFilter;		// 9Ch Top Exception Filter?

DWORD	BasePriority;		// A0h Base scheduling priority for process

DWORD	HeapOwnList;		// A4h Head of the list of process heaps

DWORD	HeapHandleBlockList;// A8h Pointer to head of heap handle block list

DWORD	pSomeHeapPtr;		// ACh normally zero, but can a pointer to a
							// moveable handle block in the heap

DWORD	pConsoleProvider;	// B0h Process that owns the console we're using?

WORD	EnvironSelector;	// B4h Selector containing process environment

WORD	ErrorMode;			// B6H SetErrorMode value (also thunks to Win16)

DWORD	pevtLoadFinished;	// B8h Pointer to event LoadFinished?

WORD	UTState;			// BCh
} PROCESS_DATABASE, *PPROCESS_DATABASE;

#pragma pack()
