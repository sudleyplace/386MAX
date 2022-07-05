; $Header:   P:/PVCS/MAX/QUILIB/QLOGOASQ.INV   1.1   04 Mar 1996 14:02:52   HENRY  $
;
; QLOGOASQ.INC - Data to build QLOGO.OVL
;
; Copyright (C) 1991-96 Qualitas, Inc.  GNU General Public License version 3.
;
; This file originally created by QLogoGen.C
;
; Changes on 1 Mar 96:
; Old		New
; Å (129)	’ (213)
; Ñ (132)	÷ (214)
; é (142)	◊ (215)
; ô (153)	ÿ (216)
; <n/a>		Ÿ (217)	; Required box drawing character
; <n/a>		⁄ (218)	; ...
; <n/a>		€ (219) ; ...
; § (164)	‹ (220)
; î (148)	› (221)
; ö (154)	€ (222)
;
; Remaining holes in the character map (224‡ used in numbering, 225· in De):
; 223	ﬁﬂ
; 226-255	‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛ˇ
;
; "ASQ" logo - 96 characters

	public wACount
wACount	dw	96

	public bALogo
bALogo	label byte
	db	'                      '
	db	'                      '
	db	'                      '
	db	'          Ä’ÇÉ÷ÖÜáà  '
	db	'         âä€€ã  å€€ç  '
	db	'  ◊èê   ëíì›€   ï€€ñ  '
	db	' óòÿﬁõúùûü†°€¢  £€€‹  '
	db	'•¶ß®©™´¨≠ÆØ∞±≤¥µ∂∑∏π  '
	db	'ΩΩæ¡ΩΩ¬√≈∆« ÀÃŒœ–—“”‘ '
	db	'                      '
	db	'                      '
	db	'                      '

; For sort:

; 000000000000000000 0000000103	(127 A)
; 000000000000030f1f 3fffffffff	(128 A)
; 0000010f3fffffffff ffffffffff	(129 A)
; 001fffffffffffffff fffffffefc	(130 A)
; 7fffffffffffffffff fffc800000	(131 A)
; fcffffffffffffffff ff3f070000	(132 A)
; 00f8ffffffffffffff ffffffff7f	(133 A)
; 000000e0f8feffffff ffffffffff	(134 A)
; 00000000000080c0f0 f8fcfeffff	(135 A)
; 000000000000000000 0000000080	(136 A)
; 000000000000000000 0000010101	(137 A)
; 070f1f1f3f3f7f7fff ffffffffff	(138 A)
; f8f0e0e0c0c0808080 8080000000	(139 A)
; 3f1f1f0f0f07070703 0303030303	(140 A)
; 80c0e0e0f0f0f8f8f8 fcfcfcfcfe	(141 A)
; 000000001f1f1f3f3f 7f7f7ffffe	(142 A)
; 00000000ffffffffff ffffffffff	(143 A)
; 0000000080c0c0c0e0 e0f0f0f8f8	(144 A)
; 000000000000000000 000000003f	(145 A)
; 010101030303030303 03030000ff	(146 A)
; ffffffffffffffffff ffffff1f86	(147 A)
; ffffffffffffffffff ffffff0000	(148 A)
; 030303010101010101 0101010101	(149 A)
; fefefefefeffffffff fffffefefe	(150 A)
; 00010103030307070f 0f1f1f1f3f	(151 A)
; fefefcfcfcf8f8f0f0 f0e0e0ffff	(152 A)
; ff7f7f7f3f3f3f1f1f 0f0f0fffff	(153 A)
; fcfcfcfefeffffffff ffffffffff	(154 A)
; 000000000000000080 8080c0c0e0	(155 A)
; 000000000001010303 0707070707	(156 A)
; 030f3f7fffffffffff ffffffffff	(157 A)
; fffffffffcf0c0c080 8080c0f0fe	(158 A)
; ffffffc30000010100 0000000000	(159 A)
; e0f8fdff7f1f8fc7e3 f87c3c1e0f	(160 A)
; 7cfcfcfcfcfcfcfcfc fcfc7c7c00	(161 A)
; 000000000080808080 8080c0c0c0	(162 A)
; 010303030303030303 0707070f0f	(163 A)
; fefefefefcfcfcfcf8 f8f0f0e0e0	(164 A)
; 000000000000010101 03030fffff	(165 A)
; 3f7f7ffffffffffefe fefcfcffff	(166 A)
; ffffffff8000000000 000000f0f0	(167 A)
; ffffffff0100000000 00001f1f1f	(168 A)
; ffffffffffffffffff 7f7f7fffff	(169 A)
; e0f0f0f0f8f8fcfcfe feffffffff	(170 A)
; 030301010000000000 000080ffff	(171 A)
; ffffffffff7f3f0f07 000000f0f8	(172 A)
; ffffffffffffffffff 7f03000000	(173 A)
; fcffffffffffffffff ffff030000	(174 A)
; 03f0feffffffffffff ffffff3f1f	(175 A)
; 007f1f8fe3f1f8fcfe ffffffffff	(176 A)
; ffffffffffffff7f7f 3f1f078080	(177 A)
; e0f0f8fcfeffffffff ffffff0f07	(178 A)
; 181818181818181818 1818181818	(179 A)
; 000000000080ffffff ffffffffff	(180 A)
; 000000000107ffffff ffffffffff	(181 A)
; 1f1f7fffffffffffff ffffffffff	(182 A)
; ffffffffffffffffff fffef00080	(183 A)
; fffffffffefcf8f0e0 8000000000	(184 A)
; c0c080000000000000 0000000000	(185 A)
; 363636363636363636 3636363636	(186 A)
; 0000000000fe06f636 3636363636	(187 A)
; 3636363636f606fe00 0000000000	(188 A)
; ffff00000000000000 0000000000	(189 A)
; f0f000000000000000 0000000000	(190 A)
; 00000000000000f818 1818181818	(191 A)
; 181818181818181f00 0000000000	(192 A)
; 1f1f00000000000000 0000000000	(193 A)
; ffff07030303030303 0303030000	(194 A)
; f8fcfeffffffffffff fffcf80000	(195 A)
; 00000000000000ff00 0000000000	(196 A)
; 0000000080e0f8ffff ffff1f0100	(197 A)
; 0000000000000080ff ffffffff00	(198 A)
; 0f070707070f1f7fff fffffff000	(199 A)
; 363636363637303f00 0000000000	(200 A)
; 00000000003f303736 3636363636	(201 A)
; fffffffffffffffefc f8e0800000	(202 A)
; 8081871f3f3f1f1f0f 0707030000	(203 A)
; 3ffffffffffffffffc f0c0000000	(204 A)
; 0000000000ff00ff00 0000000000	(205 A)
; fffffffffffff8c000 0000000000	(206 A)
; ffffffffffff000000 0000000000	(207 A)
; ffffffffffff3f0300 0000000000	(208 A)
; f0feffffffffffff1f 0100000000	(209 A)
; 0000e0ffffffffffff ff1f010000	(210 A)
; 000001ffffffffffff fffff80000	(211 A)
; 0060f0f8fcfefefffc f0c0000000	(212 A)


