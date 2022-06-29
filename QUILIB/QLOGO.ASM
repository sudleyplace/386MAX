;' $Header:   P:/PVCS/MAX/QUILIB/QLOGO.ASV   1.0   01 Mar 1996 17:43:00   HENRY  $
	 title	 QLOGO -- QLogo.OVL data source
	 page	 58,122
	 name	 QLOGO

COMMENT|		Module Specifications

Copyright:  Copyright (C) 1991-96 Qualitas, Inc.  All rights reserved.

Segmentation:  Data only

Program derived from:  None.

Original code by: Henry Groover, 1 Mar 96.

|

.xlist
	 include ASCII.INC

.list

PGROUP	group DATA

;***************************************************************************

; The following segment merely satisfies the LINKer's need to have
; a stack segment.

STACK	 segment word stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


;***************************************************************************

DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

org 0

	include QLOGO_Q.INC
	include	QLOGOASQ.INC

DATA	 ends			; End DATA segment

;***************************************************************************

	 END	 		; End QLOGO module



