extern	void do_encryptsrc(void );
extern	void do_encryptdest(void );
extern	void write_encryption(char *filedir,struct _FILESTRUC *pfstr,char *pat,int patlen);
extern	void encrypt(unsigned char *str,unsigned int len);
extern	void decrypt(unsigned char *str,unsigned int len);
extern	void do_update(void );
extern	int read_encryption(char *filedir,struct _FILESTRUC *pfstr);
