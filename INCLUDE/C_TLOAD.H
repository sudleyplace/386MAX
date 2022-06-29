/*' $Header:   P:/PVCS/MAX/INCLUDE/C_TLOAD.H_V   1.0   05 Sep 1995 13:29:36   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * C_TLOAD.H								      *
 *									      *
 * Function to check on C&T chipset					      *
 *									      *
 ******************************************************************************/

#define CHIPSET_NONE  0x0000	/* No (or unknown) chipset */
#define CHIPSET_NEAT1 0x0001	/* NEAT w/ < 1 Mb */
#define CHIPSET_VLSI  0x0002	/* VLSI */

#define CHIPSET_AT386 0x0100	/* AT/386 */
#define CHIPSET_NEAT  0x0101	/* NEAT */

WORD far pascal check_chipset(void);
/* Thu Nov 29 21:57:27 1990 alan:  fix bugs */
