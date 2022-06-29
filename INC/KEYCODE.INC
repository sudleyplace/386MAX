;' $Header:   P:/PVCS/MAX/INC/KEYCODE.INV   1.1   18 Jul 1997 12:31:18   BOB  $
;
; (C) Copyright 1987-97 Qualitas, Inc.	All rights reserved.
;
; KEYCODE.INC
;
; Equates for Keyboard Codes returned from INT 16h
;

.xcref @KEY_XINS,@KEY_CTL_XINS,@KEY_ALT_XINS
@KEY_XINS		equ  52E0h
@KEY_CTL_XINS		equ  92E0h
@KEY_ALT_XINS		equ 0A200h

.xcref @KEY_XDEL,@KEY_CTL_XDEL,@KEY_ALT_XDEL
@KEY_XDEL		equ  53E0h
@KEY_CTL_XDEL		equ  93E0h
@KEY_ALT_XDEL		equ 0A300h

.xcref @KEY_XLEFT,@KEY_CTL_XLEFT,@KEY_ALT_XLEFT
@KEY_XLEFT		equ  4BE0h
@KEY_CTL_XLEFT		equ  73E0h
@KEY_ALT_XLEFT		equ  9B00h

.xcref @KEY_XHOME,@KEY_CTL_XHOME,@KEY_ALT_XHOME
@KEY_XHOME		equ  47E0h
@KEY_CTL_XHOME		equ  77E0h
@KEY_ALT_XHOME		equ  9700h

.xcref @KEY_XEND,@KEY_CTL_XEND,@KEY_ALT_XEND
@KEY_XEND		equ  4FE0h
@KEY_CTL_XEND		equ  75E0h
@KEY_ALT_XEND		equ  9F00h

.xcref @KEY_XUP,@KEY_CTL_XUP,@KEY_ALT_XUP
@KEY_XUP		equ  48E0h
@KEY_CTL_XUP		equ  8DE0h
@KEY_ALT_XUP		equ  9800h

.xcref @KEY_XDN,@KEY_CTL_XDN,@KEY_ALT_XDN
@KEY_XDN		equ  50E0h
@KEY_CTL_XDN		equ  91E0h
@KEY_ALT_XDN		equ 0A000h

.xcref @KEY_XPGUP,@KEY_CTL_XPGUP,@KEY_ALT_XPGUP
@KEY_XPGUP		equ  49E0h
@KEY_CTL_XPGUP		equ  84E0h
@KEY_ALT_XPGUP		equ  9900h

.xcref @KEY_XPGDN,@KEY_CTL_XPGDN,@KEY_ALT_XPGDN
@KEY_XPGDN		equ  51E0h
@KEY_CTL_XPGDN		equ  76E0h
@KEY_ALT_XPGDN		equ 0A100h

.xcref @KEY_XRIGHT,@KEY_CTL_XRIGHT,@KEY_ALT_XRIGHT
@KEY_XRIGHT		equ  4DE0h
@KEY_CTL_XRIGHT 	equ  74E0h
@KEY_ALT_XRIGHT 	equ  9D00h

.xcref @KEY_PADSLASH,@KEY_CTL_PADSLASH,@KEY_ALT_PADSLASH
@KEY_PADSLASH		equ 0E02Fh
@KEY_CTL_PADSLASH	equ  9500h
@KEY_ALT_PADSLASH	equ 0A400h

.xcref @KEY_PADENTER,@KEY_CTL_PADENTER,@KEY_ALT_PADENTER
@KEY_PADENTER		equ 0E00Dh
@KEY_CTL_PADENTER	equ 0E00Ah
@KEY_ALT_PADENTER	equ 0A600h

.xcref @KEY_ESC,@KEY_ALT_ESC
@KEY_ESC		equ  011Bh
@KEY_ALT_ESC		equ  0100h

.xcref @KEY_1,@KEY_SHREIK,@KEY_ALT_1
@KEY_1			equ  0231h
@KEY_SHREIK		equ  0221h
@KEY_ALT_1		equ  7800h

@KEY_2			equ  0332h
@KEY_ATSIGN		equ  0340h
@KEY_CTL_2		equ  0300h
@KEY_ALT_2		equ  7900h

@KEY_3			equ  0433h
@KEY_POUND		equ  0423h
@KEY_ALT_3		equ  7A00h

@KEY_4			equ  0534h
@KEY_DOLLAR		equ  0524h
@KEY_ALT_4		equ  7B00h

@KEY_5			equ  0635h
@KEY_PCT		equ  0625h
@KEY_ALT_5		equ  7C00h

@KEY_6			equ  0736h
@KEY_CARET		equ  075Eh
@KEY_CTL_6		equ  071Eh
@KEY_ALT_6		equ  7D00h

@KEY_7			equ  0837h
@KEY_AMPER		equ  0826h
@KEY_ALT_7		equ  7E00h

@KEY_8			equ  0938h
@KEY_STAR		equ  092Ah
@KEY_ALT_8		equ  7F00h

@KEY_9			equ  0A39h
@KEY_LPAREN		equ  0A28h
@KEY_ALT_9		equ  8000h

@KEY_0			equ  0B30h
@KEY_RPAREN		equ  0B29h
@KEY_ALT_0		equ  8100h

@KEY_MINUS		equ  0C2Dh
@KEY_UBAR		equ  0C5Fh
@KEY_CTL_MINUS		equ  0C1Fh
@KEY_ALT_MINUS		equ  8200h

@KEY_EQUAL		equ  0D3Dh
@KEY_PLUS		equ  0D2Bh
@KEY_ALT_EQUAL		equ  8300h

@KEY_BS 		equ  0E08h
@KEY_CTL_BS		equ  0E7Fh
@KEY_ALT_BS		equ  0E00h

