; $Header:   P:/PVCS/MAX/QUILIB/QLOGO_Q.INV   1.1   01 Mar 1996 18:42:44   HENRY  $
;
; QLOGO_Q.INC - Data to build QLOGO.OVL
;
; Copyright (C) 1991-96 Qualitas, Inc.  GNU General Public License version 3.
;
; This file originally created by QLogoGen.C
;
; Changes on 1 Mar 96:
; Old		New
; � (129)	� (231)
; � (132)	� (232)
; � (142)	� (233)
; � (153)	� (234)
; � (154)	� (235)
; � (164)	� (236)
; � (148)	� (237)
;
; "Q" logo - 111 characters

	public wQCount
wQCount	dw	111

	public bQLogo
bQLogo	label byte
	db	'   �炃�ۅ�����      '
	db	' �����ۍ鏐���ے��    '
	db	'�����ۗ     �������   '
	db	'�����ۜ     �����۞   '
	db	'������       ����۠   '
	db	'������       ����ۢ   '
	db	'�������     �����ۦ   '
	db	'�����۩     ����۫�   '
	db	' �����۰������۶��    '
	db	'    ������������� ��� '
	db	'    ����������������� '
	db	'     �          ����  '

; For sort:

; 000000000000000000 0001071f3f	(127 Q)
; 00000000000001073f ffffffffff	(128 Q)
; 000000000f7fffffff ffffffffff	(129 Q)
; 00000fffffffffffff ffffffffff	(130 Q)
; 003fffffffffffffff ffffffffff	(131 Q)
; 7fffffffffffffffff ffffffffff	(132 Q)
; fcffffffffffffffff ffffffffff	(133 Q)
; 00f0ffffffffffffff ffffffffff	(134 Q)
; 0000c0fcffffffffff ffffffffff	(135 Q)
; 0000000080f8feffff ffffffffff	(136 Q)
; 00000000000000c0f0 fcffffffff	(137 Q)
; 000000000000000000 0000c0f0f8	(138 Q)
; 000000000000000000 0103070f0f	(139 Q)
; 000103070f3f7fffff ffffffffff	(140 Q)
; ffffffffffffffffff fcf0c08000	(141 Q)
; ffffffffffffffe000 0000000000	(142 Q)
; ffffffffffff000000 0000000000	(143 Q)
; ffffffffffffff0700 0000000000	(144 Q)
; ffffffffffffffffff 3f0f070100	(145 Q)
; feffffffffffffffff ffffffffff	(146 Q)
; 000080c0e0f8fcfeff ffffffffff	(147 Q)
; 000000000000000000 0080c0e0f0	(148 Q)
; 000000000000000101 0303070707	(149 Q)
; 1f3f3f7fffffffffff ffffffffff	(150 Q)
; fffefcfcf8f8f0f0e0 e0e0c0c0c0	(151 Q)
; ff7f3f3f1f1f0f0f0f 0707070303	(152 Q)
; f8f8fcfefeffffffff ffffffffff	(153 Q)
; 000000000000008080 80c0c0e0e0	(154 Q)
; 0f0f1f1f1f1f3f3f3f 3f7f7f7f7f	(155 Q)
; c0c080808080808000 0000000000	(156 Q)
; 030301010101010100 0000000000	(157 Q)
; f0f0f0f8f8f8fcfcfc fcfcfefefe	(158 Q)
; 7f7f7f7fffffffffff ffffffffff	(159 Q)
; fefefeffffffffffff ffffffffff	(160 Q)
; ffffffffffffffff7f 7f7f7f7f7f	(161 Q)
; ffffffffffffffffff fffefefefe	(162 Q)
; 7f7f3f3f3f3f1f1f1f 1f0f0f0f07	(163 Q)
; 000000000000008080 80808080c0	(164 Q)
; 000000000000010101 0103030303	(165 Q)
; fefefefcfcfcfcf8f8 f8f0f0f0e0	(166 Q)
; 070303010100000000 0000000000	(167 Q)
; ffffffffffffff7f7f 3f1f0f0707	(168 Q)
; c0c0c0c0e0e0e0f0f0 f8f8fcfeff	(169 Q)
; 030707070f0f1f1f1f 3f7f7fffff	(170 Q)
; fffffffffffffffffe fefcf8f8f0	(171 Q)
; e0e0c0c08080000000 0000000000	(172 Q)
; 030100000000000000 0000000000	(173 Q)
; ffffff7f3f1f070301 0000000000	(174 Q)
; ffffffffffffffffff 7f1f070300	(175 Q)
; 0080e0f8fcffffffff ffffffffff	(176 Q)
; 000000000080feffff ffffffffff	(177 Q)
; 00000000000003ffff ffffffffff	(178 Q)
; 181818181818181818 1818181818	(179 Q)
; 000000000007ffffff ffffffffff	(180 Q)
; 03071f3fffffffffff ffffffffff	(181 Q)
; ffffffffffffffffff fffffef8e0	(182 Q)
; fffffffffffef8f0e0 c000000000	(183 Q)
; e0c080800000000000 0000000000	(184 Q)
; 1f0300000000000000 0000000003	(185 Q)
; 363636363636363636 3636363636	(186 Q)
; 0000000000fe06f636 3636363636	(187 Q)
; 3636363636f606fe00 0000000000	(188 Q)
; ffff3f030000000000 01073fffff	(189 Q)
; ffffffff070101073f ffffffffff	(190 Q)
; 00000000000000f818 1818181818	(191 Q)
; 181818181818181f00 0000000000	(192 Q)
; fffffffff8e0f0fcff ffffffffff	(193 Q)
; fffef8800000000080 f8ffffffff	(194 Q)
; 800000000000000000 0000f0ffff	(195 Q)
; 00000000000000ff00 0000000000	(196 Q)
; 000000000000000000 00000000f8	(197 Q)
; 000000000000000000 0000000107	(198 Q)
; 000000000000000000 020f7fffff	(199 Q)
; 363636363637303f00 0000000000	(200 Q)
; 00000000003f303736 3636363636	(201 Q)
; 000000000000000000 00008080c0	(202 Q)
; 0f1f3f1f1f0f0f0703 0301010000	(203 Q)
; ffffffffffffffffff fffffef0c0	(204 Q)
; 0000000000ff00ff00 0000000000	(205 Q)
; fffffffffffffffffe f080000000	(206 Q)
; fffffffffffff8c000 0000000000	(207 Q)
; ffffffffffc0000000 0000000000	(208 Q)
; ffffffffff00000000 0000000000	(209 Q)
; ffffffffff0f000000 0000000000	(210 Q)
; ffffffffffff7f0700 0000000000	(211 Q)
; ffffffffffffffff7f 0300000000	(212 Q)
; ffffffffffffffffff ff3f070000	(213 Q)
; ffffffffffffffffff ffffff3f03	(214 Q)
; ffffffffffffffffff fffffffff8	(215 Q)
; e0e0f0f8fcfcfefffe fcf0c00000	(216 Q)
; 18181818181818f800 0000000000	(217 Q)
; 000000000000001f18 1818181818	(218 Q)
; ffffffffffffffffff ffffffffff	(219 Q)
; 00000000000000ffff ffffffffff	(220 Q)
; f0f0f0f0f0f0f0f0f0 f0f0f0f0f0	(221 Q)
; 0f0f0f0f0f0f0f0f0f 0f0f0f0f0f	(222 Q)
; ffffffffffffff0000 0000000000	(223 Q)
; 000000324c48484c32 0000000000	(224 Q)
; 00001c224478444244 7840400000	(225 Q)
; ffff00000000000000 0000000000	(226 Q)
; fffc00000000000000 0000000000	(227 Q)
; c00000000000000000 0000000000	(228 Q)
; 7f7c20000000000000 0000000000	(229 Q)
; 3f0300000000000000 0000000000	(230 Q)


