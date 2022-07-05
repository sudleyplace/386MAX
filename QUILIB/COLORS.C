/*' $Header:   P:/PVCS/MAX/QUILIB/COLORS.C_V   1.0   05 Sep 1995 17:02:00   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * COLORS.C								      *
 *									      *
 * Set colors for library code						      *
 *									      *
 ******************************************************************************/

#include "commfunc.h"
#include "libcolor.h"

void setLibColors(		/* Set colors for library code */
	BOOL mono)		/* TRUE for monochrome color scheme */
{
	if (!mono) {
		DataColor = (FG_WHITE | BG_BLUE);
		DataYellowColor = (FG_YELLOW | BG_BLUE);
		DataContinueColor = (FG_BLUE | BG_GRAY);
		QuickBackColor = (FG_WHITE|BG_GRAY);
		PressAnyKeyColor = (FG_BLACK|BG_GRAY);

		BackScreenColor = (FG_DKGRAY|BG_BLACK);
		ShadowColor = (FG_DKGRAY|BG_BLACK);
		SolidBlackColor = (FG_BLACK | BG_BLACK );

		ButtonPushedColor = (FG_WHITE | BG_BLACK );
		ButtonActiveColor = (FG_BLACK | BG_GRAY );
		ButtonDisabledColor = (FG_DKGRAY | BG_GRAY );
		ButtonHotColor = (FG_WHITE | BG_GRAY );
		ButtonChevColor = (FG_RED | BG_GRAY);

		MenuItemDisabled = FG_DKGRAY;
		MenuItemTriggerColor = FG_RED;
		MenuDisableColor = ( FG_DKGRAY | BG_GRAY );

		HelpColor = (FG_WHITE | BG_CYAN );
		HelpQuickRefColor = ( FG_RED | BG_GRAY );
		HelpCurContext = ( FG_WHITE | BG_RED  );

		QHelpColors[0] =HelpColors[0] = FG_BLACK | BG_GRAY;	/* 0: normal text		*/
		QHelpColors[1] =HelpColors[1] = FG_BLUE | BG_GRAY;	/* 1: bold			*/
		QHelpColors[2] =HelpColors[2] = FG_WHITE | BG_GRAY;	/* 2: italics			*/
		QHelpColors[3] =HelpColors[3] = FG_YELLOW | BG_GRAY;	/* 3: bold italics		*/
		QHelpColors[4] =HelpColors[4] = FG_RED	 | BG_GRAY;	/* 4: underline 		*/
		QHelpColors[5] =HelpColors[5] = FG_RED | BG_BROWN;	/* 5: bold ul			*/
		QHelpColors[6] =HelpColors[6] = FG_WHITE | BG_BLUE;	/* 6: italics ul		*/
		QHelpColors[7] =HelpColors[7] = FG_LTBLUE | BG_CYAN;	/* 7: bold italics ul		*/

		HdataColors[0] = FG_WHITE | BG_BLUE;	/* 0: normal text		    */
		HdataColors[1] = FG_LTCYAN | BG_BLUE;	/* 1: bold				*/
		HdataColors[2] = FG_BLUE | BG_GRAY;	/* 2: italics			*/
		HdataColors[3] = FG_YELLOW | BG_BLUE;	/* 3: bold italics		*/
		HdataColors[4] = FG_WHITE | BG_BLUE;	/* 4: underline 		*/
		HdataColors[5] = FG_RED | BG_BLUE;	/* 5: bold ul			*/
		HdataColors[6] = FG_WHITE | BG_BLUE;	/* 6: italics ul		*/
		HdataColors[7] = FG_LTBLUE | BG_BLUE;	/* 7: bold italics ul	*/

		ErrorColor = ( FG_WHITE | BG_RED );
		ErrorBorderColor = ( FG_WHITE | BG_RED );

		WaitColor = ( FG_WHITE | BG_RED );

		BaseColor = (FG_WHITE | BG_CYAN);
		TriggerColor = (FG_RED | BG_CYAN);
		EditColor = ( FG_BLACK | BG_GRAY );
		EditInvColor = ( FG_WHITE | BG_BLUE );
		ActiveColor = ( FG_WHITE | BG_CYAN );
		NormalColor = ( FG_BLUE | BG_CYAN );
		DisableColor = ( FG_LTBLUE | BG_CYAN );

		NorDlgColors[0] = (FG_WHITE | BG_CYAN);
		NorDlgColors[1] = (FG_YELLOW | BG_CYAN);
		NorDlgColors[2] = (FG_WHITE | BG_CYAN);
		NorDlgColors[3] = (FG_YELLOW | BG_CYAN);

		ErrDlgColors[0] = (FG_WHITE | BG_RED);
		ErrDlgColors[1] = (FG_YELLOW | BG_RED);
		ErrDlgColors[2] = (FG_WHITE | BG_RED);
		ErrDlgColors[3] = (FG_YELLOW | BG_RED);

		EditorDataColor = FG_WHITE | BG_BLUE;
		EditorHighColor = FG_YELLOW | BG_BLUE;
		EditorMarkColor = FG_WHITE | BG_CYAN;

		OptionTextColor = FG_BLACK | BG_GRAY;
		OptionHighColor = FG_WHITE | BG_BLACK;

		ProgramNameAttr = BG_BLUE | FG_WHITE;

		LogoColor = FG_YELLOW | BG_BLUE;
		AltLogoColor = FG_WHITE | BG_BLACK;
	}
	else {
		DataColor = (FG_BLACK | BG_GRAY);
		DataYellowColor = (FG_BLACK | BG_GRAY);
		DataContinueColor = (FG_BLACK | BG_GRAY);
		QuickBackColor = (FG_BLACK | BG_GRAY);
		PressAnyKeyColor = (FG_BLACK|BG_GRAY);

		BackScreenColor = (FG_DKGRAY|BG_BLACK);
		ShadowColor = (FG_BLACK|BG_BLACK);	/* ??? */
		SolidBlackColor = (FG_BLACK | BG_BLACK );

		ButtonPushedColor = (FG_BLACK | BG_GRAY );
		ButtonActiveColor = (FG_GRAY | BG_BLACK );
		ButtonDisabledColor = (FG_GRAY | BG_BLACK );
		ButtonHotColor = (FG_BLACK | BG_GRAY );
		ButtonChevColor = (FG_BLACK | BG_GRAY);

		MenuItemDisabled = FG_DKGRAY;
		MenuItemTriggerColor = FG_WHITE;
		MenuDisableColor = ( FG_DKGRAY | BG_GRAY );

		HelpColor = (FG_BLACK | BG_GRAY );
		HelpQuickRefColor = ( FG_BLACK | BG_GRAY );
		HelpCurContext = ( FG_BLACK | BG_GRAY	);

		HelpColors[0] =  FG_GRAY  | BG_BLACK;	/* 0: normal text		*/
		HelpColors[1] =  FG_GRAY  | BG_BLACK;	/* 1: bold			*/
		HelpColors[2] =  FG_GRAY  | BG_BLACK;	/* 2: italics			*/
		HelpColors[3] =  FG_GRAY  | BG_BLACK;	/* 3: bold italics		*/
		HelpColors[4] =  FG_WHITE | BG_BLACK;	/* 4: underline 		*/
		HelpColors[5] =  FG_WHITE | BG_BLACK;	/* 5: bold ul			*/
		HelpColors[6] =  FG_WHITE | BG_BLACK;	/* 6: italics ul		*/
		HelpColors[7] =  FG_WHITE | BG_BLACK;	/* 7: bold italics ul		*/

		QHelpColors[0] =  FG_BLACK | BG_GRAY;	/* 0: normal text		*/
		QHelpColors[1] =  FG_BLACK | BG_GRAY;	/* 1: bold			*/
		QHelpColors[2] =  FG_BLACK | BG_GRAY;	/* 2: italics			*/
		QHelpColors[3] =  FG_BLACK | BG_GRAY;	/* 3: bold italics		*/
		QHelpColors[4] =  FG_GRAY | BG_BLACK;	/* 4: underline 		*/
		QHelpColors[5] =  FG_GRAY | BG_BLACK;	/* 5: bold ul			*/
		QHelpColors[6] =  FG_GRAY | BG_BLACK;	/* 6: italics ul		*/
		QHelpColors[7] =  FG_GRAY | BG_BLACK;	/* 7: bold italics ul		*/

		HdataColors[0] = FG_BLACK | BG_GRAY;	/* 0: normal text		    */
		HdataColors[1] = FG_BLACK | BG_GRAY;	/* 1: bold				*/
		HdataColors[2] = FG_BLACK | BG_GRAY;	/* 2: italics			*/
		HdataColors[3] = FG_BLACK | BG_GRAY;	/* 3: bold italics		*/
		HdataColors[4] = FG_BLACK | BG_GRAY;	/* 4: underline 		*/
		HdataColors[5] = FG_BLACK | BG_GRAY;	/* 5: bold ul			*/
		HdataColors[6] = FG_BLACK | BG_GRAY;	/* 6: italics ul		*/
		HdataColors[7] = FG_BLACK | BG_GRAY;	/* 7: bold italics ul	*/

		ErrorColor = ( FG_BLACK | BG_GRAY );
		ErrorBorderColor = ( FG_BLACK | BG_GRAY );

		WaitColor = ( FG_BLACK | BG_GRAY );

		BaseColor = (FG_BLACK | BG_GRAY);
		TriggerColor = (FG_YELLOW | BG_BLACK);
		EditColor = ( FG_BLACK | BG_GRAY );
		EditInvColor = ( FG_GRAY | BG_BLACK );
		ActiveColor = ( FG_YELLOW | BG_BLACK );
		NormalColor = ( FG_BLACK | BG_GRAY );
		DisableColor = ( FG_BLACK | BG_GRAY );

		NorDlgColors[0] = (FG_BLACK | BG_GRAY);
		NorDlgColors[1] = (FG_BLACK | BG_GRAY);
		ErrDlgColors[0] = (FG_WHITE | BG_BLACK);
		ErrDlgColors[1] = (FG_WHITE | BG_BLACK);

		EditorDataColor = FG_WHITE | BG_BLACK;
		EditorHighColor = FG_WHITE | BG_BLACK;
		EditorMarkColor = FG_BLACK | BG_GRAY;

		OptionTextColor = FG_GRAY | BG_BLACK;
		OptionHighColor = FG_BLACK | BG_GRAY;

		ProgramNameAttr = BG_GRAY | FG_BLACK;

		LogoColor = FG_BLACK | BG_GRAY;
		AltLogoColor = FG_WHITE | BG_BLACK;
	}
}
