;' $Header:   P:/PVCS/MAX/INC/PNP.INV   1.1   21 Nov 1995 18:17:56   BOB  $
;
; (C) Copyright 1995 Qualitas, Inc.  GNU General Public License version 3.
;
; PNP.INC
;
; Plug 'n Play Equates and Structures
;

; PnP Presence Structure and Equates

@PnP_SIG equ	<'$PnP'>        ; Signature
@PnP_SIGREV equ 'PnP$'          ; ...       reversed (for dword comparisons)


PnP_STR struc			; New (longer) PnP struc

PnP_SIG db	@PnP_SIG	; 00:  Signature
PnP_VER db	10h		; 04:  Version:  high-order nibble, low-order nibble
				;		 major, 	    minor
				;		 BCD value of spec:  10h = 1.0
PnP_LEN db	size PnP_STR	; 05:  Byte length of struc
PnP_FLAG dw	?		; 06:  Flags:  see PnPFLAG_REC for details
PnP_SUM db	?		; 08:  Checksum of PnP_STR

; Up to this point the new and old strucs are identical

PnP_ENF dd	?		; 09:  Event notification flag address
PnP_RMVEC dd	?		; 0D:  RM entry point
PnP_PMOFF dw	?		; 11:  PM USE16 entry point offset
PnP_PMCS dd	?		; 13:  PM USE16 code segment base address
PnP_OEM dd	?		; 17:  OEM device identifier
PnP_RMDS dw	?		; 1B:  RM data segment
PnP_PMDS dd	?		; 1D:  PM USE16 data segment base address

PnP_STR ends


PnP2_STR struc			; Old (shorter) PnP struc

	db	@PnP_SIG	; 00:  Signature
	db	10h		; 04:  Version:  high-order nibble, low-order nibble
				;		 major, 	    minor
				;		 BCD value of spec:  10h = 1.0
	db	size PnP2_STR	; 05:  Byte length of struc
	dw	?		; 06:  Flags:  see PnPFLAG_REC for details
	db	?		; 08:  Checksum of PnP_STR

; Up to this point the new and old strucs are identical

PnP2_RMVEC dd	?		; 09:  RM entry point
PnP2_PMOFF dw	?		; 0D:  PM USE16 entry point offset
PnP2_PMCS dd	?		; 0F:  PM USE16 code segment base address

PnP2_STR ends


PnPFLAG_REC record $PnPFLAG_ENM:2

@PnPFLAG_ENM_NS   equ 00b	; Event notification is not supported
@PnPFLAG_ENM_POLL equ 01b	; Event notification is handled through polling


; PnP System Device Node Strcture

PnP_DEV_STR struc

PnP_DEV_LEN dw	?		; Size of the structure
PnP_DEV_NODE db ?		; Node #
PnP_DEV_PROD dd ?		; Compressed product ID
PnP_DEV_TYPE db 3 dup (?)	; Device type code
PnP_DEV_FLAG dw ?		; Attributes:  see PnPDEVFLG_REC for details
PnP_DEV_REST db ?		; The rest of the data

; Allocated resource configuration descriptor block:  variable length

; Possible resource configuration descriptor block:  variable length

; Compatible device identifiers:  variable length

PnP_DEV_STR ends

PnPDEVFLAG_REC record			\
		$PnP_DEVFLAG_CFG:2,	\
		$PnP_DEVFLAG_REM:1,	\
		$PnP_DEVFLAG_DOCK:1,	\
		$PnP_DEVFLAG_IPL:1,	\
		$PnP_DEVFLAG_INP:1,	\
		$PnP_DEVFLAG_OUT:1,	\
		$PnP_DEVFLAG_XCFG:1,	\
		$PnP_DEVFLAG_XDIS:1

@PnP_DEVFLAG_CFG_NBO	equ 00b ; Device can be configured for next boot only
@PnP_DEVFLAG_CFG_RT	equ 01b ; ...			   at runtime
;;;;;DEVFLAG_CFG_	equ 10b ; (Reserved)
@PnP_DEVFLAG_CFG_RTO	equ 11b ; Device can be configured at runtime only

