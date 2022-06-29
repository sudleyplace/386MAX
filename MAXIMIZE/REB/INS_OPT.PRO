extern	void optimize(void );
static	void walk_devices(struct _device *D);
static	int no_conflict(void );
static	void check_choice(void );
static	void analyze_choice(void );
static	int check_conflict(struct _adf_choice *A,unsigned char with);
