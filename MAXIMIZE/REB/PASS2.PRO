extern	void pass2(void );
static	char *p2_acttext(struct _dsptext *dsp);
static	int p2_toggle(int ndx,int first,int last,struct _windesc *actwin,struct _windesc *txtwin,struct _texthd **dsparray ,int trows,int ctrow,int cbrow,int crow,char *(*bldfn)(struct _dsptext *));
extern	void wrbatfile(int pass);