; Actual data:

	public	bAChar127
;  (127, 7fh)
bAChar127	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000011b


	public	bAChar128
; Ä (128, 80h)
bAChar128	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000011b
	db	00001111b
	db	00011111b
	db	00111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar129
;  €
; €Å€∞€ (129, 81h)
;  €
bAChar129	label byte
	db	00000000b
	db	00000000b
	db	11001100b
	db	00000000b
	db	00000000b
	db	11001100b
	db	11001100b
	db	11001100b
	db	11001100b
	db	11001100b
	db	01110110b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar130
; Ç (130, 82h)
bAChar130	label byte
	db	00000000b
	db	00011111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111110b
	db	11111100b


	public	bAChar131
; É (131, 83h)
bAChar131	label byte
	db	01111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111100b
	db	10000000b
	db	00000000b
	db	00000000b


	public	bAChar132
;  €
; €Ñ∞ (132, 84h)
;  ∞
bAChar132	label byte
	db	00000000b
	db	00000000b
	db	11001100b
	db	00000000b
	db	00000000b
	db	01111000b
	db	00001100b
	db	01111100b
	db	11001100b
	db	11001100b
	db	01110110b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar133
; Ö (133, 85h)
bAChar133	label byte
	db	00000000b
	db	11111000b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	01111111b


	public	bAChar134
; Ü (134, 86h)
bAChar134	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	11100000b
	db	11111000b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar135
; á (135, 87h)
bAChar135	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11000000b
	db	11110000b
	db	11111000b
	db	11111100b
	db	11111110b
	db	11111111b
	db	11111111b


	public	bAChar136
; à (136, 88h)
bAChar136	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b


	public	bAChar137
; â (137, 89h)
bAChar137	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000001b
	db	00000001b


	public	bAChar138
