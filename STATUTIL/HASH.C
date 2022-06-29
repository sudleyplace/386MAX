// $Header:   P:/PVCS/MAX/STATUTIL/HASH.C_V   1.1   28 May 1996 16:11:26   HENRY  $
//
// HASH.C - String hashing
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//

#define	STRICT
#include <windows.h>

#include <stdio.h>
#include <ctype.h>

#define	HASHPRIME	65287

// Hash a string to a 16-bit value.
// Normally this value is divided by a prime number and the
// remainder is used to index a bucket pointer list.  This
// algorithm is used for SWAT's symbol hashing.
WORD
HashStr( LPCSTR lpsz ) {

	DWORD dwRes = 0L, dw;

	for( ; *lpsz; lpsz++ ) {
		dwRes = (dwRes << 4) + (WORD) tolower( *lpsz );
		if (dw = (dwRes & 0xF0000000)) {
			dwRes ^= (dw >> 24);
			dwRes ^= dw;
		} // Leftmost nybble non-zero
	} // not end of string

	return (WORD) (dwRes % HASHPRIME);

} // HashStr()

