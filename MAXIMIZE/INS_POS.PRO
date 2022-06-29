/*' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_POS.PRV   1.0   05 Sep 1995 16:32:46   HENRY  $ */

int posinit (void);
void posread (int, char far *, char far *, WORD far *);
void poswrite (int, char far *, char far *, WORD far *);
void nvramcheck (void);
void inton (void);
void intoff (void);
