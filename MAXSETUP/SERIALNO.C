/*' $Header:   P:/PVCS/MAX/MAXSETUP/SERIALNO.C_V   1.3   03 Nov 1995 12:01:34   PETERJ  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * SERIALNO.C								      *
 *									      *
 * Routines to encode and decode Qualitas product serial numbers	      *
 *									      *
 ******************************************************************************/

#include <windows.h>
#include <ctype.h>

    // remove extrainious stuff from the SN.
int SNPackStr( LPSTR lpOut, LPSTR lpIn );

#define EQ ==
#define MAXSTR 20		// The length of the longest input string+2
				//   handled by these routines.  There is
				//   no error checking of this requirement.
				// Note that the two check digits are included
				//   in MAXSTR, thus the length of the longest
				//   input string allowed is MAXSTR-2.

// Output area for encoded serial #
// Note that the caller *MUST* copy this string to another
//   location before calling either ENCODE or DECODE routines again.
static unsigned char outstr[MAXSTR + 1];

// The following permutation is used in the algorithm to
//   weight (i.e., translate) the individual digits of the
//   input string.  It is also represented as (0)(14)(23)(58697).
			    // 0 1 2 3 4 5 6 7 8 9
static unsigned char perm[] = {0,4,3,2,1,8,9,5,6,7};

// The following table represents the transformations of the
//   dihedral group D5 of order 10.
static unsigned char d5[][10] = { {0,1,2,3,4,5,6,7,8,9},   // 0
				  {1,2,3,4,0,6,7,8,9,5},   // 1
				  {2,3,4,0,1,7,8,9,5,6},   // 2
				  {3,4,0,1,2,8,9,5,6,7},   // 3
				  {4,0,1,2,3,9,5,6,7,8},   // 4
				  {5,9,8,7,6,0,4,3,2,1},   // 5
				  {6,5,9,8,7,1,0,4,3,2},   // 6
				  {7,6,5,9,8,2,1,0,4,3},   // 7
				  {8,7,6,5,9,3,2,1,0,4},   // 8
				  {9,8,7,6,5,4,3,2,1,0},   // 9
				};

// The following table is used to re-order the digits in the result
//   so as not to be obvious as to the sequence of numbers as well
//   as the position (or number of) check digits.
// Each row represents the permutation used for each length input
//   string.  Thus, the number of rows in this table *MUST* be at
//   least MAXSTR.
static unsigned char
  ord[(MAXSTR*(MAXSTR+1))/2] =					  // Length
 {0,								  //	 1
  0, 1, 							  //	 2
  2, 0, 1,							  //	 3
  2, 0, 3, 1,							  //	 4
  2, 4, 0, 3, 1,						  //	 5
  2, 4, 0, 5, 3, 1,						  //	 6
  6, 2, 4, 0, 5, 3, 1,						  //	 7
  6, 2, 4, 0, 7, 5, 3, 1,					  //	 8
  6, 2, 8, 4, 0, 7, 5, 3, 1,					  //	 9
  6, 2, 8, 4, 0, 7, 5, 9, 3, 1, 				  //	10
  0, 2, 8, 4,10, 6, 7, 5, 9, 3, 1,				  //	11
  0, 1, 2,11, 6, 8, 5, 9, 4,10, 3, 7,				  //	12
  6,11, 2, 8, 4,10, 0, 7,12, 5, 9, 3, 1,			  //	13
  6,11, 2, 8,13, 4,10, 0, 7,12, 5, 9, 3, 1,			  //	14
  6,11, 2, 8,13, 4,14,10, 0, 7,12, 5, 9, 3, 1,			  //	15
  6,11, 2, 8,13, 4,14,10, 0, 7,12, 5,15, 9, 3, 1,		  //	16
 16, 6,11, 2, 8,13, 4,14,10, 0, 7,12, 5,15, 9, 3, 1,		  //	17
 16, 6,11, 2, 8,13,17, 4,14,10, 0, 7,12, 5,15, 9, 3, 1, 	  //	18
 16, 6,11, 2, 8,13,17, 4,14,10,18, 0, 7,12, 5,15, 9, 3, 1,	  //	19
 16, 6,11, 2, 8,13,17, 4,14,10,18, 0, 7,12, 5,15, 9,19, 3, 1,	  //	20
 };

/******************************** WEIGHT_DIGIT ********************************/
// Generate a weight digit for the input string
// We use the method described in American Mathematical Monthly,
// "Modular Arithmetic in the Marketplace", Gallian and Winters,
//   Vol. 95, #6, June-July 1988, pp. 548-551.

unsigned char weight_digit (char *inpstr)
{
  unsigned int i, j, len;
  register unsigned char c, s;

  len = lstrlen (inpstr);	// Loop through each character in the string
  s = 0;			// Initial seed (identity element in D5)

  // Loop through permutation based upon digit index, then
  // compute product in D5.  Note that multiplication in D5
  // is not commutative.
  for (i = 0; i < len; i++)
  {    c = inpstr[i] - (unsigned char) '0'; // Get next digit, convert to binary
       for (j = 0; j <= i; j++) // perm**i(c);
	    c = perm[c];
       s = d5[s][c];		// s = s * c  w.r.t. dihedral group D5
  } // End FOR

  return (s);			// Return as result

} // End WEIGHT_DIGIT


