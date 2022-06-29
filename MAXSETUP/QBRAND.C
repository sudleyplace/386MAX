
struct _EXEHDR_STR {
WORD exe_sign, // Signature == 'MZ'
     exe_r512, // Image size/512 remainder
     exe_q512, // Image size/512 quotient
     exe_nrel, // # relocation table items
     exe_hsiz, // Size of header in paras
     exe_min,  // Minimum # paras needed beyond image
     exe_max,  // Maximum ...
     exe_ss,   // Initial SS in paras
     exe_sp,   // Initial SP
     exe_chk,  // Checksum
     exe_ip,   // Initial IP
     exe_cs,   // Initial CS in paras
     exe_irel, // Offset to first relocation table item
     exe_ovrl; // Overlay #
};
typedef  struct _EXEHDR_STR EXEHDR_STR;


#define SECURITY_LEN 350		// Length of Pattern

unsigned char szPattern[SECURITY_LEN];



/********************************ENCRYPT *************************************/
// Encrypt Pattern
void	 encrypt (void)
{
	register unsigned int i, accum = 0;

	// Swap the nibbles and add a constant
	for ( i = 0; i < SECURITY_LEN; ++i )
	     szPattern[i] = (char) ( ( (szPattern[i] << 4) | (szPattern[i] >> 4) ) + 0x23);

	for ( i = 0; i < SECURITY_LEN; ++i )	  // Build a checksum
	     accum += (unsigned int) szPattern[i];

	// Store the checksum after the encrypted bytes
	*( (unsigned int *)( szPattern+i ) ) = accum;
}


int BrandFile (char *pszFileName)
{
	int rc = 0;
	unsigned int uDate, uTime;
	long lOffset;
	HFILE fh;
	EXEHDR_STR exe_hdr;

	if ((fh = _lopen ( pszFileName, READ_WRITE )) == -1)
		return -1;

	_dos_getftime (fh, &uDate, &uTime);

	if ((_llseek (fh, -((long) sizeof (lOffset)), SEEK_END) == -1) || (_lread (fh, &lOffset, sizeof (lOffset)) == -1)) {
		rc = -1;
		goto Close_file;
	}

	lOffset = ( ( lOffset & 0xFFFF0000L ) >> 12 ) + ( lOffset & 0x0000FFFFL );

	if ((_llseek (fh, 0L, SEEK_SET) == -1) || (_lread (fh, &exe_hdr, sizeof (exe_hdr)) == -1)) {
		rc = -1;
		goto Close_file;
	}

	if (exe_hdr.exe_sign == 0x5a4d)	// If .EXE format, skip over header
		lOffset += ((unsigned long) exe_hdr.exe_hsiz) << 4;

	// Ensure Pattern is initialized to 0's
	memset (szPattern, '\0', sizeof(szPattern) );

	// Encrypt data
	if (szCompany[0])
		wsprintf (szPattern, "\x01Serial #  %s\r\nLicensed to  %s - %s\r\n", szSerial, szName, szCompany );
	else
		wsprintf (szPattern, "\x01Serial #  %s\r\nLicensed to  %s\r\n", szSerial, szName );
	encrypt ();

	// Write it out
	if ((_llseek (fh, lOffset, SEEK_SET) == -1) || (_lwrite (fh, szPattern, SECURITY_LEN+SECURITY_CHK) == -1)) {
		rc = -1;
		goto Close_file;
	}

	// Restore file date/time
	_dos_setftime (fh, uDate, uTime);

Close_file:
	_lclose (fh);

	return rc;
}

