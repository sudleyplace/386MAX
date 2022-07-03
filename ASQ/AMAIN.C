/*' $Header:   P:/PVCS/MAX/ASQ/AMAIN.C_V   1.1   05 Sep 1995 16:27:26   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * AMAIN.C								      *
 *									      *
 * Main program module for ASQ.EXE					      *
 *									      *
 ******************************************************************************/

/*	C function includes */
#include <ctype.h>
#include <fcntl.h>
#include <io.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <process.h>

/*	Program Includes */

#include "button.h"
#include "commfunc.h"
#include "dialog.h"
#include "engine.h"
#include "intmsg.h"
#include "libcolor.h"
#include "menu.h"
#include "message.h"
#include "mouse.h"
#include "myalloc.h"
#include "qprint.h"
#include "profile.h"
#include "qhelp.h"
#include "sysinfo.h"
#include "ui.h"

#define ASQ
#define OWNER
#include "surface.h"
#include "asqtext.h"
#include "asqshare.h"

/*	Definitions for this Module */
int fromQshell = 0;		/* non-zero if we were called from QSHELL */
int bootDrive = 0;		/* Forced boot drive from /F switch */
char *snapDescText = "";        /* Pointer to snapshot description from cmd line */
char *RecallString;		/* Program to exec at exit if not NULL */


/*	Command line options flags */
int doCmdThenExit = FALSE;	/*	Take a snapshot then exit to qshell */

int doEval(void *wksp,unsigned nwksp);
void grab_mem(char *name,int flag);
int execMaximize( int request );
int execUpdate( void );
void paintback(void);
void setOptions(int argc, char **argv);
void setColors(void);
void write_text(char *file,void *bigbuf, unsigned nbuf);
#ifdef TESTARGS
void testargs(int argc,char **argv);
#endif /*TESTARGS*/
void errmsg(char *msg);

/*
*	 Debugging definitions for heap testing looking for leaks
*/
#define TESTHEAP()
#define HEAPDUMP()
void testheap(void );
void heapdump(void);


/*	Program Code */
/**
*
* Name		Main - Core function
*
* Synopsis	int main(int argc, char *argv[])
*
* Parameters
*		int argc			Number of arguements passed
*		char *argv			pointers to the actual arguments
*
* Description
*		Call the ui function to paint the main screens up
*	This means that it will return all sorts of information about the main
*	windows
*
* Returns	0 for no errors - 1 for an error exit
*
* Version	1.0
*/
#pragma optimize ("leg",off)
int main(int argc, char *argv[])
{
	int request = 0;
	int buttonsBad = TRUE;
	int forcePaint = TRUE;

#ifdef TESTARGS
	testargs(argc,argv);
#endif /*TESTARGS*/

	/* new jhk */
	/* allocate a 1K universal reserve buffer */
	globalReserve = my_malloc(1000);

	set_exename(argv[0],"ASQ.EXE");
	setOptions(argc,argv);

	if (SnapshotOnly) {

		memset(tutorWorkSpace,'?',WORKSPACESIZE);

		/* We need to call engine_control () to initialize SysInfo */
		if (engine_control (CTRL_PREINIT, NULL, 0)) goto SNAPSHOT_ERR;

		if (sysinfo_init(tutorWorkSpace,WORKSPACESIZE) != 0) {
SNAPSHOT_ERR:
			errmsg(SnapSysinfoErr);
		}

		printf(SnapWriting, WriteFile);
		strcpy(SysInfo->snaptitle,snapDescText);

		if (sysinfo_write(WriteFile) != 0) {
			errmsg(SnapWriteErr);
		}

		/* Purge everything */
		sysinfo_purge();

		return (0);

	} /* Snapshot only */
	else {
		inst2324();
		enable23();
	} /* Not snapshot only */

	/* We do this during CTRL_PREINIT for snapshot only */
	read_profile (FALSE, FALSE, "ASQ.PRO");
	read_profile (FALSE, FALSE, "ASQ.CFG");

	initializeScreenInfo (SnowControl);
	setColors ();

	init_input(NULL);
	strcpy( PrintFile, "ASQ.PRN" );

	hide_cursor();
	set_cursor( thin_cursor() );
#if 0
	if (fromQshell != 1) {
		paintBackgroundScreen();
	}
#endif
	/*	Set default Help System */
	helpSystem = ASQHELPCONTENTS;

	/*	Initialize the help system - Die if we fail - Starthelp gives the error */
	strcpy(HelpFileName,"ASQ.HLP"); /* Override help file name */
	if( startHelp(HelpFileName,HELPLAST) )
		goto done;

	if (fromQshell != 1) {
		if (sayHello(GraphicsLogo)) goto done;
#if 0
		wput_csa( &AsqNameWin, AsqName, ProgramNameAttr );
		halfShadow( &AsqNameWin );
#endif
	}
	if (fromQshell == 2) {
		*SnapInParens = '\0';
	}

	if( doEval(tutorWorkSpace, WORKSPACESIZE) != 0 )
		goto done;
	if( doCmdThenExit )
		goto done;

	TESTHEAP();
	HEAPDUMP();

	asq();

done:
	TESTHEAP();
	HEAPDUMP();

	endHelp();
	end_input();

	if (RecallString) {
		/* Reload QSHELL */
		int count = 0;
		char *xargv[10];


		xargv[count++] = RecallString;
		if (fromQshell) {
			xargv[count] = "/Y0";
			xargv[count][2] = (char)(fromQshell + '0');
			count++;
		}

		xargv[count++] = NULL;
		if( fromQshell > 1 ) {
			SETWINDOW( &DataWin, 0,0, 2, ScreenSize.col );
			wput_sca( &DataWin, VIDWORD( BackScreenColor, BACKCHAR ));
		}
		done2324();
		execv(xargv[0],xargv);
	}

	/* new jhk */
	if (globalReserve) my_free(globalReserve);

	abortprep(0);
	return 0;
}
#pragma optimize ("",on)

