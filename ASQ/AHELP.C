/*' $Header:   P:/PVCS/MAX/ASQ/AHELP.C_V   1.1   01 Feb 1996 10:20:32   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * AHELP.C								      *
 *									      *
 * Routines for ASQ hypertext help					      *
 *									      *
 ******************************************************************************/

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <help.h>

#include "asqtext.h"
#include "cputext.h"
#include "engine.h"
#include "inthelp.h"
#include "libcolor.h"
#include "qhelp.h"
#include "surface.h"
#include "myalloc.h"

static char tuningBuf[64];

static int AsqArgCnt;		/* Help arg count */
static char *AsqArgFrom[16];	/* Help arg from string */
static char *AsqArgTo[16];	/* Help arg to string */

WINRETURN loadMultHelp(
		PTEXTWIN fWin,		/*	Pointer to text window */
		WINDESC *win,		/* Window descriptor */
		char attr,			/*	Default Attribute */
		SHADOWTYPE shadow,	/*	Should this have a shadow */
		BORDERTYPE border,	/*	Single line border */
		int vScroll,		/*	Vertical Scroll bars */
		int hScroll,		/*	Horizontal scroll bars */
		int remember);		/*	Should we remember what was below */


int setupRecommend( int buildWindow)
{
	ENGREPORT rept;

	engine_control( CTRL_REPORT,&rept, 0);

	HelpTopicCnt = 0;

	HelpArgNum[HelpTopicCnt++] = LEARN_ABOUTQ;

	switch (rept.maxflag) {
	case MAX_BLUE:	/* Is an MCA, could run Blue Max */
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUTMAX;
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUT386;
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUTMOV;
		break;
	case MAX_MOVE:	/* Is a NEAT or LIM 4, could run Move'em */
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUTMAX;
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUT386;
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUTMOV;
		break;
	case MAX_386:	/* Is a 386, could run 386max */
	default:
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUT386;
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUTMAX;
		HelpArgNum[HelpTopicCnt++] = LEARN_ABOUTMOV;
		break;
	}

	AsqArgFrom[0] = "#PROC#";
	AsqArgTo[0] = cpu_textof( &rept.cpu );

	AsqArgFrom[1] = "#RECPROD#";

	switch (rept.maxflag) {
	case MAX_BLUE:	/* Is an MCA, could run Blue Max */
		AsqArgTo[1] = "BlueMAX";
		break;
	case MAX_MOVE:	/* Is a NEAT or LIM 4, could run Move'em */
		AsqArgTo[1] = "MOVE'EM";
		break;
	case MAX_386:	/* Is a 386, could run 386max */
	default:
		AsqArgTo[1] = "386MAX";
		break;
	}

	AsqArgCnt = 2;
	setHelpArgs(AsqArgCnt,AsqArgFrom,AsqArgTo);

	if( buildWindow ) {
		return loadMultHelp( &HelpTextWin,
					  &HelpWinDesc,
					  HelpColors[0],
					  SHADOW_SINGLE,
					  BORDER_BLANK,
					  TRUE,FALSE,
					  FALSE );
	}
	return AsqArgCnt;
}