; Actual data:

	public	bQChar127
;  (127, 7fh)
bQChar127	label byte
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
	db	00000111b
	db	00011111b
	db	00111111b


	public	bQChar128
; � (128, 80h)
bQChar128	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000111b
	db	00111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar129
;  �
; ہ۰� (129, 81h)
;  �
bQChar129	label byte
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

	public	bQChar130
; � (130, 82h)
bQChar130	label byte
	db	00000000b
	db	00000000b
	db	00001111b
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


	public	bQChar131
; � (131, 83h)
bQChar131	label byte
	db	00000000b
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
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar132
;  �
; ۄ� (132, 84h)
;  �
bQChar132	label byte
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


	public	bQChar133
; � (133, 85h)
bQChar133	label byte
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
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar134
; � (134, 86h)
bQChar134	label byte
	db	00000000b
	db	11110000b
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


	public	bQChar135
; � (135, 87h)
bQChar135	label byte
	db	00000000b
	db	00000000b
	db	11000000b
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


	public	bQChar136
; � (136, 88h)
bQChar136	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11111000b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar137
; � (137, 89h)
bQChar137	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11000000b
	db	11110000b
	db	11111100b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar138
; � (138, 8ah)
bQChar138	label byte
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
	db	11000000b
	db	11110000b
	db	11111000b


	public	bQChar139
