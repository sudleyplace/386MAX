// MAXMETER.H - includes for MAXMETER.C
// Copyright 1995 Rex Conn for Qualitas Inc.


// Date and time structure
typedef struct _DATETIME {
	unsigned char   hours;			// current hour
	unsigned char   minutes;		// current minute
	unsigned char   seconds;		// current second
	unsigned char   hundredths;		// current hundredths of a second
	unsigned char   day;			// current day
	unsigned char   month;			// current month
	short  year;			// current year
	unsigned char   weekday;		// current day of week
} DATETIME;


// Country information structure (international versions)
typedef struct {
	unsigned char cID;
	short nLength;
	short nCountryID;
	short nCodePageID;
	short fsDateFmt;
	unsigned char szCurrency[5];
	unsigned char szThousandsSeparator[2];
	unsigned char szDecimal[2];
	unsigned char szDateSeparator[2];
	unsigned char szTimeSeparator[2];
	unsigned char fsCurrencyFmt;
	unsigned char cDecimalPlace;
	unsigned char fsTimeFmt;
	long case_map_func;			// far pointer to function
	unsigned char szDataSeparator[2];
	short abReserved2[5];
} COUNTRYINFO;


int PASCAL WinMain(HANDLE, HANDLE, LPSTR, int);
BOOL InitApplication(HANDLE);
BOOL InitInstance(HANDLE, int);
long CALLBACK __export MainWndProc(HWND, UINT, WPARAM, LPARAM);
BOOL __export CALLBACK Config(HWND, unsigned, WPARAM, LPARAM);
BOOL __export CALLBACK About(HWND, unsigned, WPARAM, LPARAM);

