//' $Header:   P:/PVCS/MAX/INC/VMAXAPI.H_V   1.1   03 Nov 1995 15:05:48   BOB  $
/* vmaxapi.h - (C) Copyright 1992, 1993 Qualitas, Inc.	GNU General Public License version 3. */

#define LoadHi_Device_ID	0x001C
#define DOSMAX_Device_ID	0x2402

// V86 mode 1684-style API provided by 386MAX.VXD
// Function codes are pushed on the stack
// N.B. These equates are copies of the ones in QMAXWIN3.INC

#define V86API_XMS		0001h	// Request XMS services
#define V86API_Util		0002h	// Request utility service
#define V86API_GetVer		0003h	// Return V86 API version in client AX

// Protected mode 1684-style API provided by 386MAX.VXD
// Function codes are passed in AX

#define VMAX_GetVer		0x0000	// No inputs
					// Returns PMAPI version in AX

#define VMAX_GetSwatVer 	0x0001	// No inputs
					// Returns version in AX
					// AX = 0 if not installed

#define VMAX_GetVMHandle	0x0002	// ... for the calling machine into EBX

#define VMAX_GetSysVMHandle	0x0003	// No inputs
					// Returns SysVMHandle in EBX

#define VMAX_GetVMInfo		0x0004	// ... into EAX, ECX, EDX
					// Translated into SHELL_GetVMInfo

#define VMAX_RegisterCallback	0x0005	// ES:BX ==> callback procedure
					// DX = selector of filename intercepts
					//	... in 386LOAD.CFG format
#define CFG_WARNFLAG	'W'             //      flag for trouble makers
#define CFG_FAILFLAG	'F'             //      flag for graphics pgms
					// Returns:
					// AX = 0 if successful

// The callback procedure must be prototyped as follows:
//	VOID FAR PASCAL CallBack(WORD wSelPerVMCB, DWORD lParam)
//	wSelPerVMCB is an LDT selector the procedure can use to access
//	the per VM data maintained by the VxD

#define VMAX_UnregisterCallback 0x0006	// ES:BX ==> callback procedure

#define VMAX_IgnoreModeSwitch	0x0007	// Ignore mode switch, VM handle in EBX

#define VMAX_Terminate		0x0008	// Terminate VM, handle in EBX

#define VMAX_GetTimeSliceInfo	0x0009	// EBX is VM handle
					// Returns:
					// EAX = CB_VM_Status flags
					// ECX = Foreground priority
					// EDX = Background priority
					// ESI = % of CPU time

#define VMAX_SetTimeSliceInfo	0x000A	// EBX is VM handle
					// Inputs:
					// EAX = CB_VM_Status flags
					// ECX = Foreground priority
					// EDX = Background priority

#define VMAX_SignalSemaphore	0x000B	// Release VM from semaphore block

#define VMAX_GetDOSMAXInfo	0x000C	// Get DOSMAX information

