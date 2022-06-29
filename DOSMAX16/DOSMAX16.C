//' $Header:   P:/PVCS/MAX/DOSMAX16/DOSMAX16.C_V   1.1   03 Nov 1995 15:05:10   BOB  $
/**********************************************************************/
/*                                                                    */
/*    DOSMAX16.C -- 16-bit interface module for Universal Thunk       */
/*                  access to DOSMAX32.DLL                            */
/*                                                                    */
/**********************************************************************/

#include <windows.h>

/* Define W32SUT_16 to get the 16-bit declarations from w32sut.h: */

#define W32SUT_16                // indicate 16-bit side of interface
#include <w32sut.h>              // from \mstools\win32s\ut on CD

#include <pif95.h>
#include <dosmax2.h>
#include <vmaxapi.h>            // 386MAX.VXD protected mode API

static HINSTANCE hInst;          // DLL's instance handle

/**********************************************************************/

/* Boilerplate initialization & termination routines for a 16-bit
   DLL: */

BOOL FAR PASCAL LibMain(HINSTANCE hInstance,
						WORD wDataSeg,
						WORD cbHeap,
						DWORD ignore)
{
	if (cbHeap)
		UnlockData(0);
	hInst = hInstance;
	return TRUE;			// i.e., OK to load this DLL
} // LibMain

void FAR PASCAL WEP(BOOL bSysExit)
{
} // WEP

/**********************************************************************/

/* Calls to the entry points in the real DOSMAX.DLL funnel through
   this interface procedure.

   The arguments are:

   data        Contains a 16:16 (far) pointer to the data area passed
               to the 32-bit interface function. In general, this
               data area contains translated values of arguments and
               structures.

   funcode     Contains an arbitrary 32-bit value. In this example,
               it specifies which function should be executed in the
               target DLL.

   The return value can be used for any purpose. Here, it turns into
   the eventual return value from the original 32-bit call.
*/