/*
*	Put the fancy logo on the screen
*/
BOOL sayHello( int doit )
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
	badspawn = showLogo(doit,WhichLogo,MsgLogoText,serial,paintback);
#endif

	disable23();
	if ( doCmdThenExit ) {
		sleep(1000L);
		abort = FALSE;
	}
	else {
		abort = pressAnyKey(2500L);
	}
	enable23();

#ifndef OS2_VERSION
	if (!badspawn) showLogo(-1,WhichLogo,NULL,NULL,paintback);
#endif
	return abort;
}


void paintback(void)
{
	paintBackgroundScreen();
	wput_csa( &AsqNameWin, AsqName, ProgramNameAttr );
	halfShadow( &AsqNameWin );
}

/* Update report data */
void report_update (void)
{
#ifndef OS2_VERSION
		ENGREPORT rept;

		engine_control( CTRL_REPORT,&rept, 0);

		strcpy(ConfigName,rept.config_sys);
		strcpy(AutoexecName,rept.pszAutoexec_bat);
		if (rept.pszMax_pro)
			strcpy(MAXName,rept.pszMax_pro);
		else	MAXName[0] = '\0';
		if (rept.pszExtraDOS_pro)
			strcpy (ExtraDOSName, rept.pszExtraDOS_pro);
		else	ExtraDOSName[0] = '\0';
		if (rept.pszSYSINI)
			strcpy (SYSININame, rept.pszSYSINI);
		else	SYSININame[0] = '\0';
#endif
} /* report_update () */

/*
 *	doEval - do system evaluation
 */