; ä (138, 8ah)
bAChar138	label byte
	db	00000111b
	db	00001111b
	db	00011111b
	db	00011111b
	db	00111111b
	db	00111111b
	db	01111111b
	db	01111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar139
; ã (139, 8bh)
bAChar139	label byte
	db	11111000b
	db	11110000b
	db	11100000b
	db	11100000b
	db	11000000b
	db	11000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar140
; å (140, 8ch)
bAChar140	label byte
	db	00111111b
	db	00011111b
	db	00011111b
	db	00001111b
	db	00001111b
	db	00000111b
	db	00000111b
	db	00000111b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b


	public	bAChar141
; ç (141, 8dh)
bAChar141	label byte
	db	10000000b
	db	11000000b
	db	11100000b
	db	11100000b
	db	11110000b
	db	11110000b
	db	11111000b
	db	11111000b
	db	11111000b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111110b


	public	bAChar142
;  €
; €é∞ (142, 8eh)
;  ∞
bAChar142	label byte
	db	00000000b
	db	11000110b
	db	00010000b
	db	00111000b
	db	01101100b
	db	11000110b
	db	11000110b
	db	11111110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar143
; è (143, 8fh)
bAChar143	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar144
; ê (144, 90h)
bAChar144	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11000000b
	db	11000000b
	db	11000000b
	db	11100000b
	db	11100000b
	db	11110000b
	db	11110000b
	db	11111000b
	db	11111000b


	public	bAChar145
; ë (145, 91h)
bAChar145	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111111b


	public	bAChar146
; í (146, 92h)
bAChar146	label byte
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000000b
	db	00000000b
	db	11111111b


	public	bAChar147
; ì (147, 93h)
bAChar147	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00011111b
	db	10000110b


	public	bAChar148
;  €
; €î∞ (148, 94h)
;  ∞
bAChar148	label byte
	db	00000000b
	db	00000000b
	db	01100110b
	db	00000000b
	db	00000000b
	db	01111100b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	01111100b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar149
; ï (149, 95h)
bAChar149	label byte
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b


	public	bAChar150
; ñ (150, 96h)
bAChar150	label byte
	db	11111110b
	db	11111110b
	db	11111110b
	db	11111110b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111110b
	db	11111110b
	db	11111110b


	public	bAChar151
; ó (151, 97h)
bAChar151	label byte
	db	00000000b
	db	00000001b
	db	00000001b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000111b
	db	00000111b
	db	00001111b
	db	00001111b
	db	00011111b
	db	00011111b
	db	00011111b
	db	00111111b


	public	bAChar152
; ò (152, 98h)
bAChar152	label byte
	db	11111110b
	db	11111110b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111000b
	db	11111000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11100000b
	db	11100000b
	db	11111111b
	db	11111111b


	public	bAChar153
;  €
; €ô∞ (153, 99h)
;  ∞
bAChar153	label byte
	db	00000000b
	db	11001100b
	db	00000000b
	db	01111100b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	01111100b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar154
;  €
; €ö∞ (154, 9ah)
;  ∞
bAChar154	label byte
	db	00000000b
	db	11000110b
	db	00000000b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11000110b
	db	01111100b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar155
; õ (155, 9bh)
bAChar155	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	11000000b
	db	11000000b
	db	11100000b


	public	bAChar156
; ú (156, 9ch)
bAChar156	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000001b
	db	00000011b
	db	00000011b
	db	00000111b
	db	00000111b
	db	00000111b
	db	00000111b
	db	00000111b


	public	bAChar157
; ù (157, 9dh)
bAChar157	label byte
	db	00000011b
	db	00001111b
	db	00111111b
	db	01111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar158
; û (158, 9eh)
bAChar158	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111100b
	db	11110000b
	db	11000000b
	db	11000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	11000000b
	db	11110000b
	db	11111110b


	public	bAChar159
; ü (159, 9fh)
bAChar159	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11000011b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000001b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar160
; † (160, a0h)
bAChar160	label byte
	db	11100000b
	db	11111000b
	db	11111101b
	db	11111111b
	db	01111111b
	db	00011111b
	db	10001111b
	db	11000111b
	db	11100011b
	db	11111000b
	db	01111100b
	db	00111100b
	db	00011110b
	db	00001111b


	public	bAChar161
; ° (161, a1h)
bAChar161	label byte
	db	01111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	01111100b
	db	01111100b
	db	00000000b


	public	bAChar162
; ¢ (162, a2h)
bAChar162	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	11000000b
	db	11000000b
	db	11000000b


	public	bAChar163
