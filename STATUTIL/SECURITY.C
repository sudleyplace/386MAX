//' $Header:   P:/PVCS/MAX/STATUTIL/SECURITY.C_V   1.1   16 Apr 1996 11:31:46   PETERJ  $
//
// SECURITY.C -- Weak encryption / decryption for CATDB data
//
// This encryption scheme is intentionally weak so as not to run
// afoul of US "munitions" export restrictions.
//
// The only other restriction is that this scheme must produce
// ASCIIZ output of identical length to input.  This means we
// can't use a simple XOR-chain scheme.  We use a modified XOR-chain
// with string bit rotation, XOR-ing only the lower 5 bits.
// This guarantees that the string, which on input must contain
// only ASCII characters >= ' ' (space), will transform into
// characters also >= ' '.  Since many characters will not
// be transformed (none in the case of \0x40\x60\x20\x80\xa0)
// we'll also perform a single longitudinal bit rotation.
//
// The seed value is 00011011b (0x1B).

#define STRICT
#include <windows.h>
#include <string.h>

#include <statutil.h>

#ifdef _WIN32
    #ifndef _INC_32ALIAS
        #include <32alias.h>
    #endif
#endif

#define XOR_SEED	0x1b
#define XOR_MASK	0x1f

// Encrypt ASCIIZ string according to comments at start of file.
// *** ALL CHARACTERS IN STRING MUST BE >= ' ' OR EMBEDDED NULLS
// *** MAY OCCUR.
// Encryption is done in place.
void
Encrypt( char FAR *lpsz ) {

	int i, len;
	unsigned char c, cf;

	len = _fstrlen( lpsz );
	if (!len) {
		return;
	} // Nothing to do

	// First, the XOR chain transformation.
	c = XOR_SEED;

	for (i = 0; i < len; i++) {
		lpsz[ i ] ^= c;
		c = lpsz[ i ] & XOR_MASK;
	} // For all characters to XOR

	// Next, the bit rotate transformation.
	cf = (lpsz[ len - 1 ] & 0x01); // Flag to move into high bit

	for (i = 0; i < len; i++) {
		// Fake a rotate.  Wouldn't this be cleaner in assembler?
		cf <<= 7; // Rotate last carry bit
		cf |= (lpsz[ i ] & 0x01); // Get bit we're about to shift out
		lpsz[ i ] = (lpsz[ i ] >> 1) | (cf & 0x80);
	} // For all characters to shift

} // Encrypt

// Decrypt ASCIIZ string encrypted by Encrypt().
// Decryption is done in place.
void
Decrypt( char FAR *lpsz ) {

	int i, len;
	unsigned char c, cf;

	len = _fstrlen( lpsz );
	if (!len) {
		return;
	} // Nothing to do

	cf = (lpsz[ 0 ] & 0x80); // Bit moved from low bit of last character

	// Since XOR is a reflexive operation we need to do it in the
	// same order we started with.  The bit rotation needs to go in
	// reverse, however.
	for (i = len - 1; i >= 0; i--) {
		cf >>= 7; // Move back into place
		cf |= (lpsz[ i ] & 0x80); // Get bit we're about to shift left
		lpsz[ i ] = (lpsz[ i ] << 1) | (cf & 0x01);
	} // For all characters to un-rotate

	c = XOR_SEED;

	// Now we perform the same string XOR we did originally.  (A ^ B) ^ B == A
	for (i = 0; i < len; i++) {
		cf = lpsz[ i ] & XOR_MASK;
		lpsz[ i ] ^= c;
		c = cf;
	} // for all characters to XOR

} // Decrypt

