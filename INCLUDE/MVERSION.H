//' $Header:   P:/PVCS/MAX/INCLUDE/MVERSION.H_V   1.73   23 May 1997 13:36:00   BOB  $
//
// MVERSION.H - Version definitions for Max 8
// Included by component resource scripts.
//
// ------------------------------------------------------
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3
// ------------------------------------------------------

#include <maxnames.h>
#include <_lcldefs.h>					// Define BUILD_BETA, BUILD_ALPHA

// Check for required stuff
#ifndef VER_FILEDESCRIPTION_STR
#include <common.ver>					// From SDK
#endif

#ifndef VER_MODULE
#error VER_MODULE not defined
#endif

#ifndef VER_MODULE_STR
#error VER_MODULE_STR not defined
#endif

#define VER_MAJOR					8	// 1.xx.xxx.xxx
#define VER_MAJOR_STR				"8"
#define VER_MINOR					3	// x.0.xxx.xxx
#define VER_MINOR_STR				"03"
#define VER_BETA					4 // x.xx.001.xxx
#define VER_BETA_STR				"004"
// VER_MODULE and VER_MODULE_STR are defined in the component's resource script

#define VERSION_BETA	VER_BETA_STR "." VER_MODULE_STR
#if BUILD_BETA
#define VER_ALPHAFLAGS	VS_FF_PRIVATEBUILD
#define VER_BETAFLAGS	VS_FF_PRERELEASE
#define VERSION 		VER_MAJOR_STR "." VER_MINOR_STR "." VERSION_BETA BUILD_ALPHA
#else
#define VER_ALPHAFLAGS	0
#define VER_BETAFLAGS	0
#define VERSION 		VER_MAJOR_STR "." VER_MINOR_STR
#endif

#define VER_PRODUCTVERSION			VER_MAJOR,VER_MINOR,VER_BETA,VER_MODULE
#define VER_PRODUCTVERSION_STR		VERSION

#define VER_PRODUCTNAME_STR		MAX8PRODUCT
#define VER_LEGALCOPYRIGHT_YEARS	"1995-97"
#define VER_COMPANYNAME_STR		"Qualitas, Inc."
#define VER_COPYRIGHT1_STR			"Copyright \251 " VER_LEGALCOPYRIGHT_YEARS " " VER_COMPANYNAME_STR

#ifdef LANG_GR
#define VER_COPYRIGHT2_STR			"Alle Rechte vorbehalten."
#else
#define VER_COPYRIGHT2_STR			"GNU General Public License version 3."
#endif

#define VER_LEGALCOPYRIGHT_STR		VER_COPYRIGHT1_STR " " VER_COPYRIGHT2_STR
// Define a two-line version of the copyright for when we're low on space.
#define VER_LEGALCOPYRIGHT2_STR 	VER_COPYRIGHT1_STR "\n" VER_COPYRIGHT2_STR

#define VER_FILEFLAGSMASK			VS_FFI_FILEFLAGSMASK
#define VER_FILEFLAGS				(VER_ALPHAFLAGS|VER_BETAFLAGS)
#define VER_FILEOS					VOS_DOS_WINDOWS16

