// $Header:   P:/PVCS/MAX/MAXSETUP/SETUPDOS.C_V   1.3   25 Oct 1995 11:15:36   PETERJ  $
// Stub to run INSTALL when SETUP is run from DOS
// Written by Rex Conn 8/95 for Qualitas Inc.

#include <stdio.h>
#include <stdlib.h>
#include <process.h>


int main(int argc, char **argv)
{
	register char *pchName;
	char szInstallName[128];

	// can't run SETUP / INSTALL from a Windows DOS box!
// FIXME!
_asm {
	mov	ax, 160Ah
	int	2Fh
	cmp	ax, 0
	jnz	NotDOSBox
}
	printf("SETUP can't be run from a Windows DOS session.  Exit the DOS session\n");
	printf("and run SETUP from Windows or DOS.\n");
	_exit(1);

NotDOSBox:
	// get name of setupdos.ovl (in same directory as MAXSETUP)
	strcpy( szInstallName, argv[0] );
	pchName = szInstallName + strlen( szInstallName );

	while (--pchName > szInstallName) {
		if ((*pchName == '\\') || (*pchName == '/')) {
			strcpy( pchName + 1, "SETUPDOS.OVL" );
			break;
		}
	}

	argv[0] = szInstallName;
	_execv( szInstallName, argv );

	printf("Can't find SETUPDOS.OVL - make sure it is in the same directory\n");
	printf("as SETUP.EXE, or run SETUP.EXE from Windows.\n");
	_exit(1);
}

