// $Header:   P:/PVCS/MAX/QUILIB/DPMICTST.CPV   1.0   28 Dec 1995 17:03:34   HENRY  $
//
// DPMICTST.CPP - Test program for DPMI_CRC.ASM
//
// Copyright (C) 1995 Qualitas, Inc.  All rights reserved
//

#include <windows.h>

#include <bioscrc.h>

extern "C" int PASCAL
WinMain(	HINSTANCE hInstance,
			HINSTANCE hPrevInstance,
			LPSTR lpCmdLine,
			int nCmdShow ) {

	int nMCA = DPMI_Is_MCA();
	int nIBM = DPMI_Is_IBM();
	int nBCF = DPMI_Is_BCF();
	DWORD dwCRC, dwBIOS_Start, dwBIOS_len;
	char szMsg[ 256 ];

	dwBIOS_Start = 0xf0000;
	dwBIOS_len = 0x10000;
	if (nBCF) {
		dwBIOS_Start = 0xe0000;
		dwBIOS_len = 0x20000;
	}
	dwCRC = DPMI_BCRC( dwBIOS_Start, dwBIOS_len );
	wsprintf( szMsg, "CRC at %04lx = %04lx %s\nIs_MCA=%d\nIs_IBM=%d\nIs_BCF=%d",
				dwBIOS_Start >> 4, dwCRC & 0xffffL,
				(LPCSTR)((dwCRC >> 16) ? "Invalid" : "Valid"),
				nMCA, nIBM, nBCF );
	MessageBox( NULL, szMsg, "CRC result", MB_OK );

	return 0;

} // WinMain()