int doEval(
	void *wksp,		/* Pointer to scratch buffer */
	unsigned nwksp) 	/* How many bytes in scratch buffer */
{
	int rtn;		/* Status return */

	intmsg_setup(12);

	if (*ReadFile) {
		do_intmsg( "%s\n", Loading );
	}
	else {
		do_intmsg( EvalFmt, Hardware );
	}


	if (*GrabFile) {
		/* Grab all of memory */
		char *p;

		p = strchr(GrabFile,',');
		if (p) {
			*p++ = '\0';
		}
		else	p = "";
#ifdef DOS_VERSION
		grab_mem(GrabFile,*p);
#endif
	}

	move_cursor( DataWin.row, DataWin.col );

	if (*ReadFile) {
		strcpy(wksp,ReadFile);
		rtn = engine_control(CTRL_SYSREAD,wksp,nwksp);
		if (rtn != 0) {
			errorMessage( 511 );
		}
		SnapMenu.items[SIPOS].type = ITEM_ACTIVE;
	}
	else {
		if (bootDrive) {
			engine_control(CTRL_SETBOOT,&bootDrive,0);
		}
		rtn = engine_control(CTRL_SYSINIT,wksp,nwksp);
		if (rtn != 0) {
			errorMessage( 500 );
		}
	}

	if (*WriteFile) {
		do_intmsg( EvalFmt, WriteSnap );

		if (snapDescText) {
			engine_control( CTRL_PUTTITLE, snapDescText, 0);
			my_free(snapDescText);
			snapDescText = NULL;
		}

		rtn = engine_control(CTRL_SYSWRITE,WriteFile,0);
		if (rtn != 0) {
			errorMessage( 511 );
		}
	}
	intmsg_clear();


	if (*TextFile) {
		write_text(TextFile,wksp,nwksp);
	}

	report_update ();

	return rtn;
}

/**
*
* Name		reportEval - Change to next evaluating hardware message
*
* Synopsis	void reportEval( EVALSTATE state )
*
* Parameters
*			EVALSTATE state - What to report
*
* Description
*		This routine changes the wait message by clearing out the window
*	then writing in the new text
*
*
* Returns	void
*
* Version	1.10
*
**/
void reportEval(EVALSTATE state)
{
	if (EvalText[state] && *EvalText[state]) {

	    if (SnapshotOnly) {
		printf (EvalFmt, EvalText[state]);
	    }
	    else {
		do_intmsg(EvalFmt,EvalText[state]);
	    }

	} /* We have something to print */

} /* reportEval () */


/**
*
* Name		setOptions - Process command line options
*
* Synopsis	void setOptions(int argc, char **argv)
*
* Parameters
*		argc	Argument count from main()
*		argv	Argument vector from main()
*
* Description
*		Parse command line and set variables.
*
* Returns	None
*
* Version	1.0
*/

#pragma optimize ("leg",off)
void setOptions(int argc, char **argv)
{
	int xOK = FALSE;
	int opt;
	char *pp;

	/* Mark video mode as not set */
	ScreenSet = FALSE;

	/* EOF means end of list, 0 means next token is not a switch,
	   0x8000 set means missing required argument or invalid option */
	while ((opt = arg_getopt (argc,argv, "bcd:f:g:l:ps:tvw:xy:z:")) != EOF) {

		switch (opt & 0xff) {
		case 'B':       /* B&W monitor */
			ScreenType = SCREEN_MONO;
			ScreenSet = TRUE;
			break;

		case 'C':       /* Color monitor */
			ScreenType = SCREEN_COLOR;
			ScreenSet = TRUE;
			break;

		case 'D':       /* Snapshot description */
			pp = arg_argument ();
			if (pp) {
				snapDescText = my_malloc (strlen (pp) + 1);
				if (snapDescText)
					strcpy (snapDescText, pp);

			}
			else	goto showHelp;
			break;

		case 'F':       /* Boot drive */
			pp = arg_argument ();
			if (pp && strlen (pp) == 2 && isalpha(*pp) && pp[1] == ':') {
				bootDrive = toupper(*pp);
			}
			else	goto showHelp;
			break;

		case 'G':       /* Grab memory */
			pp = arg_argument ();
			if (pp) {
				strcpy (GrabFile,pp);
			}
			else {
				strcpy( GrabFile, DefaultGrabFile );
			}
			xOK = TRUE;
			break;

		case 'L':       /* Load snapshot */
			pp = arg_argument ();
			if (pp) {
				strcpy (ReadFile, pp);
			}
			else {
				strcpy( ReadFile, DefaultSnapShot );
			}
			break;

		case 'P':       /* Snapshot-type status output only */
			SnapshotOnly = TRUE;
			break;

		case 'S':       /* Save snapshot */
			pp = arg_argument ();
			if (pp) {
				strcpy (WriteFile, pp);
			}
			else {
				strcpy( WriteFile, DefaultSnapShot );
			}
			xOK = TRUE;
			break;

		case 'T':       /* Enable snow conTrol on CGA systems */
			SnowControl = TRUE;
			break;

		case 'V':       /* Inhibit logo */
			GraphicsLogo = FALSE;
			break;

		case 'W':        /* Text output */
			pp = arg_argument ();
			if (pp) {
				strcpy (TextFile, pp);
			}
			else	goto showHelp;

			xOK = TRUE;
			break;

		case 'X':
			/* Check for Quick Exit switch */
			doCmdThenExit = TRUE;
			break;

		case 'Y':       /* We-were-called-from-QSHELL switch */
			pp = arg_argument ();
			if (pp && strlen (pp) == 1 && isdigit(*pp)) {
				fromQshell = *pp - '0';
			}
			else	goto showHelp;

			xOK = TRUE;

			if (fromQshell < 2) {
				/* /Y1 implies /X */
				doCmdThenExit = TRUE;
				xOK = TRUE;
			}
			break;

		case 'Z':       /* Recall program */
			pp = arg_argument ();
			if (pp) {
				RecallString = my_malloc(strlen (pp) + 1);
				if (RecallString) {
					strcpy (RecallString, pp);
				}
			}
			else	goto showHelp;
			break;

		default:
			/* Any switch we don't understand */
			goto showHelp;
		}
	}

	if( doCmdThenExit && !xOK ) {
		/* Specified /X without /S or /Y */
		goto showHelp;
	}

	if (SnapshotOnly && !(*WriteFile)) {
		/* Specified undocumented /P option without /S */
		SnapshotOnly = FALSE; /* Ignore it */
	}

	return;

showHelp:
	if (SnapshotOnly) {
		printf( HelpString, "SNAPSHOT", MSG_FILENAME " ",
		"   ", "SNAPSHOT");
	}
	else {
		printf( HelpString, "ASQ", "", "/S ", "ASQ");
	}
	exit(2);
}
#pragma optimize ("",on)

