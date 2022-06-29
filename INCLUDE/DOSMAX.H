// Keys to add to / delete from the Win95 Registry

struct {
	char *pszKey;
	char *pszValue;
} DosMaxRegistry[] = {

	"CLSID\\{E7BDB3C0-080D-11CF-BABB-444553540000}", "Qualitas DOSMAX PIF Extensions",

	"CLSID\\{E7BDB3C0-080D-11CF-BABB-444553540000}\\InProcServer32", "dosmax32.dll",

	"batfile\\shellex\\PropertySheetHandlers\\BATPage", "{E7BDB3C0-080D-11CF-BABB-444553540000}",

	"comfile\\shellex\\PropertySheetHandlers\\COMPage", "{E7BDB3C0-080D-11CF-BABB-444553540000}",

	"exefile\\shellex\\PropertySheetHandlers\\EXEPage", "{E7BDB3C0-080D-11CF-BABB-444553540000}",

	"PIFFile\\shellex\\PropertySheetHandlers\\PIFPage", "{E7BDB3C0-080D-11CF-BABB-444553540000}",

	NULL, NULL
};


#define REGISTRY_ENTRIES 6

