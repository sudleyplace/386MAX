/***
 *' $Header:   P:/PVCS/MISC/XMSTEST/UMBTEST.C_V   1.1   06 Aug 1992 13:17:56   HENRY  $
 *
 * UMBTEST.C
 *
***/

#include <stdio.h>
#include <malloc.h>

#include "commdef.h"
#include "xmsinfo.h"

int main(int argc,char **argv)
{
	XMSPARM xmspar;

	if (argc);
	if (argv);

	xmsparm(&xmspar);

#if 0	/* long version */

	if (xmspar.installed) {
		/* I hate this, but it seems to be the only way to
		 * find out how much UMB memory is available. */
		int hmax = 1024;
		int hcount = 0;
		int npara = xmspar.umbavail;
		WORD *hbuf = malloc(hmax * sizeof(WORD));

		if (!hbuf) return 1;
		xmspar.umbtotal = 0;
		for (;;) {
			hbuf[hcount] = umballoc(npara);
			if (hbuf[hcount]) {
				printf("alloc #%02d, %d paras returns %04x\n",hcount,npara,hbuf[hcount]);
				hcount++;
				if (hcount > hmax) break;
				xmspar.umbtotal += npara;
			}
			else {
				npara--;
				if (npara < 1) break;
			}
		}
		while (hcount > 0) {
			hcount--;
			printf("free  #%02d:  %04x\n",hcount,hbuf[hcount]);
			umbfree(hbuf[hcount]);
		}
		free(hbuf);
		printf("Available:  %d\n",xmspar.umbavail);
		printf("Total:      %d\n",xmspar.umbtotal);
	}
#else		/* short version */
	{
		WORD umbseg;
		int npara;

		npara = 10;
		umbseg = umballoc(npara);
		printf("alloc %d paras, seg %04x\n",npara,umbseg);
		if (umbseg) umbfree(umbseg);
	}
#endif
	return 0;
}
