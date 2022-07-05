/*' $Header:   P:/PVCS/MAX/MAXIMIZE/SCREENS.C_V   1.5   11 Nov 1995 16:33:44   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * SCREENS.C								      *
 *									      *
 * MAXIMIZE screen code 						      *
 *									      *
 ******************************************************************************/

/* System Includes */
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <io.h>

/* Local includes */

#include <bioscrc.h>		/* Machine type/BCF functions */
#include <commfunc.h>		/* Common functions */
#include <debug.h>		/* Debug variables */
#include <dialog.h>		/* Surface functions */
#include <input.h>		/* Input structure */
#include <intmsg.h>		/* Intermediate message functions */
#include <saveadf.h>		/* Functions to save .ADF files */
#include <ui.h> 		/* UI functions */
#include <mbparse.h>	// Multiconfig parsing functions and declarations

#define SCREENS_C		/* ..to select message text */
#include <maxtext.h>		/* MAX message text */
#include <maxvar.h>		/* MAXIMIZE global variables */
#undef SCREENS_C

#ifndef PROTO
#include "maximize.pro"
#include <maxsub.pro>
#include "readcnfg.pro"
#include "screens.pro"
#include "wrfiles3.pro"
#include "util.pro"
#endif /*PROTO*/

/* Local variables */

/* Local functions */

/********************************* SETCOLORS ********************************/
/*  Set up our color definitions for color or monochrome screen */

void setColors(BOOL mono)
{
	NormalDialog.editAttr = EditColor;
	if (!mono) {
		/* Browse colors */
		BrBaseColor = FG_YELLOW | BG_BLUE;
		BrScrollBar = FG_GRAY | FG_BLUE;

		P1LowCool  = FG_WHITE | BG_BLUE;
		P1LowHot   = FG_WHITE | BG_RED;
		P1HighCool = FG_YELLOW | BG_BLUE;
		P1HighHot  = FG_YELLOW | BG_RED;

		       /*lo/hi cool/hot*/
		P2ActColors[0] [0] = FG_YELLOW | BG_BLUE;
		P2ActColors[0] [1] = FG_YELLOW | BG_BLUE;
		P2ActColors[1] [0] = FG_YELLOW | BG_RED;
		P2ActColors[1] [1] = FG_YELLOW | BG_RED;
		       /*lo/hi cool/hot*/
		P2TxtColors[0] [0] = FG_WHITE | BG_BLUE;
		P2TxtColors[0] [1] = FG_YELLOW | BG_BLUE;
		P2TxtColors[1] [0] = FG_WHITE | BG_RED;
		P2TxtColors[1] [1] = FG_YELLOW | BG_RED;
		       /*lo/hi cool/hot*/
		P3ActColors[0] [0] = FG_YELLOW | BG_BLUE;
		P3ActColors[0] [1] = FG_YELLOW | BG_BLUE;
		P3ActColors[1] [0] = FG_YELLOW | BG_RED;
		P3ActColors[1] [1] = FG_YELLOW | BG_RED;
		       /*lo/hi cool/hot*/
		P3TxtColors[0] [0] = FG_WHITE | BG_BLUE;
		P3TxtColors[0] [1] = FG_WHITE | BG_BLUE;
		P3TxtColors[1] [0] = FG_WHITE | BG_RED;
		P3TxtColors[1] [1] = FG_WHITE | BG_RED;

		P3GrpLow  = FG_BLACK | BG_GRAY;
		P3GrpHigh = FG_WHITE | BG_BLACK;
		P3GrpAlt  = FG_LTCYAN | BG_BLUE;

		ProgBarHot   = FG_GRAY | BG_RED;
	}
	else {
		/* Browse colors */
		BrBaseColor = FG_WHITE | BG_BLACK;
		BrScrollBar = FG_GRAY | FG_BLACK;

		P1LowCool  = FG_GRAY | BG_BLACK;
		P1LowHot   = FG_BLACK | BG_GRAY;
		P1HighCool = FG_WHITE | BG_BLACK;
		P1HighHot  = FG_BLACK | BG_GRAY;

		       /*lo/hi cool/hot*/
		P2ActColors[0] [0] = FG_WHITE | BG_BLACK;
		P2ActColors[0] [1] = FG_WHITE | BG_BLACK;
		P2ActColors[1] [0] = FG_BLACK | BG_GRAY;
		P2ActColors[1] [1] = FG_BLACK | BG_GRAY;
		       /*lo/hi cool/hot*/
		P2TxtColors[0] [0] = FG_GRAY | BG_BLACK;
		P2TxtColors[0] [1] = FG_WHITE | BG_BLACK;
		P2TxtColors[1] [0] = FG_BLACK | BG_GRAY;
		P2TxtColors[1] [1] = FG_BLACK | BG_GRAY;
		       /*lo/hi cool/hot*/
		P3ActColors[0] [0] = FG_WHITE | BG_BLACK;
		P3ActColors[0] [1] = FG_WHITE | BG_BLACK;
		P3ActColors[1] [0] = FG_BLACK | BG_GRAY;
		P3ActColors[1] [1] = FG_BLACK | BG_GRAY;
		       /*lo/hi cool/hot*/
		P3TxtColors[0] [0] = FG_GRAY | BG_BLACK;
		P3TxtColors[0] [1] = FG_GRAY | BG_BLACK;
		P3TxtColors[1] [0] = FG_BLACK | BG_GRAY;
		P3TxtColors[1] [1] = FG_BLACK | BG_GRAY;

		P3GrpLow  = FG_BLACK | BG_GRAY;
		P3GrpHigh = FG_WHITE | BG_BLACK;
		P3GrpAlt  = FG_GRAY | BG_BLACK;

		ProgBarHot   = FG_GRAY | BG_BLACK;
	}
}

/*********************************** DO_LOGO *********************************/

void do_logo(int doit)
{
	BOOL abort;
	int badspawn;
	char serial[100];

	if (!decrypt_serialno(serial,sizeof(serial))) {
		/* Ack! */
		errorMessage(559);
#ifndef CVDBG
		abortprep(0);
		exit(255);
#endif
	}


#ifndef OS2_VERSION
	badspawn = showLogo(doit,"Q",MsgLogoText,serial,paintback);
#endif

	disable23();
	/* Inside windows? */
	if (win_version() != 0) {
		/* Naughty, naughty.... */
		do_error(MsgFromWin,TRUE);
		abort = TRUE;
	}
	else {
		abort = pressAnyKey(2500L);
	}
	enable23();

#ifndef OS2_VERSION
	if (!badspawn) showLogo(-1,"Q",NULL,NULL,paintback);
#endif
	if (abort) {
		cstdwind();
		done2324();
		maxout (0);
	}
} /* End DO_LOGO */

/*********************************** DO_INTRO *********************************/

