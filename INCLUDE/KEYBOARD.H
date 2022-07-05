/*' $Header:   P:/PVCS/MAX/INCLUDE/KEYBOARD.H_V   1.0   05 Sep 1995 13:29:44   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-92 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * KEYBOARD.H								      *
 *									      *
 * Keyboard support functions						      *
 *									      *
 ******************************************************************************/

#ifndef KEYBOARD_INCLUDED
#define KEYBOARD_INCLUDED

/* Keystroke codes */
#define KEY_BKSP	0x0008	/* Backspace */
#define KEY_TAB 	0x0009	/* TAB */
#define KEY_ENTER	0x000d	/* ENTER */
#define KEY_ESCAPE	0x001b	/* Escape */

#define KEY_NUL 	0x0300	/* NUL */
#define KEY_ALTBKSP	0x0E00	/* Alt-Backspace */
#define KEY_STAB	0x0F00	/* Shift-TAB */
#define KEY_BACKTAB	0x0F00	/* Another popular name for this key */

#define KEY_ALTQ	0x1000	/* Alt-Q */
#define KEY_ALTW	0x1100	/* Alt-W */
#define KEY_ALTE	0x1200	/* Alt-E */
#define KEY_ALTR	0x1300	/* Alt-R */
#define KEY_ALTT	0x1400	/* Alt-T */
#define KEY_ALTY	0x1500	/* Alt-Y */
#define KEY_ALTU	0x1600	/* Alt-U */
#define KEY_ALTI	0x1700	/* Alt-I */
#define KEY_ALTO	0x1800	/* Alt-O */
#define KEY_ALTP	0x1900	/* Alt-P */
#define ALT_LBKT	0x1A00	/* Alt-[ */
#define ALT_RBKT	0x1B00	/* Alt-] */
#define KEY_AENTER	0x1C00	/* Alt-ENTER */
		      /*0x1D00	   Ctrl Key */
#define KEY_ALTA	0x1e00	/* Alt-A */
#define KEY_ALTS	0x1f00	/* Alt-S */

#define KEY_ALTD	0x2000	/* Alt-D */
#define KEY_ALTF	0x2100	/* Alt-F */
#define KEY_ALTG	0x2200	/* Alt-G */
#define KEY_ALTH	0x2300	/* Alt-H */
#define KEY_ALTJ	0x2400	/* Alt-J */
#define KEY_ALTK	0x2500	/* Alt-K */
#define KEY_ALTL	0x2600	/* Alt-L */
#define KEY_ALTSEMI	0x2700	/* Alt-; */
#define KEY_ALTQUOTE	0x2800	/* Alt-' */
#define KEY_ALTGRAVE	0x2900	/* Alt-` */
		      /*0x2A00	/* Shift Key */
		      /*0x2B00	   \ | Key */
#define KEY_ALTZ	0x2c00	/* Alt-Z */
#define KEY_ALTX	0x2d00	/* Alt-X */
#define KEY_ALTC	0x2e00	/* Alt-C */
#define KEY_ALTV	0x2f00	/* Alt-V */

#define KEY_ALTB	0x3000	/* Alt-B */
#define KEY_ALTN	0x3100	/* Alt-N */
#define KEY_ALTM	0x3200	/* Alt-M */
#define KEY_ALTCOMMA	0x3300	/* Alt-, */
#define KEY_ALTDOT	0x3400	/* Alt-. */
#define KEY_ALTSLASH	0x3500	/* Alt-/ */
		      /*0x3600	   Shift Key */
		      /*0x3700	   Numeric * */
		      /*0x3800	   Alt Key */
		      /*0x3900	   Spacebar */
		      /*0x3A00	   Caps Lock */
#define KEY_F1		0x3b00	/* F1 */
#define KEY_F2		0x3c00	/* F2 */
#define KEY_F3		0x3d00	/* F3 */
#define KEY_F4		0x3e00	/* F4 */
#define KEY_F5		0x3f00	/* F5 */

#define KEY_F6		0x4000	/* F6 */
#define KEY_F7		0x4100	/* F7 */
#define KEY_F8		0x4200	/* F8 */
#define KEY_F9		0x4300	/* F9 */
#define KEY_F10 	0x4400	/* F10 */
		      /*0x4500	   Num Lock */
		      /*0x4600	   Scroll Lock (83/84 only) */
