// $Header:   P:/PVCS/MAX/INCLUDE/32ALIAS.H_V   1.4   05 Jul 1996 14:42:46   PETERJ  $
// Aliases for Win16 to Win32 conversion. 
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved

#ifndef _INC_32ALIAS
//--------------------------------------------------------------
#define _INC_32ALIAS

	#define _fheapmin	_heapmin
	#define	_fheapwalk	_heapwalk

	#define _ffree		free
	#define _fmalloc	malloc
	#define _frealloc	realloc
	#define _fmemcpy	memcpy
	#define _fmemccpy	_memccpy
	#define _fmemset	memset

	#define _fstrcat	strcat
	#define _fstrncat	strncat
	#define _fstrcmp	strcmp
	#define _fstrchr	strchr
	#define _fstrcpy	strcpy
	#define _fstrdup	strdup
	#define _fstricmp	_stricmp
	#define _fstrlen	strlen
	#define _fstrncmp	strncmp
	#define _fstrncpy	strncpy
	#define _fstrnicmp	_strnicmp
	#define _fstrtok	strtok
	#define _fstrrchr	strrchr
	#define _fstrpbrk	strpbrk
	#define _fstrspn	strspn
	#define _fstrstr	strstr
	#define _fstrlwr	_strlwr


    #define READ  OF_READ
    #define WRITE OF_WRITE
    #define READ_WRITE OF_READWRITE

//------------------------------------------------------------------
#endif
