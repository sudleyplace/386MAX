/*' $Header:   P:/PVCS/MAX/INCLUDE/CPUTEXT.H_V   1.2   02 Jun 1997 14:37:28   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CPUCODES.H								      *
 *									      *
 * Code numbers for CPU and FPU types					      *
 *									      *
 ******************************************************************************/

#ifndef CPUTEXT_INCLUDED
#define CPUTEXT_INCLUDED

#include <commdef.h>

/* CPU id codes */

#define CPU_8088	1	/* 8088 */
#define CPU_8086	2	/* 8086 */
#define CPU_V20 	3	/* NEC V20 */
#define CPU_V30 	4	/* NEC V30 */
#define CPU_80188	5	/* 80188 */
#define CPU_80186	6	/* 80186 */
#define CPU_80286	7	/* 80286 */
#define CPU_80386	8	/* 80386 */
#define CPU_80386SX	9	/* 80386 SX */
#define CPU_80486	10	/* 80486 */
#define CPU_80486SX	11	/* 80486 SX */
#define CPU_PENTIUM	12	/* Pentium */
#define CPU_PENTPRO	13	/* Pentium Pro (P6) */

/* FPU id codes */
/* These need to stay in order, since they're saved as */
/* ordinal values in ASQ snapshots. */

#define FPU_NONE	0	/* None installed */
#define FPU_8087	1	/* 8087 */
#define FPU_80287	2	/* 80287 */
#define FPU_80387	3	/* 80387 */
#define FPU_EMULATED	4	/* Emulated */
#define FPU_BUILTIN	5	/* Built-in (i.e. 486 DX) */
#define FPU_80387SX	6	/* 80387SX */

char *cpu_textof( void *p );
char *fpu_textof(WORD type);

#endif /*CPUTEXT_INCLUDED*/
/* Mon Nov 26 17:06:11 1990 :  new */
