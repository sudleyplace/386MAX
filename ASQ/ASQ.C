/*' $Header:   P:/PVCS/MAX/ASQ/ASQ.C_V   1.1   05 Sep 1995 16:27:26   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * ASQ.C								      *
 *									      *
 * Main dispatch routine for ASQ					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <stdio.h>
#include <string.h>

/*	Program Includes */
#define ASQ_C
#include "asqtext.h"

#include "asqshare.h"
#include "button.h"
#include "commfunc.h"
#include "editwin.h"
#include "engine.h"
#include "libcolor.h"
#include "menu.h"
#include "mouse.h"
#include "qprint.h"
#include "surface.h"
#include "ui.h"
#include "cputext.h"

/*	Definitions for this Module */
#define BACKCHAR '\xdb'

extern void report_update (void); /* from ASQ.C */

/*	Program Code */
/**
*
* Name		Asq - Core function
*
* Synopsis	void Asq(void)
*
* Parameters
*		No paramaters
*
* Description
*		Main dispatch routine for Asq
*
* Returns	No return
*
* Version	1.0
*/
#pragma optimize ("leg",off)
void asq( void )
{
	int request;
	int forcePaint = TRUE;

	if( saveButtons() != BUTTON_OK ) {
		goto done;
	}
	addButton( AsqButtons, NUMASQBUTTONS, NULL );
	showAllButtons();

	for(;;) {
		MENURETURN askReturn;
		KEYCODE resKey =	0;

		/* Disable all menu items that depend on absent files */
		if (*MAXName) ConfigMenu.items[CPPOS].type = ITEM_ACTIVE;
		else ConfigMenu.items[CPPOS].type = ITEM_DISABLED;

		if (*ExtraDOSName) ConfigMenu.items[CEPPOS].type = ITEM_ACTIVE;
		else ConfigMenu.items[CEPPOS].type = ITEM_DISABLED;

		if (*SYSININame) ConfigMenu.items[CSIPOS].type = ITEM_ACTIVE;
		else ConfigMenu.items[CSIPOS].type = ITEM_DISABLED;

		PrintProgramName = AsqName;
		showMenu( (PMENU)&AsqTopMenu, MENU_VISIBLE );
		setButtonText( KEY_ESCAPE, AsqButtons[ASQEXITESC].text, AsqButtons[ASQEXITESC].colorStart	);

		/*	Set default Help System */
		helpSystem = ASQHELPCONTENTS;

		askReturn = askMenu( (PMENU)&AsqTopMenu, NULL, &request, forcePaint );
		if( MENU_BUTTON == askReturn && LastButton.key == KEY_ESCAPE ) {
			pushButton( LastButton.number );
			hideMenu( AsqTopMenu.items[AsqTopMenu.info.active].lower );
			AsqTopMenu.info.active = SNAPMENUPOS;
			SnapMenu.info.active = SXPOS;
			forcePaint = TRUE;
			continue;
		}

		switch( askReturn ) {
		case MENU_BUTTON:
			pushButton( LastButton.number );
			hideMenu( AsqTopMenu.items[AsqTopMenu.info.active].lower );
			if( LastButton.key == KEY_ESCAPE ) {
				goto cleanup;
			}
			showMenu( (PMENU)&AsqTopMenu, MENU_DISABLED );
			switch( LastButton.key ) {
			case KEY_F2:
				doPrint( NULL, P_MENU, request, request, FALSE );
				break;
			}
			break;
		case MENU_DIRECT:
			if( request != SNAPLOAD ) {
				hideMenu( AsqTopMenu.items[AsqTopMenu.info.active].lower );
				showMenu( (PMENU)&AsqTopMenu, MENU_DISABLED );
				forcePaint = FALSE;
			}
gotRequest:
			switch( request ) {
				int helpRequest;
#ifndef OS2_VERSION
			case SNAPLOAD:
				if (!(*SnapInParens)) {
					/* Recover from /Y2 */
					strcpy(SnapInParens,SNAPINPARENS);
				}
				snapLoad();
				forcePaint = TRUE;
				report_update ();
				break;
			case SNAPSAVE:
				snapSave();
				forcePaint = TRUE;
				break;
			case SNAPINFO:
				resKey = presentData(INFO_SNAPSHOT, HELP_SNAPINFO, FALSE);
				break;
			case SNAPCLEAR:
				snapClear();
				forcePaint = TRUE;
				report_update ();
				break;
#endif
			case SNAPEXIT:
				goto cleanup;
			case MEMORYSUMMARY:
				resKey = presentData(INFO_MEM_SUMM, HELP_MEM_SUMM, FALSE);
				break;
			case MEMORYLOWDOS:
				resKey = presentData(INFO_MEM_LOW, HELP_MEM_LOW, FALSE);
				break;
			case MEMORYHIGHDOS:
				resKey = presentData(INFO_MEM_HIGH, HELP_MEM_HIGH, FALSE);
				break;
			case MEMORYROMSCAN:
				resKey = presentData(INFO_MEM_ROM, HELP_MEM_ROM, FALSE);
				break;
			case MEMORYINTERRUPTS:
				resKey = presentData(INFO_MEM_INT, HELP_MEM_INT, FALSE);
				break;
			case MEMORYEXTENDED:
				resKey = presentData(INFO_MEM_EXT, HELP_MEM_EXT, FALSE);
				break;
			case MEMORYEXPANDED:
				resKey = presentData(INFO_MEM_EXP, HELP_MEM_EXP, FALSE);
				break;
			case MEMORYEMS:
				resKey = presentData(INFO_MEM_EMS, HELP_MEM_EMS, FALSE);
				break;
			case MEMORYXMS:
				resKey = presentData(INFO_MEM_XMS, HELP_MEM_XMS, FALSE);
				break;
			case MEMORYTIMING:
				resKey = presentData(INFO_MEM_TIME, HELP_MEM_TIME, FALSE);
				break;

			case CONFIGSUMMARY:
				resKey = presentData(INFO_CFG_SUMM, HELP_CFG_SUMM, FALSE);
				break;
			case CONFIGSYS:
				altPageOK = TRUE;
				if (!(*ReadFile)) {
					if (*ConfigName)
						resKey = fileEdit( HELP_CFG_CONFIG, TUTORIAL_Cfg_Cfg, ConfigName, TRUE,
							/**ReadFile ? SnapInParens :*/ NULL );
					else	errorMessage( 200 ); /* File or path not found */
				}
				else {
					resKey = presentData(INFO_CFG_CONFIG, HELP_CFG_CONFIG, TRUE);
				}

				altPageOK = FALSE;
				break;
			case CONFIGAUTOEXEC:
				altPageOK = TRUE;
				if (!(*ReadFile)) {
					if (*AutoexecName)
						resKey = fileEdit( HELP_CFG_AUTOEXEC, TUTORIAL_Cfg_Aut, AutoexecName, TRUE,
							/* *ReadFile ? SnapInParens :*/ NULL );
					else	errorMessage( 200 ); /* File or path not found */
				}
				else {
					resKey = presentData(INFO_CFG_AUTOEXEC, HELP_CFG_AUTOEXEC, TRUE);
				}
				altPageOK = FALSE;
				break;
			case CONFIGMAXPRO:
				altPageOK = TRUE;
				if (!(*ReadFile)) {
					if (*MAXName)
						resKey = fileEdit( HELP_CFG_386MAX, TUTORIAL_Cfg_Pro, MAXName, TRUE,
							/* *ReadFile ? SnapInParens :*/ NULL );
					else	errorMessage( 200 ); /* File or path not found */
				}
				else {
					resKey = presentData(INFO_CFG_386MAX, HELP_CFG_386MAX, TRUE);
				}
				altPageOK = FALSE;
				break;
			case CONFIGEXTRADOSPRO:
				altPageOK = TRUE;
				if (!(*ReadFile)) {
					if (*ExtraDOSName)
						resKey = fileEdit( HELP_CFG_EXTRADOS, TUTORIAL_Cfg_EPro, ExtraDOSName, TRUE, NULL );
					else	errorMessage( 200 ); /* File or path not found */
				}
				else {
					resKey = presentData(INFO_CFG_EXTRADOS, HELP_CFG_EXTRADOS, TRUE);
				}
				altPageOK = FALSE;
				break;
			case CONFIGSYSINI:
				altPageOK = TRUE;
				if (!(*ReadFile)) {
					if (*SYSININame)
						resKey = fileEdit( HELP_CFG_SYSINI, TUTORIAL_Cfg_SYSINI, SYSININame, TRUE, NULL );
					else	errorMessage( 200 ); /* File or path not found */
				}
				else {
					resKey = presentData(INFO_CFG_SYSINI, HELP_CFG_SYSINI, TRUE);
				}
				altPageOK = FALSE;
				break;
			case CONFIGQUALITAS:
				resKey = presentData(INFO_CFG_QUALITAS, HELP_CFG_QUALITAS, FALSE);
				break;

			case CONFIGWINDOWS:
				resKey = presentData(INFO_CFG_WINDOWS, HELP_CFG_WINDOWS, FALSE);
				break;

			case CONFIGCMOS:
				resKey = presentData(INFO_HW_CMOS, HELP_HW_CMOS, FALSE);
				break;

			case HARDSUMMARY:
				resKey = presentData(INFO_HW_SUMM, HELP_HW_SUMM, FALSE);
				break;
			case HARDVIDEO:
				resKey = presentData(INFO_HW_VIDEO, HELP_HW_VIDEO, FALSE);
				break;
			case HARDDRIVES:
				resKey = presentData(INFO_HW_DRIVES, HELP_HW_DRIVES, FALSE);
				break;
			case HARDPORTS:
				resKey = presentData(INFO_HW_PORTS, HELP_HW_PORTS, FALSE);
				break;
			case HARDBIOS:
				resKey = presentData(INFO_HW_BIOS, HELP_HW_BIOS, FALSE);
				break;
			case MLEARNASQ:
				helpRequest = LEARNASQ;
				goto dumpHelp;
			case MLEARNQUALITAS:
				helpRequest = LEARNQUALITAS;
				goto dumpHelp;
			case MLEARNTUNING:
				helpRequest = LEARNTUNING;
				goto dumpHelp;
			case MLEARNMEMORY:
				helpRequest = LEARNMEMORY;
				goto dumpHelp;
			case MLEARNCONFIG:
				helpRequest = LEARNCONFIG;
				goto dumpHelp;
			case MLEARNEQUIPMENT:
				helpRequest = LEARNEQUIPMENT;
				goto dumpHelp;
			case MLEARNCONTENTS:
				helpRequest = LEARNCONTENTS;
				goto dumpHelp;
			case MLEARNINDEX:
				helpRequest = LEARNINDEX;
				goto dumpHelp;
			case MLEARNGLOSSARY:
				helpRequest = LEARNGLOSSARY;
				goto dumpHelp;
			case AHELPCONTENTS:
				helpRequest = ASQHELPCONTENTS;
				goto dumpHelp;
			case AHELPINDEX:
				helpRequest = ASQHELPINDEX;
				goto dumpHelp;
			case AHELPHELP:
				helpRequest = ASQHELPHELP;
				goto dumpHelp;
			case AHELPMENUS:
				helpRequest = ASQHELPMENUS;
				goto dumpHelp;
			case AHELPDIALOGS:
				helpRequest = ASQHELPDIALOGS;
				goto dumpHelp;
			case AHELPPRINT:
				helpRequest = ASQHELPPRINT;
				goto dumpHelp;
			case AHELPTUTORIAL:
				helpRequest = ASQHELPTUTOR;
dumpHelp:
				showHelp( helpRequest, FALSE );
				forcePaint = TRUE;
				break;
			}
			if( resKey == KEY_APGUP || resKey == KEY_APGDN ) {
				int *base = resKey == KEY_APGUP ? altPgUp : altPgDn;
				int quickHelp;

				request = *(base+request);

				/*
				*	Now have the new request
				*	Make the menu info match that request
				*/
				switch( request ) {
				case MEMORYSUMMARY:
nextSnapDisabled:
					request = MEMORYSUMMARY;
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MSPOS;
					quickHelp = MemoryMenu.items[MSPOS].quickHelpNumber;
					break;
				case MEMORYLOWDOS:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MLPOS;
					quickHelp = MemoryMenu.items[MLPOS].quickHelpNumber;
					break;
				case MEMORYHIGHDOS:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MHPOS;
					quickHelp = MemoryMenu.items[MHPOS].quickHelpNumber;
					break;
				case MEMORYROMSCAN:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MRPOS;
					quickHelp = MemoryMenu.items[MRPOS].quickHelpNumber;
					break;
				case MEMORYINTERRUPTS:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MIPOS;
					quickHelp = MemoryMenu.items[MIPOS].quickHelpNumber;
					break;
				case MEMORYEXTENDED:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MTPOS;
					quickHelp = MemoryMenu.items[MTPOS].quickHelpNumber;
					break;
				case MEMORYEXPANDED:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MPPOS;
					quickHelp = MemoryMenu.items[MPPOS].quickHelpNumber;
					break;
				case MEMORYEMS:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MEPOS;
					quickHelp = MemoryMenu.items[MEPOS].quickHelpNumber;
					break;
				case MEMORYXMS:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MXPOS;
					quickHelp = MemoryMenu.items[MXPOS].quickHelpNumber;
					break;
				case MEMORYTIMING:
					AsqTopMenu.info.active = MEMORYMENUPOS;
					MemoryMenu.info.active = MAPOS;
					quickHelp = MemoryMenu.items[MAPOS].quickHelpNumber;
					break;
				case CONFIGSUMMARY:
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CSPOS;
					quickHelp = ConfigMenu.items[CSPOS].quickHelpNumber;
					break;
				case CONFIGSYS:
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CCPOS;
					quickHelp = ConfigMenu.items[CCPOS].quickHelpNumber;
					break;
				case CONFIGAUTOEXEC:
prevMaxDisabled:
					request = CONFIGAUTOEXEC;
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CAPOS;
					quickHelp = ConfigMenu.items[CAPOS].quickHelpNumber;
					break;
				case CONFIGMAXPRO:
prevExtraDOSDisabled:
					request = CONFIGMAXPRO;
					if( ConfigMenu.items[CPPOS].type == ITEM_DISABLED) {
						if( base == altPgUp )
							goto prevMaxDisabled;
						else
							goto nextMaxDisabled;
					}
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CPPOS;
					quickHelp = ConfigMenu.items[CPPOS].quickHelpNumber;
					break;
				case CONFIGEXTRADOSPRO:
nextMaxDisabled:
prevSYSINIDisabled:
					request = CONFIGEXTRADOSPRO;
					if( ConfigMenu.items[CEPPOS].type == ITEM_DISABLED) {
						if( base == altPgUp )
							goto prevExtraDOSDisabled;
						else
							goto nextExtraDOSDisabled;
					}
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CEPPOS;
					quickHelp = ConfigMenu.items[CEPPOS].quickHelpNumber;
					break;
				case CONFIGSYSINI:
nextExtraDOSDisabled:
					request = CONFIGSYSINI;
					if( ConfigMenu.items[CSIPOS].type == ITEM_DISABLED) {
						if( base == altPgUp )
							goto prevSYSINIDisabled;
						else
							goto nextSYSINIDisabled;
					}
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CSIPOS;
					quickHelp = ConfigMenu.items[CSIPOS].quickHelpNumber;
					break;
				case CONFIGQUALITAS:
nextSYSINIDisabled:
					request = CONFIGQUALITAS;
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CQPOS;
					quickHelp = ConfigMenu.items[CQPOS].quickHelpNumber;
					break;
				case CONFIGWINDOWS:
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CWPOS;
					quickHelp = ConfigMenu.items[CWPOS].quickHelpNumber;
					break;
				case CONFIGCMOS:
					AsqTopMenu.info.active = CONFIGMENUPOS;
					ConfigMenu.info.active = CMPOS;
					quickHelp = ConfigMenu.items[CMPOS].quickHelpNumber;
					break;
				case HARDSUMMARY:
					AsqTopMenu.info.active = HARDWAREMENUPOS;
					HardMenu.info.active = HSPOS;
					quickHelp = HardMenu.items[HSPOS].quickHelpNumber;
					break;
				case HARDVIDEO:
					AsqTopMenu.info.active = HARDWAREMENUPOS;
					HardMenu.info.active = HVPOS;
					quickHelp = HardMenu.items[HVPOS].quickHelpNumber;
					break;
				case HARDDRIVES:
					AsqTopMenu.info.active = HARDWAREMENUPOS;
					HardMenu.info.active = HDPOS;
					quickHelp = HardMenu.items[HDPOS].quickHelpNumber;
					break;
				case HARDPORTS:
					AsqTopMenu.info.active = HARDWAREMENUPOS;
					HardMenu.info.active = HPPOS;
					quickHelp = HardMenu.items[HPPOS].quickHelpNumber;
					break;
				case HARDBIOS:
prevSnapDisabled:
					request = HARDBIOS;
					AsqTopMenu.info.active = HARDWAREMENUPOS;
					HardMenu.info.active = HBPOS;
					quickHelp = HardMenu.items[HBPOS].quickHelpNumber;
					break;
				case SNAPINFO:
					if( SnapMenu.items[SIPOS].type == ITEM_DISABLED) {
						if( base == altPgUp )
							goto prevSnapDisabled;
						else
							goto nextSnapDisabled;
					}
					AsqTopMenu.info.active = SNAPMENUPOS;
					SnapMenu.info.active = SIPOS;
					quickHelp = SnapMenu.items[SIPOS].quickHelpNumber;
					break;
				}
				showQuickHelp( quickHelp );

				goto gotRequest;
			}
			break;
		}
	}
cleanup:
	restoreButtons( );

done:
	return;
}
#pragma optimize ("",on)


