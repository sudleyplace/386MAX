/*' $Header:   P:/PVCS/MAX/INCLUDE/SVGA_INF.H_V   1.0   05 Sep 1995 13:29:58   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * SVGA_INF.H								      *
 *									      *
 * Header file for SVGA_INF.ASM 					      *
 *									      *
 ******************************************************************************/

#define 	 VENDOR_UNK	 0
#define 	 ATI		 1
#define 	 TRIDENT	 2
#define 	 VIDEO7 	 3
#define 	 PARADISE	 4
#define 	 TSENG		 5
#define 	 CHIPS		 6
#define 	 GENOA		 7
#define 	 VESA		 8
#define 	 AHEAD		 9
#define 	 ORCHID 	10
#define 	 CIRRUS 	11	// 256K only
#define 	 S3_INC 	12
#define 	 DIAMOND	13
#define 	 STB		14


#define 	 MODEL_UNK	 0
#define 	ATI_18800	 1
#define 	 ATI_28800	 2
#define 	TRIDENT_8800	 1
#define 	 TRIDENT_8900	 2
#define 	VIDEO7_VEGA	 1
#define 	 VIDEO7_FASTWRITE 2
#define 	 VIDEO7_V7VGAV5  3
#define 	 VIDEO7_1024i	 4
#define 	PARADISE_PVGA1a 1
#define 	 PARADISE_WD90C00 2
#define 	 PARADISE_WD90C10 3
#define 	 PARADISE_WD90C11 4
#define 	TSENG_ET3000	 1
#define 	 TSENG_ET4000	 2
#define 	CHIPS_82C451	 1
#define 	 CHIPS_82C452	 2
#define 	 CHIPS_82C453	 3
#define 	 CHIPS_82C455	 4
#define 	 CHIPS_82C456	 5
#define 	GENOA_5000	 1
#define 	 GENOA_GVGA	 2
#define 	VESA_OEM	 1
#define 	 VESA_128	 2
#define 	AHEAD_A 	 1
#define 	 AHEAD_B	 2
#define 	S3_86C911	 1
#define 	DIAMOND_SS	 1
#define 	STB_ET4000	 1
#define 	 STB_S3 	 2

extern	 int	 SVGA_ISVGA (void);		/* Return nonzero if EGA or
						   VGA */

extern	 unsigned int	 SVGA_ACTIVEROM (void); /* Return segment of active
						   VGA ROM */

extern	 int	 SVGA_VENDOR (void);		/* Return vendor identifier
						   (as defined above) */

extern	 int	 SVGA_MODEL (void);		/* Return model identifier */

extern	 int	 SVGA_MEMSIZE (void);		/* Return memory size in KB */

extern	 char _far *SVGA_VENDORID (int vendor); /* Return a string identifying
						   specified vendor; use -1
						   to get current vendor */

extern	 char _far *SVGA_MODELID (int model);	/* Return string identifying
						   specified model, or -1
						   for current model */

extern	 int	 VESA_MODECNT;			/* Number of VESA modes
						   supported if vendor==VESA */

extern	 int _far *VESA_MODES;			/* List of VESA modes */

