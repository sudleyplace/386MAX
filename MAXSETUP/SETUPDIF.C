// SETUPDIF.C - File difference utility for SETUP

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#include "setup.h"
#include "messages.h"


#define MAXLINE   256		/* maximum characters in the input line */
#define EOF_REACHED	0	/* eof during resync */
#define RE_SYNCED	1	/* we managed to re-sync */
#define NO_SYNC		2	/* no sync but no eof either */

struct LINE {			/* structure defining a line internally */
	int nLineNum;		/* what line on page */
	unsigned char checksum;	/* use a checksum for quick comparison */
	struct LINE *prev;	/* pointer to previous line */
	struct LINE *link;	/* linked list pointer */
	struct LINE *same;	/* pointer to next line with checksum */
	char szText[MAXLINE];	/* text of line */
};

typedef struct LINE *pLINE;
struct LINE root[3];		/* root of internal linked list */

int command_errors = 0;		/* number of command line errors */
int fModified;
char xx1[132], xx2[132];	/* space for file names */
char *szaInfileName[3] = {NULL,xx1,xx2};
char szDiffFile[132];		/* output file name */
HFILE hInput[3];		/* input file pointers */
HFILE hOutput;			/* output file ptr */

static pLINE at[3] = {NULL, &(root[1]), &(root[2])};
static pLINE same_check [MAXLINE] [2];

int nReSync = 1;		/* lines that must match for resync */


int QueryCompare(pLINE);
int equal (pLINE, pLINE);
void position (int, pLINE);
void Checksum (pLINE);
pLINE next_line (int);
void discard (int, pLINE);
void put (pLINE);
void _added (pLINE);
void deleted (pLINE);
int resync (pLINE, pLINE, int);
void diff(void);
void open_files(void);
void strip_opt (int, char **);


int Difference (char *szTarget, char *szSource, char *szDiff)
{
	remove( szDiff );

	command_errors = 0;		/* number of command line errors */
	memset( &(root[0]), '\0', sizeof(root) );
	memset( &(same_check[0][0]), '\0', sizeof(same_check) );
	at[0] = NULL;
	at[1] = &(root[1]);
	at[2] = &(root[2]);

	lstrcpy (szaInfileName[1], szTarget);
	lstrcpy (szaInfileName[2], szSource);
	lstrcpy (szDiffFile, szDiff);

	open_files();
	if (command_errors)
		return -1;

	/* set root previous pointers to 0 */
	at[1]->prev = NULL;
	at[2]->prev = NULL;

	fModified = 0;

	diff();
	_lclose( hInput[1] );
	_lclose( hInput[2] );
	_lclose( hOutput );

	return (fModified);
}


/* tells us whether or not this line should be considered for
   comparison or is a filler (eg header, blank) line */
int QueryCompare (pLINE line)
{
	register int i;

	if (line == NULL)	/* EOF reached */
		return 0;

        for ( i = 0; (i < MAXLINE); i++) {

		switch (line->szText[i]) {
		case '\0':
		case '\n':
			return 1;
		case '\t':
		case ' ':
			break;
		default:
			return 0;
		}
	}

	return 1;
}


/* equal - tells us if the pointers 'a' and 'b' point to line buffers
   containing equivalent text or not */
int equal (pLINE a, pLINE b)
{
	if (((a == NULL) || (b == NULL)) || (a->checksum != b->checksum))
		return 0;

	return (!lstrcmpi (a->szText, b->szText));
}


/* position - moves the input pointer for file 'f' such that the next line to
   be read will be 'where' */
void position (int f, pLINE where)
{
	at[f] = &root[f];
	if (where != NULL) {
		while (at[f]->link != where)
			at[f] = at[f]->link;
	}
}


/* Checksum - calculates a simple checksum for the line, and stores it in
   the line buffer.  This allows for faster comparisons */
void Checksum (pLINE a)
{
	register int i;

	a->checksum = 0;
	for (i = 0; (a->szText[i] != '\0'); i++) {
		/* ignore case */
		a->checksum ^= toupper (a->szText[i]);
	}
}


