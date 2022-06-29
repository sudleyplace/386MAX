// $Header:   P:/PVCS/MAX/DOSMAX32/SHEXINIT.CPV   1.1   18 Dec 1995 16:15:16   BOB  $
//
//  MODULE:   shexinit.cpp
//
//  PURPOSE:   Implements the IShellExtInit member function necessary to support
//             the context menu and property sheet portioins of this shell extension.  
//

#include "priv.h"
#include "dosmax32.h"


//
//  FUNCTION: CShellExt::Initialize(LPCITEMIDLIST, LPDATAOBJECT, HKEY)
//
//  PURPOSE: Called by the shell when initializing a context menu or property
//           sheet extension.
//
//  PARAMETERS:
//    pIDFolder - Specifies the parent folder
//    pDataObj  - Spefifies the set of items selected in that folder.
//    hRegKey   - Specifies the type of the focused item in the selection.
//
//  RETURN VALUE:
//
//    NOERROR in all cases.
//
//  COMMENTS:   Note that at the time this function is called, we don't know 
//              (or care) what type of shell extension is being initialized.  
//              It could be a context menu or a property sheet.
//

STDMETHODIMP CShellExt::Initialize(LPCITEMIDLIST pIDFolder,
                                   LPDATAOBJECT pDataObj,
                                   HKEY hRegKey)
{
    // Initialize can be called more than once

    if (m_pDataObj)
    	m_pDataObj->Release();

    // duplicate the object pointer and registry handle

    if (pDataObj)
    {
    	m_pDataObj = pDataObj;
    	pDataObj->AddRef();
    }

    return NOERROR;
}