@KEY_TAB		equ  0F09h
@KEY_SHF_TAB		equ  0F00h
@KEY_CTL_TAB		equ  9400h
@KEY_ALT_TAB		equ 0A500h

@KEY_Q			equ  1071h
@KEY_SHF_Q		equ  1051h
@KEY_CTL_Q		equ  1011h
@KEY_ALT_Q		equ  1000h

@KEY_W			equ  1177h
@KEY_SHF_W		equ  1157h
@KEY_CTL_W		equ  1117h
@KEY_ALT_W		equ  1100h

@KEY_E			equ  1265h
@KEY_SHF_E		equ  1245h
@KEY_CTL_E		equ  1205h
@KEY_ALT_E		equ  1200h

@KEY_R			equ  1372h
@KEY_SHF_R		equ  1352h
@KEY_CTL_R		equ  1312h
@KEY_ALT_R		equ  1300h

@KEY_T			equ  1474h
@KEY_SHF_T		equ  1454h
@KEY_CTL_T		equ  1414h
@KEY_ALT_T		equ  1400h

@KEY_Y			equ  1579h
@KEY_SHF_Y		equ  1559h
@KEY_CTL_Y		equ  1519h
@KEY_ALT_Y		equ  1500h

@KEY_U			equ  1675h
@KEY_SHF_U		equ  1655h
@KEY_CTL_U		equ  1615h
@KEY_ALT_U		equ  1600h

@KEY_I			equ  1769h
@KEY_SHF_I		equ  1749h
@KEY_CTL_I		equ  1709h
@KEY_ALT_I		equ  1700h

@KEY_O			equ  186Fh
@KEY_SHF_O		equ  184Fh
@KEY_CTL_O		equ  180Fh
@KEY_ALT_O		equ  1800h

@KEY_P			equ  1970h
@KEY_SHF_P		equ  1950h
@KEY_CTL_P		equ  1910h
@KEY_ALT_P		equ  1900h

@KEY_LBR		equ  1A5Bh
@KEY_LBRACE		equ  1A7Bh
@KEY_CTL_LBR		equ  1A1Bh
@KEY_ALT_LBR		equ  1A00h

@KEY_RBR		equ  1B5Dh
@KEY_RBRACE		equ  1B7Dh
@KEY_CTL_RBR		equ  1B1Dh
@KEY_ALT_RBR		equ  1B00h

@KEY_CR 		equ  1C0Dh
@KEY_SHF_CR		equ  1C0Dh
@KEY_CTL_CR		equ  1C0Ah
@KEY_ALT_CR		equ  1C00h

@KEY_A			equ  1E61h
@KEY_SHF_A		equ  1E41h
@KEY_CTL_A		equ  1E01h
@KEY_ALT_A		equ  1E00h

@KEY_S			equ  1F73h
@KEY_SHF_S		equ  1F53h
@KEY_CTL_S		equ  1F13h
@KEY_ALT_S		equ  1F00h

@KEY_D			equ  2064h
@KEY_SHF_D		equ  2044h
@KEY_CTL_D		equ  2004h
@KEY_ALT_D		equ  2000h

@KEY_F			equ  2166h
@KEY_SHF_F		equ  2146h
@KEY_CTL_F		equ  2106h
@KEY_ALT_F		equ  2100h

@KEY_G			equ  2267h
@KEY_SHF_G		equ  2247h
@KEY_CTL_G		equ  2207h
@KEY_ALT_G		equ  2200h

@KEY_H			equ  2368h
@KEY_SHF_H		equ  2348h
@KEY_CTL_H		equ  2308h
@KEY_ALT_H		equ  2300h

@KEY_J			equ  246Ah
@KEY_SHF_J		equ  244Ah
@KEY_CTL_J		equ  240Ah
@KEY_ALT_J		equ  2400h

@KEY_K			equ  256Bh
@KEY_SHF_K		equ  254Bh
@KEY_CTL_K		equ  250Bh
@KEY_ALT_K		equ  2500h

@KEY_L			equ  266Ch
@KEY_SHF_L		equ  264Ch
@KEY_CTL_L		equ  260Ch
@KEY_ALT_L		equ  2600h

@KEY_SEMI		equ  273Bh
@KEY_COLON		equ  273Ah
@KEY_ALT_SEMI		equ  2700h

@KEY_QUOTE		equ  2827h
@KEY_DQUOTE		equ  2822h
@KEY_ALT_QUOTE		equ  2800h

@KEY_BQUOTE		equ  2960h
@KEY_TILDE		equ  297Eh
@KEY_ALT_BQUOTE 	equ  2900h

@KEY_BSLASH		equ  2B5Ch
@KEY_STILE		equ  2B7Ch
@KEY_CTL_BSLASH 	equ  2B1Ch
@KEY_ALT_BSLASH 	equ  2B00h

@KEY_Z			equ  2C7Ah
@KEY_SHF_Z		equ  2C5Ah
@KEY_CTL_Z		equ  2C1Ah
@KEY_ALT_Z		equ  2C00h

@KEY_X			equ  2D78h
@KEY_SHF_X		equ  2D58h
@KEY_CTL_X		equ  2D18h
@KEY_ALT_X		equ  2D00h

@KEY_C			equ  2E63h
@KEY_SHF_C		equ  2E43h
@KEY_CTL_C		equ  2E03h
@KEY_ALT_C		equ  2E00h

@KEY_V			equ  2F76h
@KEY_SHF_V		equ  2F56h
@KEY_CTL_V		equ  2F16h
@KEY_ALT_V		equ  2F00h

@KEY_B			equ  3062h
@KEY_SHF_B		equ  3042h
@KEY_CTL_B		equ  3002h
@KEY_ALT_B		equ  3000h

@KEY_N			equ  316Eh
@KEY_SHF_N		equ  314Eh
@KEY_CTL_N		equ  310Eh
@KEY_ALT_N		equ  3100h

