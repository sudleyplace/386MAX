// $Header:   P:/PVCS/MAX/INCLUDE/STATRES.H_V   1.1   23 May 1996 13:28:26   HENRY  $
//
// STATRES.H - Resource IDs used by STATUTIL
//
// Copyright (C) 1996 Qualitas, Inc.  All rights reserved.
//
// The range 29500-29999 is reserved for use by resource-using
// code in the STATUTIL project.  No resources are defined; that
// is the responsibility of the application.  This file needs to
// be included in the application's .RC files.

#ifndef _STATRES_INCLUDED
#define	_STATRES_INCLUDED

// IDD_STAT_* dialog IDs
#define	IDD_STAT_SPLASH		29500	// Splash screen "dialog"
#define	IDD_STAT_BLUESCREEN	29501	// Blue screen "dialog" (no controls)

// IDC_STAT_* control IDs
#define	IDC_STAT_SPLASHBMP	29550	// Splash screen static control

// IDB_STAT_* bitmap IDs
#define	IDB_STAT_SPLASHSCRN	29600	// Splash screen bitmap

// IDS_STAT_* string IDs
#define	IDS_STAT_BADDIRNAME	29650	// Dir name won't work
#define	IDS_STAT_BADDIRATTR	29651	// Attributes are in the set {RHS}

#define	STATRES_END			29999

#endif

