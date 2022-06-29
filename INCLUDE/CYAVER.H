// $Header:   P:/PVCS/MAX/INCLUDE/CYAVER.H_V   1.8   05 May 1997 11:06:14   PETERJ  $
//
// CYAVER.H - component version info file
//
// ---------------------------------------------------------
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved
// ---------------------------------------------------------
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

#define VER_MAJOR					1	// 1.xx.xxx.xxx
#define VER_MAJOR_STR				"1"
#define VER_MINOR					51	// x.0.xxx.xxx
#define VER_MINOR_STR				"51"
#define VER_BETA					001 // x.xx.001.xxx
#define VER_BETA_STR				"001"
// VER_MODULE and VER_MODULE_STR are defined in the component's resource script

#ifdef TLOCK
#define VER_TL  		"TL"
#else
#define VER_TL
#endif

#define VERSION_BETA	VER_BETA_STR "." VER_MODULE_STR
#if BUILD_BETA
#define VER_ALPHAFLAGS	VS_FF_PRIVATEBUILD
#define VER_BETAFLAGS	VS_FF_PRERELEASE
#define VERSION 		VER_MAJOR_STR "." VER_MINOR_STR VER_TL "." VERSION_BETA BUILD_ALPHA
#else
#define VER_ALPHAFLAGS	0
#define VER_BETAFLAGS	0
#define VERSION 		VER_MAJOR_STR "." VER_MINOR_STR VER_TL
#endif

#define VER_PRODUCTVERSION			VER_MAJOR,VER_MINOR,VER_BETA,VER_MODULE
#define VER_PRODUCTVERSION_STR		VERSION

#define VER_PRODUCTNAME_STR 		"C.Y.A."
#define VER_LEGALCOPYRIGHT_YEARS	"1996"
#define VER_COMPANYNAME_STR 		"Qualitas, Inc."
#define VER_COPYRIGHT1_STR			"Copyright \251 " VER_LEGALCOPYRIGHT_YEARS " " VER_COMPANYNAME_STR

#ifdef LANG_GR
#define VER_COPYRIGHT2_STR			"Alle Rechte vorbehalten."
#elif LANG_FR
#define VER_COPYRIGHT2_STR			"All rights reserved."
#else
#define VER_COPYRIGHT2_STR			"All rights reserved."
#endif

#define VER_LEGALCOPYRIGHT_STR		VER_COPYRIGHT1_STR " " VER_COPYRIGHT2_STR
// Define a two-line version of the copyright for when we're low on space.
#define VER_LEGALCOPYRIGHT2_STR		VER_COPYRIGHT1_STR "\n" VER_COPYRIGHT2_STR

#define VER_FILEFLAGSMASK			VS_FFI_FILEFLAGSMASK
#define VER_FILEFLAGS				(VER_ALPHAFLAGS|VER_BETAFLAGS)
#define VER_FILEOS					VOS_DOS_WINDOWS16
