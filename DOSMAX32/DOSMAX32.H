// $Header:   P:/PVCS/MAX/DOSMAX32/DOSMAX32.H_V   1.1   18 Dec 1995 16:14:50   BOB  $
//
// The class ID of this Shell extension class.
//
// class id:  87b9bd00-c65c-11cd-a259-00dd010e8c28
//
//
// NOTE!!!  If you use this shell extension as a starting point,
//	    you MUST change the GUID below.  Simply run UUIDGEN.EXE
//	    to generate a new GUID.
//

#ifndef _DOSMAX_H
#define _DOSMAX_H

DEFINE_GUID(CLSID_ShellExtension, 0xE7BDB3C0L, 0x080D, 0x11CF, 0xBA, 0xBB, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00 );

// this class factory object creates context menu handlers for Chicago shell
class CShellExtClassFactory : public IClassFactory
{
protected:
	ULONG	m_cRef;

public:
	CShellExtClassFactory();
	~CShellExtClassFactory();

	//IUnknown members
	STDMETHODIMP			QueryInterface(REFIID, LPVOID FAR *);
	STDMETHODIMP_(ULONG)	AddRef();
	STDMETHODIMP_(ULONG)	Release();

	//IClassFactory members
	STDMETHODIMP			CreateInstance(LPUNKNOWN, REFIID, LPVOID FAR *);
	STDMETHODIMP			LockServer(BOOL);

};
typedef CShellExtClassFactory *LPCSHELLEXTCLASSFACTORY;

// this is the actual OLE Shell context menu handler
class CShellExt : public
			 ///IContextMenu,
			 IShellExtInit,
			 ///IExtractIcon,
			 ///IPersistFile,
			 ///IShellLink,
			 IShellPropSheetExt
			 ///ICopyHook
{
public:
    char	 m_szPropSheetFileUserClickedOn[MAX_PATH];  //This will be the same as
							    // m_szFileUserClickedOn but I include
							    // here for demonstration.  That is,
							    // m_szFileUserClickedOn gets filled in
							    // as a result of this sample supporting
							    // the IExtractIcon and IPersistFile
							    // interface.  If this sample *only* showed
							    // a Property Sheet extension, you would
							    // need to use the method I do here to find
							    // the filename the user clicked on.

protected:
	ULONG	     m_cRef;
	LPDATAOBJECT m_pDataObj;
    char	 m_szFileUserClickedOn[MAX_PATH];

	STDMETHODIMP DoPIFMenu1(HWND hParent,
							LPCSTR pszWorkingDir,
							LPCSTR pszCmd,
			    			LPCSTR pszParam,
			    			int iShowCmd);

public:
	CShellExt();
	~CShellExt();

	//IUnknown members
	STDMETHODIMP			QueryInterface(REFIID, LPVOID FAR *);
	STDMETHODIMP_(ULONG)	AddRef();
	STDMETHODIMP_(ULONG)	Release();

	//IShell members
	///STDMETHODIMP			QueryContextMenu(HMENU hMenu,
	///										 UINT indexMenu,
	///										 UINT idCmdFirst,
	///										 UINT idCmdLast,
	///				    					 UINT uFlags);
	///
	///STDMETHODIMP			InvokeCommand(LPCMINVOKECOMMANDINFO lpcmi);
	///
	///STDMETHODIMP			GetCommandString(UINT idCmd,
	///										 UINT uFlags,
	///										 UINT FAR *reserved,
	///										 LPSTR pszName,
	///										 UINT cchMax);
	///
	//IShellExtInit methods
	STDMETHODIMP		    Initialize(LPCITEMIDLIST pIDFolder,
									   LPDATAOBJECT pDataObj,
									   HKEY hKeyID);

    //IExtractIcon methods
    ///STDMETHODIMP GetIconLocation(UINT	uFlags,
	///			 LPSTR	szIconFile,
	///			 UINT	cchMax,
	///			 int   *piIndex,
	///			 UINT  *pwFlags);
	///
    ///STDMETHODIMP Extract(LPCSTR pszFile,
	///		 UINT	nIconIndex,
	///		 HICON	*phiconLarge,
	///		 HICON	*phiconSmall,
	///		 UINT	nIconSize);

    //IPersistFile methods
    ///STDMETHODIMP GetClassID(LPCLSID lpClassID);
	///
    ///STDMETHODIMP IsDirty();
	///
    ///STDMETHODIMP Load(LPCOLESTR lpszFileName, DWORD grfMode);
	///
    ///STDMETHODIMP Save(LPCOLESTR lpszFileName, BOOL fRemember);
	///
    ///STDMETHODIMP SaveCompleted(LPCOLESTR lpszFileName);
	///
    ///STDMETHODIMP GetCurFile(LPOLESTR FAR* lplpszFileName);

    //IShellPropSheetExt methods
    STDMETHODIMP AddPages(LPFNADDPROPSHEETPAGE lpfnAddPage, LPARAM lParam);

    STDMETHODIMP ReplacePage(UINT uPageID,
			     LPFNADDPROPSHEETPAGE lpfnReplaceWith,
			     LPARAM lParam);

    //ICopyHook method
    ///STDMETHODIMP_(UINT) CopyCallback(HWND hwnd,
	///			     UINT wFunc,
	///			     UINT wFlags,
	///			     LPCSTR pszSrcFile,
	///			     DWORD dwSrcAttribs,
	///			     LPCSTR pszDestFile,
	///			     DWORD dwDestAttribs);

};

typedef CShellExt *LPCSHELLEXT;

enum DOSMAXNums {DOSMAX_OFF=0, DOSMAX_ON, DOSMAX_DEF};
extern BOOL fDebug;

void DispLastError (int);

#endif // _DOSMAX_H
