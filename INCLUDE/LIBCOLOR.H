/*' $Header:   P:/PVCS/MAX/INCLUDE/LIBCOLOR.H_V   1.1   01 Feb 1996 10:23:26   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * LIBCOLOR.H								      *
 *									      *
 * This file contains all COLOR definitions and the definition for the color  *
 * initiation routine							      *
 *									      *
 ******************************************************************************/

#ifndef LIBCOLOR_INCLUDED
#define LIBCOLOR_INCLUDED

#ifndef WINDOWFN_INCLUDED
#include <windowfn.h>           /* To get color definitions */
#endif

#ifdef OWNER
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL
  #define GLINIT
#else
  #undef  GLOBAL
  #undef  GLINIT
  #define GLOBAL extern
#endif /*  OWNER  */

typedef unsigned char UCHAR;

GLOBAL UCHAR DataColor; 	/* Color of normal text in data window */
GLOBAL UCHAR DataYellowColor;	/* Color for high text in data window */
GLOBAL UCHAR DataContinueColor; /* Color for blah blahblah */
GLOBAL UCHAR QuickBackColor;	/* Color for Quick window bacground */
GLOBAL UCHAR PressAnyKeyColor;	/* Color for press-any-key message */

GLOBAL UCHAR BackScreenColor;
GLOBAL UCHAR ShadowColor;
GLOBAL UCHAR SolidBlackColor;

GLOBAL UCHAR ButtonPushedColor;
GLOBAL UCHAR ButtonActiveColor;
GLOBAL UCHAR ButtonDisabledColor;
GLOBAL UCHAR ButtonHotColor;
GLOBAL UCHAR ButtonChevColor;

GLOBAL UCHAR MenuItemDisabled;
GLOBAL UCHAR MenuItemTriggerColor;
GLOBAL UCHAR MenuDisableColor;

GLOBAL UCHAR HelpColor;
GLOBAL UCHAR HelpQuickRefColor;
GLOBAL UCHAR HelpCurContext;

GLOBAL UCHAR HelpColors[8];
GLOBAL UCHAR QHelpColors[8];
GLOBAL UCHAR HdataColors[8];

GLOBAL UCHAR ErrorColor;
GLOBAL UCHAR ErrorBorderColor;

GLOBAL UCHAR WaitColor;

GLOBAL UCHAR BaseColor;
GLOBAL UCHAR TriggerColor;
GLOBAL UCHAR EditColor;
GLOBAL UCHAR EditInvColor;
GLOBAL UCHAR ActiveColor;
GLOBAL UCHAR NormalColor;
GLOBAL UCHAR DisableColor;

GLOBAL UCHAR NorDlgColors[4];		/* Normal dialog colors */
GLOBAL UCHAR ErrDlgColors[4];		/* Error dialog colors */

GLOBAL UCHAR EditorDataColor;
GLOBAL UCHAR EditorHighColor;
GLOBAL UCHAR EditorMarkColor;

GLOBAL UCHAR OptionTextColor;
GLOBAL UCHAR OptionHighColor;

GLOBAL UCHAR ProgramNameAttr;

GLOBAL UCHAR LogoColor;
GLOBAL UCHAR AltLogoColor;

#endif /*  LIBCOLOR_INCLUDED	*/