void do_intro(void)
{
	KEYCODE key;

	/* Intro P1 */
	key = dialog(&NormalDialog,
		TitleIntro,
		MsgIntroP1,
#if SYSTEM != MOVEM
		HELP_INTROMAX,
#else
		HELP_INTROMOV,
#endif
		NULL,
		0);

	if (key == KEY_ESCAPE) AbyUser = AnyError = 1;
	if (AnyError) return;

#if SYSTEM != MOVEM
	if (
#ifdef DEBUG
	    MCAflag ||
#endif
		       Is_MCA ()) {
		char temp[256];

		/* If the LoadString\ADF directory is up to date, */
		/* don't display this message since we don't need */
		/* to ask for the reference diskette. */
		if (check_adf_files (temp, sizeof (temp))) return;

		/* Intro for PS/2 */
		key = dialog(&NormalDialog,
			TitleIntro,
			MsgIntroPs2,
			HELP_INTROP2,
			NULL,
			0);

		if (key == KEY_ESCAPE) AbyUser = AnyError = 1;
	}
#endif	/* != MOVEM */

} /* End DO_INTRO */

/*************************** WARNING_PANEL **********************************/
void warning_panel (char *msg,int helpnum)
{
	DIALOGPARM parm;

	parm = NormalDialog;
	parm.attr = ErrDlgColors;
	dialog(&parm,
		TitleWarning,
		msg,
		helpnum,
		NULL,
		0);
}

/*************************** MESSAGE_PANEL **********************************/
void message_panel (char *msg,int helpnum)
{
	dialog(&NormalDialog,
		TitleMessage,
		msg,
		helpnum,
		NULL,
		0);
}

/*************************** ACTION_PANEL **********************************/
BOOL action_panel (char *msg,int helpnum)
{
	KEYCODE key;

	DIALOGPARM parm;

	parm = NormalDialog;
	parm.pButton = YesNoButtons;
	parm.nButtons = sizeof(YesNoButtons)/sizeof(YesNoButtons[0]);
	key = dialog(&parm,
		TitleAction,
		msg,
		helpnum,
		NULL,
		0);
	if (toupper(key) == RESP_YES) return TRUE;
	return FALSE;

}

void do_getdrv (void)
{
	DIALOGPARM parm;
	DIALOGEDIT edit;
	char drvedit[2];
	char buff[80];
	int drivebad = 0;

	if (!isalpha(BootDrive)) BootDrive = get_bootdrive();
	drvedit[0] = (char) BootDrive;
top:
	if (drivebad) {
		/* Even if specified via BOOTDRIVE or command line, */
		/* validate drive. */
		parm = NormalDialog;
		drvedit[1] = '\0';
		parm.width = SMALL_DIALOG;
		parm.editShadow = SHADOW_NONE;
		edit = DriveEdit;
		edit.editText = drvedit;
		edit.editLen = 1;

		for (;;) {
			KEYCODE key;

			key = dialog(&parm,
				TitleAction,
				MsgBootDisk,
				HELP_BOOTDSK,
				&edit,
				1);

			if (key == KEY_ESCAPE) {
				AnyError = AbyUser = TRUE;
				break;
			}

			if (isalpha(drvedit[0])) {
				break;
			}
		}
	}

	drivebad = 1;	/* If we go back, we'll ask before shooting */

	buff[0] = drvedit[0];
	strcpy (buff+1, ":\\CONFIG.SYS");

	truename (buff);

	/* Ensure the file exists */
	if (_access (buff, 0) < 0) {
		/* CONFIG.SYS file not found */
		do_warning(MsgCnfNf,0);
		goto top;
	} /* End IF */

	/* Ensure we have _read/_write permission */
	if (_access (buff, 2) < 0) {
		do_warning(MsgCnfWp,0);
		goto top;
	} /* End IF */
	ActiveFiles[CONFIG] = str_mem(buff);

	/* If the AUTOEXEC file doesn't exist, create it */
	strcpy (&buff[1], ":\\AUTOEXEC.BAT");
	if (_access (buff, 0) < 0)
		createfile (buff);

	ActiveFiles[AUTOEXEC] = str_mem(buff);
	BootDrive = drvedit[0];

} /* End DO_GETDRV */

/***************************** DO_FILEREQ **********************************/

char *do_filereq(void)
{
	DIALOGPARM parm;
	DIALOGEDIT edit;
	static char line[80];
	char *rtn;

	parm = NormalDialog;
	parm.width = MEDIUM_DIALOG;
	edit = PathEdit;
	edit.editText = line;
	edit.editLen = sizeof(line);
	rtn = NULL;
	line[0] = '\0';
	for (;;) {
		int ii;
		KEYCODE key;

		key = dialog(&parm,
			TitleAction,
			MsgReqFile,
			HELP_FILEREQ,
			&edit,
			1);

		if (key == KEY_ESCAPE) {
			AnyError = AbyUser = TRUE;
			break;
		}

		trim(line);
		if (key == KEY_ESCAPE) break;

		/* Ensure the string ends with a path separator */
		ii = strlen (line);
		if (ii != 0 && line[ii - 1] != '\\')
			strcat (line, "\\");

		ii = chkforfiles (line, 0);
		if (ii == 0) {
			rtn = line;
			break;
		}
	}
	return rtn;
} /* End DO_FILEREQ */


/***************************** DO_REFDSK **********************************/

KEYCODE do_refdsk (char *line,int nline)
{
	int nc;
	KEYCODE key;
	DIALOGPARM parm;
	DIALOGEDIT edit;
	char temp[MAXFILELENGTH];

	if (check_adf_files(temp,sizeof(temp))) {
		/* Already have valid .ADF files */
		line[nline-1] = '\0';
		strncpy(line,temp,nline-1);
		return KEY_ENTER;
	}

	parm = NormalDialog;
	parm.width = LARGE_DIALOG;

	parm.pButton = RefDiskButtons;
	parm.nButtons = sizeof(RefDiskButtons)/sizeof(RefDiskButtons[0]);

	edit = PathEdit;
	edit.editWin.ncols = LARGE_DIALOG - 5;
	edit.editText = line;
	edit.editLen = nline;


	RefDisk = FALSE;
DOREFDSK:
	dialog_callback(0,NULL);
	saveButtons();	/* ..so that we can override the line 25 Esc button */
	key = dialog(&parm,
		TitleAction,
		MsgRefDsk,
		HELP_REFDSK,
		&edit,
		1);
	restoreButtons();
	dialog_callback(KEY_ESCAPE,chkabort);

	switch (key) {
	case KEY_ENTER:
		nc = strlen(line);
		if (nc > 0) {
			RefDisk = TRUE;
			if (line[nc-1] != '\\') {
				strcat(line,"\\");
			}
			do_intmsg(MsgCopyADF);
			if (save_adf_files(line,temp)) {
				line[nline-1] = '\0';
				strncpy(line,temp,nline-1);
				goto bottom;
			}
			else	goto DOREFDSK;
		}

	case KEY_ESCAPE:
DOREFDSK2:
		/* Reverse the defaults */

		YesNoButtons[0].defButton = !YesNoButtons[0].defButton;
		YesNoButtons[1].defButton = !YesNoButtons[1].defButton;

		key = dialog(&WarningDialog,
			TitleWarning,
			MsgRefDsk2,
			HELP_REFDSK2,
			NULL,
			0);

		YesNoButtons[0].defButton = !YesNoButtons[0].defButton;
		YesNoButtons[1].defButton = !YesNoButtons[1].defButton;


		switch (key) {
		case KEY_ENTER:
		case RESP_NO:
			 goto DOREFDSK;

		case RESP_YES:
			key = KEY_ESCAPE;
			goto bottom;

		default:
			putchar ('\007');
			goto DOREFDSK2;
		} /* End SWITCH */
	default:
		goto DOREFDSK;
	} /* End SWITCH */
bottom:
	return key;

} /* End DO_REFDSK */

