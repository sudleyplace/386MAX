/*' $Header:   P:/PVCS/MAX/ASQENG/TIMER.H_V   1.0   05 Sep 1995 15:05:58   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * TIMER.H								      *
 *									      *
 * Timing function declarations 					      *
 *									      *
 ******************************************************************************/

typedef struct _timelist {	/* Memory timing region list */
	WORD start;		/* Block segment address */
	WORD length;		/* Block length in paras */
	WORD count;		/* Access count */
} TIMELIST;

/*-asm-*/ WORD pascal far time_mem(WORD start,int cpuflag);
/*-asm-*/ WORD pascal far time_cpu(WORD count);
/*-asm-*/ WORD pascal far multime(WORD count);
