// $Header:   P:/PVCS/MAX/MAXEDIT/MESSAGES.H_V   1.2   27 Feb 1996 12:34:58   PETERJ  $
// Messages for MAX 8 maxedit.exe
// Copyright (C) 1995 Qualitas, Inc. All Rights Reserved.

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

EXTERN LPSTR szMsg_NoMem
    DEFVAL( "Zu wenig Speicher verfügbar!" );

EXTERN LPSTR szMsg_CantAlloc
    DEFVAL( "Kann für den Editor keinen zusätzlichen Speicher erhalten." );

//------------------------------------------------------------------
// Help Keys. Text must match help topic exactly.
//------------------------------------------------------------------

 EXTERN LPSTR szHKEY_Over
    DEFVAL( "MAXedit - Überblick" );

EXTERN LPSTR szHKEY_TechS
    DEFVAL( "Kundendienst in Deutschland" );

//------------------------------------------------------------------
#else
// English
//------------------------------------------------------------------
EXTERN LPSTR szMsg_NoMem
    DEFVAL( "Out of memory" );

EXTERN LPSTR szMsg_CantAlloc
    DEFVAL( "Can't allocate additional memory for edit control." );

//------------------------------------------------------------------
// Help Keys. Text must match help topic exactly.
//------------------------------------------------------------------

 EXTERN LPSTR szHKEY_Over
    DEFVAL( "MAXedit Overview" );

EXTERN LPSTR szHKEY_TechS
    DEFVAL( "Technical Support" );

//------------------------------------------------------------------
#endif