/****************************** DO_QUICKMAX *******************************/
void do_quickmax (void)
{
	KEYCODE key;
	DIALOGPARM parm;

	parm = NormalDialog;
	parm.pButton = YesNoButtons;
	parm.nButtons = sizeof(YesNoButtons)/sizeof(YesNoButtons[0]);
	key = dialog(&parm,
		TitleAction,
		MsgQuickMax,
		HELP_QUICKMAX,
		NULL,
		0);

	if ( key == RESP_YES ) {
		QuickMax = NopauseMax = 1;
		message_panel(MsgReboot,0);
	}
	else		  QuickMax = -1;
} /* End do_quickmax */

#define NBOX 3		/* How many overlapped boxes */
#define BOXROW 3	/* Row of first box */
#define BOXCOL 10	/* Col of first box */
#define BOXNROWS 8	/* Rows in each box */
#define BOXNCOLS 17	/* Cols in each box */
#define BOXROWINC 2	/* Row increment to next box */
#define BOXCOLINC 2	/* Col increment to next box */
#define BOXCOLSPACE 35	/* Col space between box sets */
#define ARROWLEN 12	/* Length of arrow between box sets */

static void *ProgressSave = NULL;
static char spnbuff[41] = { 0 };
static int dispflags = 0;
static WINDESC waitmsgwin;
static int WaitMsgLen;	/* Offset for "completed." within "Maximizing in */
			/* progress" message. */

/****************************** WPUT_CF ***********************************/
void wput_cf (WINDESC *wp, char _far *fstr)
// Copy a far string to near addressable spnbuff[] and display
{

 memset (spnbuff,0,sizeof(spnbuff));
 _fstrcpy ((char _far *)spnbuff,fstr);
 wput_c(wp,spnbuff);

} // wput_cf ()

/***************************** INIT_PROGRESS *******************************/
// Initialize optimization progress display, using msgtext to uniquely
// identify screen as "Maximizing" or "Reordering"
void init_progress(char *msgtext)
{
	int nc;
	WINDESC widewin;	// Temporary window descriptor
	HELPTEXT htext;

	/* Calculate offset of "completed." within "Maximizing ..." */
	WaitMsgLen = (int) (strchr (msgtext, ' ') - msgtext + 1);

	/* Bring up the background, temporarily alter reality */
	widewin = DataWin;	// Copy contents of standard data window
	widewin.nrows++;	// Stretch vertically by one row
	widewin.ncols = (QuickWin.col + QuickWin.ncols) - DataWin.col;

	/* Save what's behind */
	ProgressSave = win_save(&widewin,SHADOW_DOUBLE);

	/* Clear and shadow */
	wput_sca(&widewin,VIDWORD(DataColor,' '));
	shadowWindow(&widewin);

	loadText(&htext,
		 HelpInfo[HELP_PROGSCRN].type,
		 HelpInfo[HELP_PROGSCRN].context);
	showText(&htext,&widewin,HdataColors,NULL);

	nc = strlen(msgtext);	// Length of text to display
	waitmsgwin = widewin;	// Copy window used for background screen
	waitmsgwin.row++;	// Start one row down
	waitmsgwin.col += (waitmsgwin.ncols - nc) / 2;
				// Center our text
	waitmsgwin.nrows = 1;
	waitmsgwin.ncols = nc;
	wput_csa(&waitmsgwin,msgtext,DataYellowColor);
	disableButton( KEY_F1, TRUE );
	disableButton (KEY_ESCAPE, TRUE);

	dispflags = 0;

}

/*************************** SHOW_PROGRESS *******************************/
/* Called as a far indirect call from the ORDFIT procedure (contained
 * in UTIL_OPT.ASM).  UTIL_OPT.ASM declares _OPT_PROGRESS as an extern
 * dword pointer.  _OPT_PROGRESS is allocated as a public dword in
 * MAXSUB.ASM, and is initialized to the segment and offset of this
 * function during MAXIMIZE() before the call to ORDFIT.  ORDFIT loads
 * a safe stack and calls this procedure through an indirect far call
 * (call [dword ptr xxxx]).
 */
 /**** These constants define display locations for progress display. ****/
#define COUNT_XPOS	20	// Starting column for all long values
#define COUNT_XLEN	30	// Max. digits for all long values (includes ,)
#define TIME_XPOS	53	// Starting column for time (HH:MM:SS)
#define TIME_XLEN	8	// Length of time (wraps at 99 hours)
#define BYTES_XPOS	64	// Starting column for bytes moved high
#define BYTES_XLEN	7	// Max. digits for bytes moved high (nnn,nnn)
#define BAR_YPOS	5	// Line for percentage histogram
#define TOTAL_YPOS	11	// Line for total combinations
#define CUR_YPOS	13	// Line for combinations considered
#define BEST_YPOS	15	// Line for combinations to best fit so far
#define BPCT_XPOS	42	// Column for best fit as % of total
#define BPCT_XLEN	8	// Digits for best fit percentage (xxx.x%)
#define BBPCT_XPOS	BYTES_XPOS-1 // Column for best bytes moved as % of tot
#define CTRLBRK_YPOS	18	// Line for "Ctrl-Break aborts"
#define ESC_YPOS	19	// Line for "Escape to accept current best fit"
#define MSG_XPOS	3	// Line for "{Maximizing,Reordering} in prog."
#define ANYKEY_YPOS	21	// Line for "Press any key..."