#define KEY_HOME	0x4700	/* Home */
#define KEY_UP		0x4800	/* Up */
#define KEY_PGUP	0x4900	/* PgUp */
		      /*0x4A00	   Numeric - */
#define KEY_LEFT	0x4b00	/* Left */
		      /*0x4C00	   Numeric 5 */
#define KEY_RIGHT	0x4d00	/* Right */
		      /*0x4E00	   Numeric + */
#define KEY_END 	0x4f00	/* End */

#define KEY_DOWN	0x5000	/* Down */
#define KEY_PGDN	0x5100	/* PgDn */
#define KEY_INS 	0x5200	/* Ins */
#define KEY_DEL 	0x5300	/* Del */
#define KEY_SF1 	0x5400	/* Shift F1 */
#define KEY_SF2 	0x5500	/* Shift F2 */
#define KEY_SF3 	0x5600	/* Shift F3 */
#define KEY_SF4 	0x5700	/* Shift F4 */
#define KEY_SF5 	0x5800	/* Shift F5 */
#define KEY_SF6 	0x5900	/* Shift F6 */
#define KEY_SF7 	0x5a00	/* Shift F7 */
#define KEY_SF8 	0x5b00	/* Shift F8 */
#define KEY_SF9 	0x5c00	/* Shift F9 */
#define KEY_SF10	0x5d00	/* Shift 10 */
#define KEY_CF1 	0x5e00	/* Ctrl F1 */
#define KEY_CF2 	0x5f00	/* Ctrl F2 */

#define KEY_CF3 	0x6000	/* Ctrl F3 */
#define KEY_CF4 	0x6100	/* Ctrl F4 */
#define KEY_CF5 	0x6200	/* Ctrl F5 */
#define KEY_CF6 	0x6300	/* Ctrl F6 */
#define KEY_CF7 	0x6400	/* Ctrl F7 */
#define KEY_CF8 	0x6500	/* Ctrl F8 */
#define KEY_CF9 	0x6600	/* Ctrl F9 */
#define KEY_CF10	0x6700	/* Ctrl 10 */
#define KEY_AF1 	0x6800	/* Alt F1 */
#define KEY_AF2 	0x6900	/* Alt F2 */
#define KEY_AF3 	0x6a00	/* Alt F3 */
#define KEY_AF4 	0x6b00	/* Alt F4 */
#define KEY_AF5 	0x6c00	/* Alt F5 */
#define KEY_AF6 	0x6d00	/* Alt F6 */
#define KEY_AF7 	0x6e00	/* Alt F7 */
#define KEY_AF8 	0x6f00	/* Alt F8 */

#define KEY_AF9 	0x7000	/* Alt F9 */
#define KEY_AF10	0x7100	/* Alt 10 */
#define KEY_CPRTSC	0x7200	/* Ctrl PrtSc */
#define KEY_CLEFT	0x7300	/* Ctrl-Left */
#define KEY_CRIGHT	0x7400	/* Ctrl-Right */
#define KEY_CEND	0x7500	/* Ctrl-End */
#define KEY_CPGDN	0x7600	/* Ctrl-PgDn */
#define KEY_CHOME	0x7700	/* Ctrl-Home */
#define KEY_ALT1	0x7800	/* Alt 1 */
#define KEY_ALT2	0x7900	/* Alt 2 */
#define KEY_ALT3	0x7a00	/* Alt 3 */
#define KEY_ALT4	0x7b00	/* Alt 4 */
#define KEY_ALT5	0x7c00	/* Alt 5 */
#define KEY_ALT6	0x7d00	/* Alt 6 */
#define KEY_ALT7	0x7e00	/* Alt 7 */
#define KEY_ALT8	0x7f00	/* Alt 8 */

