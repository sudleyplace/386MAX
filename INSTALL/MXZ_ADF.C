/*' $Header:   P:/PVCS/MAX/INSTALL/MXZ_ADF.C_V   1.1   08 Feb 1996 12:43:12   BOB  $ */
/************************************************************************
 *																						      *
 * (C) Copyright 1993 Qualitas, Inc.  All rights reserved.			      *
 *																						      *
 * MXZ_ADF.C																		*
 *																						      *
 ************************************************************************/

#include <string.h>

#include "common.h"
#include "instext.h"

#ifndef PROTO
#include "files.pro"
#include "ins_adf.pro"
#include "ins_pos.pro"
#endif

typedef WORD  _far *FPWORD;

void	CheckForBadADFs( void )
{
	char cmos_values[4];
	char adapter_values[4];
	WORD wadapter_id;
	int  cSlotNo;

	if (!IZITQEMM() && posinit() == 0)
	{
		for( cSlotNo = 1 ; cSlotNo < 12 ; cSlotNo++)
		{

			posread(cSlotNo, cmos_values, adapter_values, &wadapter_id );

			switch ( wadapter_id )
			{
				case 0x71D4:
					add2maxpro( ActiveOwner, MsgKingston );
					break;
			}
		}
	}
}