/**
*
* Name		setColors - Change colors for mono screen
*
* Synopsis	void setOptions(BOOL mono)
*
* Parameters
*		mono	TRUE to select monochrome color scheme
*
* Description
*		Set all of our color defintions for a monochrome or color
*		tube.  A separate routine, slamLibColor, does the same
*		thing for library code.
*
* Returns	None
*
* Version	1.0
*/

void setColors (void)
{
	SnapMenu.items[S_POS0].attr = DataContinueColor;
	LearnMenu.items[L_TPOS2].attr = DataContinueColor;
	AsqHelpMenu.items[P_POS1].attr = DataContinueColor;
}

#ifdef DOS_VERSION

/*
 *	grab_mem - grab memory image for diagnostic purposes
 */

void grab_mem(char *name,int flag)
{
	int fh;
	long para;
	long start;
	long stop;

	/* Dump all of memory to a file.  This code is intended
	 * for LARGE MODEL only. */

	switch (toupper(flag)) {
	case 'L':
		start = 0;
		stop = _psp;
		break;
	case 'H':
		start = 0xA000;
		stop = 0x10000;
		break;
	default:
		start = 0;
		stop = 0x10000;
		break;
	}

	if (!(*name)) name = DefaultGrabFile;
	close(creat(name,0644));
	fh = open(name,O_RDWR | O_BINARY);
	if (fh < 0) return;

	for (para = start; para < stop; para += 0x400) {
		char far *p;

		p = FAR_PTR(para,0);
		if (write(fh,p,0x4000) != 0x4000) break;
	}
	close(fh);
}

/*
 *	write_text - write selected data to text file
 */


INFONUM TheseNums[] = {
	INFO_MEM_SUMM,		/* Memory_Summary */
	INFO_CFG_SUMM,		/* Config_Summary */
	INFO_HW_SUMM,		/* Hardware_Summary1 */
	0
};


#define MAXENGTEXT 256

