/*' $Header:   P:/PVCS/MAX/QMT/MAKEBOOT.H_V   1.0   05 Sep 1995 16:56:24   HENRY  $ */
/************************************************************************
 *																						*
 * (C) Copyright 1993 Qualitas, Inc.  GNU General Public License version 3.			*
 *																						*
 * MAKEBOOT.H																		*
 *																						*
 * Include file for MAKEBOOT.COM														*
 *																						*
 ************************************************************************/


#define FAR	_far
#define NEAR	_near
#define  HUGE  _huge

#define TRUE	1
#define FALSE	0

typedef int					HFILE;
typedef unsigned char	BYTE , NEAR *PBYTE, HUGE *HPBYTE;
typedef void _huge		*HPVOID;
typedef unsigned int		WORD , NEAR *PWORD, HUGE *HPWORD;
typedef unsigned long	DWORD, NEAR *PDWORD, HUGE *HPDWORD;

#define I24_IGNORE		0x0000
#define I24_RETRY			0x0001
#define I24_TERM_PROG	0x0002
#define I24_TERM_FUNC	0x0003
