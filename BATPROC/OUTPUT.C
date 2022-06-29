// OUTPUT.C
// Reentrant & smaller sprintf() replacement for 4DOS
// Copyright (c) 1990, 1991  Rex C. Conn  All rights reserved.
//
//  %[flags][width][.precision][size]type
//    flags:
//	- left justify the result
//	+ right justify the result
//    width:
//	Minimum number of characters to write (pad with ' ' or '0').
//	If width is a *, get it from the next argument in the list.
//    .precision
//	Precision - Maximum number of characters or digits for output field
//	If precision is a *, get it from the next argument in the list.
//    size:
//	F     Specifies argument is FAR
//	l     Specifies 'd', 'u', 'x' is long
//    type:
//	c     character
//	s     string
//	[ ]    array of characters
//	d     signed integer
//	u     unsigned integer
//	x     unsigned hex
//	n     number of characters written so far

#include <ctype.h>
#include <io.h>
#include <limits.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "batproc.h"


// write a string to memory
static void pascal w_string(char **pdest, const char far *str, int minlen, int maxlen, char fill)
{
	register int count;
	register char *target;
	const char far *p;
	int length;

	target = *pdest;

	for (count = 0, p = str; (*p != '\0'); p++, count++) {
		if (count == maxlen)
			break;
	}

	for ( ; (minlen > count); minlen--)
		*target++ = fill;

	for (length = count; (length > 0); length--)
		*target++ = *str++;

	for (minlen = -minlen; (minlen > count); minlen--)
		*target++ = fill;

	*pdest = target;
}


static char pascal get_int(va_list *parg, const char **pp, register int *vp)
{
	register const char *p;
	char c, sign = 0;

	p = *pp;

	if (*p == '-') {
		p++;
		sign++;
	}

	c = *p; 		// save fill character

	if (*p == '0')          // skip zero in case '0*'
		p++;

	if (*p == '*') {
		// next argument is the value
		p++;
		*vp = va_arg(*parg, int);
	} else {
		// convert the width from ASCII to binary
		for (*vp = atoi(p); (isdigit(*p)); p++)
			;
	}

	if (sign)
		*vp = -(*vp);
	*pp = p;

	return c;
}


// This routine does the actual parsing & formatting of the sprintf() statement
static int pascal _fmtout(char *dest, register const char *fmt, va_list arg)
{
	int val, val2;
	const char *auto_p;
	char *save_dest, buf[(CHAR_BIT * sizeof(long)) + 1];
	char islong, isfar, fill;

	save_dest = dest;

	for ( ; *fmt; fmt++) {

		// is it an argument spec?
		if (*fmt == '%') {

			// set the default values
			isfar = islong = 0;
			val = 0;
			val2 = INT_MAX;
			fill = ' ';
			auto_p = fmt + 1;

			// get the width
			if (get_int(&arg, &auto_p, &val) == '0')
				fill = '0';

			// get precision
			if (*auto_p == '.') {
				auto_p++;
				get_int(&arg,&auto_p,&val2);
			}
			fmt = auto_p - 1;

next_fmt:
			switch (*(++fmt)) {
			case 'l':       // long int
				islong = 1;
				goto next_fmt;
			case 'F':       // Far data
				isfar = 1;
				goto next_fmt;
			case 's':       // string
				w_string(&dest, (isfar ? va_arg(arg,const char far *) : (const char far *)va_arg(arg, const char *)),val,val2,fill);
				continue;
			case 'x':       // unsigned hex int
			case 'u':       // unsigned decimal int
				w_string(&dest,strupr(ultoa(islong ? va_arg(arg,unsigned long) : va_arg(arg,unsigned int),buf,((*fmt == 'u') ? 10 : 16))),val,32,fill);
				continue;
			case 'd':       // signed decimal int
				w_string(&dest,ltoa(islong ? va_arg(arg,long) : va_arg(arg,int),buf,10),val,32,fill);
				continue;
			case 'c':       // character
				*dest++ = (char)va_arg(arg,int);
				continue;
			case 'n':       // number of characters written so far
				w_string(&dest,ltoa((long)(dest - save_dest),buf,10),val,32,fill);
				continue;
			}
		}

		*dest++ = *fmt;
	}

	*dest = '\0';

	return (int)(dest - save_dest); 	// length of string
}


// replaces the RTL sprintf()
int cdecl sprintf(char *dest, const char *fmt, ...)
{
	va_list arglist;

	va_start(arglist,fmt);
	return (_fmtout(dest,fmt,arglist));
}


// fast printf() replacement function
void cdecl qprintf(int handle, char *format, ...)
{
	register int length;
	char string[CMDBUFSIZ+16];
	va_list arglist;

	va_start(arglist,format);
	length = _fmtout(string,format,arglist);
	write(handle,string,length);
}


// write a string (no buffering) to the specified handle
void pascal qputs(int handle, register char *string)
{
	write(handle,string,strlen(string));
}


// write a string & LF (no buffering) to the specified handle
void pascal qputslf(register int handle, char *string)
{
	qputs(handle,string);
	qputc(handle,'\n');
}


// write a character (no buffering) to the specified handle
void pascal qputc(int handle, char c)
{
	write(handle,&c,1);
}