; £ (163, a3h)
bAChar163	label byte
	db	00000001b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000111b
	db	00000111b
	db	00000111b
	db	00001111b
	db	00001111b


	public	bAChar164
;  €
; €§∞ (164, a4h)
;  ∞
bAChar164	label byte
	db	00000000b
	db	00000000b
	db	01110110b
	db	11011100b
	db	00000000b
	db	11011100b
	db	01100110b
	db	01100110b
	db	01100110b
	db	01100110b
	db	01100110b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar165
; • (165, a5h)
bAChar165	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000011b
	db	00000011b
	db	00001111b
	db	11111111b
	db	11111111b


	public	bAChar166
; ¶ (166, a6h)
bAChar166	label byte
	db	00111111b
	db	01111111b
	db	01111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111110b
	db	11111110b
	db	11111110b
	db	11111100b
	db	11111100b
	db	11111111b
	db	11111111b


	public	bAChar167
; ß (167, a7h)
bAChar167	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	10000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11110000b
	db	11110000b


	public	bAChar168
; ® (168, a8h)
bAChar168	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00000001b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00011111b
	db	00011111b
	db	00011111b


	public	bAChar169
; © (169, a9h)
bAChar169	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	01111111b
	db	01111111b
	db	01111111b
	db	11111111b
	db	11111111b


	public	bAChar170
; ™ (170, aah)
bAChar170	label byte
	db	11100000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11111000b
	db	11111000b
	db	11111100b
	db	11111100b
	db	11111110b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar171
; ´ (171, abh)
bAChar171	label byte
	db	00000011b
	db	00000011b
	db	00000001b
	db	00000001b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11111111b
	db	11111111b


	public	bAChar172
; ¨ (172, ach)
bAChar172	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	01111111b
	db	00111111b
	db	00001111b
	db	00000111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11110000b
	db	11111000b


	public	bAChar173
; ≠ (173, adh)
bAChar173	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	01111111b
	db	00000011b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar174
; Æ (174, aeh)
bAChar174	label byte
	db	11111100b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00000011b
	db	00000000b
	db	00000000b


	public	bAChar175
; Ø (175, afh)
bAChar175	label byte
	db	00000011b
	db	11110000b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00111111b
	db	00011111b


	public	bAChar176
; ∞ (176, b0h)
bAChar176	label byte
	db	00000000b
	db	01111111b
	db	00011111b
	db	10001111b
	db	11100011b
	db	11110001b
	db	11111000b
	db	11111100b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar177
; ± (177, b1h)
bAChar177	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	01111111b
	db	01111111b
	db	00111111b
	db	00011111b
	db	00000111b
	db	10000000b
	db	10000000b


	public	bAChar178
; ≤ (178, b2h)
bAChar178	label byte
	db	11100000b
	db	11110000b
	db	11111000b
	db	11111100b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00001111b
	db	00000111b


	public	bAChar179
; ≥ (179, b3h)
bAChar179	label byte
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b


	public	bAChar180
; ¥ (180, b4h)
bAChar180	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar181
; µ (181, b5h)
bAChar181	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar182
; ∂ (182, b6h)
bAChar182	label byte
	db	00011111b
	db	00011111b
	db	01111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bAChar183
; ∑ (183, b7h)
bAChar183	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111110b
	db	11110000b
	db	00000000b
	db	10000000b


	public	bAChar184
; ∏ (184, b8h)
bAChar184	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111110b
	db	11111100b
	db	11111000b
	db	11110000b
	db	11100000b
	db	10000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar185
; π (185, b9h)
bAChar185	label byte
	db	11000000b
	db	11000000b
	db	10000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar186
; ∫ (186, bah)
bAChar186	label byte
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b


	public	bAChar187
; ª (187, bbh)
bAChar187	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111110b
	db	00000110b
	db	11110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b


	public	bAChar188
; º (188, bch)
bAChar188	label byte
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	11110110b
	db	00000110b
	db	11111110b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar189
; Ω (189, bdh)
bAChar189	label byte
	db	11111111b
	db	11111111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar190
; æ (190, beh)
bAChar190	label byte
	db	11110000b
	db	11110000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar191
; ø (191, bfh)
bAChar191	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b


	public	bAChar192
; ¿ (192, c0h)
bAChar192	label byte
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar193
; ¡ (193, c1h)
bAChar193	label byte
	db	00011111b
	db	00011111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar194
; ¬ (194, c2h)
bAChar194	label byte
	db	11111111b
	db	11111111b
	db	00000111b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000000b
	db	00000000b


	public	bAChar195