#define KEY_ALT9	0x8000	/* Alt 9 */
#define KEY_ALT0	0x8100	/* Alt 0 */
#define KEY_ALTMIN	0x8200	/* Alt - */
#define KEY_ALTEQU	0x8300	/* Alt = */
#define KEY_CPGUP	0x8400	/* Ctrl-PgUp */
#define KEY_F11 	0x8500	/* F11 */
#define KEY_F12 	0x8600	/* F12 */
#define KEY_SF11	0x8700	/* Shift-F11 */
#define KEY_SF12	0x8800	/* Shift-F12 */
#define KEY_CF11	0x8900	/* Ctrl-F11 */
#define KEY_CF12	0x8A00	/* Ctrl-F12 */
#define KEY_AF11	0x8B00	/* Alt-F11 */
#define KEY_AF12	0x8C00	/* Alt-F12 */
#define KEY_CUP 	0x8D00	/* Ctrl-Up */
		      /*0x8E00*/
		      /*0x8F00*/

		      /*0x9000*/
#define KEY_CDOWN	0x9100	/* Ctrl-Down */
#define KEY_CINS	0x9200	/* Ctrl-Ins */
#define KEY_CDEL	0x9300	/* Ctrl-Del */
#define KEY_CTAB	0x9400	/* Ctrl-TAB */
#define KEY_CNSLASH	0x9500	/* Ctrl-Numeric-/ */
		      /*0x9600*/
#define KEY_AHOME	0x9700	/* Alt-Home */
#define KEY_AUP 	0x9800	/* Alt-Up */
#define KEY_APGUP	0x9900	/* Alt-PgUp */
		      /*0x9A00*/
#define KEY_ALEFT	0x9B00	/* Alt-Left */
		      /*0x9C00*/
#define KEY_ARIGHT	0x9d00	/* Alt-Right */
		      /*0x9E00*/
#define KEY_AEND	0x9f00	/* Alt-End */

#define KEY_ADOWN	0xA000	/* Alt-Down */
#define KEY_APGDN	0xA100	/* Alt-PgDn */
#define KEY_AINS	0xA200	/* Alt-Ins */
#define KEY_ADEL	0xA300	/* Alt-Del */
#define KEY_ALTNSLASH	0xA400	/* Alt-Num-/ */
#define KEY_ATAB	0xA500	/* Alt-TAB */
#define KEY_ANENTER	0xA600	/* Alt-Numeric-ENTER */


#define KEY_ALTDN	0x3800	/* Alt key went down */
#define KEY_ALTUP	0xF800	/* Alt key came up */

#define KEYFLAG_RSHFT 0x0001	/* Right shift key down */
#define KEYFLAG_LSHFT 0x0002	/* Left shift key down */
#define KEYFLAG_XCTRL 0x0004	/* Either ctrl key down */
#define KEYFLAG_XALT  0x0008	/* Either alt key down */
#define KEYFLAG_SCROL 0x0010	/* Scroll lock is on */
#define KEYFLAG_NUM   0x0020	/* Num lock in on */
#define KEYFLAG_CAPS  0x0040	/* Caps lock is on */

/* Macro to test for normal (ASCII) keystroke */
#define NORMALKEY(k) ((k)&0xff)

/* Macro to test for special (non-ASCII) keystroke */
#define SPECIALKEY(k) (!((k)&0xff))

#ifndef COMMDEF_INCLUDED
typedef unsigned short KEYCODE; /* Keystroke codes */
typedef unsigned short KEYFLAG; /* Keyboard flags */
typedef unsigned long  EXTKEY;	/* Extended keystroke info */
#endif

/* Return keycode portion of extended key */
#define KEYCODE_OF(k) ((KEYCODE)((k) & 0xffff))

/* Return keyflag portion of extended key */
#define KEYFLAG_OF(k) ((KEYFLAG)((k) >> 16))

/* Make extended key from keycode and keyflag */
#define EXTKEY_OF(k,f) ((EXTKEY)(k) | (((EXTKEY)(f)) << 16))

typedef struct _keyparm {	/* Keyboard parameters */
	int flags;		/* 0=std kb/func, 1=ext func, 2=ext kb, 3=both */
} KEYPARM;

/* Functions */
void init_keyboard(KEYPARM *parm);
void end_keyboard(void);
KEYCODE get_key(int nowait);	/* Test / wait for one keystroke */
EXTKEY	get_extkey(int nowait); /* Test / wait for keystroke + flags */

KEYCODE translate_altKey( KEYCODE key );		/* Take chorded alt char and return real character */
#endif /*KEYBOARD_INCLUDED*/