@KEY_M			equ  326Dh
@KEY_SHF_M		equ  324Dh
@KEY_CTL_M		equ  320Dh
@KEY_ALT_M		equ  3200h

@KEY_COMMA		equ  332Ch
@KEY_LCARET		equ  333Ch
@KEY_ALT_COMMA		equ  3300h

@KEY_PERIOD		equ  342Eh
@KEY_RCARET		equ  343Eh
@KEY_ALT_PERIOD 	equ  3400h

@KEY_SLASH		equ  352Fh
@KEY_QUERY		equ  353Fh
@KEY_ALT_SLASH		equ  3500h

@KEY_PADSTAR		equ  372Ah
@KEY_SHF_PADSTAR	equ  372Ah
@KEY_CTL_PADSTAR	equ  9600h
@KEY_ALT_PADSTAR	equ  3700h

@KEY_SPACE		equ  3920h
@KEY_SHF_SPACE		equ  3920h
@KEY_CTL_SPACE		equ  3920h
@KEY_ALT_SPACE		equ  3920h

@KEY_F1 		equ  3B00h
@KEY_SHF_F1		equ  5400h
@KEY_CTL_F1		equ  5E00h
@KEY_ALT_F1		equ  6800h

@KEY_F2 		equ  3C00h
@KEY_SHF_F2		equ  5500h
@KEY_CTL_F2		equ  5F00h
@KEY_ALT_F2		equ  6900h

@KEY_F3 		equ  3D00h
@KEY_SHF_F3		equ  5600h
@KEY_CTL_F3		equ  6000h
@KEY_ALT_F3		equ  6A00h

@KEY_F4 		equ  3E00h
@KEY_SHF_F4		equ  5700h
@KEY_CTL_F4		equ  6100h
@KEY_ALT_F4		equ  6B00h

@KEY_F5 		equ  3F00h
@KEY_SHF_F5		equ  5800h
@KEY_CTL_F5		equ  6200h
@KEY_ALT_F5		equ  6C00h

@KEY_F6 		equ  4000h
@KEY_SHF_F6		equ  5900h
@KEY_CTL_F6		equ  6300h
@KEY_ALT_F6		equ  6D00h

@KEY_F7 		equ  4100h
@KEY_SHF_F7		equ  5A00h
@KEY_CTL_F7		equ  6400h
@KEY_ALT_F7		equ  6E00h

@KEY_F8 		equ  4200h
@KEY_SHF_F8		equ  5B00h
@KEY_CTL_F8		equ  6500h
@KEY_ALT_F8		equ  6F00h

@KEY_F9 		equ  4300h
@KEY_SHF_F9		equ  5C00h
@KEY_CTL_F9		equ  6600h
@KEY_ALT_F9		equ  7000h

@KEY_F10		equ  4400h
@KEY_SHF_F10		equ  5D00h
@KEY_CTL_F10		equ  6700h
@KEY_ALT_F10		equ  7100h

@KEY_HOME		equ  4700h
@KEY_SHF_HOME		equ  4737h
@KEY_CTL_HOME		equ  7700h

@KEY_UP 		equ  4800h
@KEY_SHF_UP		equ  4838h
@KEY_CTL_UP		equ  8D00h

@KEY_PGUP		equ  4900h
@KEY_SHF_PGUP		equ  4939h
@KEY_CTL_PGUP		equ  8400h

@KEY_PADMINUS		equ  4A2Dh
@KEY_SHF_PADMINUS	equ  4A2Dh
@KEY_CTL_PADMINUS	equ  8E00h
@KEY_ALT_PADMINUS	equ  4A00h

@KEY_LEFT		equ  4B00h
@KEY_SHF_LEFT		equ  4B34h
@KEY_CTL_LEFT		equ  7300h

@KEY_PAD5		equ  4C00h
@KEY_SHF_PAD5		equ  4C35h
@KEY_CTL_PAD5		equ  8F00h

@KEY_RIGHT		equ  4D00h
@KEY_SHF_RIGHT		equ  4D36h
@KEY_CTL_RIGHT		equ  7400h

@KEY_PADPLUS		equ  4E2Bh
@KEY_SHF_PADPLUS	equ  4E2Bh
@KEY_CTL_PADPLUS	equ  9000h
@KEY_ALT_PADPLUS	equ  4E00h

@KEY_END		equ  4F00h
@KEY_SHF_END		equ  4F31h
@KEY_CTL_END		equ  7500h

@KEY_DN 		equ  5000h
@KEY_SHF_DN		equ  5032h
@KEY_CTL_DN		equ  9100h

@KEY_PGDN		equ  5100h
@KEY_SHF_PGDN		equ  5133h
@KEY_CTL_PGDN		equ  7600h

@KEY_INS		equ  5200h
@KEY_SHF_INS		equ  5230h
@KEY_CTL_INS		equ  9200h

@KEY_DEL		equ  5300h
@KEY_SHF_DEL		equ  532Eh
@KEY_CTL_DEL		equ  9300h

@KEY_F11		equ  8500h
@KEY_SHF_F11		equ  8700h
@KEY_CTL_F11		equ  8900h
@KEY_ALT_F11		equ  8B00h

@KEY_F12		equ  8600h
@KEY_SHF_F12		equ  8800h
@KEY_CTL_F12		equ  8A00h
@KEY_ALT_F12		equ  8C00h

@KEY_AWIN		equ  9A00h	; Locally defined
@KEY_SHF_AWIN		equ  9C00h	; ...
@KEY_CTL_AWIN		equ  9E00h	; ...
@KEY_ALT_AWIN		equ 0A700h	; ...

