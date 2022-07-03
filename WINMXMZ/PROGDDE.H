// $Header:   P:/PVCS/MAX/WINMXMZ/PROGDDE.H_V   1.1   13 Oct 1995 11:56:42   HENRY  $
// PROGDDE.H - prototypes for PROGDDE.CPP.
// Copyright (C) 1995 Qualitas, Inc.  GNU General Public License version 3.

#ifdef __cplusplus
extern "C" {
#endif

    // delete Program manager group.
BOOL CALLBACK DeletePMGroup( HINSTANCE hInst, LPSTR lpszGroup );

    // send command to Progman via DDE.
BOOL SendPMExecCmd( HINSTANCE hInst, LPSTR lpszCmd);


#ifdef __cplusplus
}
#endif // __cplusplus