; � (139, 8bh)
bQChar139	label byte
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
	db	00000111b
	db	00001111b
	db	00001111b


	public	bQChar140
; � (140, 8ch)
bQChar140	label byte
	db	00000000b
	db	00000001b
	db	00000011b
	db	00000111b
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


	public	bQChar141
; � (141, 8dh)
bQChar141	label byte
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
	db	11110000b
	db	11000000b
	db	10000000b
	db	00000000b


	public	bQChar142
;  �
; ێ� (142, 8eh)
;  �
bQChar142	label byte
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


	public	bQChar143
; � (143, 8fh)
bQChar143	label byte
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


	public	bQChar144
; � (144, 90h)
bQChar144	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00000111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar145
; � (145, 91h)
bQChar145	label byte
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
	db	00001111b
	db	00000111b
	db	00000001b
	db	00000000b


	public	bQChar146
; � (146, 92h)
bQChar146	label byte
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
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar147
; � (147, 93h)
bQChar147	label byte
	db	00000000b
	db	00000000b
	db	10000000b
	db	11000000b
	db	11100000b
	db	11111000b
	db	11111100b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar148
;  �
; ۔� (148, 94h)
;  �
bQChar148	label byte
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


	public	bQChar149
; � (149, 95h)
bQChar149	label byte
	db	00000000b
	db	00000000b
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


	public	bQChar150
; � (150, 96h)
bQChar150	label byte
	db	00011111b
	db	00111111b
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


	public	bQChar151
; � (151, 97h)
bQChar151	label byte
	db	11111111b
	db	11111110b
	db	11111100b
	db	11111100b
	db	11111000b
	db	11111000b
	db	11110000b
	db	11110000b
	db	11100000b
	db	11100000b
	db	11100000b
	db	11000000b
	db	11000000b
	db	11000000b


	public	bQChar152
; � (152, 98h)
bQChar152	label byte
	db	11111111b
	db	01111111b
	db	00111111b
	db	00111111b
	db	00011111b
	db	00011111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00000111b
	db	00000111b
	db	00000111b
	db	00000011b
	db	00000011b


	public	bQChar153
;  �
; ۙ� (153, 99h)
;  �
bQChar153	label byte
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


	public	bQChar154
;  �
; ۚ� (154, 9ah)
;  �
bQChar154	label byte
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


	public	bQChar155
; � (155, 9bh)
bQChar155	label byte
	db	00001111b
	db	00001111b
	db	00011111b
	db	00011111b
	db	00011111b
	db	00011111b
	db	00111111b
	db	00111111b
	db	00111111b
	db	00111111b
	db	01111111b
	db	01111111b
	db	01111111b
	db	01111111b


	public	bQChar156
; � (156, 9ch)
bQChar156	label byte
	db	11000000b
	db	11000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar157
; � (157, 9dh)
bQChar157	label byte
	db	00000011b
	db	00000011b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar158
; � (158, 9eh)
bQChar158	label byte
	db	11110000b
	db	11110000b
	db	11110000b
	db	11111000b
	db	11111000b
	db	11111000b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111110b
	db	11111110b
	db	11111110b


	public	bQChar159
; � (159, 9fh)
bQChar159	label byte
	db	01111111b
	db	01111111b
	db	01111111b
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


	public	bQChar160
; � (160, a0h)
bQChar160	label byte
	db	11111110b
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
	db	11111111b
	db	11111111b


	public	bQChar161
; � (161, a1h)
bQChar161	label byte
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
	db	01111111b
	db	01111111b
	db	01111111b


	public	bQChar162
; � (162, a2h)
bQChar162	label byte
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
	db	11111110b
	db	11111110b
	db	11111110b


	public	bQChar163
; � (163, a3h)
bQChar163	label byte
	db	01111111b
	db	01111111b
	db	00111111b
	db	00111111b
	db	00111111b
	db	00111111b
	db	00011111b
	db	00011111b
	db	00011111b
	db	00011111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00000111b


	public	bQChar164
;  �
; ۤ� (164, a4h)
;  �
bQChar164	label byte
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


	public	bQChar165
; � (165, a5h)
bQChar165	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000011b
	db	00000011b
	db	00000011b
	db	00000011b


	public	bQChar166
; � (166, a6h)
bQChar166	label byte
	db	11111110b
	db	11111110b
	db	11111110b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111100b
	db	11111000b
	db	11111000b
	db	11111000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11100000b


	public	bQChar167
; � (167, a7h)
bQChar167	label byte
	db	00000111b
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
	db	00000000b
	db	00000000b


	public	bQChar168