.xcref @KEY_001,@KEY_002,@KEY_003,@KEY_004,@KEY_005,@KEY_006,@KEY_007,@KEY_008
.xcref @KEY_009,@KEY_010,@KEY_011,@KEY_012,@KEY_013,@KEY_014,@KEY_015,@KEY_016
.xcref @KEY_017,@KEY_018,@KEY_019,@KEY_020,@KEY_021,@KEY_022,@KEY_023,@KEY_024
.xcref @KEY_025,@KEY_026,@KEY_027,@KEY_028,@KEY_029,@KEY_030,@KEY_031,@KEY_032
.xcref @KEY_033,@KEY_034,@KEY_035,@KEY_036,@KEY_037,@KEY_038,@KEY_039,@KEY_040
.xcref @KEY_041,@KEY_042,@KEY_043,@KEY_044,@KEY_045,@KEY_046,@KEY_047,@KEY_048
.xcref @KEY_049,@KEY_050,@KEY_051,@KEY_052,@KEY_053,@KEY_054,@KEY_055,@KEY_056
.xcref @KEY_057,@KEY_058,@KEY_059,@KEY_060,@KEY_061,@KEY_062,@KEY_063,@KEY_064
.xcref @KEY_065,@KEY_066,@KEY_067,@KEY_068,@KEY_069,@KEY_070,@KEY_071,@KEY_072
.xcref @KEY_073,@KEY_074,@KEY_075,@KEY_076,@KEY_077,@KEY_078,@KEY_079,@KEY_080
.xcref @KEY_081,@KEY_082,@KEY_083,@KEY_084,@KEY_085,@KEY_086,@KEY_087,@KEY_088
.xcref @KEY_089,@KEY_090,@KEY_091,@KEY_092,@KEY_093,@KEY_094,@KEY_095,@KEY_096
.xcref @KEY_097,@KEY_098,@KEY_099,@KEY_100,@KEY_101,@KEY_102,@KEY_103,@KEY_104
.xcref @KEY_105,@KEY_106,@KEY_107,@KEY_108,@KEY_109,@KEY_110,@KEY_111,@KEY_112
.xcref @KEY_113,@KEY_114,@KEY_115,@KEY_116,@KEY_117,@KEY_118,@KEY_119,@KEY_120
.xcref @KEY_121,@KEY_122,@KEY_123,@KEY_124,@KEY_125,@KEY_126,@KEY_127,@KEY_128
.xcref @KEY_129,@KEY_130,@KEY_131,@KEY_132,@KEY_133,@KEY_134,@KEY_135,@KEY_136
.xcref @KEY_137,@KEY_138,@KEY_139,@KEY_140,@KEY_141,@KEY_142,@KEY_143,@KEY_144
.xcref @KEY_145,@KEY_146,@KEY_147,@KEY_148,@KEY_149,@KEY_150,@KEY_151,@KEY_152
.xcref @KEY_153,@KEY_154,@KEY_155,@KEY_156,@KEY_157,@KEY_158,@KEY_159,@KEY_160
.xcref @KEY_161,@KEY_162,@KEY_163,@KEY_164,@KEY_165,@KEY_166,@KEY_167,@KEY_168
.xcref @KEY_169,@KEY_170,@KEY_171,@KEY_172,@KEY_173,@KEY_174,@KEY_175,@KEY_176
.xcref @KEY_177,@KEY_178,@KEY_179,@KEY_180,@KEY_181,@KEY_182,@KEY_183,@KEY_184
.xcref @KEY_185,@KEY_186,@KEY_187,@KEY_188,@KEY_189,@KEY_190,@KEY_191,@KEY_192
.xcref @KEY_193,@KEY_194,@KEY_195,@KEY_196,@KEY_197,@KEY_198,@KEY_199,@KEY_200
.xcref @KEY_201,@KEY_202,@KEY_203,@KEY_204,@KEY_205,@KEY_206,@KEY_207,@KEY_208
.xcref @KEY_209,@KEY_210,@KEY_211,@KEY_212,@KEY_213,@KEY_214,@KEY_215,@KEY_216
.xcref @KEY_217,@KEY_218,@KEY_219,@KEY_220,@KEY_221,@KEY_222,@KEY_223,@KEY_224
.xcref @KEY_225,@KEY_226,@KEY_227,@KEY_228,@KEY_229,@KEY_230,@KEY_231,@KEY_232
.xcref @KEY_233,@KEY_234,@KEY_235,@KEY_236,@KEY_237,@KEY_238,@KEY_239,@KEY_240
.xcref @KEY_241,@KEY_242,@KEY_243,@KEY_244,@KEY_245,@KEY_246,@KEY_247,@KEY_248
.xcref @KEY_249,@KEY_250,@KEY_251,@KEY_252,@KEY_253,@KEY_254,@KEY_255
@KEY_001		equ  0001h
@KEY_002		equ  0002h
@KEY_003		equ  0003h
@KEY_004		equ  0004h
@KEY_005		equ  0005h
@KEY_006		equ  0006h
@KEY_007		equ  0007h
@KEY_008		equ  0008h
@KEY_009		equ  0009h
@KEY_010		equ  000Ah
@KEY_011		equ  000Bh
@KEY_012		equ  000Ch
@KEY_013		equ  000Dh
@KEY_014		equ  000Eh
@KEY_015		equ  000Fh
@KEY_016		equ  0010h
@KEY_017		equ  0011h
@KEY_018		equ  0012h
@KEY_019		equ  0013h
@KEY_020		equ  0014h
@KEY_021		equ  0015h
@KEY_022		equ  0016h
@KEY_023		equ  0017h
@KEY_024		equ  0018h
@KEY_025		equ  0019h
@KEY_026		equ  001Ah
@KEY_027		equ  001Bh
@KEY_028		equ  001Ch
@KEY_029		equ  001Dh
@KEY_030		equ  001Eh
@KEY_031		equ  001Fh
@KEY_032		equ  0020h
@KEY_033		equ  0021h
@KEY_034		equ  0022h
@KEY_035		equ  0023h
@KEY_036		equ  0024h
@KEY_037		equ  0025h
@KEY_038		equ  0026h
@KEY_039		equ  0027h
@KEY_040		equ  0028h
@KEY_041		equ  0029h
@KEY_042		equ  002Ah
@KEY_043		equ  002Bh
@KEY_044		equ  002Ch
@KEY_045		equ  002Dh
@KEY_046		equ  002Eh
@KEY_047		equ  002Fh
@KEY_048		equ  0030h
@KEY_049		equ  0031h
@KEY_050		equ  0032h
@KEY_051		equ  0033h
@KEY_052		equ  0034h
@KEY_053		equ  0035h
@KEY_054		equ  0036h
@KEY_055		equ  0037h
@KEY_056		equ  0038h
@KEY_057		equ  0039h
@KEY_058		equ  003Ah
@KEY_059		equ  003Bh
@KEY_060		equ  003Ch
@KEY_061		equ  003Dh
@KEY_062		equ  003Eh
@KEY_063		equ  003Fh
@KEY_064		equ  0040h
@KEY_065		equ  0041h
@KEY_066		equ  0042h
@KEY_067		equ  0043h
@KEY_068		equ  0044h
@KEY_069		equ  0045h
@KEY_070		equ  0046h
@KEY_071		equ  0047h
@KEY_072		equ  0048h
@KEY_073		equ  0049h
@KEY_074		equ  004Ah
@KEY_075		equ  004Bh
@KEY_076		equ  004Ch
@KEY_077		equ  004Dh
@KEY_078		equ  004Eh
@KEY_079		equ  004Fh
@KEY_080		equ  0050h
@KEY_081		equ  0051h
@KEY_082		equ  0052h
@KEY_083		equ  0053h
@KEY_084		equ  0054h
@KEY_085		equ  0055h
@KEY_086		equ  0056h
@KEY_087		equ  0057h
@KEY_088		equ  0058h
@KEY_089		equ  0059h
@KEY_090		equ  005Ah
@KEY_091		equ  005Bh
@KEY_092		equ  005Ch
@KEY_093		equ  005Dh
@KEY_094		equ  005Eh
@KEY_095		equ  005Fh
@KEY_096		equ  0060h
@KEY_097		equ  0061h
@KEY_098		equ  0062h
@KEY_099		equ  0063h
@KEY_100		equ  0064h
@KEY_101		equ  0065h
@KEY_102		equ  0066h
@KEY_103		equ  0067h
@KEY_104		equ  0068h
@KEY_105		equ  0069h
@KEY_106		equ  006Ah
@KEY_107		equ  006Bh
@KEY_108		equ  006Ch
@KEY_109		equ  006Dh
@KEY_110		equ  006Eh
@KEY_111		equ  006Fh
@KEY_112		equ  0070h
@KEY_113		equ  0071h
@KEY_114		equ  0072h
@KEY_115		equ  0073h
@KEY_116		equ  0074h
@KEY_117		equ  0075h
@KEY_118		equ  0076h
@KEY_119		equ  0077h
@KEY_120		equ  0078h
@KEY_121		equ  0079h
@KEY_122		equ  007Ah
@KEY_123		equ  007Bh
@KEY_124		equ  007Ch
@KEY_125		equ  007Dh
@KEY_126		equ  007Eh
@KEY_127		equ  007Fh
@KEY_128		equ  0080h
@KEY_129		equ  0081h
@KEY_130		equ  0082h
@KEY_131		equ  0083h
@KEY_132		equ  0084h
@KEY_133		equ  0085h
@KEY_134		equ  0086h
@KEY_135		equ  0087h
@KEY_136		equ  0088h
@KEY_137		equ  0089h
@KEY_138		equ  008Ah
@KEY_139		equ  008Bh
@KEY_140		equ  008Ch
@KEY_141		equ  008Dh
@KEY_142		equ  008Eh
@KEY_143		equ  008Fh
@KEY_144		equ  0090h
@KEY_145		equ  0091h
@KEY_146		equ  0092h
@KEY_147		equ  0093h
@KEY_148		equ  0094h
@KEY_149		equ  0095h
@KEY_150		equ  0096h
@KEY_151		equ  0097h
@KEY_152		equ  0098h
@KEY_153		equ  0099h
@KEY_154		equ  009Ah
@KEY_155		equ  009Bh
@KEY_156		equ  009Ch
@KEY_157		equ  009Dh
@KEY_158		equ  009Eh
@KEY_159		equ  009Fh
@KEY_160		equ  00A0h
@KEY_161		equ  00A1h
@KEY_162		equ  00A2h
@KEY_163		equ  00A3h
@KEY_164		equ  00A4h
@KEY_165		equ  00A5h
@KEY_166		equ  00A6h
@KEY_167		equ  00A7h
@KEY_168		equ  00A8h
@KEY_169		equ  00A9h
@KEY_170		equ  00AAh
@KEY_171		equ  00ABh
@KEY_172		equ  00ACh
@KEY_173		equ  00ADh
@KEY_174		equ  00AEh
@KEY_175		equ  00AFh
@KEY_176		equ  00B0h
@KEY_177		equ  00B1h
@KEY_178		equ  00B2h
@KEY_179		equ  00B3h
@KEY_180		equ  00B4h
@KEY_181		equ  00B5h
@KEY_182		equ  00B6h
@KEY_183		equ  00B7h
@KEY_184		equ  00B8h
@KEY_185		equ  00B9h
@KEY_186		equ  00BAh
@KEY_187		equ  00BBh
@KEY_188		equ  00BCh
@KEY_189		equ  00BDh
@KEY_190		equ  00BEh
@KEY_191		equ  00BFh
@KEY_192		equ  00C0h
@KEY_193		equ  00C1h
@KEY_194		equ  00C2h
@KEY_195		equ  00C3h
@KEY_196		equ  00C4h
@KEY_197		equ  00C5h
@KEY_198		equ  00C6h
@KEY_199		equ  00C7h
@KEY_200		equ  00C8h
@KEY_201		equ  00C9h
@KEY_202		equ  00CAh
@KEY_203		equ  00CBh
@KEY_204		equ  00CCh
@KEY_205		equ  00CDh
@KEY_206		equ  00CEh
@KEY_207		equ  00CFh
@KEY_208		equ  00D0h
@KEY_209		equ  00D1h
@KEY_210		equ  00D2h
@KEY_211		equ  00D3h
@KEY_212		equ  00D4h
@KEY_213		equ  00D5h
@KEY_214		equ  00D6h
@KEY_215		equ  00D7h
@KEY_216		equ  00D8h
@KEY_217		equ  00D9h
@KEY_218		equ  00DAh
@KEY_219		equ  00DBh
@KEY_220		equ  00DCh
@KEY_221		equ  00DDh
@KEY_222		equ  00DEh
@KEY_223		equ  00DFh
@KEY_224		equ  00E0h
@KEY_225		equ  00E1h
@KEY_226		equ  00E2h
@KEY_227		equ  00E3h
@KEY_228		equ  00E4h
@KEY_229		equ  00E5h
@KEY_230		equ  00E6h
@KEY_231		equ  00E7h
@KEY_232		equ  00E8h
@KEY_233		equ  00E9h
@KEY_234		equ  00EAh
@KEY_235		equ  00EBh
@KEY_236		equ  00ECh
@KEY_237		equ  00EDh
@KEY_238		equ  00EEh
@KEY_239		equ  00EFh
@KEY_240		equ  00F0h
@KEY_241		equ  00F1h
@KEY_242		equ  00F2h
@KEY_243		equ  00F3h
@KEY_244		equ  00F4h
@KEY_245		equ  00F5h
@KEY_246		equ  00F6h
@KEY_247		equ  00F7h
@KEY_248		equ  00F8h
@KEY_249		equ  00F9h
@KEY_250		equ  00FAh
@KEY_251		equ  00FBh
@KEY_252		equ  00FCh
@KEY_253		equ  00FDh
@KEY_254		equ  00FEh
@KEY_255		equ  00FFh

