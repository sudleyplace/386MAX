/***
 *' $Header:   P:/PVCS/MAX/DOSHELP/HMAKEL.C_V   1.6   28 Feb 1996 12:49:40   BUILD  $
 *
 * hmakel.c
 * HelpMake Laundry
 *
 * When compiling help files from .RTF files using HelpMake, the
 * escape sequences used for characters with bit 7 set (\'xx where
 * xx is a non-ASCII hex value) are not recognized.  Whether
 * this is a quirk of HelpMake or the way Word for Windows creates
 * RTF files does not concern us.  We replace these escape sequences
 * with their ASCII equivalents, and everyone is happy.  Output is
 * written to <basename>.out
 *
 * The highest failing version of HelpMake is 1.08 (shipped with C7).
 *
 * We also need to strip out \deflangnnnn (inserted by WinWord 2.0)
 * and \aenddoc.
 *
 * And while we're at it, WinWord 2.0 does another odd thing.  Attributes
 * like {\u underlin}{\u ing} get broken up arbitrarily, and this
 * causes HelpMake to not handle the second part properly.
 *
 * Handling WinWord 6 adds more wrinkles into the bag.  We now have
 * documents saved using the OEM character set, so we must handle those
 * as well as stripping several new attributes.
 *
***/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dos.h>

// Translation table.  Actual translation starts at 0xa0 though there are
// some OEM characters starting at 0x80.
// Whatever this other character set is, it's not the Windows set nor
// the Roman-8 international character set.
// We now have some OEM characters overlaid.
#define XTABOFF 0x80
char *xtab =
       //01234567        89abcdef
        "€‚ƒ„…†‡"      "ˆ‰Š‹ŒŽ"      // 80 - 8f
        "‘’“”•–—"      "˜™š›œžŸ"      // 90 - 9f

       //01234567        89abcdef
        "?­›œ?³?"      "þ?¦®ª???"      // a0 - af
        "øñý??æãù"      "??§¯¬«?¨"      // b0 - bf
        "????Ž’€"      "???????"      // c0 - cf

       //01234567        89abcdef
        "?¥????™?"      "????š??á"      // d0 - df
        "… ƒ?„†‘‡"      "Š‚ˆ‰¡Œ‹"      // e0 - ef
        "?¤•¢“?”?"      "?—£–??˜"      // f0 - ff
                ;

char    fullpath[_MAX_PATH], outpath[_MAX_PATH],
        drive[_MAX_DRIVE],
        dir[_MAX_DIR],
        fname[_MAX_FNAME],
        ext[_MAX_EXT];

char    lbuff[5120];

#define MAXNEST 20      // Maximum levels of {} processing
char    NestExp[MAXNEST][10];
int     NestLvl=-1;     // Not in any nesting level

 unsigned long lcount;
 unsigned long ldisp;
 int count, merge;

void error (char *fmt, char *msg)
{
 char temp[120];

 sprintf (temp, fmt, msg);
 fprintf (stderr, "\nhmakeL error: %s\n", temp);
 exit (-1);
} // error ()

char *pszAttr (char *pBuff)
// Return ASCIIZ version: "\ul " ==> "ul"
{
  static char saAttr[10];
  int i;

  for (++pBuff /* Skip leading \ */, i=0; *pBuff && *pBuff != ' ' && i < 9;
        pBuff++, i++) saAttr[i] = *pBuff;
  saAttr[i] = '\0';

  return (saAttr);

} // pszAttr ()

void launder_hex (char *lbuff)
{
        char *escape;
        char  replace;
        int   hexval;
        char  temp[5];

        // Launder line - we depend on it always shrinking, so we needn't
        // provide for expansion
        for (escape = lbuff; escape = strstr (escape, "\\'"); ) {

            if (sscanf (escape + 2, "%2x", &hexval) &&
                hexval >= XTABOFF &&
                hexval < 0x100 &&
                (replace = xtab[hexval-XTABOFF]) != '?') {

                sprintf (escape, "%c%s", replace, escape + 4);
                escape++;
                count++;

            } // hex value is valid and character is recognized
            else { // Skip sequence lead-in

                strncpy (temp, escape, 4);
                temp[4] = '\0';         // Make sure it ends somewhere
                fprintf (stderr, " \"%s\" not recognized, line %lu\n",
                                temp, lcount);
                escape += 2;            // Skip lead-in of sequence

            } // Unrecognized sequence

        } // for ()

} // launder_hex()

void launder_deflang (char *lbuff)
{
        char *escape;
        char *trailer;

        // Clobber all occurrences of \deflangnnnn (nnnn=1024)
        while (escape = strstr (lbuff, "\\deflang")) {

          for (trailer = escape + 8; isdigit (*trailer); trailer++) ;
          strcpy (escape, trailer);
          count++;

        } // while \deflang isn't dead

} // launder_deflang()

void launder_langn (char *lbuff)
{
        char *escape;
        char *trailer;

        // Clobber all occurrences of \langnnnn (nnnn=1024)
        while (escape = strstr (lbuff, "\\lang")) {

          for (trailer = escape + 5; isdigit (*trailer); trailer++) ;
          strcpy (escape, trailer);
          count++;

        } // while \lang isn't dead

} // launder_langn ()

