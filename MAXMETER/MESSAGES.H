// $Header:   P:/PVCS/MAX/MAXMETER/MESSAGES.H_V   1.2   27 Feb 1996 12:37:06   PETERJ  $
// Messages for MAX 8 MAXmeter.exe
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
#ifdef LANG_GR
// German
//------------------------------------------------------------------

EXTERN LPSTR szMsg_Select
    DEFVAL ( "Sie müssen mindestens ein Anzeige-Element auswählen!" ); 

EXTERN LPSTR szMsg_App
    DEFVAL ( "MAXmeter" );

//------------------------------------------------------------------
// Menu Entries
//------------------------------------------------------------------
EXTERN LPSTR szM_Config
    DEFVAL( "E&instellungen..." );

EXTERN LPSTR szM_Font
    DEFVAL( "Schrift&art..." );

EXTERN LPSTR szM_Over
    DEFVAL( "Üb&erblick" );

EXTERN LPSTR szM_Search
    DEFVAL( "&Hilfethema suchen..." );

EXTERN LPSTR szM_TechS
    DEFVAL( "&Technischer Kundendienst" );

EXTERN LPSTR szM_About
    DEFVAL( "Inf&o über MAXmeter..." );

//------------------------------------------------------------------
// these are the WinHelp keys.
// they MUST match the topics in the Help File.
//------------------------------------------------------------------
EXTERN LPSTR szHKEY_MOver
    DEFVAL( "MAXmeter - Überblick" );
    
EXTERN LPSTR szHKEY_TechS
    DEFVAL( "Kundendienst in Deutschland" );

//------------------------------------------------------------------
#else
// English
//------------------------------------------------------------------

EXTERN LPSTR szMsg_Select
    DEFVAL ( "You must select at least one item to display!" ); 

EXTERN LPSTR szMsg_App
    DEFVAL ( "MAXmeter" );

//------------------------------------------------------------------
// Menu Entries
//------------------------------------------------------------------
EXTERN LPSTR szM_Config
    DEFVAL( "Co&nfigure..." );

EXTERN LPSTR szM_Font
    DEFVAL( "&Font..." );

EXTERN LPSTR szM_Over
    DEFVAL( "&Overview" );

EXTERN LPSTR szM_Search
    DEFVAL( "&Search for Help on..." );

EXTERN LPSTR szM_TechS
    DEFVAL( "&Technical Support" );

EXTERN LPSTR szM_About
    DEFVAL( "&About MAXmeter..." );

//------------------------------------------------------------------
// these are the WinHelp keys.
// they MUST match the topics in the Help File.
//------------------------------------------------------------------
EXTERN LPSTR szHKEY_MOver
    DEFVAL( "MAXmeter Overview" );
    
EXTERN LPSTR szHKEY_TechS
    DEFVAL( "Technical Support" );

//------------------------------------------------------------------
#endif