; In keycode order,

;;;;_ALT_ESC		equ  0100h

;;;;_CTL_2		equ  0300h

;;;;_ALT_BS		equ  0E00h
;;;;_SHF_TAB		equ  0F00h
;;;;_ALT_Q		equ  1000h
;;;;_ALT_W		equ  1100h
;;;;_ALT_E		equ  1200h
;;;;_ALT_R		equ  1300h
;;;;_ALT_T		equ  1400h
;;;;_ALT_Y		equ  1500h
;;;;_ALT_U		equ  1600h
;;;;_ALT_I		equ  1700h
;;;;_ALT_O		equ  1800h
;;;;_ALT_P		equ  1900h
;;;;_ALT_LBR		equ  1A00h
;;;;_ALT_RBR		equ  1B00h
;;;;_ALT_CR		equ  1C00h

;;;;_ALT_A		equ  1E00h
;;;;_ALT_S		equ  1F00h
;;;;_ALT_D		equ  2000h
;;;;_ALT_F		equ  2100h
;;;;_ALT_G		equ  2200h
;;;;_ALT_H		equ  2300h
;;;;_ALT_J		equ  2400h
;;;;_ALT_K		equ  2500h
;;;;_ALT_L		equ  2600h
;;;;_ALT_SEMI		equ  2700h
;;;;_ALT_QUOTE		equ  2800h
;;;;_ALT_BQUOTE 	equ  2900h
;;;;_ALT_BSLASH 	equ  2B00h
;;;;_ALT_Z		equ  2C00h
;;;;_ALT_X		equ  2D00h
;;;;_ALT_C		equ  2E00h
;;;;_ALT_V		equ  2F00h
;;;;_ALT_B		equ  3000h
;;;;_ALT_N		equ  3100h
;;;;_ALT_M		equ  3200h
;;;;_ALT_COMMA		equ  3300h
;;;;_ALT_PERIOD 	equ  3400h
;;;;_ALT_SLASH		equ  3500h