void _far _loadds show_progress(OPT_PROG far *ps)
{
	WINDESC win;
	char *spnptr;		// To achieve model independence, we need to
				// do pointer conversion from the far pointers
				// contained in the OPT_PROG structure

	// Display percentage bar, 2% per character
	SETWINDOW (&win, 5, COUNT_XPOS, 1, COUNT_XLEN);
	if (ps->pct > 1) {
		win.ncols = ps->pct / 2;
		wput_sa(&win,ProgBarHot);
	}

	if (!(dispflags & 0x01)) {  // If locally flagged for redisplay

	 win.row = TOTAL_YPOS;	    // Row for total
	 win.ncols = COUNT_XLEN;    // Number of characters in a long value
	 wput_cf(&win,ps->ptotal);  // Display it

	 win.col = BYTES_XPOS;	     // Column for bytes in high DOS
	 win.ncols = BYTES_XLEN;     // Length of dword byte value
	 wput_cf(&win,ps->ptothigh); // Display it

	 dispflags |= 0x01;	    // Set flag

	} // dispflags & 1 is false

	win.row = CUR_YPOS;	    // Row for current
	win.col = COUNT_XPOS;	    // Column for count
	win.ncols = COUNT_XLEN;     // Number of characters in a long value
	wput_cf(&win,ps->pdone);    // Display it (this almost always changes)

	win.col = TIME_XPOS;	    // Column for time
	win.ncols = TIME_XLEN;	    // Length of time
	wput_cf(&win,ps->pelapsed); // Display it (this ALWAYS changes)

	if (ps->flags & 0x8000) {   // If caller flagged redisplay best

	 // Set display window for best count
	 SETWINDOW(&win,BEST_YPOS,COUNT_XPOS,1,COUNT_XLEN);
	 wput_cf(&win,ps->pbestcnt); // Display it

	 win.col = TIME_XPOS;	     // Column for best time
	 win.ncols = TIME_XLEN;      // Length of time
	 wput_cf(&win,ps->pbestelap); // Display it

	 win.col = BYTES_XPOS;	     // Column for bytes moved high
	 win.ncols = BYTES_XLEN;     // Length of bytes moved high
	 wput_cf(&win,ps->pbestbyte); // Display it

	 // Set display window for best count as percentage of total
	 SETWINDOW (&win,BEST_YPOS+1,BPCT_XPOS,1,BPCT_XLEN);
	 spnptr = spnbuff;	     // Point to local buffer
	 *spnptr++ = ' ';            // Clear first character
	 _fstrcpy ((char _far *) spnptr, ps->pbestpct);
				     // Get near addressability

	 for (; *spnptr == ' '; spnptr++) ;     // Skip leading spaces

	 if (*spnptr) { 	     // Not null
	  *(--spnptr) = '(';         // Back off 1 character and blast in '('
	  strcat (spnptr, ")");      // Add trailing ')'
	 } // *spnptr != '\0'

	 wput_c (&win,spnbuff);      // Display percentage

	 // Display bytes moved high as percentage of bytes in high DOS
	 win.col = BBPCT_XPOS;	     // Position for best bytes percentage
	 spnptr = spnbuff;	     // Point to local buffer
	 *spnptr++ = ' ';            // Clear first character
	 _fstrcpy ((char _far *) spnptr, ps->pbestbpct);
				     // Get near addressability

	 for (; *spnptr == ' '; spnptr++) ;     // Skip leading spaces

	 if (*spnptr) { 	     // Not null
	  *(--spnptr) = '(';         // Back off 1 character and blast in '('
	  strcat (spnptr, ")");      // Add trailing ')'
	 } // *spnptr != '\0'

	 wput_c (&win,spnbuff);      // Display percentage

	 ps->flags &= 0x7fff;	     // Clear flags in caller's data structure

	 // Do we have a best fit, so we can display "Esc to accept" message?
	 // And did we not already display the message?
	 if (!(dispflags & 0x02) && ps->pbestcnt[COUNT_XLEN-1] != ' ') {

	  // Display window for "Esc to accept message
	  SETWINDOW (&win, ESC_YPOS, MSG_XPOS, 1, strlen (MsgPressEsc));
	  wput_c (&win, MsgPressEsc); // Display it
	  dispflags |= 0x02;	      // Set message displayed flag

	 } // dispflags & 2 is false, and best is not blank

	} // Best data needs to be redisplayed

} // show_progress()

/***************************** CONFIRM_ABESC ******************************/
// Callback routine for optimization progress
// Called from int 1C handler in UTIL_OPT.ASM
// Callback type is 0 (confirm ESC) or 1 (confirm Ctrl-Break)
// Return is 1 to confirm, 0 to deny
int _far _loadds confirm_abesc (int cb_type)
{
	char *msg;
	KEYCODE key;
	DIALOGPARM parm;

	switch (cb_type) {
	 case 0:
		msg = MsgConfirmEsc;
		break;
	 case 1:
		msg = MsgConfirmAbort;
		break;
	 default:
		return (0);
	}

	parm = NormalDialog;
	parm.pButton = YesNoButtons;
	parm.nButtons = sizeof(YesNoButtons)/sizeof(YesNoButtons[0]);
	key = dialog(&parm,
		TitleAction,
		msg,
		0,
		NULL,
		0);

	return (key == RESP_YES ? 1 : 0);

} // confirm_abesc()

/***************************** END_PROGRESS *******************************/
void end_progress(void)
{
	WINDESC win;
	INPUTEVENT event;

	waitmsgwin.col += WaitMsgLen;
	waitmsgwin.ncols -= WaitMsgLen;
	wput_sc (&waitmsgwin,' ');
	waitmsgwin.ncols = sizeof(CompleteMsg)-1;
	wput_c (&waitmsgwin,CompleteMsg);

	/* If it's Quick MAXIMIZE, wait 5 seconds (5000 ms) */
	/* If from Windows, don't wait at all */
	if (FromWindows) {
		get_input( 100L, &event );
	} /* Running from windows */
	else {

		SETWINDOW (&win, CTRLBRK_YPOS,MSG_XPOS,ESC_YPOS-CTRLBRK_YPOS+1,60);
		wput_sc (&win,' ');
		SETWINDOW (&win,ANYKEY_YPOS,MSG_XPOS,1,strlen(MsgPressAnyKey));
		wput_c (&win,MsgPressAnyKey);
		get_input (QuickMax > 0 ? 5000L : INPUT_WAIT, &event);

	} /* Running from DOS */

	disableButton( KEY_F1, FALSE );
	disableButton (KEY_ESCAPE, FALSE);
	win_restore(ProgressSave,TRUE);
}