DWORD FAR PASCAL UT16Proc(LPVOID data,
						  DWORD funcode)
{
	typedef struct
	{
		int ELO,
			EHI;
	} L2I;

	///DebugBreak();

	switch (funcode)
    {                          // select function to perform
		/*--------------------------------------------------------------------*/
		/*	Function ORD_OpenProperties: 
				int WINAPI OpenProperties(LPCSTR lpszApp,
										  LPCSTR lpszPIF,
										  int hInf,
										  int flOpt).
			To step this function down, the thunk passes the address of a
			structure that points to the control string and the (translated)
			vector of arguments.
		*/
		
		case ORD_OpenProperties:
		{
			struct SDA_OP
			{
				LPCSTR  lpszApp;
				LPCSTR  lpszPIF;
				L2I		hInf;
				L2I		flOpt;
			} FAR *op = (struct SDA_OP FAR *) data;
 
			return OpenProperties(  op->lpszApp,
									op->lpszPIF,
									op->hInf.ELO,
									op->flOpt.ELO);
		}

	/*--------------------------------------------------------------------*/
	/* Function ORD_GetProperties:
			int WINAPI GetProperties(int hProps,
									LPCSTR lpszGroup,
									LPVOID lpProps,
									int cbProps,
									int flOpt)
	*/

		case ORD_GetProperties:
		{
			struct SDA_GP
			{
				L2I		hProps;
				LPCSTR  lpszGroup;
				LPVOID  lpProps;
				L2I		cbProps;
				L2I		flOpt;
			} FAR *gp = (struct SDA_GP FAR *) data;
 
			return GetProperties(gp->hProps.ELO,
								 gp->lpszGroup,
								 gp->lpProps,
								 gp->cbProps.ELO,
								 gp->flOpt.ELO);
		}
        
	/*--------------------------------------------------------------------*/
	/* Function ORD_SetProperties:
			int WINAPI SetProperties(int hProps,
									LPCSTR lpszGroup,
									const VOID FAR *lpProps,
									int cbProps,
									int flOpt)
	*/

		case ORD_SetProperties:
		{
			struct SDA_SP
			{
				L2I		hProps;
				LPCSTR  lpszGroup;
				const VOID FAR * lpProps;
				L2I		cbProps;
				L2I		flOpt;
			} FAR *sp = (struct SDA_SP FAR *) data;
 
			return SetProperties(sp->hProps.ELO,
								 sp->lpszGroup,
								 sp->lpProps,
								 sp->cbProps.ELO,
								 sp->flOpt.ELO);
		}
								 
	/*--------------------------------------------------------------------*/
	/* Function ORD_CloseProperties:
			int WINAPI CloseProperties(int hProps,
										int flOpt)
	*/

		case ORD_CloseProperties:
		{
			struct SDA_CP
			{
				L2I		hProps;
				L2I		flOpt;
			} FAR *cp = (struct SDA_CP FAR *) data;
			
			return CloseProperties( cp->hProps.ELO,
									cp->flOpt.ELO);
		}

	/*--------------------------------------------------------------------*/
	// Function ORD_ReadProperties
	//
	// Returns TRUE if successful, FALSE otherwise

		case ORD_ReadProperties:
		{
			int hProps, ret;
			struct SDA_RP
			{
				LPCSTR  lpszApp;
				LPCSTR  lpszPIF;
				L2I		hInf;
				L2I		flOpt1;			// Used by OpenProperties()
				LPCSTR  lpszGroup;
				LPVOID	lpProps;
				L2I		cbProps;
				L2I		flOpt2;			// Used by GetProperties()
				L2I		flOpt3;			// Used by CloseProperties()
			} FAR *rp = (struct SDA_RP FAR *) data;
 
			hProps = OpenProperties(rp->lpszApp,
									rp->lpszPIF,
									rp->hInf.ELO,
									rp->flOpt1.ELO);
			if (hProps)			// Returns handle if successful, NULL otherwise
			{
				ret = GetProperties( hProps,
									 rp->lpszGroup,
									 rp->lpProps,
									 rp->cbProps.ELO,
									 rp->flOpt2.ELO);
				if (ret == 0)	// Returns # bytes read if successful, zero otherwise
					ret = SetProperties( hProps,
										 rp->lpszGroup,
										 rp->lpProps,
										 rp->cbProps.ELO,
										 rp->flOpt2.ELO);
				if (NULL == CloseProperties(hProps, rp->flOpt3.ELO)
				 && ret != 0)
					return TRUE;
			}
			return FALSE;
		}

	/*--------------------------------------------------------------------*/
	// Function ORD_WriteProperties
	//
	// Returns TRUE if successful, FALSE otherwise

		case ORD_WriteProperties:
		{
			int hProps, ret;
			struct SDA_WP
			{
				LPCSTR  lpszApp;
				LPCSTR  lpszPIF;
				L2I		hInf;
				L2I		flOpt1;			// Used by OpenProperties()
				LPCSTR  lpszGroup;
				const VOID FAR * lpProps;
				L2I		cbProps;
				L2I		flOpt2;			// Used by SetProperties()
				L2I		flOpt3;			// Used by CloseProperties()
			} FAR *wp = (struct SDA_WP FAR *) data;
 
			hProps = OpenProperties(wp->lpszApp,
									wp->lpszPIF,
									wp->hInf.ELO,
									wp->flOpt1.ELO);
			if (hProps)			// Returns handle if successful, NULL otherwise
			{
				// SetProperties returns # bytes written if successful,
				// 0 otherwise.
				ret = SetProperties( hProps,
									 wp->lpszGroup,
									 wp->lpProps,
									 wp->cbProps.ELO,
									 wp->flOpt2.ELO);
				if (NULL == CloseProperties(hProps, wp->flOpt3.ELO)
				 && ret != 0)
					return TRUE;
			}
			return FALSE;
		}

	/*--------------------------------------------------------------------*/
	// Function ORD_GetDOSMAXInfo
	// Returns -1 if VxD not loaded
	//			0 if VxD loaded and DOSMAX=OFF
	//			1 ...					  =ON
		case ORD_GetDOSMAXInfo:
		{
			int (CALLBACK *lpfnVxD) (void) = NULL;
			#define VxD_NOT_PRES 0xFFFF
			
			_asm{
				push	es;				// Save registers
				push	di;				// ...
			
				xor		di,di;			// Start off at zero
				mov		es,di;			// ...
			
				mov		ax,0x1684;		// Get API entry function
				mov		bx,LoadHi_Device_ID; // Device ID
				int		0x2F;			// Request API service
										// If present, return ES:DI ==> VxD
				mov		word ptr lpfnVxD[0],di; // Save the address
				mov		word ptr lpfnVxD[2],es; // ...

				pop		di;				// Restore
				pop		es;				// ...
			}
			
			if (lpfnVxD)
			{
				// Ensure the VxD version is late enough
				_asm{
					mov		ax,VMAX_GetVer; // VxD function
				}
				
				if (((WORD) lpfnVxD()) < 0x0800) // If too early,
					return VxD_NOT_PRES;	// it's essentially not present
				
				_asm{
					mov		ax,VMAX_GetDOSMAXInfo; // VxD function
				}

				return lpfnVxD();			// Return the value
			}
			else
				return VxD_NOT_PRES;		// Mark as VxD not present
		}

	/*--------------------------------------------------------------------*/
		default:
		{
			char errmsg[128];
		
			wsprintf(errmsg, "Unknown function (index %ld) specified in call"
							 " to DOSMAX16.DLL Universal Thunk", funcode);
			MessageBox(NULL, errmsg, "ERROR", MB_ICONHAND | MB_OK);
			return 0;
		}
	} // End switch
} // UT16Proc