#ifdef REVIVETHEMENUCALLBACKS
/**
*
* Name		quickAsq - Paint the data window for asq functions
*
* Synopsis	void quickAsq(int code )
*
* Parameters
*		int code			What callback code is being passed
*
* Description
*		Paint the data window for asq
*
* Returns	No return
*
* Version	1.0
*/
void quickAsq( int code )	/*	Set a menu background */
{

	disableButton( KEY_ESCAPE, code == SNAPEXIT );

	switch( code ) {
	case SNAPLOAD:
		showDataHelp(AS_DATA_Load );
		break;
	case SNAPSAVE:
		showDataHelp(AS_DATA_Save);
		break;
	case SNAPINFO:
		/*	Still missing */
		quickShowData(INFO_SNAPSHOT);
		break;
	case SNAPCLEAR:
		showDataHelp(AS_DATA_Clear );
		break;

	case SNAPEXIT:
		showDataHelp(AS_DATA_Exit );
		break;

	case MEMORYSUMMARY:
		quickShowData(INFO_MEM_SUMM);
		break;
	case MEMORYLOWDOS:
		quickShowData(INFO_MEM_LOW);
		break;
	case MEMORYHIGHDOS:
		quickShowData(INFO_MEM_HIGH);
		break;
	case MEMORYROMSCAN:
		quickShowData(INFO_MEM_ROM);
		break;
	case MEMORYINTERRUPTS:
		quickShowData(INFO_MEM_INT);
		break;
	case MEMORYEXTENDED:
		quickShowData(INFO_MEM_EXT);
		break;
	case MEMORYEXPANDED:
		quickShowData(INFO_MEM_EXP);
		break;
	case MEMORYEMS:
		quickShowData(INFO_MEM_EMS);
		break;
	case MEMORYXMS:
		quickShowData(INFO_MEM_XMS);
		break;
	case MEMORYTIMING:
		quickShowData(INFO_MEM_TIME);
		break;

	case CONFIGSUMMARY:
		quickShowData(INFO_CFG_SUMM);
		break;
	case CONFIGSYS:
		quickShowData(INFO_CFG_CONFIG);
		break;
	case CONFIGAUTOEXEC:
		quickShowData(INFO_CFG_AUTOEXEC);
		break;
	case CONFIGMAXPRO:
		quickShowData(INFO_CFG_386MAX);
		break;
	case CONFIGCMOS:
		quickShowData(INFO_HW_CMOS);
		break;

	case HARDSUMMARY:
		quickShowData(INFO_HW_SUMM);
		break;
	case HARDVIDEO:
		quickShowData(INFO_HW_VIDEO);
		break;
	case HARDDRIVES:
		quickShowData(INFO_HW_DRIVES);
		break;
	case HARDPORTS:
		quickShowData(INFO_HW_PORTS);
		break;
	case HARDBIOS:
		quickShowData(INFO_HW_BIOS);
		break;
	case MLEARNASQ:
	case MLEARNQUALITAS:
	case MLEARNTUNING:
	case MLEARNMEMORY:
	case MLEARNCONFIG:
	case MLEARNEQUIPMENT:
	case MLEARNCONTENTS:
	case MLEARNINDEX:
	case MLEARNGLOSSARY:
		showDataHelp(AS_DATA_Learn );
		break;

	case AHELPCONTENTS:
	case AHELPINDEX:
	case AHELPHELP:
	case AHELPMENUS:
	case AHELPDIALOGS:
	case AHELPPRINT:
	case AHELPTUTORIAL:
		showDataHelp(AS_DATA_Help );
		break;
	}
}
#endif /* REVIVETHEMENUCALLBACKS */