// Insert our WinMaxim line into the startup batch file, either before the
// first shell program present in the chain of startup batch files or at
// the end of the startup batch file (usually autoexec.bat)
void
InsertStartup( char *pszINI ) {

	char temp[ _MAX_PATH ];
	FILE *pfSumm = fopen( pszINI, "at" );

	if (pfSumm) {

			int nWhere, nFile;
			BATFILE *b;
			DSPTEXT *newline;
			char *pszExt;

			// Find the first shell line listed in MAXIMIZE.OUT, which could
			// be a descendent of AUTOEXEC.BAT
			for (b = FirstBat; b; b = b->nextbat) {
				if (b->flags && strpbrk( b->flags, "~$" )) {
					// Ignore QMT.EXE and RAMEXAM.EXE as they're supposed
					// to run first.
					_splitpath( b->command, NULL, NULL, temp, NULL );
					if (_stricmp( temp, "RAMEXAM" ) &&
						_stricmp( temp, "QMT" )) {
						break;
					} // Not a memory tester
				} // Found a shell
			} // Looking for a shell

			// Note that we no longer need BATFILE->line so we're not
			// going to try to update it for all subsequent nodes in
			// the list...
			newline = get_mem( sizeof( DSPTEXT ) );
			if (b) {
				nWhere = b->line;
				newline->next = b->batline;
				newline->prev = b->batline->prev;
				b->batline->prev = newline;
				if (newline->prev) {
					newline->prev->next = newline;
				}
				else {
					b->batline = newline;
				} // New root
			} // Insert before
			else {

				DSPTEXT *pt, *ptPrev;
				int nStartup, nWhere2;
				char szFname[ _MAX_FNAME ], szStartupName[ _MAX_FNAME ];

				// Try to find StartupBat (which should have gotten forced
				// into memory).  Note that BATPROC.UMB may come before
				// us, as may other batch files containing marked lines.
				_splitpath( StartupBat, NULL, NULL, szStartupName, NULL );
				for (nStartup = BATFILES;
					 nStartup < MAXFILES && ActiveFiles[ nStartup ];
					 nStartup++) {

					// Ignore the extension
					_splitpath( ActiveFiles[ nStartup ], NULL, NULL, szFname, NULL );
					if (!_stricmp( szFname, szStartupName )) break;

				} // For all possible batch files

				// Fall back to a sensible default
				if (nStartup >= MAXFILES) nStartup = BATFILES;

				// Walk along ->batline->next until we find
				// the actual end of AUTOEXEC (whatever the
				// first batch file is called).
				// Note that we must ignore lines not visible due to gotos
				// (somewhat nitpicking, as the end of the file should always
				// be visible unless there's a missing label or a non-returning
				// batch file).  We must also not only ignore but fail to
				// count lines slated for deletion.
				// If for some reason there are no visible lines, move on
				// to the next batch file.
				// Note that the above code (finding the startup batch
				// file) does _not_ duplicate what we do here w.r.t. skipping
				// bogeys like BATPROC.UMB.  We want to add our line to the
				// last possible place in the startup batch file, not in
				// some batch file called from it.
				nWhere2 = -1;
				while (nStartup < MAXFILES && ActiveFiles[ nStartup ]) {

				  nWhere = 0;
				  for (pt = HbatStrt[ nStartup ];
					   pt;
					   pt = pt->next) {

					if (pt->deleted) continue;
					nWhere++;
					if (!pt->visible) continue;
					ptPrev = pt;
					nWhere2 = nWhere;

				  } // Count lines

				  if (ptPrev) break;
				  nStartup++;

				} // Not end of file list

				// Add ourselves after ptPrev if it's the end, before
				// if not (as ptPrev is probably a bad goto or one way
				// batch call).
				nWhere = nWhere2;
				if (ptPrev && ptPrev->next) {
					newline->prev = ptPrev->prev;
					if (newline->prev) newline->prev->next = newline;
					// Note that we'll get re-rooted below if needed
					newline->next = ptPrev;
					ptPrev->prev = newline;
					// We're getting added one line earlier than normal
					nWhere--;
				} // Adding before ptPrev
				else {
					newline->prev = ptPrev;
					if (ptPrev) ptPrev->next = newline;
					// else ??? we're in deep do-do
					newline->next = NULL;
				} // Add after ptPrev at EOF

			} // Add to end

			// Now insert line that will start Windows
			// c:\386max\winmaxim /summary
			sprintf( temp, "%swinmaxim /summary", LoadString );
			newline->text = str_mem( temp );

			// Now figure out which file it's in
			temp[ 0 ] = '\0';

			for (nFile = BATFILES; ActiveFiles[ nFile ] && !temp[ 0 ];
							nFile++) {

				DSPTEXT *pt;

				// If we inserted our line at the start of a file,
				// we have to re-root ourselves in the HbatStrt list.
				if ((pt = HbatStrt[ nFile ]) && (pt = pt->prev) &&
					pt == newline) {
					HbatStrt[ nFile ] = pt;
				} // Re-root it

				for (pt = HbatStrt[ nFile ]; pt; pt = pt->next) {
					if (pt == newline) {
						strcpy( temp, ActiveFiles[ nFile ] );
						break;
					} // got a match
				} // for all starting lines

			} // for all batch files

			_strlwr( temp );
			pszExt = strstr( temp, ".áat" );
			if (pszExt) {
				pszExt[ 1 ] = 'b';
			} // Kluge: substitute real name

			// Write line number and batch file name to RemoveLine
			// in [Summary] section of Maximize.ini
			fprintf( pfSumm, "RemoveLine=%d,%s\n", nWhere + 1, temp );

			// For further laughs, if MultiConfig is active, we need
			// to insert 4 lines at the start of CONFIG.SYS:
			// [menu]
			// MenuItem=thissect
			// MenuDefault=thissect,0
			// [common]
			// and have WinMaxim remove 'em
			if (MultiBoot && nWhere >= 0) {

				DSPTEXT *ptRoot = get_mem( sizeof( DSPTEXT ) ), *ptNew;

				// Root in HbatStrt.   Note this will screw all the
				// line numbering, but that should only apply to MAXIMIZE.OUT
				// and we don't really care at this point in Phase 3 anyway.
				ptRoot->next = HbatStrt[ CONFIG ];
				HbatStrt[ CONFIG ] = ptRoot;
				//if (ptRoot->next) {
				//	ptRoot->next->prev = ptRoot;
				//} // Set backward link
				ptRoot->text = "[menu]";

				sprintf( temp, "MenuItem=%s\nMenuDefault=%s,0\n[common]",
					MultiBoot, MultiBoot );
				ptNew = get_mem( sizeof( DSPTEXT ) );
				ptNew->text = str_mem( temp );

				ptNew->prev = ptRoot;
				ptNew->next = ptRoot->next;
				ptRoot->next = ptNew;
				if (ptNew->next) {
					ptNew->next->prev = ptNew;
				} // Set back link

				fprintf( pfSumm, "RemoveMenu=4,%s\n", ActiveFiles[ CONFIG ] );

			} // Add to CONFIG.SYS

			fprintf( pfSumm, "; End of Maximize summary\n" );
			fclose( pfSumm );

		} // Opened INI file successfully

} // InsertStartup()

static TEXTWIN CompleteWin;

static void fillit(WINDESC *win,WORD *line);

#define MINHIGH 12	/* Min rows in high DOS section */