; √ (195, c3h)
bAChar195	label byte
	db	11111000b
	db	11111100b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111100b
	db	11111000b
	db	00000000b
	db	00000000b


	public	bAChar196
; ƒ (196, c4h)
bAChar196	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar197
; ≈ (197, c5h)
bAChar197	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11100000b
	db	11111000b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00011111b
	db	00000001b
	db	00000000b


	public	bAChar198
; ∆ (198, c6h)
bAChar198	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00000000b


	public	bAChar199
; « (199, c7h)
bAChar199	label byte
	db	00001111b
	db	00000111b
	db	00000111b
	db	00000111b
	db	00000111b
	db	00001111b
	db	00011111b
	db	01111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11110000b
	db	00000000b


	public	bAChar200
; » (200, c8h)
bAChar200	label byte
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110111b
	db	00110000b
	db	00111111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar201
; … (201, c9h)
bAChar201	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111111b
	db	00110000b
	db	00110111b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b
	db	00110110b


	public	bAChar202
;   (202, cah)
bAChar202	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111110b
	db	11111100b
	db	11111000b
	db	11100000b
	db	10000000b
	db	00000000b
	db	00000000b


	public	bAChar203
; À (203, cbh)
bAChar203	label byte
	db	10000000b
	db	10000001b
	db	10000111b
	db	00011111b
	db	00111111b
	db	00111111b
	db	00011111b
	db	00011111b
	db	00001111b
	db	00000111b
	db	00000111b
	db	00000011b
	db	00000000b
	db	00000000b


	public	bAChar204
; Ã (204, cch)
bAChar204	label byte
	db	00111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111100b
	db	11110000b
	db	11000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar205
; Õ (205, cdh)
bAChar205	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111111b
	db	00000000b
	db	11111111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar206
; Œ (206, ceh)
bAChar206	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111000b
	db	11000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar207
; œ (207, cfh)
bAChar207	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar208
; – (208, d0h)
bAChar208	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00111111b
	db	00000011b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar209
; — (209, d1h)
bAChar209	label byte
	db	11110000b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00011111b
	db	00000001b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar210
; “ (210, d2h)
bAChar210	label byte
	db	00000000b
	db	00000000b
	db	11100000b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00011111b
	db	00000001b
	db	00000000b
	db	00000000b


	public	bAChar211
; ” (211, d3h)
bAChar211	label byte
	db	00000000b
	db	00000000b
	db	00000001b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111000b
	db	00000000b
	db	00000000b


	public	bAChar212
; ‘ (212, d4h)
bAChar212	label byte
	db	00000000b
	db	01100000b
	db	11110000b
	db	11111000b
	db	11111100b
	db	11111110b
	db	11111110b
	db	11111111b
	db	11111100b
	db	11110000b
	db	11000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bAChar213
; ’ (213, d5h) was Å 129
bAChar213	label byte
	db	00000000b
	db	00000000b
	db	00000001b
	db	00001111b
	db	00111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b

	public	bAChar214
; ÷ (214, d6h) was Ñ 132
bAChar214	label byte
	db	11111100b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00111111b
	db	00000111b
	db	00000000b
	db	00000000b

	public	bAChar215
; ◊ (215, d7h) was é (142)	
bAChar215	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00011111b
	db	00011111b
	db	00011111b
	db	00111111b
	db	00111111b
	db	01111111b
	db	01111111b
	db	01111111b
	db	11111111b
	db	11111110b

	public	bAChar216
; ÿ (216, d8h) was ô (153)	
bAChar216	label byte
	db	11111111b
	db	01111111b
	db	01111111b
	db	01111111b
	db	00111111b
	db	00111111b
	db	00111111b
	db	00011111b
	db	00011111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	11111111b
	db	11111111b

	public	bAChar217
; Ÿ (217, d9h) added - required box drawing character
bAChar217	label byte
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	11111000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	public	bAChar218
; ⁄ (218, dah) ...
bAChar218	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00011111b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b

	public	bAChar219
; € (219, dbh) ...
bAChar219	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b

	public	bAChar220
; ‹ (220, dch) was § (164)	
bAChar220	label byte
	db	11111110b
	db	11111110b
	db	11111110b
	db	11111110b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111000b
	db	11111000b
	db	11110000b
	db	11110000b
	db	11100000b
	db	11100000b

	public	bAChar221
; › (221, ddh) was î (148)	
bAChar221	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00000000b
	db	00000000b

	public	bAChar222
; ﬁ (222, deh) was ö (154)	
bAChar222	label byte
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111110b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b

