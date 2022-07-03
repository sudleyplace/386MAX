;' $Header:   P:/PVCS/MAX/QMT/MEM_MSGS.INV   1.0   05 Sep 1995 16:56:00   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	GNU General Public License version 3.
;
; MEM_MSG.INC
;
; DPMIERR messages
;

ifdef LANG_GR
@MSG_DPMI1 equ	 <'kann nicht durch DPMI Host in Protected Mode wechseln.'>
@MSG_DPMI1A equ  <'Nicht gengend Speicher fr Protected Mode durch DPMI Host.'>
@MSG_DPMI2 equ	 <'kann Segment nicht auf Selektor abbilden.'>
@MSG_DPMI3 equ	 <'kann lokale lineare Region nicht sperren (Lock).'>
@MSG_DPMI4 equ	 <'kann einen DPMI Selektor nicht allokieren.'>
@MSG_DPMI5 equ	 <'kann DPMI Descriptor nicht erhalten.'>
@MSG_DPMI6 equ	 <'kann DPMI Descriptor nicht setzen.'>
@MSG_DPMI7 equ	 <'kann DPMI Seitengr”áe (Page Size) nicht erhalten.'>
@MSG_DPMI8 equ	 <'kein Speicher zum Test vorhanden.'>
@MSG_DPMI9 equ	 <'kann DPMI P2L Speicher nicht allokieren.'>
@MSG_DPMI10 equ  <'kann DPMI P2L Speicher nicht sperren (Lock).'>
@MSG_DPMI11 equ  <'kann keine Information ber freien DPMI Speicher erhalten.'>
@MSG_DPMI12 equ  <'kann DPMI Speicher nicht allokieren.'>
@MSG_DPMI13 equ  <'kann DPMI Speicher nicht sperren (Lock).'>
@MSG_DPMI14 equ  <'kann DPMI P2L Speicher nicht entsperren (Unlock).'>
@MSG_DPMI15 equ  <'kann DPMI P2L Speicher nicht freigeben.'>
@MSG_DPMI16 equ  <'kann DPMI Speicher nicht entsperren (Unlock).'>
@MSG_DPMI17 equ  <'kann DPMI Speicher nicht freigeben.'>
else
@MSG_DPMI1 equ	 <'Unable to enter Protected Mode through DPMI host.'>
@MSG_DPMI1A equ  <'Insufficient memory to enter Protected Mode through DPMI host.'>
@MSG_DPMI2 equ	 <'Unable to map segment to selector.'>
@MSG_DPMI3 equ	 <'Unable to lock local linear region.'>
@MSG_DPMI4 equ	 <'Unable to allocate one DPMI selector.'>
@MSG_DPMI5 equ	 <'Unable to get DPMI descriptor.'>
@MSG_DPMI6 equ	 <'Unable to set DPMI descriptor.'>
@MSG_DPMI7 equ	 <'Unable to get DPMI page size.'>
@MSG_DPMI8 equ	 <'No memory to test.'>
@MSG_DPMI9 equ	 <'Unable to allocate DPMI P2L memory.'>
@MSG_DPMI10 equ  <'Unable to lock DPMI P2L memory.'>
@MSG_DPMI11 equ  <'Unable to get DPMI free memory information.'>
@MSG_DPMI12 equ  <'Unable to allocate DPMI memory.'>
@MSG_DPMI13 equ  <'Unable to lock DPMI memory.'>
@MSG_DPMI14 equ  <'Unable to unlock DPMI P2L memory.'>
@MSG_DPMI15 equ  <'Unable to free DPMI P2L memory.'>
@MSG_DPMI16 equ  <'Unable to unlock DPMI memory.'>
@MSG_DPMI17 equ  <'Unable to free DPMI memory.'>
endif				; IFDEF LANG_GR