void do_compsub(int highonly,
		WINDESC *pwin,
		SUMFIT *psumfit,
		FILE *pfSumm
)
/* Subroutine to do_complete () */
{
	SUMFIT far *psum;
#ifdef HARPO
	SUBFIT far *psub;
#endif
	char temp[80];
	DWORD size;
	int nWSEntry = 0;

	if (!pfSumm && !highonly) {
		strcpy(temp,"ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿");
		pwin->ncols = strlen(temp);
		vWinPut_sca(&CompleteWin,pwin,temp,DataColor);
		pwin->row++;
	} /* Loading low */

	for (psum = psumfit; psum->lseg != 0; psum++) {
		LSEGFIT far *plseg;

		if (highonly) {
			if (!psum->preg) continue;
		}
		else {
			/* Filter out programs loaded high, or with RPARA=0 */
			/* (older 386LOAD), or non-resident */
			if (psum->preg || !(psum->rpara) || psum->flag.xres) continue;
		}

		/* Only add paragraph for MAC entry if low AND driver */
		size = (DWORD)(psum->rpara + MACSIZE(psum)) * 16;

		if (!psum->flag.umb && !(psum->flag.drv) && highonly) {
			/* If not a device driver or UMB, count environment. */
			size += (DWORD)(psum->epar1 ) * 16;
		}

		/* Get pointer to LSEG */
		plseg = FAR_PTR(psum->lseg,0);

		if (pfSumm) {
			fprintf( pfSumm, "%sseg%d=%lu,%-12.12Fs\n", highonly ? "Hi" : "Lo",
									nWSEntry, size, plseg->name );
			nWSEntry++;
		} // Write to summary file for Windows
		else {

			sprintf(temp,"³%-12.12Fs %7s³",
				plseg->name,
				ltoe (size, 0));

			pwin->ncols = strlen(temp);
			vWinPut_sca(&CompleteWin,pwin,temp,DataColor);
			pwin->row++;

		} // Not summarizing in Windows
	}
#ifdef HARPO
	for (psub = psubsegs; psub && psub->lseg; psub++) {

		if ((highonly && !psub->newreg) ||
			(!highonly && psub->newreg))	continue;

		size = (DWORD) (psub->rpara + highonly) * 16;

		if (pfSumm) {
			fprintf( pfSumm, "%sseg%d=%lu,%-12.12Fs\n", highonly ? "Hi" : "Lo",
									nWSEntry, size, (subsid( psub ))->idtext );
			nWSEntry++;
		} // Write to summary file for Windows
		else {

			sprintf(temp,"³%-12.12Fs %7s³",
				(subsid (psub))->idtext,
				ltoe (size, 0));

			pwin->ncols = strlen(temp);
			vWinPut_sca(&CompleteWin,pwin,temp,DataColor);
			pwin->row++;

		} // Not summarizing in Windows

	}
#endif
	if (!pfSumm) {

		strcpy(temp,"ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ");
		pwin->ncols = strlen(temp);
		vWinPut_sca(&CompleteWin,pwin,temp,DataColor);

	} // Not summarizing in Windows

} /* End do_compsub () */

/***************************** DO_COMPLETE *******************************/
void do_complete(SUMFIT far *psumfit)
{
	int nc;
	int nrows;
	int nlow;
	int nhigh;
	WINDESC win;
	HELPTEXT htext;
	SUMFIT far *psum;
#ifdef HARPO
	SUBFIT far *psub;
#endif
	WINDESC OurWin;
	WINRETURN winError = WIN_OK;
	char temp[ _MAX_PATH ];
	FILE *pfSumm = NULL;
	char *pszSumm;
	int SummFromWindows = FromWindows;

	if (FromWindows) {

		// Get a temporary file we can write everything to
		// It must be in the same directory so we can rename it
		// when we're done.
		sprintf( temp, "%s%%MXIN!!.###", LoadString );
		pszSumm = str_mem( temp );

		if (!pszSumm) {
			SummFromWindows = FALSE; // Revert to DOS summary
		} // Couldn't get name
		else {
			sprintf( temp, "%sMAXIMIZE.INI", LoadString );
			if (CopyIniXSect( pszSumm, temp, "[summary]\n" ) < 0 ||
				(pfSumm = fopen( pszSumm, "at" )) == NULL) {
				_unlink( pszSumm );
				free( pszSumm );
				SummFromWindows = FALSE;
			} // Copy failed
		} // Copy INI file except previous summary

	}

	/* Count up the rows */
	nlow = nhigh = 0;
	for (psum = psumfit; psum->lseg != 0; psum++) {
		if (psum->preg) nhigh++;
		else
		 if (psum->rpara && !psum->flag.xres) nlow++;
	}

#ifdef HARPO
	/* Count up any subsegments */
	if (psub = psubsegs) {
		for ( ; psub->lseg != 0; psub++) {
			if (psub->newreg)	nhigh++;
			else			nlow++;
		} /* for (all subsegments) */
	} /* Subsegments exist */
#endif

	if (SummFromWindows) {

		int n;

		fprintf( pfSumm, "[Summary]\n"
						 "; This summary written by MAXIMIZE.EXE\n"
						 "NHigh=%d\n"
						 "NLow=%d\n"
						 "HighParas=%lu\n"
						 "LowParas=%lu\n"
						 "NHighRegs=%u\n",
						 	nhigh, nlow,
							(DWORD)BESTSIZE,
							(DWORD)LowParas,
							(WORD)nHighRegions );

		for (n = 0; n < nHighRegions; n++) {
			fprintf( pfSumm, "Reg%u=%u\n", n, waHighRegions[ n ] );
		} // Dump all region sizes

	} // Record total high and low

	nrows = 4 + 1 + nhigh + 1;
	if (nrows < MINHIGH) nrows = MINHIGH;

	if (nlow) {
		nrows += 3 + 1 + nlow + 1;
	}

	OurWin = DataWin;
	if (nrows < OurWin.nrows) nrows = OurWin.nrows;

	if (!SummFromWindows) {

		/* Create the window */
		winError = vWin_create( /*	Create a text window */
			&CompleteWin,		/*	Pointer to text window */
			&OurWin,		/* Window descriptor */
			nrows,			/*	How many rows in the window*/
			OurWin.ncols,		/*	How wide is the window */
			DataColor,		/*	Default Attribute */
			SHADOW_NONE,		/*	Should this have a shadow */
			BORDER_NONE,		/*	Single line border */
			TRUE,			/*	Scroll bars */
			FALSE,
			TRUE,		/*	Should we remember what was below */
			FALSE );		/*	Is this window delayed */

		if (winError != WIN_OK) return;

		loadText(&htext,
		 	HelpInfo[HELP_COMPSCRN].type,
		 	HelpInfo[HELP_COMPSCRN].context);
		showText(&htext,&(CompleteWin.win),HdataColors,fillit);

		/* Stuff moved high */
		sprintf(temp,MsgMovingHigh,ltoe (((DWORD) BESTSIZE) << 4, 0));

		win.col = 0;
		win.row = 1;
		win.nrows = 1;
		win.ncols = CompleteWin.win.ncols;

		nc = strlen(temp);
		win.col += (win.ncols - nc) / 2;
		win.ncols = nc;
		vWinPut_sca(&CompleteWin,&win,temp,DataYellowColor);

		win.col = CompleteWin.win.col;
		win.row += 4;

	} // Not summarizing in Windows

	do_compsub( TRUE, &win, psumfit, pfSumm );

	/* Stuff left low */

	if (nlow < 1) goto nolow;

	if (win.row < MINHIGH-1) win.row = MINHIGH-1;

	if (!SummFromWindows) {

		sprintf(temp,MsgLeftLow,ltoe (((DWORD) LowParas) << 4, 0));

		win.row += 2;
		nc = strlen(temp);
		win.col = (OurWin.ncols - nc) / 2;
		win.ncols = nc;
		vWinPut_sca(&CompleteWin,&win,temp,DataYellowColor);

		win.col = CompleteWin.win.col;
		win.row += 2;

	} // Not summarizing in Windows

	do_compsub( FALSE, &win, psumfit, pfSumm );

nolow:
	if (!SummFromWindows) {

		win.ncols = 0;
			while (win.row < OurWin.nrows) {
		  	vWinPut_sca(&CompleteWin,&win,"",DataColor);
		  	win.row++;
		}

		addButton( OkButtons, sizeof(OkButtons)/sizeof(OkButtons[0]), NULL );
		showAllButtons();

	} // Not summarizing in Windows

	while (!SummFromWindows) {
		/*	Let user run around -  Automatically turns window paints on */
		switch( vWin_ask(&CompleteWin,NULL)) {
		case WIN_BUTTON:
			pushButton( LastButton.number );
			switch( LastButton.key ) {
			case KEY_F1:
				showHelp( HELP_COMPLETE, FALSE	);
				break;
			case KEY_F2:
				/*doPrint( &textWin, P_MENU, infoNum, helpNum, FALSE );*/
				break;
			case KEY_ENTER:
				goto bottom;
			case KEY_ESCAPE:
				chkabort();
			} // switch (key)
		} // switch (vWin_ask())
	} // while (1) if not from Windows

bottom:
	if (SummFromWindows) {

		fclose( pfSumm );
		sprintf( temp, "%sMAXIMIZE.INI", LoadString );
		if (!_unlink( temp )) {
			rename( pszSumm, temp );
		} // Able to delete MAXIMIZE.INI
		else {
			SummFromWindows = FALSE;
		} // Failed to unlink / rename

		free( pszSumm );

		if (SummFromWindows) {
			InsertStartup( temp );
		} // Success so far

	} // From Windows

	vWin_destroy(&CompleteWin);

	dropButton( OkButtons, sizeof(OkButtons)/sizeof(OkButtons[0]) );

}