void launder_splitattr (char *lbuff)
{
        char *psz;
        char *attr;

        // To catch splitting of attributes, we need to keep track of
        // the nested expression.  If nesting ends and immediately
        // begins with the same expression, we skip the end and reopen.
        // We may need to handle:
        // This is {\ul underlined
        // a}{\ul nd so is this}.
        for (psz = lbuff; *psz; psz++) {
          switch (*psz) {
            case '{':
                NestLvl++;
                if (*(psz+1) == '\\')
                        strcpy (NestExp[NestLvl], pszAttr (psz+1));
                break;
            case '}':
                if (*(psz+1) != '{' || *(psz+2) != '\\' ||
                        NestLvl<=0 || NestLvl>=MAXNEST)
                  NestLvl--;
                else {
                  attr = pszAttr (psz+2);
                  if (!stricmp (attr, NestExp[NestLvl]) &&
                        stricmp (attr, "cf2")) {

                        if (lcount != ldisp) {
                          ldisp = lcount;
                          fprintf (stderr, "Merging:%s", lbuff);
                        }
                        // Skip "}{\attr "
                        strcpy (psz, psz + 3 + strlen (attr) + 1);
                        merge++;

                  } // Merge attribute
                  else
                        NestLvl--;
                } // Got }{\ and we're not too deep
          } // switch()
        } // Scan entire line

} // launder_splitattr ()

// Called by KILLSTR() macro
void killsub( char *pszHaystack, char *pszNeedle, int nLen )
{
        char *escape, *pszEnd;

        while (escape = strstr (pszHaystack, pszNeedle)) {

          // Skip trailing space or tab
          // _ONLY_ if we're preceded by one
          pszEnd = escape + nLen - 1;
          if (*pszEnd == ' ' || *pszEnd == '\t') {
                if (escape != pszHaystack && escape[ -1 ] == ' ') pszEnd++;
          }

          strcpy( escape, pszEnd );
          count++;

        } // while not dead

} // killsub()

void launder_aenddoc (char *lbuff)
{
#define KILLSTR(s) \
        /* Clobber all occurrences */                           \
        killsub( lbuff, "\\" #s, sizeof( "\\" #s ) )

    //------------------------------------------------------------------
    // new additions by Pete for German Max 8.01. re-activated 2/28/96
        KILLSTR(fracwidth);
        KILLSTR(widctlpar);
        KILLSTR(slmult);
        KILLSTR(otblrul);
    //------------------------------------------------------------------

        KILLSTR(aenddoc);

        KILLSTR(noextrasprl);

        KILLSTR(prcolbl);

        KILLSTR(cvmme);

        KILLSTR(sprsspbf);

        KILLSTR(brkfrm);


        KILLSTR(swpbdr);

        KILLSTR(hyphcaps);

        KILLSTR(fet);

} // launder_aenddoc ()

int cdecl main (int argc, char *argv[])
{
 int i;
 FILE *infile, *outfile;
 unsigned ftime, fdate;

 fprintf (stderr, "HelpMake Laundry version 1.00\n"
                "Copyright (c) 1992-96 Qualitas, Inc.  All rights reserved.\n");

 if (argc < 2)  error ("No files specified.", NULL);

 // Ensure input buffer is null-terminated
 lbuff [sizeof(lbuff)-1] = '\0';

 for (i=1; i < argc; i++) {

    _splitpath (argv[i], drive, dir, fname, ext);
    _makepath (fullpath, drive, dir, fname, ext);
    _makepath (outpath, drive, dir, fname, ".out");

    fprintf (stderr, "Processing %s -", fullpath);
    count = 0;
    merge = 0;
    lcount = 0L;
    ldisp = 0xFFFFFFFFL;

    if ((infile = fopen (fullpath, "r")) == NULL)  error ("File %s not found.", fullpath);
    if ((outfile = fopen (outpath, "w")) == NULL)
        error ("Open error on %s.", outpath);

    // Preserve time/date stamp, as this tool is used by NMAKE
    if (_dos_getftime (fileno (infile), &ftime, &fdate)) {
        error ("Unable to get time/date for %s.", fullpath);
    }

    NestLvl = -1; // Not in {}
    while (fgets (lbuff, sizeof(lbuff)-1, infile)) {

        lcount++;

        launder_hex (lbuff);

        launder_deflang (lbuff);

        launder_aenddoc (lbuff);

        launder_langn (lbuff);

        launder_splitattr (lbuff);

        // Dump it
        fputs (lbuff, outfile);

    } // while not EOF

    // Ensure everything's written before we set time and date,
    // otherwise they'll get changed again when we call fclose
    fflush (outfile);

    // Restore original time/date stamp
    if (_dos_setftime (fileno (outfile), ftime, fdate) && count) {
        error ("Unable to change time/date for %s.", outpath);
    }

    // Close files
    fclose (outfile);
    fclose (infile);

    if (count || merge) {
        fprintf (stderr, " %d replacements, %d attribute merges\n",
                count, merge);
    }
    else {
        fprintf (stderr, " no changes\n");
    }

 } // for ()

 return (0);

} // main ()