; � (168, a8h)
bQChar168	label byte
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
	db	00001111b
	db	00000111b
	db	00000111b


	public	bQChar169
; � (169, a9h)
bQChar169	label byte
	db	11000000b
	db	11000000b
	db	11000000b
	db	11000000b
	db	11100000b
	db	11100000b
	db	11100000b
	db	11110000b
	db	11110000b
	db	11111000b
	db	11111000b
	db	11111100b
	db	11111110b
	db	11111111b


	public	bQChar170
; � (170, aah)
bQChar170	label byte
	db	00000011b
	db	00000111b
	db	00000111b
	db	00000111b
	db	00001111b
	db	00001111b
	db	00011111b
	db	00011111b
	db	00011111b
	db	00111111b
	db	01111111b
	db	01111111b
	db	11111111b
	db	11111111b


	public	bQChar171
; � (171, abh)
bQChar171	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111110b
	db	11111110b
	db	11111100b
	db	11111000b
	db	11111000b
	db	11110000b


	public	bQChar172
; � (172, ach)
bQChar172	label byte
	db	11100000b
	db	11100000b
	db	11000000b
	db	11000000b
	db	10000000b
	db	10000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar173
; � (173, adh)
bQChar173	label byte
	db	00000011b
	db	00000001b
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


	public	bQChar174
; � (174, aeh)
bQChar174	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	01111111b
	db	00111111b
	db	00011111b
	db	00000111b
	db	00000011b
	db	00000001b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar175
; � (175, afh)
bQChar175	label byte
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
	db	00011111b
	db	00000111b
	db	00000011b
	db	00000000b


	public	bQChar176
; � (176, b0h)
bQChar176	label byte
	db	00000000b
	db	10000000b
	db	11100000b
	db	11111000b
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


	public	bQChar177
; � (177, b1h)
bQChar177	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar178
; � (178, b2h)
bQChar178	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000011b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar179
; � (179, b3h)
bQChar179	label byte
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


	public	bQChar180
; � (180, b4h)
bQChar180	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar181
; � (181, b5h)
bQChar181	label byte
	db	00000011b
	db	00000111b
	db	00011111b
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
	db	11111111b


	public	bQChar182
; � (182, b6h)
bQChar182	label byte
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
	db	11111110b
	db	11111000b
	db	11100000b


	public	bQChar183
; � (183, b7h)
bQChar183	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111110b
	db	11111000b
	db	11110000b
	db	11100000b
	db	11000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar184
; � (184, b8h)
bQChar184	label byte
	db	11100000b
	db	11000000b
	db	10000000b
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


	public	bQChar185
; � (185, b9h)
bQChar185	label byte
	db	00011111b
	db	00000011b
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
	db	00000011b


	public	bQChar186
; � (186, bah)
bQChar186	label byte
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


	public	bQChar187
; � (187, bbh)
bQChar187	label byte
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


	public	bQChar188
; � (188, bch)
bQChar188	label byte
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


	public	bQChar189
; � (189, bdh)
bQChar189	label byte
	db	11111111b
	db	11111111b
	db	00111111b
	db	00000011b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000001b
	db	00000111b
	db	00111111b
	db	11111111b
	db	11111111b


	public	bQChar190
; � (190, beh)
bQChar190	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00000111b
	db	00000001b
	db	00000001b
	db	00000111b
	db	00111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar191
; � (191, bfh)
bQChar191	label byte
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


	public	bQChar192
; � (192, c0h)
bQChar192	label byte
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


	public	bQChar193
; � (193, c1h)
bQChar193	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111000b
	db	11100000b
	db	11110000b
	db	11111100b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar194
; � (194, c2h)
bQChar194	label byte
	db	11111111b
	db	11111110b
	db	11111000b
	db	10000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	11111000b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar195
; � (195, c3h)
bQChar195	label byte
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
	db	11110000b
	db	11111111b
	db	11111111b


	public	bQChar196
; � (196, c4h)
bQChar196	label byte
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


	public	bQChar197
; � (197, c5h)
bQChar197	label byte
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
	db	11111000b


	public	bQChar198
; � (198, c6h)
bQChar198	label byte
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
	db	00000111b


	public	bQChar199
; � (199, c7h)
bQChar199	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000010b
	db	00001111b
	db	01111111b
	db	11111111b
	db	11111111b


	public	bQChar200
; � (200, c8h)
bQChar200	label byte
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


	public	bQChar201
; � (201, c9h)
bQChar201	label byte
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


	public	bQChar202
