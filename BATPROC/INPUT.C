// INPUT.C
// Reentrant & smaller sscanf() replacement for 4DOS
// Copyright (c) 1990, 1991  Rex C. Conn  GNU General Public License version 3.
//
//    %[*][width][size]type
//	  *:
//	      Scan but don't assign this field.
//	  width:
//	      Controls the maximum # of characters read.
//	  size:
//	      F     Specifies argument is FAR
//	      l     Specifies 'd', 'u' is long
//	  type:
//	      c     character
//	      s     string
//	     [ ]    array of characters
//	      d     signed integer
//	      u     unsigned integer
//	      n     number of characters read so far


#include <ctype.h>
#include <stdlib.h>
#include <stdarg.h>
#include <limits.h>
#include <string.h>

#include "batproc.h"


static int pascal _fmtin(register const char *source, register const char *fmt, va_list arg)
{
	char table[256];		// ASCII table for %[^...]
	const char *base;
	char far *fptr, islong, isfar, ignore, reject, using_table, sign_flag;
	int fields = 0, width;
	long value;

	// save start point (for %n)
	base = source;

	while (*fmt != '\0') {

		if (*fmt == '%') {

			isfar = islong = 0;
			ignore = reject = using_table = sign_flag = 0;

			if (*(++fmt) == '*') {
				fmt++;
				ignore++;
			}

			// get max field width
			if (isdigit(*fmt)) {
				for (width = atoi(fmt); (isdigit(*fmt)); fmt++)
					;
			} else
				width = INT_MAX;	// max string width 32K!

next_fmt:
			switch (*fmt) {

			case 'l':
				islong = 1;
				fmt++;
				goto next_fmt;

			case 'F':
				isfar = 1;
				fmt++;
				goto next_fmt;

			case '[':
				using_table++;
				if (*(++fmt) == '^') {
					reject++;
					fmt++;
				}

				memset(table,reject,256);
				for ( ; ((*fmt) && (*fmt != ']')); fmt++)
					table[*fmt] ^= 1;

			case 'c':
			case 's':

				if ((*fmt == 'c') && (width == INT_MAX))
					width = 1;
				else if (*fmt == 's') {
					// skip leading whitespace
					source = skipspace((char *)source);
				}

				if (ignore == 0) {
					if (isfar)
						fptr = va_arg(arg, char far *);
					else
						fptr = (char far *)(va_arg(arg, char *));
				}

				for ( ; ((width > 0) && (*source)); source++, width--) {

					if (using_table) {
						if (table[*source] == 0)
							break;
					} else if ((*fmt == 's') && (isspace(*source)))
						break;

					if (ignore == 0)
						*fptr++ = *source;
				}

				if (ignore == 0) {
					if (*fmt != 'c')
						*fptr = '\0';
					fields++;
				}
				break;

			case 'u':
			case 'd':
				// skip leading whitespace
				source = skipspace((char *)source);

				// check for leading sign
				if (*source == '-') {
					sign_flag++;
					source++;
				}

				for (fptr = (char far *)source, value = 0L; ((width > 0) && (isdigit(*source))); source++, width--)
					value = (value * 10) + (*source - '0');

				if (sign_flag)
					value = -value;

			case 'n':
				// number of characters read so far
				if (*fmt == 'n')
					value = (long)(source - base);

				if (ignore == 0) {

					if (islong) {
						if (isfar)
							*(va_arg(arg,long far *)) = value;
						else
							*(va_arg(arg,long *)) = value;
					} else {
						if (isfar)
							*(va_arg(arg,unsigned int far *)) = (unsigned int)value;
						else
							*(va_arg(arg,unsigned int *)) = (unsigned int)value;
					}

					// if start was a digit, inc field count
					if ((isdigit(*fptr)) || (*fmt == 'n'))
						fields++;
				}
				break;

			default:
				if (*fmt != *source++)
					return fields;
			}

			fmt++;

		} else if (isspace(*fmt)) {

			// skip leading whitespace
			fmt = skipspace((char *)fmt);
			source = skipspace((char *)source);

		} else if (*fmt++ != *source++)
			return fields;
	}

	return fields;
}


// replace the RTL sscanf()
int cdecl sscanf(const char *source, const char *fmt, ...)
{
	va_list arglist;

	va_start(arglist,fmt);
	return (_fmtin(source,fmt,arglist));
}

