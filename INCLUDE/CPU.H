/*' $Header:   P:/PVCS/MAX/INCLUDE/CPU.H_V   1.2   02 Jun 1997 14:37:28   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * CPU.H								      *
 *									      *
 * Function to check cpu and fpu types					      *
 *									      *
 ******************************************************************************/

#ifndef CPU_INCLUDED
#define CPU_INCLUDED

#include <cputext.h>		/* CPU/FPU code translation */

typedef struct _cpuparm {
	WORD cpu_type;		/* CPU type */
	WORD vir_flag;		/* != 0 if CPU in virtual mode */
	WORD fpu_type;		/* FPU (coprocessor) type */
	WORD fpu_bug;		/* != 0 if early 387 with bugs */
	WORD wei_flag;		/* > 0 if Weitek coprocessor */
	WORD vcpi_ver;		/* VCPI version if not 0 */
	WORD win_ver;		/* Windows version if not 0 */
	union {
	 struct {
	  DWORD fpu:1,		/*  0: Has FPU on-chip */
		vme:1,		/*  1: Supports VM extensions */
		de:1,		/*  2: Supports debug extensions */
		pse:1,		/*  3: Page size ext (4MB pages) */
		rdtsc:1,	/*  4: Supports RDTSC instruction */
		rdmsr:1,	/*  5: Supports RDMSR / WRMSR */
		pae:1,		/*  6: Physical address extensions */
		mce:1,		/*  7: Machine check exception */
		cx8:1,		/*  8: CMPXCHG8B */
		apic:1, 	/*  9: On-chip APIC */
		p54c:1, 	/* 10: P54C/CM/Multiprocessor/Overdrive */
		rsvd4:1,	/* 11: Reserved (was RDECR / WRECR) */
		mtrr:1, 	/* 12: Memory Type Range Register MSRs supp. */
		pge:1,		/* 13: PTE global bit supported */
		mca:1,		/* 14: Machine check architecture */
		cmov:1, 	/* 15: Conditional move */
		rsvd1:1,	/* 16: Reserved (was ZALLOC) */
		rsvd:13,	/* 17-29: Reserved */
		Intel:1,	/* 30: GenuineIntel CPU */
		rsvd2:1;	/* 31: Used by CPUID.COM */
	  };
	  DWORD dwFlags;
	};
	union {
	 struct {
	  DWORD stepping:4,	/* Stepping ID */
		model:4,	/* Model ID */
		family:4,	/* Family (4, 5, 6, etc.) */
		rsvd3:20;
	 };
	 DWORD dwCPUID;
	};
	char aID[ 12 ]; 	/* Vendor's ID (GenuineIntel, etc.) */
} CPUPARM;

void far pascal check_cpu(CPUPARM far *parm);
WORD far pascal check_cpusx(void);

#endif

/* Mon Nov 26 17:05:51 1990 alan:  rwsystxt and other bugs */
