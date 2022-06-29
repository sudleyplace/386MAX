;' $Header:   P:/PVCS/MAX/386MAX/QMAX@RET.OEV   1.2   27 Dec 1995 17:11:32   HENRY  $

; QMAX_OEM.RET	; Retail Version of 386MAX

; These equates control how 386MAX is assembled

@OEM_EMS	 equ 1	; 1 = Allow EMS support
@OEM_BKFILL	 equ 1	; 1 = Allow backfill (0-640)
@OEM_LOFILL	 equ 1	; 1 = Allow low DOS memory fill (640-704)
@OEM_HIFILL	 equ 1	; 1 = Allow high DOS memory fill
@OEM_DMA	 equ @OEM_EMS or @OEM_BKFILL or @OEM_LOFILL or @OEM_HIFILL
@OEM_MISC	 equ 1	; 1 = Allow miscellaneous features (PRO=/EEMS/IOP=)
@OEM_DEBUG	 equ 1	; 1 = Allow debugging features
@OEM_SOFT	 equ 1	; 1 = OEM software companies
@OEM_WTK	 equ 1	; 1 = Supports Weitek
@OEM_XMS	 equ 1	; 1 = Supports XMS
@OEM_VCPI	 equ 1	; 1 = Supports VCPI
@OEM_SIZE	 equ 1	; 1 = Display size error listing if insufficient memory
@OEM_EEMS	 equ 0	; 1 = Supports EEMS
@OEM_ACCEL	 equ 0	; 1 = 386 accelarator card vendor
@OEM_INST	 equ 1	; 1 = INSTALL program supported
@OEM_STATE	 equ 0	; 1 = Initial state is AUTO; 0 = initial state is ON
@OEM_VIDMAC	 equ 0	; 1 = Allow CHECK_VIDMAC
@OEM_BCF	 equ 1	; 1 = Allow BCF command
@OEM_SRAM	 equ 1	; 1 = Allow SHADOWRAM keyword
@OEM_BETA	 equ 0	; 1 = Assemble in beta version text
@OEM_VDS	 equ 1	; 1 = Allow Virtual DMA Services
@OEM_EMSLIST	 equ 0	; 1 = Display EMS usage in LIST screen
@OEM_WIN3	 equ 1	; 1 = Supports Windows 3.0
@OEM_FLEX	 equ 1	; 1 = Supports FLEXFRAME
@OEM_DPMI	 equ 1	; 1 = Supports DPMI version 0.9
@OEM_FLEXROM	 equ 1	; 1 = Supports FlexROM and VGASWAP
@OEM_INTERNAL	 equ 0	; 1 = Supports experimental features
@OEM_CPQCUT	 equ 1	; 1 = Supports Compaq Cut Table
@OEM_HARPO	 equ 1	; 1 = Supports subsegment table
@OEM_VIRTUALMEM  equ 1	; 1 = Supports Virtual Memory

@OEM_HILOAD	 equ 1	; 1 = Allow LOADHIGH/LOADLOW in utility program
@OEM_AUTO	 equ 1	; 1 = Allow AUTO/ON/OFF      in utility program
@OEM_TIMEMEM	 equ 1	; 1 = Allow TIMEMEM	     in utility program
@OEM_ROMSCAN	 equ 1	; 1 = Allow ROMSCAN	     in utility program
@OEM_MAPMEM	 equ 1	; 1 = Allow MAPMEM	     in utility program
@OEM_MAPDEV	 equ 1	; 1 = Allow MAPDEV	     in utility program
@OEM_MAPEMS	 equ 1	; 1 = Allow MAPEMS	     in utility program
@OEM_LIST	 equ 1	; 1 = Allow LIST	     in utility program

@OEM_SUBT_386	 equ 1

	 include QMAX_OEM.ALL

@OEM_SYS	 equ @OEMSYS_RET
@OEM_FILE	 equ <'386MAX'>         ; File name
@OEM_IOCTL	 equ <'386MAX'>         ; IOCTL name
@OEM_TEXT	 equ <'Qualitas MAX'>   ; File text
@OEM_U2TEXT	 equ <'386UTIL'>        ; Name of UTIL2