;;;;_ALT_PADSTAR	equ  3700h

;;;;_F1 		equ  3B00h
;;;;_F2 		equ  3C00h
;;;;_F3 		equ  3D00h
;;;;_F4 		equ  3E00h
;;;;_F5 		equ  3F00h
;;;;_F6 		equ  4000h
;;;;_F7 		equ  4100h
;;;;_F8 		equ  4200h
;;;;_F9 		equ  4300h
;;;;_F10		equ  4400h

;;;;_HOME		equ  4700h
;;;;_UP 		equ  4800h
;;;;_PGUP		equ  4900h
;;;;_ALT_PADMINUS	equ  4A00h
;;;;_LEFT		equ  4B00h
;;;;_PAD5		equ  4C00h
;;;;_RIGHT		equ  4D00h
;;;;_ALT_PADPLUS	equ  4E00h
;;;;_END		equ  4F00h
;;;;_DN 		equ  5000h
;;;;_PGDN		equ  5100h
;;;;_INS		equ  5200h
;;;;_DEL		equ  5300h
;;;;_SHF_F1		equ  5400h
;;;;_SHF_F2		equ  5500h
;;;;_SHF_F3		equ  5600h
;;;;_SHF_F4		equ  5700h
;;;;_SHF_F5		equ  5800h
;;;;_SHF_F6		equ  5900h
;;;;_SHF_F7		equ  5A00h
;;;;_SHF_F8		equ  5B00h
;;;;_SHF_F9		equ  5C00h
;;;;_SHF_F10		equ  5D00h
;;;;_CTL_F1		equ  5E00h
;;;;_CTL_F2		equ  5F00h
;;;;_CTL_F3		equ  6000h
;;;;_CTL_F4		equ  6100h
;;;;_CTL_F5		equ  6200h
;;;;_CTL_F6		equ  6300h
;;;;_CTL_F7		equ  6400h
;;;;_CTL_F8		equ  6500h
;;;;_CTL_F9		equ  6600h
;;;;_CTL_F10		equ  6700h
;;;;_ALT_F1		equ  6800h
;;;;_ALT_F2		equ  6900h
;;;;_ALT_F3		equ  6A00h
;;;;_ALT_F4		equ  6B00h
;;;;_ALT_F5		equ  6C00h
;;;;_ALT_F6		equ  6D00h
;;;;_ALT_F7		equ  6E00h
;;;;_ALT_F8		equ  6F00h
;;;;_ALT_F9		equ  7000h
;;;;_ALT_F10		equ  7100h