int setupTuning( int buildWindow )
{
	ENGREPORT rept;
	char *buf = tuningBuf;

	engine_control( CTRL_REPORT,&rept, 0);

	HelpTopicCnt = 0;

	HelpArgNum[HelpTopicCnt++] = LEARN_TUNEINTRO;

	HelpArgNum[HelpTopicCnt++] = LEARN_TUNEMEM;

	if( rept.dosver < 0x31e )	/*	Version lt 3.30 */
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEVERS;

	if( rept.files < 20 )
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEFILLOW;
	else if( rept.files > 30 )
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEFILHI;
	else
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEFILMED;

	if( rept.buffers < 10 || rept.buffers > 20 )
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEBUFF;

	if( rept.fcbx > 4 || rept.fcby != 0 )
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEFCB;

	if( (rept.envsize - ( rept.envsize / 10 )) >= rept.envused )
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEENV;

	if( rept.cpu.cpu_type >= CPU_V30 ||
	    rept.stackx != 0 || rept.stacky != 0 )
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNESTA;

	if( rept.fastopen )
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEFAS;

	if( rept.print )
		HelpArgNum[HelpTopicCnt++] = LEARN_TUNEPRI;

	sprintf(buf,"%d.%02d", ( rept.dosver & 0xFF00)>> 8, rept.dosver & 0xFF );
	AsqArgFrom[0] = "#DOSVER#";
	AsqArgTo[0] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",rept.files);
	AsqArgFrom[1] = "#FILES#";
	AsqArgTo[1] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",rept.buffers);
	AsqArgFrom[2] = "#B#";
	AsqArgTo[2] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",rept.fcbx);
	AsqArgFrom[3] = "#FX#";
	AsqArgTo[3] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",rept.fcby);
	AsqArgFrom[4] = "#FY#";
	AsqArgTo[4] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",rept.envsize);
	AsqArgFrom[5] = "#ES#";
	AsqArgTo[5] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",rept.envused);
	AsqArgFrom[6] = "#EU#";
	AsqArgTo[6] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",rept.stackx);
	AsqArgFrom[7] = "#SX#";
	AsqArgTo[7] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",rept.stacky);
	AsqArgFrom[8] = "#SY#";
	AsqArgTo[8] = buf;
	buf += strlen(buf)+1;

	sprintf(buf,"%d",(int)((rept.ddbytes+rept.tsrbytes)/1024));
	AsqArgFrom[9] = "#TSR#";
	AsqArgTo[9] = buf;
	buf += strlen(buf)+1;

	AsqArgCnt = 10;
	setHelpArgs(AsqArgCnt,AsqArgFrom,AsqArgTo);

	if( buildWindow ) {
		return loadMultHelp( &HelpTextWin,
					  &HelpWinDesc,
					  HelpColors[0],
					  SHADOW_SINGLE,
					  BORDER_BLANK,
					  TRUE,FALSE,
					  FALSE );
	}
	return AsqArgCnt;
}