/* next_line - allocates, links and returns the next line from file 'f' if
   no lines are buffered, otherwise returns the next buffered line from 'f'
   and updates the link pointer to the next buffered line; it also inserts
   the line in the correct place in the array same_check */
pLINE next_line (int f)
{
	pLINE place_hold, start;

	if (at[f]->link != NULL) {
		at[f] = at[f]->link;
		return (at[f]);
	}

	at[f]->link = (pLINE) malloc (sizeof(struct LINE));
	if (at[f]->link == NULL)
		_exit (2);

	place_hold = at[f];
	at[f] = at[f]->link;
	if (place_hold == &(root[f]))
		at[f]->prev = NULL;
	else
		at[f]->prev = place_hold;
	at[f]->link = NULL;
	at[f]->same = NULL;

	if ((hInput[f] == HFILE_ERROR) || (GetLine( hInput[f], at[f]->szText, MAXLINE-1 ) <= 0)) {
		free (at[f]);
		at[f] = place_hold;
		at[f]->link = NULL;
		at[f]->same = NULL;
		return NULL;
	}

	/* calculate a checksum for the new line of text */
	Checksum (at[f]);

	/* insert it in the correct place in the array unless it is
	   a QueryCompare line */
	if (!QueryCompare (at[f])) {

 		start = same_check [at[f]->checksum][f-1];
		if (start == NULL)
			same_check [at[f]->checksum][f-1] = at[f];
		else {
			while (start->same != NULL)
				start = start->same;
			/* start is NULL now, insert at[f] here */
			start->same = at[f];
		}
	}

	return (at[f]);
}


/* discard - deallocates all buffered lines from the root up to and inclu-
   ding 'to' for file 'f', including from same_check */
void discard (int f, pLINE to)
{
	pLINE temp;

	for ( ; ; ) {

		if ((root[f].link == NULL) || (to == NULL))
			break;

		temp = root[f].link;
		/* ok the line exists, now find the record in same_check */
		if (!QueryCompare (temp)) {
			/* replace with temp->same */
			same_check [temp->checksum][f-1] = temp->same;
		}

		root[f].link = root[f].link->link;
if (root[f].link != NULL)
		root[f].link->prev = NULL;

		if (temp != NULL)
			free (temp);
		if (temp == to)
			break;
	}

	at[f] = &root[f];
}


/* put - prints all lines from the root of file 1 up to and including 'line'.
   This is only called if
   a match exists for each significant line in file 2 */
void put (pLINE line)
{
	pLINE temp;

	for (temp = root[1].link; ; ) {

		if (temp == NULL)
			break;
		_lwrite( hOutput, "\t", 1);
		_lwrite( hOutput, temp->szText, lstrlen(temp->szText) );
		_lwrite( hOutput, "\r\n", 2);
		if (temp == line)
			break;
		temp = temp->link;
	}
}


/* _added - prints a change summary for all significant lines from the root
   of file 1 up to and including 'line'.  If output is enabled, adds a
   change bar to the text and outputs the line to the output file */
void _added (pLINE line)
{
	char szBuf[MAXLINE+10];
	pLINE temp;

	for (temp = root[1].link; ; ) {

		if (temp == NULL)
			break;

		if (QueryCompare (temp))
			_lwrite( hOutput, temp->szText, lstrlen(temp->szText) );
		else {
			wsprintf(szBuf, "%s%c\t%s", szMsg_Added, 187, temp->szText);
			_lwrite( hOutput, szBuf, lstrlen( szBuf ) );
			fModified = 1;
		}
		_lwrite( hOutput, "\r\n", 2);

		if (temp == line)
			break;

		temp = temp->link;
	}
}


/* deleted - outputs a change summary for all lines i file 2 from the root
   up to and including 'line' */
void deleted (pLINE line)
{
	char szBuf[MAXLINE+10];
	pLINE temp;

	for (temp = root[2].link; ;) {

		if (temp == NULL)
			break;

		if (QueryCompare (temp))
			_lwrite( hOutput, temp->szText, lstrlen(temp->szText) );
		else {
			wsprintf(szBuf, "%s%c\t%s", szMsg_Deleted, 187, temp->szText);
			_lwrite( hOutput, szBuf, lstrlen( szBuf ) );
			fModified = 1;
		}
		_lwrite( hOutput, "\r\n", 2);

		if (temp == line)
			break;
		temp = temp->link;
	}
}