; � (202, cah)
bQChar202	label byte
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
	db	10000000b
	db	11000000b


	public	bQChar203
; � (203, cbh)
bQChar203	label byte
	db	00001111b
	db	00011111b
	db	00111111b
	db	00011111b
	db	00011111b
	db	00001111b
	db	00001111b
	db	00000111b
	db	00000011b
	db	00000011b
	db	00000001b
	db	00000001b
	db	00000000b
	db	00000000b


	public	bQChar204
; � (204, cch)
bQChar204	label byte
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
	db	11111110b
	db	11110000b
	db	11000000b


	public	bQChar205
; � (205, cdh)
bQChar205	label byte
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


	public	bQChar206
; � (206, ceh)
bQChar206	label byte
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
	db	10000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar207
; � (207, cfh)
bQChar207	label byte
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


	public	bQChar208
; � (208, d0h)
bQChar208	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar209
; � (209, d1h)
bQChar209	label byte
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
	db	00000000b


	public	bQChar210
; � (210, d2h)
bQChar210	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	00001111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar211
; � (211, d3h)
bQChar211	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	01111111b
	db	00000111b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar212
; � (212, d4h)
bQChar212	label byte
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
	db	00000000b


	public	bQChar213
; � (213, d5h)
bQChar213	label byte
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
	db	00111111b
	db	00000111b
	db	00000000b
	db	00000000b


	public	bQChar214
; � (214, d6h)
bQChar214	label byte
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
	db	00111111b
	db	00000011b


	public	bQChar215
; � (215, d7h)
bQChar215	label byte
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
	db	11111000b


	public	bQChar216
; � (216, d8h)
bQChar216	label byte
	db	11100000b
	db	11100000b
	db	11110000b
	db	11111000b
	db	11111100b
	db	11111100b
	db	11111110b
	db	11111111b
	db	11111110b
	db	11111100b
	db	11110000b
	db	11000000b
	db	00000000b
	db	00000000b


	public	bQChar217
; � (217, d9h)
bQChar217	label byte
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


	public	bQChar218
; � (218, dah)
bQChar218	label byte
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


	public	bQChar219
; � (219, dbh)
bQChar219	label byte
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


	public	bQChar220
; � (220, dch)
bQChar220	label byte
	db	00000000b
	db	00000000b
	db	00000000b
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


	public	bQChar221
; � (221, ddh)
bQChar221	label byte
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b
	db	11110000b


	public	bQChar222
; � (222, deh)
bQChar222	label byte
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b
	db	00001111b


	public	bQChar223
; � (223, dfh)
bQChar223	label byte
	db	11111111b
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


	public	bQChar224
;  �
; �� (224, e0h)
;  �
bQChar224	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01110110b
	db	11011100b
	db	11011000b
	db	11011000b
	db	11011100b
	db	01110110b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar225
;  �
; �� (225, e1h)
;  �
bQChar225	label byte
	db	00000000b
	db	00000000b
	db	01111000b
	db	11001100b
	db	11001100b
	db	11011000b
	db	11001100b
	db	11000110b
	db	11000110b
	db	11000110b
	db	11001100b
	db	00000000b
	db	00000000b
	db	00000000b


	public	bQChar226
; � (226, e2h)
bQChar226	label byte
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


	public	bQChar227
; � (227, e3h)
bQChar227	label byte
	db	11111111b
	db	11111100b
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


	public	bQChar228
; � (228, e4h)
bQChar228	label byte
	db	11000000b
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


	public	bQChar229
; � (229, e5h)
bQChar229	label byte
	db	01111111b
	db	01111100b
	db	00100000b
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


	public	bQChar230
; � (230, e6h)
bQChar230	label byte
	db	00111111b
	db	00000011b
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


	public	bQChar231
; � (231, e7h) was 129 �
bQChar231	label byte
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00001111b
	db	01111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b


	public	bQChar232
; � (232, e8h) was 132 �
bQChar232	label byte
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
	db	11111111b
	db	11111111b

	public	bQChar233
; � (233, e9h) was 142 �
bQChar233	label byte
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11111111b
	db	11100000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	public	bQChar234
; � (234, eah) was 153 �
bQChar234	label byte
	db	11111000b
	db	11111000b
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

	public	bQChar235
; � (235, ebh) was 154 �
bQChar235	label byte
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
	db	11100000b

	public	bQChar236
; � (236, ech) was 164 �
bQChar236	label byte
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
	db	10000000b
	db	10000000b
	db	10000000b
	db	11000000b

	public	bQChar237
; � (237, edh) was 148 �
bQChar237	label byte
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
	db	11000000b
	db	11100000b
	db	11110000b

