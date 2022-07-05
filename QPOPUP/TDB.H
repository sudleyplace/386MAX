/* tdb.h - (C) Copyright 1992-93 Qualitas, Inc.  GNU General Public License version 3. */

/* Windows 3.1 task database structure */

/* The layout described here is taken from TDB.INC dated 25 MAR 91 */
/* Comparison with actual in-memory structures shows TDB.INC isn't quite */
/* up to date with the retail Windows 3.1.  Where possible, I've fixed that */

/* More information on the various data structures involved here can be found */
/* in the DDK documentation and include files, as well as in the */
/* Undocumented Windows book. */

#ifndef _INC_TDB_H			/* Only include this thing once */
#define _INC_TDB_H

#define NUM_TASK_INTS	7		/* Number of task specific interrupts */
#define TASK_MAGIC	'DT'            /* Magic number for task database */

/* Equates for TDB.Flags */
#define TDB_WINOLDAPP	0x01
#define TDB_OS2APP	0x02
#define TDB_WIN32S	0x04

typedef struct tagTDB { 		/* Task database entry */
	HTASK	Next;			/* Handle of next task entry */
	WORD	TaskSP; 		/* Saved SS:SP for this task */
	WORD	TaskSS;
	UINT	nEvents;		/* Task event counter */
	BYTE	Priority;		/* Task priority (0 is highest) */

	BYTE	ThreadOrdinal;		/* Ordinal # of this thread */
	WORD	ThreadNext;
	HTASK	ThreadTDB;		/* The real TDB for this task */
	WORD	ThreadList;
	WORD	ThreadFree;
	UINT	ThreadCount;		/* Total count of thread structures */

	WORD	FCW;			/* Floating point control word */

	BYTE	Flags;			/* Task flags */
	BYTE	Reserved1;		/* Filler  to maintain alignment */

	WORD	ErrMode;		/* Error mode for this task */
	UINT	ExpWinVer;		/* Expected Windows version */
	HINSTANCE hInst;		/* Task module handle to free in kill */
	WORD	pModule;		/* Pointer to module database */
	WORD	Queue;			/* Pointer to task event queue */
	HTASK	Parent; 		/* TDB of parent task */
	WORD	SigAction;		/* Action for app task signal */
	FARPROC ASignalProc;		/* App's task signal procedure */
	FARPROC USignalProc;		/* User's task signal procedure */
	FARPROC GNotifyProc;		/* Task global discard notify proc */

	FARPROC TaskInts[NUM_TASK_INTS]; /* Task specific hardware interrupts */

	WORD	CompatFlags;		/* Compatibility flags */
	WORD	Compat2Flags;		/* Compatibility flags, again */
	BYTE	Reserved2[9];		/* To preserve Windows 2.x offsets */
	BYTE	cLibrary;		/* Unknown purpose */
	DWORD	PHT;			/* HANDLE:OFF to private handle table */
	WORD	PDB;			/* Selector of MS-DOS PSP */
	DWORD	DTA;			/* SEL:OFF of disk transfer area */
	char	Drive;			/* Current drive (82h = C:) */
	char	Directory[65];		/* Current directory */
	WORD	Validity;		/* Initial AX to be passed to task */
	WORD	YieldTo;		/* Argument to DirectedYield */
	WORD	LibInitSeg;		/* Selector of libraries to init */
	WORD	LibInitOff;		/* Offset of ... */

	WORD	MPISel; 		/* MakeProcInstance thunks ... */
	WORD	MPIThunks[8*8/2];	/* ... */

	char	ModName[8];		/* Module name */
	WORD	Magic;			/* 'DT' magic number */
} TDB;

typedef TDB FAR*	LPTDB;		/* Long pointer to a TDB */

#endif	/* #ifndef _INC_TDB_H */
