// $Header:   P:/PVCS/MAX/MAXCTRL/MESSAGES.H_V   1.2   27 Feb 1996 12:31:02   PETERJ  $
// Messages for MAX 8 Toolbox.exe
// Copyright (C) 1995 Qualitas, Inc. GNU General Public License version 3.

#ifdef EXTERN
    #undef EXTERN
#endif

#ifdef DEFVAL
    #undef DEFVAL
#endif

#ifdef SETUP_MSG_DEFVARS
    #define EXTERN
    #define DEFVAL(v) =v
#else
    #define EXTERN extern
    #define DEFVAL(v)
#endif

//------------------------------------------------------------------
// not for translation
//------------------------------------------------------------------
EXTERN LPSTR szMsg_Title   DEFVAL( "Toolbox" );
EXTERN LPSTR szMsg_DOSMAX  DEFVAL( "DOSMAX" );
EXTERN LPSTR szMsg_Stacks  DEFVAL( "Stacks" );
//------------------------------------------------------------------


//------------------------------------------------------------------
#ifdef LANG_GR
// German
//------------------------------------------------------------------
EXTERN LPSTR szMsg_INICorrupt 
    DEFVAL( "QMAX.INI ist beschädigt oder die Datei fehlt. Korrigieren Sie den Fehler und rufen Sie die Toolbox erneut auf.");

EXTERN LPSTR szMsg_StksHi 
    DEFVAL( "DOSMAX erfordert ein Hochladen der DOS STACKS. Möchten Sie STACKS-Hochladen aktivieren?" );

EXTERN LPSTR szMsg_NoStks
    DEFVAL( "Sind DOS Stacks nicht hochgeladen, können Sie DOSMAX nicht anwenden." );

EXTERN LPSTR szMsg_UseMDA
    DEFVAL( "MDA nutzen" );

EXTERN LPSTR szMsg_VGAMDA
    DEFVAL( "VGASWAP erfordert die Nutzung des MDA-Speicherbereiches. Möchten Sie VGASWAP ausschalten?" );

EXTERN LPSTR szMsg_Uninstall
    DEFVAL( "Entfernen" );

EXTERN LPSTR szMsg_UnOK
    DEFVAL( "Sie haben sich zum Entfernen einiger oder sämtlicher Qualitas MAX Komponenten entschieden. Damit ist Qualitas MAX möglicherweise nicht mehr in vollem Umfang funktionsfähig. Möchten Sie die Aktion fortsetzen?" );

EXTERN LPSTR szMsg_HiMem
    DEFVAL( "Entfernen des Qualitas MAX hinterläßt Ihr System ohne Memory Management. Für Windows müssen Sie mindestens HIMEM.SYS installieren." );

EXTERN LPSTR szMsg_Cancel
    DEFVAL( "Abbrechen" );

EXTERN LPSTR szMsg_Changes
    DEFVAL( "Sie haben Änderungen vorgenommen - möchten Sie diese verwerfen?" );

EXTERN LPSTR szMsg_Editing
    DEFVAL( "Bearbeite:" );

//------------------------------------------------------------------
// Help Keys...These must match help text exactly.
//------------------------------------------------------------------
EXTERN LPSTR szHKEY_TO
    DEFVAL( "Toolbox - Überblick" );

EXTERN LPSTR szHKEY_TS
    DEFVAL( "Kundendienst in Deutschland" );

//------------------------------------------------------------------
// menu strings
//------------------------------------------------------------------

EXTERN LPSTR szM_Over
    DEFVAL( "Üb&erblick" );

EXTERN LPSTR szM_Search
    DEFVAL( "&Hilfethema suchen..." );

EXTERN LPSTR szM_TechS
    DEFVAL( "&Technischer Kundendienst" );

EXTERN LPSTR szM_About
    DEFVAL( "Inf&o über Toolbox..." );

//------------------------------------------------------------------
#else
// English
//------------------------------------------------------------------
EXTERN LPSTR szMsg_INICorrupt 
    DEFVAL( "QMAX.INI is corrupted or missing.  Please correct it and run Toolbox again.");

EXTERN LPSTR szMsg_StksHi 
    DEFVAL( "DOSMAX requires loading DOS STACKS high. Do you want to enable STACKS high?");

EXTERN LPSTR szMsg_NoStks
    DEFVAL( "If DOS Stacks are not loaded high, you will not be able to use DOSMAX." );

EXTERN LPSTR szMsg_UseMDA
    DEFVAL( "Use MDA" );

EXTERN LPSTR szMsg_VGAMDA
    DEFVAL( "VGASWAP requires using the MDA. Do you want to disable VGASWAP?" );

EXTERN LPSTR szMsg_Uninstall
    DEFVAL( "Uninstall" );

EXTERN LPSTR szMsg_UnOK
    DEFVAL( "You have elected to Uninstall some or all components of Qualitas MAX.  By Uninstalling these items, you may be removing items essential to the operation of Qualitas MAX.  Do you wish to continue?" );

EXTERN LPSTR szMsg_HiMem
    DEFVAL( "Uninstalling Qualitas MAX leaves your system without memory management.  You must load HIMEM.SYS for Windows to function." );

EXTERN LPSTR szMsg_Cancel
    DEFVAL( "Cancel" );

EXTERN LPSTR szMsg_Changes
    DEFVAL( "You have made changes; do you wish to discard these changes?" );

EXTERN LPSTR szMsg_Editing
    DEFVAL( "Editing:" );

//------------------------------------------------------------------
// Help Keys...These must match help text exactly.
//------------------------------------------------------------------
EXTERN LPSTR szHKEY_TO
    DEFVAL( "Toolbox overview" );

EXTERN LPSTR szHKEY_TS
    DEFVAL( "Technical Support" );

//------------------------------------------------------------------
// menu strings
//------------------------------------------------------------------

EXTERN LPSTR szM_Over
    DEFVAL( "&Overview" );

EXTERN LPSTR szM_Search
    DEFVAL( "&Search for Help on..." );

EXTERN LPSTR szM_TechS
    DEFVAL( "&Technical Support" );

EXTERN LPSTR szM_About
    DEFVAL( "&About Toolbox..." );

//------------------------------------------------------------------
#endif
