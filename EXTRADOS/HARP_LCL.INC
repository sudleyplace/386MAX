;***************************************************************************

;-------------- Local flags ---------------------

@LCL_DD 	equ 8000h	; 1 = Loaded via Device Driver (0 if not)
@LCL_XREMOVE	equ 4000h	; Don't remove the temporary UMB
@LCL_XCMPSB	equ 2000h	; Skip CMPSB for DOS verification
@LCL_REL21	equ 1000h	; We have already released int21 (INSTALL=)
@LCL_CCOM	equ 0800h	; Move COMMAND.COM to High DOS
@LCL_ENVIRON	equ 0400h	; Move the master environment to High DOS
@LCL_NOPSP	equ 0200h	; Don't create a fake PSP
@LCL_TEST	equ 0100h	; Test for Compatibility (getsize)
@LCL_OFF	equ 0080h	; We have been turned off
@LCL_CMD_SHARE	equ 0040h	; We're asked to load SHARE into High DOS
@LCL_PROG_SHARE equ 0020h	; The current 4B program is SHARE
@LCL_EXE	equ 0010h	; Loaded program is an EXE program
@LCL_XENV	equ 0008h	; E = NOLOADHI has been requested
@LCL_DDO	equ 0004h	; OnTrack's DDO driver is present
@LCL_MODEL	equ 0002h	; MODEL= value found in profile
@LCL_DEBUG	equ 0001h	; Debugging support active

COMMENT |

Flag descriptions:

LCL_DD:     This falg is set by the Device Driver entrance code.  It
	    allows common subroutines to detect whether or not the code
	    was executed from within CONFIG.SYS or from the command line.

LCL_XREMOVE: This feature will allow the resident code to remain resident
	    in case it can not de-install successfully becasue someone has
	    hooked interrupt 21h after us.  This should not happen unless
	    we aren't the last INSTALL= program.

LCL_XCMPSB: This flag allows the user to specify the patch points in case
	    he/she is running on a version of DOS that we can not identify.

LCL_RESIZE: This flag has two meanings.  The flag is set in INIT_XMS if
	    the XMS driver si capable of supporting UMB resizing.  During
	    ALLOC_UMB, the flag is cleared after we determine the method
	    of allocating UMBs.  The flag is then set if we allocated a
	    huge UMB, and need to resize it at the same time that we are
	    going to remove the transient UMB.

LCL_CCOM:
LCL_ENVIRON:
LCL_NOPSP:
	    These flags are for moving COMMAND.COM and the master
	    environment to High DOS.

LCL_OFF:    This flag is set after we intercept interrupt 21h, function
	    4B00h.  In case we can't de-install, then future function
	    4B00s will not cause our code to activate.

LCL_TEST:   This flag is set via the /t command line option and is
	    instructs HARPO to enter a testing (or getsize) mode.  If set,
	    we will go resident as a character device so that MAXIMIZE
	    can query us (via IOCTL) and determine the size of each of
	    the sub-segments.

LCL_DEBUG:  This flag allows various interrupt 01s to become active, for
	    debugging.

|


