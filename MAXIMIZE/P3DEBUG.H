/*' $Header:   P:/PVCS/MAX/MAXIMIZE/P3DEBUG.H_V   1.0   05 Sep 1995 16:33:18   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * P3DEBUG.H								      *
 *									      *
 * Controls for Pass 3 debugging					      *
 *									      *
 ******************************************************************************/

#define DEBUGFILE "debug.$$$"       /* Name of debug file */
/* #define DUMPDEBUG */

#ifdef DUMPDEBUG
#define CVDBG
#endif

#ifdef CVDBG
#define DEBUG_SUMFIT	/* SUMFIT / LSEG diagnostics (required) */
#define REORDER_DEBUG	/* REORDER diagnostics (optional) */
#endif

#ifdef REORDER_DEBUG
#define DUMP_DEBUG
#endif

#ifdef DEBUG_SUMFIT
#define DUMP_DEBUG
#endif

