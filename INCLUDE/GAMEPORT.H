/*' $Header:   P:/PVCS/MAX/INCLUDE/GAMEPORT.H_V   1.0   05 Sep 1995 13:30:10   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * GAMEPORT.H								      *
 *									      *
 * Definitions for MASM module GAMEPORT.ASM.				      *
 *									      *
 ******************************************************************************/

/* We can't try to detect the presence of a joystick using (heaven forbid!)
 * the BIOS because some vendors' BIOSes will hang.  Silly us.  We read the
 * port, looking for a likely bit transition...
 */

/* Return 0 if no joystick, or number of adapters connected (1 or 2) */
int GameCount (void);