/**
*
* Name		loadMultHelp - Concatenate multiple help contexts and spray into a created window
*
* Synopsis
* Parameters
*
* Description
*		Do some stuff, do some more stuff, and return
*
* Returns	No return
*
* Version	1.0
*/
#pragma optimize("leg",off)
WINRETURN loadMultHelp(
		PTEXTWIN fWin,		/*	Pointer to text window */
		WINDESC *win,		/* Window descriptor */
		char attr,			/*	Default Attribute */
		SHADOWTYPE shadow,	/*	Should this have a shadow */
		BORDERTYPE border,	/*	Single line border */
		int vScroll,		/*	Vertical Scroll bars */
		int hScroll,		/*	Horizontal scroll bars */
		int remember)		/*	Should we remember what was below */
{
	char fullContext[80];
	char line[MAXLINE];
	WORD line2[MAXLINE];
	WORD *bufp;
	int kk;
	int nRows;
	int totalRows;
	int nChars;
	WORD nLeft;
	nc thisNc;
	WINDESC workWin;
	WINRETURN winError = WIN_OK;

	compBuffer = NULL;
	decompBuffer = NULL;
	PrintableHelp = FALSE;

	memset( &HelpHotSpot, 0, sizeof( HelpHotSpot ));

	totalRows = 0;
	bufp = (WORD *)tutorWorkSpace;
	nLeft = WORKSPACESIZE;
	for (kk=0; kk < HelpTopicCnt; kk++) {
		int HelpArgNumber = HelpArgNum[kk];
		HELPTYPE hType = HelpInfo[HelpArgNumber].type;


		thisNc = HelpInfo[HelpArgNumber].contextNumber;

		/*	Got a context - Now get the compressed size */
		compSize = HelpNcCb( thisNc );

		compBuffer = my_fmalloc( compSize );
		if( !compBuffer ) {
			winError = WIN_NOMEMORY;
			goto done;
		}

		decompSize = HelpLook( thisNc, compBuffer );
		decompBuffer = my_fmalloc( decompSize );
		if( !decompBuffer ) {
			winError = WIN_NOMEMORY;
			goto done;
		}
		HelpDecomp( compBuffer, decompBuffer, thisNc );

		/*	Save this off so help can push it on the visit stack */
		nRows = HelpcLines( decompBuffer );
		totalRows += nRows;

		if( HelpGetLine( 1, MAXLINE-1, line, decompBuffer ) > 1 ) {
			/*	Check to see if the line is the control line */
			if( line[0] == CONTEXTTRIGGER ) {
				char *next;
				nRows--;
				/*	Get the start and stop contexts
				*			  012...   n12
				*	Format is @P H.start H.stop
				*	P indicates that it is printable
				*/
				PrintableHelp = toupper(line[1]) == 'P';
				if (kk == 0) {
					next = strchr( line+CONTEXTOFFSET, ' ' );
					if( next ) {
						*(next++) = '\0';
						strcpy( fullContext, HelpTitles[hType].name );
						strcat( fullContext, line+CONTEXTOFFSET );
						prevStop = HelpNc( fullContext, HelpTitles[hType].context );
						strcpy( fullContext, HelpTitles[hType].name );
						strcat( fullContext, next );
						nextStop = HelpNc( fullContext, HelpTitles[hType].context );
					} else
						prevStop = nextStop = 0;	/*	No next and previous */
				}
			}
		}

		for(nRows=1;;nRows++) {
			nChars = HelpGetCells( nRows, MAXLINE-1, line,
						decompBuffer, HelpColors);

			if( nChars == -1 || (WORD)(nChars+2) > nLeft )
				break;

			/*	Line is now full of a text line that has attributes  attached
			 *		Copy them into the scratch buffer
			 */
			*bufp++ = (WORD)(nChars/2);
			nLeft -= 2;
			if( nChars > 1 ) {
				/*	Skip the context trigger line */
				if( line[0] == CONTEXTTRIGGER ) {
					bufp--;
					nLeft += 2;
					totalRows--;
					continue;
				}

				if (HelpArgCnt > 0) {
					help_argsubs(line2,(WORD *)line,nChars/2);
					memcpy(bufp,line2,nChars);
				}
				else {
					memcpy(bufp,line,nChars);
				}
				bufp += nChars/2;
				nLeft--;
			}
		}
		my_free( compBuffer );
		compBuffer = NULL;
		my_free( decompBuffer );
		decompBuffer = NULL;
	}

	workWin = *win;
	winError = vWin_create( /*	Create a text window */
		fWin,			/*	Pointer to text window */
		win,			/* Window descriptor */
		totalRows,		/*	How many rows in the window*/
		workWin.ncols-2,		/*	How wide is the window */
		attr,			/*	Default Attribute */
		shadow, 		/*	Should this have a shadow */
		border, 		/*	Single line border */
		vScroll,		/*	Scroll bars */
		hScroll,
		remember,		/*	Should we remember what was below */
		FALSE );		/*	Is this window delayed */

	workWin.row = 0;
	workWin.col = 0;
	workWin.nrows = 1;

	bufp = (WORD *)tutorWorkSpace;
	for (kk = 0; kk < totalRows; kk++) {
		int nn;

		nn = *bufp++;
		if (nn > 0) {
			workWin.ncols = nn;
			if( workWin.ncols > win->ncols )
				workWin.ncols = win->ncols;

			vWinPut_ca( fWin, &workWin,(char *)bufp);
		}
		workWin.row++;
		bufp += nn;
	}

done:
	if( compBuffer )
		my_ffree( compBuffer );
	if( decompBuffer ) {
		my_ffree( decompBuffer );
	}

	/*	No hotspots here!!!!! */
	lastHelpTopic = NULL;
	if( winError != WIN_OK )
		errorMessage( WIN_NOTFOUND );
	return winError;
}
#pragma optimize("",on)