@PnP_DEVFLAG_CFG equ	(mask $PnP_DEVFLAG_CFG)  ; 0180: Device configure state
						 ; See @PnP_DEVFLAG_CFG_xxx for details
@PnP_DEVFLAG_REM equ	(mask $PnP_DEVFLAG_REM)  ; 0040: Device is removable
@PnP_DEVFLAG_DOCK equ	(mask $PnP_DEVFLAG_DOCK) ; 0020: Device is docking station
@PnP_DEVFLAG_IPL equ	(mask $PnP_DEVFLAG_IPL)  ; 0010: Device can be primary IPL
@PnP_DEVFLAG_INP equ	(mask $PnP_DEVFLAG_INP)  ; 0008: Device is primary input
@PnP_DEVFLAG_OUT equ	(mask $PnP_DEVFLAG_OUT)  ; 0004: Device is primary output
@PnP_DEVFLAG_XCFG equ	(mask $PnP_DEVFLAG_XCFG) ; 0002: Device cannot be configured
@PnP_DEVFLAG_XDIS equ	(mask $PnP_DEVFLAG_XDIS) ; 0001: Device cannot be disabled


; Small Resource Data type record

PnP_SRES_REC record \
		$PnP_SRES_TYPE:1, \
		$PnP_SRES_NAME:4, \
		$PnP_SRES_LEN:3

@PnP_SRES_NAME_VER equ	01h	; Version #
@PnP_SRES_NAME_LID equ	02h	; Logical device ID
@PnP_SRES_NAME_CID equ	03h	; Compatible device ID
@PnP_SRES_NAME_IRQ equ	04h	; IRQ format
@PnP_SRES_NAME_DMA equ	05h	; DMA format
@PnP_SRES_NAME_SDF equ	06h	; Start dependent function
@PnP_SRES_NAME_EDF equ	07h	; End ...
@PnP_SRES_NAME_IO  equ	08h	; I/O port descriptor
@PnP_SRES_NAME_IOF equ	09h	; Fixed location I/O port descriptor
;;;;_SRES_NAME_    equ	0Ah	; (Reserved)
;;;;_SRES_NAME_    equ	0Bh	; (Reserved)
;;;;_SRES_NAME_    equ	0Ch	; (Reserved)
;;;;_SRES_NAME_    equ	0Dh	; (Reserved)
@PnP_SRES_NAME_VEN equ	0Eh	; Vendor defined
@PnP_SRES_NAME_EOT equ	0Fh	; End tag


; Small Resource IRQ format

PnP_IRQ_STR struc

PnP_IRQ_MASK dw ?		; IRQ mask bits
PnP_IRQ_INFO db ?		; Information (see PnP_IRQ_REC for details)

PnP_IRQ_STR ends

PnP_IRQ_REC record  \
		$PnP_IRQ_LOLVL:1, \
		$PnP_IRQ_HILVL:1, \
		$PnP_IRQ_LOEDG:1, \
		$PnP_IRQ_HIEDG:1


; Small Resource DMA format

PnP_DMA_STR struc

PnP_DMA_MASK db ?		; DMA channel mask bits
PnP_DMA_INFO db ?		; Information (see PnP_DMA_REC for details)

PnP_DMA_STR ends

PnP_DMA_REC record  \
		$PnP_DMA_CHAN:2,  \
		$PnP_DMA_WMODE:1, \
		$PnP_DMA_BMODE:1, \
		$PnP_DMA_BUSM:1,  \
		$PnP_DMA_TRANS:2


; Large Resource Data type record

PnP_LRES_REC record \
		$PnP_LRES_TYPE:1, \
		$PnP_LRES_NAME:7

