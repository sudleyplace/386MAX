/*' $Header:   P:/PVCS/MAX/ASQENG/MEM_INFO.H_V   1.1   01 Feb 1996 10:32:38   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * MEM_INFO.H								      *
 *									      *
 * Formatting routines for memory screens				      *
 *									      *
 ******************************************************************************/

#include <commdef.h>    /* Common definitions */

void Memory_Summary(HANDLE hinfo);
void Memory_Low_DOS(HANDLE hinfo);
void Memory_High_DOS(HANDLE hinfo);
void Memory_ROM_Scan(HANDLE hinfo);
void Memory_Interrupts(HANDLE hinfo);
void Memory_Extended(HANDLE hinfo);
void Memory_Expanded(HANDLE hinfo);
void Memory_EMS_Usage(HANDLE hinfo);
void Memory_XMS(HANDLE hinfo);
void Memory_Timing(HANDLE hinfo);
void Memory_Debug(HANDLE hinfo);