void write_text(char *file,void *bigbuf, unsigned nbuf)
{
	int kk;
	FILE *f1;


	f1 = fopen(file,"w");
	if (!f1) {
		errorMessage(201);
		return;
	}

	{
		ENGREPORT rept;

		engine_control( CTRL_REPORT,&rept, 0);
		/* MAX shell will read these, but probably will */
		/* use values it got by parsing CONFIG.SYS itself. */
		fprintf(f1,"%s\n",rept.config_sys);
		fprintf(f1,"%s\n",rept.pszAutoexec_bat);
		fprintf(f1,"%s\n",rept.pszMax_pro);
		fprintf(f1,"%s\n",rept.pszExtraDOS_pro);
		fprintf(f1,"%s\n",rept.pszSYSINI);
	}

	for (kk = 0; TheseNums[kk]; kk++) {
		ENGTEXT text;		/* Engine text struct */
		char textbuf[MAXENGTEXT]; /* Scratch buffer for text */

		if (engine_control(CTRL_SETBUF,bigbuf,nbuf) != 0) {
			fprintf(f1,"Set buffer error\n");
			return;
		}

		text.nbuf = MAXENGTEXT;
		text.buf = textbuf;

		if (engine_control(CTRL_ISETUP,&text,TheseNums[kk]) != 0) {
			fprintf(f1,"Info setup error on %d\n",TheseNums[kk]);
			return;
		}

		fprintf(f1,"! %d %d %d\n",
			TheseNums[kk],text.width,text.length);
		for (;;) {
			if (engine_control(CTRL_IFETCH,&text,0) != 0) {
				break;
			}

			textbuf[MAXENGTEXT-1] = '\0';
			fprintf(f1,"|%c%c|%s\n",textbuf[0],textbuf[1],textbuf+2);
		}

		if (engine_control(CTRL_IPURGE,&text,TheseNums[kk]) != 0) {
			fprintf(f1,"Info setup error on %d\n",TheseNums[kk]);
		}
	}
	fclose(f1);
}
#endif

/*
 *	This is a stub version of our memory handle system.
 *	We don't actually use memory handles in the DOS version(s).
 */
#if 0
#include "commdef.h"
#include "hmem.h"
#endif
HANDLE	 mem_alloc(		/* Allocate a memory handle */
	WORD nbytes,		/* How many bytes */
	int type)		/* Memory type */
{
	if (nbytes);
	if (type);
	return 0;
}

LPVOID mem_lock(		/* Lock handle, return pointer */
	HANDLE handle)		/* Memory handle */
{
	if (handle);
	return 0;
}

LPVOID mem_unlock(		/* Unlock handle */
	HANDLE handle)		/* Memory handle */
{
	if (handle);
	return 0;
}

HANDLE	 mem_realloc(		/* Allocate a memory handle */
	HANDLE handle,		/* Memory handle */
	WORD nbytes)		/* How many bytes */
{
	if (handle);
	if (nbytes);
	return 0;
}

HANDLE	 mem_clone(		/* Clone a memory handle - Return the new one */
	HANDLE handle)		/* Memory handle */
{
	if (handle);
	return 0;
}

BOOL mem_grow(			/* Grow a memory handle */
	LPHANDLE handle,	/* Memory handle */
	WORD nbytes)		/* How many bytes to grow by */
{
	if (handle);
	if (nbytes);
	return 0;
}

void   mem_free(		/* Free a memory handle */
	HANDLE handle)		/* Memory handle */
{
	if (handle);
}

void mem_setname(		/* Set name for a memory handle */
	HANDLE handle,		/* Memory handle */
	LPSTR name)		/* Name, 1 to 9 chars */
{
	if (handle);
	if (name);
}

void   mem_report(		/* Report handle table */
	int flag)		/* 0 for normal, 1 for full report */
{
	if (flag);
}


#ifdef TESTARGS
void testargs(int argc,char **argv)
{
	int iarg;
	FILE *fp;


	fp = fopen("aux","w");
	if (!fp) return;

	fprintf(fp,"argc = %d\n",argc);
	for (iarg = 0; iarg < argc; iarg++) {
		fprintf(fp,"  argv[%d] = \"%s\"\n",iarg,argv[iarg]);
	}
	fprintf(fp,"--------\n");
	fclose(fp);
}
#endif /*TESTARGS*/

/********************************* ERRMSG() *****************************/
/* Print an error message and exit to DOS.  Used only with /P option */
void errmsg (char *msg)
{
	fprintf (stderr, msg);
	exit (-1);
}