static void fillit(WINDESC *win,WORD *line)
{
	vWinPut_ca(&CompleteWin,win,(char *)line);
}

/******************************** DO_EMSHELP *******************************/

KEYCODE do_emshelp()
{
	KEYCODE key;
	DIALOGPARM parm;

	parm = NormalDialog;
	parm.width = LARGE_DIALOG;
	parm.pButton = EmsHelpButtons;
	parm.nButtons = sizeof(EmsHelpButtons)/sizeof(EmsHelpButtons[0]);

	key = dialog(&parm,
		TitleAction,
		MsgEmsHelp,
		0,
		NULL,
		0);

	if (key == KEY_ESCAPE)
		AbyUser = AnyError = 1;

	return key;
} /* End DO_EMSHELP */


/**************************** ASK_PROBE ***************************************/
/* Returns 1 if user answered Y to PROBE question, 0 otherwise. */
int ask_probe (void)
{
	// If running from Windows, get the value from MAXIMIZE.INI
	if (FromWindows) {

		return GetProfileInt( "Defaults", "ROMSrch", 0, NULL );

	} // Read from MAXIMIZE.INI
	else {

		KEYCODE key;
		DIALOGPARM parm;

		parm = NormalDialog;
		parm.pButton = YesNoButtons;

		if (QuickMax > 0) {	/* Quick Maximize */
			/* Yes is button 0, No is button 1 (defined in libtext.h) */
			parm.pButton [0].defButton = FALSE;	/* Change from "Yes" */
			parm.pButton [1].defButton = TRUE;	/* Default to "No" */
		} /* Make No the default button */

		parm.nButtons = sizeof(YesNoButtons)/sizeof(YesNoButtons[0]);
		key = dialog(&parm,
			TitleAction,
			MsgProbe,
			HELP_PROBE,
			NULL,
			0);

		if ( key == RESP_YES ) return TRUE;
		else		  return FALSE;

	} // Ask the user

} /* End ask_probe () */

/**************************** ASK_VGASWAP *************************************/
/* Returns 1 if user answered Y to VGASWAP question, 0 otherwise. */
int ask_vgaswap (void)
{
	if (FromWindows) {

		return GetProfileInt( "Defaults", "VGASwap", 0, NULL );

	} // Get switch from MAXIMIZE.INI
	else {

		KEYCODE key;
		DIALOGPARM parm;

		parm = NormalDialog;
		parm.pButton = YesNoButtons;
		parm.nButtons = sizeof(YesNoButtons)/sizeof(YesNoButtons[0]);
		key = dialog(&parm,
			TitleAction,
			MsgVGASwap,
			HELP_VGASWAP,
			NULL,
			0);

		if ( key == RESP_YES ) return TRUE;
		else		  return FALSE;

	} // Ask the user

} /* End ask_vgaswap () */


/********************************* REBOOTMSG *******************************
 * Display message prior to rebooting as the REBOOT function
 * intentionally delays for about six seconds to allow time
 * for a disk cache using delayed writes to flush.
 * This is a separate function because main() also calls it.
 */

void rebootmsg (void)
{
	/* Rebooting the system will take a moment */
	do_intmsg(MsgRebootM);
} /* End REBOOTMSG */

/*-------------------------------------------------------------*/
/*  Function to find BATPROC				       */
/*-------------------------------------------------------------*/

void dofndbat (char *buff)
{
	strcpy (buff, LoadString);
	strcat (buff, BATPROC);
	if (_access (buff, 0) != 0) {
		*buff = '\0';
		do_error (MsgBatNf,TRUE);
	}
}

/****************************** DO_BOOTMSG **********************************/

KEYCODE do_bootmsg (char *text)
{
	KEYCODE key;

	intmsg_indent(0);	/* No indent */
	do_intmsg(text);
	if (!NopauseMax)
	 do_intmsg(MsgPressEnter);
	intmsg_indent(-1);	/* Default indent */

	addButton( OkButtons, sizeof(OkButtons)/sizeof(OkButtons[0]), NULL );
	showAllButtons();

	key = dialog_input(HELP_REBOOT,NULL);

	disableButton( KEY_ENTER, TRUE );

	return key;
} /* End DO_BOOTMSG */

