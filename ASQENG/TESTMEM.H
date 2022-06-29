/*' $Header:   P:/PVCS/MAX/ASQENG/TESTMEM.H_V   1.0   05 Sep 1995 15:05:58   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * TESTMEM.H								      *
 *									      *
 * Test memory function declaration					      *
 *									      *
 ******************************************************************************/

/* Memory types */
#define TESTMEM_UNKNOWN 0
#define TESTMEM_RAM	1
#define TESTMEM_ROM	2
#define TESTMEM_EMPTY	3
#define TESTMEM_MCAMEM	7	/* RAM or ROM on MCA adapters */

int pascal far testmem(unsigned short start, unsigned short far *size);
