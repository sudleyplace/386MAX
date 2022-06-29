extern	void p1browse(void );
static	char *astate(int ndx);
extern	void procmenu(struct _windesc *actwin,struct _windesc *txtwin,int nrows);
static	int toggle(int row);
static	void dadapwind(int rows,struct _windesc *mainwin,struct _windesc *actwin,struct _windesc *txtwin);
static	void cadapwind(struct _windesc *mainwin);
extern	void adapline(struct _windesc *actwin,struct _windesc *txtwin,int row,char *action,char *name,int high);
extern	unsigned short p1_input(struct _inputevent *event);
