/*' $Header:   P:/PVCS/MAX/QUILIB/INSHELP.C_V   1.0   05 Sep 1995 17:02:12   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * INSHELP.C								      *
 *									      *
 * Function to insert help text into the DOS 5 help file		      *
 *									      *
 ******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>
#include <ctype.h>

#include "commfunc.h"

int insert_help(char *name, char **newlines, int nlines, int savechanges)
/* Return number of lines changed.  Changes are not saved unless */
/* savechanges != 0 */
{
	FILE *f1;
	FILE *f2;
	int kk;
	int nstem;
	char *pp;
	char line[256];
	int numchanges = 0, lastchanged = 0;

	if (access(name,6) != 0) return FALSE;

	strcpy(line,name);
	pp = strrchr(line,'.');
	if (!pp) pp = line+strlen(line);
	if (strlen(pp) > 4) return FALSE;
	nstem = pp - line;

	f1 = fopen(name,"r");
	if (!f1) return FALSE;

	strcpy(line+nstem,".$$$");
	if (savechanges) {
		f2 = fopen(line,"w");
		if (!f2) {
			fclose(f1);
			return FALSE;
		}
	} /* Saving changes */

	for (kk = 0; kk < nlines; kk++) {
		pp = strchr(newlines[kk],' ');
		if (!pp) newlines[kk] = NULL;
		else	 *pp = '\0';
	}

	while (fgets(line,sizeof(line),f1)) {
		if (isalnum(*line)) {
			pp = strchr(line,' ');
			if (pp) *pp = '\0';

			for (	kk = savechanges ? 0 : lastchanged;
				kk < nlines;
				kk++) {
				int tst;

				if (!newlines[kk]) continue;

				tst = stricmp(line,newlines[kk]);
				if (tst < 0) {
					break;
				}
				if (tst == 0) {
					/* Matching line(s) already in file, toss 'em */
					while (fgets(line,sizeof(line),f1)) {
						if (!isspace(*line)) break;
					}
					pp = strchr(line,' ');
					if (pp) *pp = '\0';
				}
				if (tst >= 0) {
					newlines[kk][strlen(newlines[kk])] = ' ';
					numchanges += tst;
					if (savechanges) {
					    if (fputs(newlines[kk],f2)) goto bailout;
					    newlines[kk] = NULL;
					} /* Changes are written */
					lastchanged = max (lastchanged, kk+1);
				}
			}
			if (pp) *pp = ' ';
		}
		if (savechanges && fputs(line,f2)) goto bailout;
	}
	fclose(f1);
	if (savechanges) {

		for (kk = 0; kk < nlines; kk++) {
			if (newlines[kk]) {
				newlines[kk][strlen(newlines[kk])] = ' ';
				if (fputs(newlines[kk],f2)) goto bailout;
				newlines[kk] = NULL;
			}
		}

		fclose(f2);
		strcpy(line,name);
		strcpy(line+nstem,".OLD");
		unlink(line);
		if (rename(name,line) != 0) goto bailout;

		strcpy(line+nstem,".$$$");
		if (rename(line,name) != 0) {
			strcpy(line+nstem,".OLD");
			rename(line,name);
			goto bailout;
		}
		strcpy(line+nstem,".OLD");
		unlink(line);

	} /* Changes were written */
	else {
		numchanges += min (0, nlines - lastchanged);
	} /* Add lines left over to changes needed */

	return (numchanges);
bailout:
	fclose(f1);
	if (savechanges) {
		fclose(f2);
		strcpy(line,name);
		strcpy(line+nstem,".$$$");
		unlink(line);
	}
	return FALSE;
}