/* resync - resynchronizes file 1 and file 2 after a difference is detected
   and outputs changed lines and change summaries via _added() and deleted().
   Exits with the file inputs pointing at the next two lines that match,
   unless it is impossible to sync up again, in which case all lines in file 1
   are printed via _added().  Deallocates lines printed by this function. */
int resync (pLINE first, pLINE second, int lookahead)
{
	pLINE file1_start, file2_start, last_bad1, last_bad2, t1, t2, check;
	int i, k, moved1, moved2;

	/* first ensure sufficient lines in memory */
	position (2, second);
        last_bad2 = second;
	for ( k = 0; (k < lookahead) && (last_bad2 != NULL) ; k++)
		last_bad2 = next_line(2);

	/* now reset file pointers */
	moved1 = 0;
	file1_start = first;
	position (1, first);

	for (k = 0; (k < lookahead); k++) {

		while (QueryCompare (file1_start = next_line(1)))
			;
		if (file1_start == NULL)
			goto no_sy;
		moved2 = 0;

		/* now see if there is a matching line at all */
		check = same_check [file1_start->checksum][1];
		while (check != NULL) {

			/* look for matching entries */
			while (!equal (check, file1_start)) {
				check = check->same;
				if (check == NULL)
					break;
			}

			if (check != NULL) {

				/* ok we have a hit */
				t1 = file1_start;
				file2_start = check;
				t2 = file2_start;
				position (1, file1_start);
				position (2, file2_start);
				for (i=0; (i < nReSync) && (equal (t1,t2)); i++) {
					while (QueryCompare (t1 = next_line (1)))
						;
					while (QueryCompare (t2 = next_line (2)))
						;
					if ((t1 == NULL) || (t2 == NULL))
						break;
				}

				if (i == nReSync) {
					moved2++;
					if ((last_bad2 = file2_start->prev) == NULL)
						moved2 = 0;
					goto synced;
				}

				/* get next entry */
				check = check->same;
			} /* if check != NULL */
		} /* end of while check != NULL */

		/* else no sync, no matching entries yet, loop the for list */
		last_bad1 = file1_start;
		position (1, file1_start);
		while (QueryCompare (file1_start = next_line (1)))
			;
		moved1++;

	} /* for each line in file 1 lookahead */

        return (NO_SYNC);

no_sy:
	position (1,first);
	while ((first = next_line(1)) != NULL) {
		_added (first);
		discard (1, first);
	}
	return (EOF_REACHED);

synced:
	if (moved1) {
		_added (last_bad1);
		discard (1, last_bad1);
	}
	position (1, file1_start);
	if (moved2) {
		deleted (last_bad2);
		discard (2, last_bad2);
	}
	position (2, file2_start);

	return (RE_SYNCED);
}


/* diff - differencing executive.  Prints and deallocates all lines up to
   where a difference is detected, at which point resync() is called.  Exits
   on end of file 1 */
void diff(void)
{
	int look_lines, result;
	pLINE first = NULL, second = NULL;

	for (;;) {

		while (QueryCompare (first = next_line (1)))
			;
		if (first == NULL) {
			put (first);
			break;
		}

		while (QueryCompare (second = next_line (2)))
			;

		if (equal (first, second)) {
			put (first);
			discard (1,first);
			discard (2,second);
//		} else if (second != NULL) {
		} else {
			look_lines = 10;   /* start with 10 lines look-ahead */
			result = NO_SYNC;
                        while (result == NO_SYNC) {
				result = resync (first, second, look_lines);
				look_lines *= 2;
			}
		} 

		if (second == NULL)
			break;
	}
}


/* open_files - opens the input and the output files */
void open_files(void)
{
	register int i;

	for (i=1; (i < 3); i++) {
		hInput[i] = _lopen (szaInfileName[i], READ | OF_SHARE_DENY_NONE);
	}

	if ((hOutput = _lcreat (szDiffFile, 0)) == HFILE_ERROR)
		command_errors++;
}