@PnP_LRES_NAME_M16  equ 01h	; 16-bit memory range descriptor
@PnP_LRES_NAME_IDA  equ 02h	; Identifier string (ANSI)
@PnP_LRES_NAME_IDU  equ 03h	; Identifier string (Unicode)
@PnP_LRES_NAME_VEN  equ 04h	; Vendor defined
@PnP_LRES_NAME_M32  equ 05h	; 32-bit memory range descriptor
@PnP_LRES_NAME_M32F equ 06h	; 32-bit fixed location memory range descriptor
@PnP_LRES_NAME_MAX  equ 06h	; Maximum defined value


; Large Resource 32-bit Fixed Memory format

PnP_M32F_REC record \
		$PnP_M32F_ROM:1, \
		$PnP_M32F_SHD:1, \
		$PnP_M32F_CTL:2, \
		$PnP_M32F_SUP:1, \
		$PnP_M32F_CAC:1, \
		$PnP_M32F_WRT:1



; PnP function codes

@PnP_GET_NUM_NODES  equ 00h	; Get # nodes
@PnP_GET_DEV_NODE   equ 01h	; Get info for a device node
@PnP_SET_DEV_NODE   equ 02h	; Set ...
@PnP_GET_EVENT	    equ 03h	; Get Event Type
@PnP_SEND_MSG	    equ 04h	; Send Message
@PnP_GET_DOCK_INFO  equ 05h	; Get docking station info
;;;;		    equ 06h	; Reserved
;;;;		    equ 07h	; Reserved
;;;;		    equ 08h	; Reserved
@PnP_SET_STATIC_RES equ 09h	; Set statically allocated resources
@PnP_GET_STATIC_RES equ 0Ah	; Get statically allocated resources
@PnP_GET_APM_ID_TAB equ 0Bh	; Get APM ID table
@PnP_GET_ISA_CFG    equ 40h	; Get ISA configuration structure
@PnP_GET_ESCD_INFO  equ 41h	; Get ESCD info
@PnP_GET_ESCD	    equ 42h	; Get ESCD data
@PnP_SET_ESCD	    equ 43h	; Set ESCD data

; BIOS Boot Specification Functions

@PnP_GET_VERSION    equ 60h	; Get Version #
@PnP_GET_DEV_CNT    equ 61h	; Get Device Count
@PnP_GET_PRIORITY   equ 62h	; Get Priority and Table
@PnP_SET_PRIORITY   equ 63h	; Set Priority
@PnP_GET_IPLDEV     equ 64h	; Get IPL Device from Last Boot
@PnP_GET_BOOT1ST    equ 65h	; Get Boot First
@PnP_SET_BOOT1ST    equ 66h	; Set Boot First


; PnP Message Codes

@PnP_MSG_OK	equ	0	; Continue with sequence which initiated the event
@PnP_MSG_ABORT	equ	1	; Abort the ...


; PnP BIOS Boot Specification Equates

@PnP_BBS_IPL	equ	0	; IPL-relative
@PnP_BBS_BCV	equ	1	; BCV-relative


; PnP function return values

@PnP_SUCCESS	 equ	0	; Successful
@PnP_ERR_UNKFN	 equ	81h	; Unknown function
@PnP_ERR_NOTSUP  equ	82h	; Function not supported
@PnP_ERR_INVHNDL equ	83h	; Invalid handle
@PnP_ERR_BADPARM equ	84h	; Bad parameter
@PnP_ERR_SETFAIL equ	85h	; Set failed
@PnP_ERR_NOEVENT equ	86h	; Events not pending
@PnP_ERR_SYSXLCK equ	87h	; System not locked
@PnP_ERR_NOISA	 equ	88h	; No ISA PnP cards
@PnP_ERR_NODOCK  equ	89h	; Unable to determine dock capabilities
@PnP_ERR_NOBATT  equ	8Ah	; Config changed failed - no battery
@PnP_ERR_RESCONF equ	8Bh	; Config changed failed - resource conflict
@PnP_ERR_TINYBUF equ	8Ch	; Buffer too small
@PnP_ERR_ESCD	 equ	8Dh	; Use ESCD support
@PnP_ERR_NOMSG	 equ	8Eh	; Message not supported
@PnP_ERR_HARDERR equ	8Fh	; Hardware error


