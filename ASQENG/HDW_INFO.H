/*' $Header:   P:/PVCS/MAX/ASQENG/HDW_INFO.H_V   1.1   01 Feb 1996 10:32:30   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * HDW_INFO.H								      *
 *									      *
 * Formatting routines for hardware screens				      *
 *									      *
 ******************************************************************************/

#include <commdef.h>    /* Common definitions */

void Hardware_Summary(HANDLE hinfo);
void Hardware_Video(HANDLE hinfo);
void Hardware_Drives(HANDLE hinfo);
void Hardware_Ports(HANDLE hinfo);
void Hardware_BIOS_Detail(HANDLE hinfo);
void Hardware_CMOS_Detail(HANDLE hinfo);