/****************************** DO_TEXTARG *******************************/
void do_textarg(int num,char *arg)
{
	if (num > 0) {
		MaximizeArgTo[num-1] = arg;
	}
}

/************************** ISTDWIND *************************************/

void istdwind(void)	/* Set up the main (background) window */
{
	init_input(NULL);

	hide_cursor();
	set_cursor( thin_cursor() );

	dialog_callback(KEY_ESCAPE,chkabort);
}

/************************** PAINTBACK *************************************/

void paintback(void)	/* Set up the main (background) window */
{
	paintBackgroundScreen();
	do_prodname();
}


/************************** CSTDWIND *************************************/

void cstdwind(void)		/* Reset the main (background) window */
{
	 end_input();
	 show_cursor();
	 set_cursor(thin_cursor());
	 clearscreen ();
	 done2324();
}

/****************************** DO_PRODNAME *************************************/
void	 do_prodname ( void )
{
	WINDESC win;
	char temp[40];

	sprintf(temp,MsgMaximizing,Pass);
	SETWINDOW(&win,0,0,1,0);
	win.ncols = strlen(temp);
	wput_csa( &win, temp, PressAnyKeyColor );
	halfShadow( &win );

	SETWINDOW(&win,0,0,1,0);
	win.ncols = strlen(Prodname);
	win.col = ScreenSize.col - win.ncols;
	wput_csa( &win, Prodname, DataColor );
	halfShadow( &win );
}

/****************************** CLEARSCREEN ***********************************/
void	 clearscreen ( void )
{
	WINDESC win;

	SETWINDOW(&win,0,0,ScreenSize.row,ScreenSize.col);

	wput_sca(&win,0x0720);
	move_cursor(0,0);
} /* End clearscreen */

void do_error ( 	/* Process error windows */
	char *text,		/* Error message text */
	BOOL abort)		/* Abort indicator:  FALSE = return to caller */
				/*		     TRUE  = exit at end */
{
	disableButton(KEY_ESCAPE,TRUE);
	dialog(&ErrorDialog,
		TitleError,
		text,
		0,
		NULL,
		0);
	disableButton(KEY_ESCAPE,FALSE);

	if (abort) {
		abortprep(1);
	}
}

/*********************************** DO_WARNING *******************************/
void do_warning ( char *text, int helpnum )
{
	disableButton(KEY_ESCAPE,TRUE);
	dialog(&ErrorDialog,
		TitleError,
		text,
		helpnum,
		NULL,
		0);
	disableButton(KEY_ESCAPE,FALSE);
} /* End do_warning */

/*********************************** DO_MISTAKE *******************************/
int do_mistake ( char *msg, int helpnum )
{
	KEYCODE key;

	key = dialog(&WarningDialog,
		TitleWarning,
		msg,
		helpnum,
		NULL,
		0);
	if (toupper(key) == RESP_YES ) return TRUE;
	return FALSE;
} /* End do_mistake */

/********************************* DO_ABREBOOT *****************************/
/* ABIOS error occurred.  Ask the user if they want to reboot. */
/* We don't need to do anything special to reboot, since 1) MAX is */
/* present and 2) we haven't changed any files yet.  We will make */
/* sure LASTPHAS is erased, however. */
void do_abreboot (void)
{
	KEYCODE key;
	char MaximizePath[_MAX_PATH];

	sprintf (MaximizePath, "%sMaximize", LoadString);
	do_textarg (1, MaximizePath);

	key = dialog(&WarningDialog,
		TitleWarning,
		MsgABIOSErr,
		HELP_ABIOSERR,
		NULL,
		0);

	if ( key == RESP_YES ) { /* User asked us to reboot */
		(void) _unlink (ActiveFiles[LASTPHASE]);
		/* Rebooting the system will take a moment... */
		rebootmsg();
		reboot(); /* We don't come back */
	}

} /* End do_abreboot() */

/* Ask user about BackupMax and BackupMin values. */
/* If they cancel, we'll ask again some other day. */
/* Valid max î { 1...999, -1}, min î { empty, 0...999} */
KEYCODE ask_backup (int seedmax)
{
  KEYCODE key;
  DIALOGPARM parm;
  char temp1[14], temp2[14];

	parm = NormalDialog;
	parm.width = LARGE_DIALOG;

	parm.pButton = BackupButtons;
	parm.nButtons = NUMBACKUPBUTTONS;

	BackupEdit[0].editText = temp1;
	BackupEdit[1].editText = temp2;

	BackupMax = seedmax;

	dialog_callback(0,NULL);
	saveButtons();	/* ..so that we can override the line 25 Esc button */

	do {

	  sprintf (temp1, "%3d", BackupMax);
	  sprintf (temp2, "%3d", BackupMin);

	  key = dialog(&parm,
		TitleAction,
		MsgDelBackup,
		HELP_DELBACKUP,
		BackupEdit,
		2);

	  BackupMax = atoi (temp1);
	  BackupMin = atoi (temp2);

	  if (key == KEY_ESCAPE || (/* BackupMax >= 1 && */ BackupMax <= 999 &&
				    BackupMin >= 0 && BackupMin <= 999 &&
				    BackupMin < BackupMax)) break;

	  do_warning (MsgInvBack, 0);

	} while (1);

	restoreButtons();
	dialog_callback(KEY_ESCAPE,chkabort);

	return (key);

} /* ask_backup () */

/* Copy .INI file exclusive of specified section.  This allows us
 * to simply append the section, effectively replacing it.
 *
 * Returns 0 if successful, -1 if error occurred.
**/
int
CopyIniXSect( char *pszDestPath, char *pszSourcePath, char *pszExclude ) {

	FILE *pfDest, *pfSource;
	int nRes = -1, nInSect;
#define MAXINIBUFF	256
	char szBuff[ MAXINIBUFF + 1 ];

	disable23();

	if ((pfSource = fopen( pszSourcePath, "r" )) == NULL) {
		enable23();
		return -1;
	}
	if ((pfDest = fopen( pszDestPath, "w" )) == NULL) {
		fclose( pfSource );
		enable23();
		return -1;
	}

	nInSect = 0; // 1 if we're skipping this section
	while (fgets( szBuff, MAXINIBUFF, pfSource )) {

		// Make sure it's null-terminated
		szBuff[ MAXINIBUFF ] = '\0';

		// Check for a section name
		if (szBuff[ 0 ] == '[') {

			if (!_stricmp( pszExclude, szBuff )) {
				nInSect = 1;
			} // Found section we're skipping
			else {
				nInSect = 0;
			} // Found start of another section

		} // Got a section name

		if (nInSect) continue;

		fputs( szBuff, pfDest );

	} // Not EOF

	nRes = 0;

CopyIniXSect_Exit:
	fclose( pfDest );
	fclose( pfSource );

	enable23();

	return nRes;

} // CopyIniXSect()

