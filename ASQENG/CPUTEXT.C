/*' $Header:   P:/PVCS/MAX/ASQENG/CPUTEXT.C_V   1.1   01 Feb 1996 10:33:16   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * CPUTEXT.C								      *
 *									      *
 * Translate CPU and FPU codes to names 				      *
 *									      *
 ******************************************************************************/

#include <cputext.h>
#include <cpu.h>
#include <libtext.h>

char *cpu_textof( void *p )
{
#define pCPU	((CPUPARM *)p)
	switch (pCPU->cpu_type) {
	case CPU_8088:	return "8088";
	case CPU_8086:	return "8086";
	case CPU_V20:	return "NEC V20";
	case CPU_V30:	return "NEC V30";
	case CPU_80188: return "80188";
	case CPU_80186: return "80186";
	case CPU_80286: return "80286";
	case CPU_80386: return "80386";
	case CPU_80386SX: return "80386SX";
	case CPU_80486: return "80486";
	case CPU_80486SX: return "80486SX";
	case CPU_PENTIUM: return pCPU->Intel ? "Pentium" : "80586";
	case CPU_PENTPRO: return pCPU->Intel ? "Pentium Pro" : "80686";
	default:		return NATL_UNKNOWN;
	}
}

char *fpu_textof(WORD type)
{
	switch (type) {
	case FPU_NONE:		return NATL_NONE;
	case FPU_8087:		return "8087";
	case FPU_80287: 	return "80287";
	case FPU_80387: 	return "80387";
	case FPU_EMULATED:	return NATL_EMULATED;
	case FPU_BUILTIN:	return NATL_BUILTIN;
	case FPU_80387SX:	return "80387SX";

	default:		return NATL_UNKNOWN;
	}
}
/* Mon Nov 26 17:06:06 1990 :  new */