;;;;_CTL_LEFT		equ  7300h
;;;;_CTL_RIGHT		equ  7400h
;;;;_CTL_END		equ  7500h
;;;;_CTL_PGDN		equ  7600h
;;;;_CTL_HOME		equ  7700h
;;;;_ALT_1		equ  7800h
;;;;_ALT_2		equ  7900h
;;;;_ALT_3		equ  7A00h
;;;;_ALT_4		equ  7B00h
;;;;_ALT_5		equ  7C00h
;;;;_ALT_6		equ  7D00h
;;;;_ALT_7		equ  7E00h
;;;;_ALT_8		equ  7F00h
;;;;_ALT_9		equ  8000h
;;;;_ALT_0		equ  8100h
;;;;_ALT_MINUS		equ  8200h
;;;;_ALT_EQUAL		equ  8300h
;;;;_CTL_PGUP		equ  8400h
;;;;_F11		equ  8500h
;;;;_F12		equ  8600h
;;;;_SHF_F11		equ  8700h
;;;;_SHF_F12		equ  8800h
;;;;_CTL_F11		equ  8900h
;;;;_CTL_F12		equ  8A00h
;;;;_ALT_F11		equ  8B00h
;;;;_ALT_F12		equ  8C00h
;;;;_CTL_UP		equ  8D00h
;;;;_CTL_PADMINUS	equ  8E00h
;;;;_CTL_PAD5		equ  8F00h
;;;;_CTL_PADPLUS	equ  9000h
;;;;_CTL_DN		equ  9100h
;;;;_CTL_INS		equ  9200h
;;;;_CTL_DEL		equ  9300h
;;;;_CTL_TAB		equ  9400h
;;;;_CTL_PADSLASH	equ  9500h
;;;;_CTL_PADSTAR	equ  9600h
;;;;_ALT_XHOME		equ  9700h
;;;;_ALT_XUP		equ  9800h
;;;;_ALT_XPGUP		equ  9900h
;;;;_AWIN		equ  9A00h
;;;;_ALT_XLEFT		equ  9B00h
;;;;_SHF_AWIN		equ  9C00h
;;;;_ALT_XRIGHT 	equ  9D00h
;;;;_CTL_AWIN		equ  9E00h
;;;;_ALT_XEND		equ  9F00h
;;;;_ALT_XDN		equ 0A000h
;;;;_ALT_XPGDN		equ 0A100h
;;;;_ALT_XINS		equ 0A200h
;;;;_ALT_XDEL		equ 0A300h
;;;;_ALT_PADSLASH	equ 0A400h
;;;;_ALT_TAB		equ 0A500h
;;;;_ALT_PADENTER	equ 0A600h
;;;;_ALT_AWIN		equ 0A700h