/********************************* CHECK_DIGIT ********************************/
// Generate a check digit for the input string
// This value is the multiplicative inverse of the
// corresponding weight_digit, and then converted to ASCII.

unsigned char check_digit (char *inpstr)

{ unsigned char s;

  s = weight_digit (inpstr);	// Return weight of the string in binary

  // Find inverse of S in D5
  // Since this is the first zero entry in the row D5[S], we can use
  // STRLEN.
  // Convert to ASCII and return as result
  return ((unsigned char) ('0' + lstrlen (d5[s])));

} // End CHECK_DIGIT


/********************************** ENCODE_SERIALNO ***************************/
// Encode serial #

unsigned char * encode_serialno (unsigned char *inpstr)

{ unsigned int i, len, nprec;
  unsigned char tmpstr[MAXSTR + 1];

  // Copy input string to local storage to append check digits
  lstrcpy (tmpstr, inpstr);

  // Generate 1st check digit and append check digit to output string
  len = lstrlen (tmpstr);
  tmpstr[len++] = check_digit (tmpstr);
  tmpstr[len] = '\0';           // Ensure properly terminated

  // Generate 2nd check digit and append check digit to output string
  tmpstr[len++] = check_digit (tmpstr);
  tmpstr[len] = '\0';           // Ensure properly terminated

  // Re-order digits of outgoing string to confuse the casual viewer
  nprec = (len * (len - 1))/2;	// # preceding entries in the ORD table
  for (i = 0; i < len; i++)
       outstr[ord[nprec + i]] = tmpstr[i];
  outstr[len] = '\0';           // Ensure properly terminated

  // Return pointer to caller
  return (outstr);

} // End ENCODE_SERIALNO


/********************************** DECODE_SERIALNO ***************************/
// Decode serial # and validate check digits
// If the input string is invalid, the result is NULL.
// Input string must contain digits only.

unsigned char * decode_serialno (unsigned char *inpstr)

{ 
  int nRet;  
  unsigned int i, len, nprec;
  unsigned char c, tmpstr[MAXSTR + 1], packstr[ MAXSTR + 1];

  nRet = SNPackStr( (LPSTR) packstr, (LPSTR) inpstr );
  
  if ( nRet == 0 )
      {
      return ((void *) 0);
      }

  // Re-order digits of input string to unconfuse the program
  len = lstrlen ( packstr );

      // Ensure there's something to process
      // We need at least two check digits
      // PETERJ 11/3/95 moved the 12 test from setup.c to here.
      // this was if ( len < 2 )
  if (len != 12)
//////BEEP ();
      return ((void *) 0);	//  return error

  if (len >= sizeof (tmpstr))	// Ensure input string not too long
//////BEEP ();
      return ((void *) 0);	//  return error

  nprec = (len * (len - 1))/2;	// # preceding entries in the ORD table
  for (i = 0; i < len; i++) {
	if (isdigit (packstr[i])) {
		tmpstr[i] = packstr[ord[nprec + i]];
	}
	else {
		return ((void *) 0);
	}
  }
  tmpstr[len] = '\0';           // Ensure properly terminated

  // Generate 2nd weight digit and confirm that the product of it and
  // the check digit is zero.
  c = tmpstr[--len] - (unsigned char) '0'; // Get expected check digit in binary
  tmpstr[len] = '\0';           // Ensure properly terminated

  if (d5[weight_digit (tmpstr)][c] != 0) // If product not zero,
      return ((void *) 0);	// return error

  // Generate 1st weight digit and confirm that the product of it and
  // the check digit is zero.
  c = tmpstr[--len] - (unsigned char) '0'; // Get expected check digit in binary
  tmpstr[len] = '\0';           // Ensure properly terminated

  if (d5[weight_digit (tmpstr)][c] != 0) // If product not zero,
      return ((void *) 0);	// return error

  // Copy temporary string to output string
  lstrcpy (outstr, tmpstr);

  // Return pointer to caller
  return (outstr);

} // End DECODE_SERIALNO

/********************************** SNPackStr ***************************/
// remove extranious characters from serial numbers.
// return TRUE if not all zeros. (prevent this as a valid serial number)

int SNPackStr( LPSTR lpOut, LPSTR lpIn )
    {
    int nZedTrap = 0;
    char FAR *lpIptr;
    char FAR *lpOptr;
    
    lpIptr = lpIn;
    lpOptr = lpOut;

    do
        {
        if ( *lpIptr == '\0' )
            {
            *lpOptr = '\0';
            break;
            }

            // only copy numbers and null.
        if ( ( *lpIptr >= '0' ) && ( *lpIptr <= '9' )) 
            {
            *lpOptr = *lpIptr;
            
            if ( *lpOptr != '0' ) 
                {
                nZedTrap = 1;
                }
            ++lpOptr;
            }
        } while ( *lpIptr++ );

    return nZedTrap;
    }
