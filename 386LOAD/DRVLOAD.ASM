;' $Header:   P:/PVCS/MAX/386LOAD/DRVLOAD.ASV   1.1   30 May 1997 10:38:04   BOB  $
	 title	 DRVLOAD -- 386MAX Device Driver Loader For CONFIG.SYS
	 page	 58,122
	 name	 DRVLOAD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:
Group RGROUP:
	       Program segment RCODE,	para-aligned,  public, class 'rcode'
	       Data    segment RDATA,	dword-aligned, public, class 'rdata'
Group PGROUP:
	       Stack   segment STACK,	byte-aligned,  stack,  class 'prog'
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Data    segment DATZ,	para-aligned,  public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Data    segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'
	       Data    segment SEG_TXT, byte-aligned,  public, class 'zdata'
	       Data    segment SEG_LEN, word-aligned,  public, class 'zdata'
	       Data    segment SEG_TAB, word-aligned,  public, class 'zdata'
	       Data    segment SEG_ACT, word-aligned,  public, class 'zdata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'
	       Data    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, February 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
.list

RGROUP	 group	 RCODE,RDATA
RCODE	 segment para public 'rcode' ; Start RCODE segment

RCODE	 ends			; End RCODE segment

RDATA	 segment dword public 'rdata' ; Start RDATA segment

RDATA	 ends			; End RDATA segment

PGROUP	 group	 STACK,CODE,DATA,DATZ,NCODE,NDATA,ACODE,ADATA,DTAIL,SEG_TXT,SEG_LEN,SEG_TAB,SEG_ACT,UCODE,UDATA,ZZTAIL

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .SYS file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment

CODE	 segment para public 'prog' ; Start CODE segment
CODE	 ends			; End CODE segment


DATA	 segment dword public 'data' ; Start DATA segment
DATA	 ends			; End DATA segment


DATZ	 segment para public 'data' ; Start DATZ segment
DATZ	 ends			; End DATZ segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
NCODE	 ends			; End NCODE segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
NDATA	 ends			; End NDATA segment


ACODE	 segment byte public 'zdata' ; Start ACODE segment
ACODE	 ends			; End ACODE segment


ADATA	 segment dword public 'zdata' ; Start ADATA segment
ADATA	 ends			; End ADATA segment


DTAIL	 segment para public 'zdata' ; Start DTAIL segment
DTAIL	 ends			; End DTAIL segment


SEG_LEN  segment word public 'zdata' ; Start SEG_LEN segment
SEG_LEN  ends			; End SEG_LEN segment


SEG_TAB  segment word public 'zdata' ; Start SEG_TAB segment
SEG_TAB  ends			; End SEG_TAB segment


SEG_ACT  segment word public 'zdata' ; Start SEG_ACT segment
SEG_ACT  ends			; End SEG_ACT segment


SEG_TXT  segment byte public 'zdata' ; Start SEG_TXT segment
SEG_TXT  ends			; End SEG_TXT segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
UCODE	 ends			; End UCODE segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
UDATA	 ends			; End UDATA segment


; This segment *MUST* appear as the last one in sequence

ZZTAIL	 segment dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 public  IDENTIFY
IDENTIFY label	 byte		; This identifier is needed by LOADCO2
				; but isn't used in this model.  That is,
				; it isn't one to be IDed by INSTALL.

ZZTAIL	 ends			; End ZZTAIL segment

	 MEND			; End DRVLOAD module