;;;;_CTL_A		equ  1E01h
;;;;_CTL_B		equ  3002h
;;;;_CTL_C		equ  2E03h
;;;;_CTL_D		equ  2004h
;;;;_CTL_E		equ  1205h
;;;;_CTL_F		equ  2106h
;;;;_CTL_G		equ  2207h
;;;;_BS 		equ  0E08h
;;;;_CTL_H		equ  2308h
;;;;_TAB		equ  0F09h
;;;;_CTL_I		equ  1709h
;;;;_CTL_CR		equ  1C0Ah
;;;;_CTL_J		equ  240Ah
;;;;_CTL_PADENTER	equ 0E00Ah
;;;;_CTL_K		equ  250Bh
;;;;_CTL_L		equ  260Ch
;;;;_CR 		equ  1C0Dh
;;;;_SHF_CR		equ  1C0Dh
;;;;_CTL_M		equ  320Dh
;;;;_PADENTER		equ 0E00Dh
;;;;_CTL_N		equ  310Eh
;;;;_CTL_O		equ  180Fh
;;;;_CTL_P		equ  1910h
;;;;_CTL_Q		equ  1011h
;;;;_CTL_R		equ  1312h
;;;;_CTL_S		equ  1F13h
;;;;_CTL_T		equ  1414h
;;;;_CTL_U		equ  1615h
;;;;_CTL_V		equ  2F16h
;;;;_CTL_W		equ  1117h
;;;;_CTL_X		equ  2D18h
;;;;_CTL_Y		equ  1519h
;;;;_CTL_Z		equ  2C1Ah
;;;;_ESC		equ  011Bh
;;;;_CTL_LBR		equ  1A1Bh
;;;;_CTL_BSLASH 	equ  2B1Ch
;;;;_CTL_RBR		equ  1B1Dh
;;;;_CTL_6		equ  071Eh
;;;;_CTL_MINUS		equ  0C1Fh
;;;;_CTL_SPACE		equ  3920h
;;;;_SHF_SPACE		equ  3920h
;;;;_ALT_SPACE		equ  3920h
;;;;_SPACE		equ  3920h
;;;;_SHREIK		equ  0221h
;;;;_DQUOTE		equ  2822h
;;;;_POUND		equ  0423h
;;;;_DOLLAR		equ  0524h
;;;;_PCT		equ  0625h
;;;;_AMPER		equ  0826h
;;;;_QUOTE		equ  2827h
;;;;_LPAREN		equ  0A28h
;;;;_RPAREN		equ  0B29h
;;;;_STAR		equ  092Ah
;;;;_PADSTAR		equ  372Ah
;;;;_SHF_PADSTAR	equ  372Ah
;;;;_PLUS		equ  0D2Bh
;;;;_PADPLUS		equ  4E2Bh
;;;;_SHF_PADPLUS	equ  4E2Bh
;;;;_COMMA		equ  332Ch
;;;;_MINUS		equ  0C2Dh
;;;;_PADMINUS		equ  4A2Dh
;;;;_SHF_PADMINUS	equ  4A2Dh
;;;;_PERIOD		equ  342Eh
;;;;_SHF_DEL		equ  532Eh
;;;;_SLASH		equ  352Fh
;;;;_PADSLASH		equ 0E02Fh
;;;;_0			equ  0B30h
;;;;_SHF_INS		equ  5230h
;;;;_1			equ  0231h
;;;;_SHF_END		equ  4F31h
;;;;_2			equ  0332h
;;;;_SHF_DN		equ  5032h
;;;;_3			equ  0433h
;;;;_SHF_PGDN		equ  5133h
;;;;_4			equ  0534h
;;;;_SHF_LEFT		equ  4B34h
;;;;_5			equ  0635h
;;;;_SHF_PAD5		equ  4C35h
;;;;_6			equ  0736h
;;;;_SHF_RIGHT		equ  4D36h
;;;;_7			equ  0837h
;;;;_SHF_HOME		equ  4737h
;;;;_8			equ  0938h
;;;;_SHF_UP		equ  4838h
;;;;_9			equ  0A39h
;;;;_SHF_PGUP		equ  4939h
;;;;_COLON		equ  273Ah
;;;;_SEMI		equ  273Bh
;;;;_LCARET		equ  333Ch
;;;;_EQUAL		equ  0D3Dh
;;;;_RCARET		equ  343Eh
;;;;_QUERY		equ  353Fh
;;;;_ATSIGN		equ  0340h
;;;;_SHF_A		equ  1E41h
;;;;_SHF_B		equ  3042h
;;;;_SHF_C		equ  2E43h
;;;;_SHF_D		equ  2044h
;;;;_SHF_E		equ  1245h
;;;;_SHF_F		equ  2146h
;;;;_SHF_G		equ  2247h
;;;;_SHF_H		equ  2348h
;;;;_SHF_I		equ  1749h
;;;;_SHF_J		equ  244Ah
;;;;_SHF_K		equ  254Bh
;;;;_SHF_L		equ  264Ch
;;;;_SHF_M		equ  324Dh
;;;;_SHF_N		equ  314Eh
;;;;_SHF_O		equ  184Fh
;;;;_SHF_P		equ  1950h
;;;;_SHF_Q		equ  1051h
;;;;_SHF_R		equ  1352h
;;;;_SHF_S		equ  1F53h
;;;;_SHF_T		equ  1454h
;;;;_SHF_U		equ  1655h
;;;;_SHF_V		equ  2F56h
;;;;_SHF_W		equ  1157h
;;;;_SHF_X		equ  2D58h
;;;;_SHF_Y		equ  1559h
;;;;_SHF_Z		equ  2C5Ah
;;;;_LBR		equ  1A5Bh
;;;;_BSLASH		equ  2B5Ch
;;;;_RBR		equ  1B5Dh
;;;;_CARET		equ  075Eh
;;;;_UBAR		equ  0C5Fh
;;;;_BQUOTE		equ  2960h
;;;;_A			equ  1E61h
;;;;_B			equ  3062h
;;;;_C			equ  2E63h
;;;;_D			equ  2064h
;;;;_E			equ  1265h
;;;;_F			equ  2166h
;;;;_G			equ  2267h
;;;;_H			equ  2368h
;;;;_I			equ  1769h
;;;;_J			equ  246Ah
;;;;_K			equ  256Bh
;;;;_L			equ  266Ch
;;;;_M			equ  326Dh
;;;;_N			equ  316Eh
;;;;_O			equ  186Fh
;;;;_P			equ  1970h
;;;;_Q			equ  1071h
;;;;_R			equ  1372h
;;;;_S			equ  1F73h
;;;;_T			equ  1474h
;;;;_U			equ  1675h
;;;;_V			equ  2F76h
;;;;_W			equ  1177h
;;;;_X			equ  2D78h
;;;;_Y			equ  1579h
;;;;_Z			equ  2C7Ah
;;;;_LBRACE		equ  1A7Bh
;;;;_STILE		equ  2B7Ch
;;;;_RBRACE		equ  1B7Dh
;;;;_TILDE		equ  297Eh
;;;;_CTL_BS		equ  0E7Fh

;;;;_XHOME		equ  47E0h
;;;;_XUP		equ  48E0h
;;;;_XPGUP		equ  49E0h
;;;;_XLEFT		equ  4BE0h
;;;;_XRIGHT		equ  4DE0h
;;;;_XEND		equ  4FE0h
;;;;_XDN		equ  50E0h
;;;;_XPGDN		equ  51E0h
;;;;_XINS		equ  52E0h
;;;;_XDEL		equ  53E0h
;;;;_CTL_XLEFT		equ  73E0h
;;;;_CTL_XRIGHT 	equ  74E0h
;;;;_CTL_XEND		equ  75E0h
;;;;_CTL_XPGDN		equ  76E0h
;;;;_CTL_XHOME		equ  77E0h
;;;;_CTL_XPGUP		equ  84E0h
;;;;_CTL_XUP		equ  8DE0h
;;;;_CTL_XDN		equ  91E0h
;;;;_CTL_XINS		equ  92E0h
;;;;_CTL_XDEL		equ  93E0h

