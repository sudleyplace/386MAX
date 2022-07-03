// $Header:   P:/PVCS/MAX/STATUTIL/IOFMT.C_V   1.4   09 Dec 1996 14:06:34   PETERJ  $
//
// IOFMT.C - Reentrant & smaller (s)scanf() replacement for Windows 3.x
//	  Adapted from CSCRIPT\iofmt.c
//
// Copyright (C) 1994-96 Qualitas, Inc.  GNU General Public License version 3
// Copyright (c) 1994, 1995  Rex C. Conn  GNU General Public License version 3.

#include <windows.h>

#include <ctype.h>
#include <limits.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include <iofmt.h>

#ifdef _WIN32
#include <32alias.h>
#endif

static int _fmtin(const char FAR *, const char *, va_list);
static char GetInteger(va_list *, const char **, int *);


// From W16CALLS.C:
// replace RTL isspace() - we only want to check for spaces & tabs
int _fastcall iswhite(char c)
{
	return ((c == ' ') || (c == '\t'));
}

// From MISC.C:
// map character to upper case (including foreign language chars)
int _fastcall _ctoupper(int c)
{
	if (c < 'a')
		return c;

	return ((c > 0xFF) ? c : (int)LOWORD(AnsiUpper((LPSTR)(DWORD)(BYTE)c)));
}

//	  %[*][width][size]type
//	  *:
//		  Scan but don't assign this field.
//	  width:
//		  Controls the maximum # of characters read.
//	  size:
//		  F 	Specifies argument is FAR
//		  l 	Specifies 'd', 'u' is long
//	  type:
//		  c 	character
//		  s 	string
//		 [ ]	array of characters
//		  d 	signed integer
//		  u 	unsigned integer
//			  x 	hex integer
//		  n 	number of characters read so far

static int _fmtin(const char FAR *source, register const char *fmt, va_list arg)
{
	int fields = 0, width, n;
	long lVal;
	char ignore, reject, using_table, sign_flag;
	char islong, isfar, ishex;
	char table[256];		// ASCII table for %[^...]
	char FAR *base;
	char FAR *fptr;

	// save start point (for %n)
	base = (char FAR *)source;

	while (*fmt != '\0') {

		if (*fmt == '%') {

			isfar = islong = 0;
			ignore = reject = using_table = sign_flag = 0;

			if (*(++fmt) == '*') {
				fmt++;
				ignore++;
			}

			// get max field width
			if ((*fmt >= '0') && (*fmt <= '9')) {
				for (width = atoi(fmt); ((*fmt >= '0') && (*fmt <= '9')); fmt++)
					;
			} else
				width = INT_MAX;
next_fmt:
			switch (*fmt) {
			case 'l':       // long int
				islong = 1;
				fmt++;
				goto next_fmt;

			case 'F':       // far pointer
				isfar = 1;
				fmt++;
				goto next_fmt;

			case '[':
				using_table++;
				if (*(++fmt) == '^') {
					reject++;
					fmt++;
				}

				_fmemset(table,reject,256);
				for ( ; ((*fmt) && (*fmt != ']')); fmt++)
					table[*fmt] ^= 1;

			case 'c':
			case 's':

				if ((*fmt == 'c') && (width == INT_MAX))
					width = 1;
				else if (*fmt == 's') {
					// skip leading whitespace
					while ((*source == ' ') || (*source == '\t'))
						source++;
				}

				if (ignore == 0) {
					if (isfar)
						fptr = (char FAR *)(va_arg(arg, char FAR *));
					else
						fptr = (char FAR *)(va_arg(arg, char *));
				}

				for ( ; ((width > 0) && (*source)); source++, width--) {

					if (using_table) {
						if (table[*source] == 0)
							break;
					} else if ((*fmt == 's') && ((*source == ' ') || (*source == '\t')))
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
			case 'x':
				// skip leading whitespace
				while ((*source == ' ') || (*source == '\t'))
					source++;

				ishex = (*fmt == 'x');

				// check for leading sign
				if (*source == '-') {
					sign_flag++;
					source++;
				}

				if (ishex) {

					for (fptr = (char FAR *)source, lVal = 0L; ((width > 0) && (isxdigit(*source))); source++, width--) {
					n = ((isdigit(*source)) ? *source - '0' : (_ctoupper(*source) - 'A') + 10);
					lVal = (lVal * 16) + n;
					}

				} else {

					for (fptr = (char FAR *)source, lVal = 0L; ((width > 0) && (*source >= '0') && (*source <= '9')); source++, width--)
					lVal = (lVal * 10) + (*source - '0');

					if (sign_flag)
					lVal = -lVal;
				}

			case 'n':
				// number of characters read so far
				if (*fmt == 'n')
					lVal = (int)(source - base);

				if (ignore == 0) {

					if (islong) {
						if (isfar)
							*(va_arg(arg,long FAR *)) = lVal;
						else
							*(va_arg(arg,long *)) = lVal;
					} else {
						if (isfar)
							*(va_arg(arg,unsigned int far *)) = (unsigned int)lVal;
						else
							*(va_arg(arg,unsigned int *)) = (unsigned int)lVal;
					}

					// if start was a digit, inc field count
					if ((*fmt == 'n') || ((*fptr >= '0') && (*fptr <= '9')))
						fields++;
				}
				break;

			default:
				if (*fmt != *source++)
					return fields;
			}

			fmt++;

		} else if (iswhite(*fmt)) {

			// skip leading whitespace
			while ((*fmt == ' ') || (*fmt == '\t'))
				fmt++;
			while ((*source == ' ') || (*source == '\t'))
				source++;

		} else if (*fmt++ != *source++)
			return fields;
	}

	return fields;
}


static char GetInteger(va_list *parg, const char **pp, register int *vp)
{
	register const char *p;
	char c, sign = 0;

	p = *pp;

	if (*p == '-') {
		p++;
		sign++;
	}

	c = *p; 		// save fill character

	if (*p == '*') {
		// next argument is the value
		p++;
		*vp = va_arg(*parg, int);
	} else {
		// convert the width from ASCII to binary
		for (*vp = atoi(p); ((*p >= '0') && (*p <= '9')); p++)
			;
	}

	if (sign)
		*vp = -(*vp);
	*pp = p;

	return c;
}



// replace the RTL sscanf()
int _cdecl sscanf(const char *source, const char *fmt, ...)
{
	va_list arglist;

	va_start(arglist,fmt);
	return (_fmtin(source,fmt,arglist));
}


// far source version of sscanf
int _cdecl FAR sscanf_far(const char FAR *source, const char *fmt, ...)
{
	va_list arglist;

	va_start(arglist,fmt);
	return (_fmtin(source,fmt,arglist));
}

