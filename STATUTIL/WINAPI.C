//' $Header:   P:/PVCS/MAX/QED/WINAPI.C_V   1.0   25 Sep 1996 09:47:32   BOB  $

//****************************************************************************
//	WINAPI.C -- Windows API Cracker
//
//	This module is compiled twice:
//			Environment
//	-------------------
//		1.	_WIN16	   
//		2.	_WIN32	   
//****************************************************************************

#pragma pack (1)
#define STRICT
//#define _WIN32_WCE  0x0400 -- Conflicts witrh WM_QUERYENDSESSION, etc.
#define WINVER	0x0500
#define _WIN32_WINNT  0x0500
#include <windows.h>
#include <windowsx.h>
#include <commdlg.h>
#include <cpl.h>
#include <ctl3d.h>
#include <dde.h>
#include <penwin.h>
#include <Qualitas.h>
#include <QControl.h>
#ifdef _WIN32
#include <commctrl.h>
#endif

#ifndef PROTO
#include "winapi.pro"
#include <dbgbrk.pro>
#endif

#ifndef _WIN32
#define _WIN16
#endif

#ifdef DEBUG
extern int Debug;
int APICount = 0;
#endif

#ifdef DEBUG

#define INDENT			"            "  // Line indent for special cases
#define INDLEN		(sizeof (INDENT) - 1) // Size of INDENT without trailing zero
#define MAXLEN		79					// Maximum line length

typedef struct tagFLAGS
{
	char *szName;
	DWORD dwFlag;
	DWORD dwMask;		// If non-zero, apply to flag first, then equality
						// with dwFlag.
} FLAGS, FAR *LPFLAGS;


#define CDDS_MASK		(CDDS_SUBITEM | CDDS_ITEM | 0xFFFF)
FLAGS Flags_CDDS[] =
{
	{"CDDS_ITEMPOSTERASE"     , CDDS_ITEMPOSTERASE      , CDDS_MASK},
	{"CDDS_ITEMPOSTPAINT"     , CDDS_ITEMPOSTPAINT      , CDDS_MASK},
	{"CDDS_ITEMPREERASE"      , CDDS_ITEMPREERASE       , CDDS_MASK},
	{"CDDS_ITEMPREPAINT"      , CDDS_ITEMPREPAINT       , CDDS_MASK},
	{"CDDS_POSTERASE"         , CDDS_POSTERASE          , CDDS_MASK},
	{"CDDS_POSTPAINT"         , CDDS_POSTPAINT          , CDDS_MASK},
	{"CDDS_PREERASE"          , CDDS_PREERASE           , CDDS_MASK},
	{"CDDS_PREPAINT"          , CDDS_PREPAINT           , CDDS_MASK},
	{"CDDS_ITEM"              , CDDS_ITEM               , CDDS_MASK},
	{"CDDS_SUBITEM"           , CDDS_SUBITEM            , CDDS_MASK},
};
#define nFlags_CDDS 	(sizeof (Flags_CDDS)/sizeof (Flags_CDDS[0]))


FLAGS Flags_CDIS[] =
{
	{"CDIS_CHECKED"           , CDIS_CHECKED            },
	{"CDIS_DEFAULT"           , CDIS_DEFAULT            },
	{"CDIS_DISABLED"          , CDIS_DISABLED           },
	{"CDIS_FOCUS"             , CDIS_FOCUS              },
	{"CDIS_GRAYED"            , CDIS_GRAYED             },
	{"CDIS_HOT"               , CDIS_HOT                },
	{"CDIS_INDETERMINATE"     , CDIS_INDETERMINATE      },
	{"CDIS_MARKED"            , CDIS_MARKED             },
	{"CDIS_SELECTED"          , CDIS_SELECTED           },
};
#define nFlags_CDIS 	(sizeof (Flags_CDIS)/sizeof (Flags_CDIS[0]))


FLAGS Flags_BN[] =
{
	{"BN_CLICKED"               , BN_CLICKED       , 0xFFFFFFFF},
	{"BN_PAINT"                 , BN_PAINT         , 0xFFFFFFFF},
////{"BN_HILITE"                , BN_HILITE        , 0xFFFFFFFF},    // BN_PUSHED
////{"BN_UNHILITE"              , BN_UNHILITE      , 0xFFFFFFFF},    // BN_UNPUSHED
	{"BN_DISABLE"               , BN_DISABLE       , 0xFFFFFFFF},
////{"BN_DOUBLECLICKED"         , BN_DOUBLECLICKED , 0xFFFFFFFF},    // BN_DOUBLECLICK
	{"BN_PUSHED"                , BN_PUSHED        , 0xFFFFFFFF},
	{"BN_UNPUSHED"              , BN_UNPUSHED      , 0xFFFFFFFF},
	{"BN_DBLCLK"                , BN_DBLCLK        , 0xFFFFFFFF},
	{"BN_SETFOCUS"              , BN_SETFOCUS      , 0xFFFFFFFF},
	{"BN_KILLFOCUS"             , BN_KILLFOCUS     , 0xFFFFFFFF},
};
#define nFlags_BN		(sizeof (Flags_BN)/sizeof (Flags_BN[0]))


FLAGS Flags_CBN[] =
{
	{"CBN_ERRSPACE"             , (DWORD) CBN_ERRSPACE     , 0xFFFFFFFF},
	{"CBN_SELCHANGE"            ,         CBN_SELCHANGE    , 0xFFFFFFFF},
	{"CBN_DBLCLK"               ,         CBN_DBLCLK       , 0xFFFFFFFF},
	{"CBN_SETFOCUS"             ,         CBN_SETFOCUS     , 0xFFFFFFFF},
	{"CBN_KILLFOCUS"            ,         CBN_KILLFOCUS    , 0xFFFFFFFF},
	{"CBN_EDITCHANGE"           ,         CBN_EDITCHANGE   , 0xFFFFFFFF},
	{"CBN_EDITUPDATE"           ,         CBN_EDITUPDATE   , 0xFFFFFFFF},
	{"CBN_DROPDOWN"             ,         CBN_DROPDOWN     , 0xFFFFFFFF},
	{"CBN_CLOSEUP"              ,         CBN_CLOSEUP      , 0xFFFFFFFF},
	{"CBN_SELENDOK"             ,         CBN_SELENDOK     , 0xFFFFFFFF},
	{"CBN_SELENDCANCEL"         ,         CBN_SELENDCANCEL , 0xFFFFFFFF},
};
#define nFlags_CBN		(sizeof (Flags_CBN)/sizeof (Flags_CBN[0]))


FLAGS Flags_DT[] =
{
	{"DT_BOTTOM"              , DT_BOTTOM               },
	{"DT_CALCRECT"            , DT_CALCRECT             },
	{"DT_CENTER"              , DT_CENTER               },
	{"DT_EDITCONTROL"         , DT_EDITCONTROL          },
	{"DT_END_ELLIPSIS"        , DT_END_ELLIPSIS         },
	{"DT_EXPANDTABS"          , DT_EXPANDTABS           },
	{"DT_EXTERNALLEADING"     , DT_EXTERNALLEADING      },
	{"DT_HIDEPREFIX"          , DT_HIDEPREFIX           },
	{"DT_INTERNAL"            , DT_INTERNAL             },
	{"DT_LEFT"                , DT_LEFT                 },
	{"DT_MODIFYSTRING"        , DT_MODIFYSTRING         },
	{"DT_NOCLIP"              , DT_NOCLIP               },
	{"DT_NOFULLWIDTHCHARBREAK", DT_NOFULLWIDTHCHARBREAK },
	{"DT_NOPREFIX"            , DT_NOPREFIX             },
	{"DT_PATH_ELLIPSIS"       , DT_PATH_ELLIPSIS        },
	{"DT_PREFIXONLY"          , DT_PREFIXONLY           },
	{"DT_RIGHT"               , DT_RIGHT                },
	{"DT_RTLREADING"          , DT_RTLREADING           },
	{"DT_SINGLELINE"          , DT_SINGLELINE           },
	{"DT_TABSTOP"             , DT_TABSTOP              },
	{"DT_TOP"                 , DT_TOP                  },
	{"DT_VCENTER"             , DT_VCENTER              },
	{"DT_WORD_ELLIPSIS"       , DT_WORD_ELLIPSIS        },
	{"DT_WORDBREAK"           , DT_WORDBREAK            },
};
#define nFlags_DT		(sizeof (Flags_DT)/sizeof (Flags_DT[0]))


FLAGS Flags_EN[] =
{
	{"EN_SETFOCUS"            , EN_SETFOCUS     , 0xFFFFFFFF},
	{"EN_KILLFOCUS"           , EN_KILLFOCUS    , 0xFFFFFFFF},
	{"EN_CHANGE"              , EN_CHANGE       , 0xFFFFFFFF},
	{"EN_UPDATE"              , EN_UPDATE       , 0xFFFFFFFF},
	{"EN_ERRSPACE"            , EN_ERRSPACE     , 0xFFFFFFFF},
	{"EN_MAXTEXT"             , EN_MAXTEXT      , 0xFFFFFFFF},
	{"EN_HSCROLL"             , EN_HSCROLL      , 0xFFFFFFFF},
	{"EN_VSCROLL"             , EN_VSCROLL      , 0xFFFFFFFF},
	{"EN_ALIGN_LTR_EC"        , EN_ALIGN_LTR_EC , 0xFFFFFFFF},
	{"EN_ALIGN_RTL_EC"        , EN_ALIGN_RTL_EC , 0xFFFFFFFF},
};
#define nFlags_EN		(sizeof (Flags_EN)/sizeof (Flags_EN[0]))


FLAGS Flags_HDF[] =
{
	{"HDF_LEFT"               , HDF_LEFT            , 0xF},
	{"HDF_RIGHT"              , HDF_RIGHT           , 0xF},
	{"HDF_CENTER"             , HDF_CENTER          , 0xF},
	{"HDF_JUSTIFYMASK"        , HDF_JUSTIFYMASK     , 0xF},
	{"HDF_RTLREADING"         , HDF_RTLREADING      , 0xF},
	{"HDF_BITMAP"             , HDF_BITMAP               },           
	{"HDF_BITMAP_ON_RIGHT"    , HDF_BITMAP_ON_RIGHT      },                 
	{"HDF_IMAGE"              , HDF_IMAGE                },                 
	{"HDF_OWNERDRAW"          , HDF_OWNERDRAW            },
	{"HDF_STRING"             , HDF_STRING               },           
};
#define nFlags_HDF		(sizeof (Flags_HDF)/sizeof (Flags_HDF[0]))


FLAGS Flags_HDI[] =
{
	{"HDI_BITMAP"             , HDI_BITMAP    },
	{"HDI_FORMAT"             , HDI_FORMAT    },
	{"HDI_DI_SETITEM"         , HDI_DI_SETITEM},
	{"HDI_FILTER"             , HDI_FILTER    },
////{"HDI_HEIGHT"             , HDI_HEIGHT    },    // Same as HDI_WIDTH
	{"HDI_IMAGE"              , HDI_IMAGE     },
	{"HDI_LPARAM"             , HDI_LPARAM    },
	{"HDI_ORDER"              , HDI_ORDER     },
	{"HDI_TEXT"               , HDI_TEXT      },
	{"HDI_WIDTHHEIGHT"        , HDI_WIDTH     },
};
#define nFlags_HDI		(sizeof (Flags_HDI)/sizeof (Flags_HDI[0]))


FLAGS Flags_HDFT[] =
{
	{"HDFT_ISSTRING"          , HDFT_ISSTRING           },
	{"HDFT_ISNUMBER"          , HDFT_ISNUMBER           },
	{"HDFT_HASNOVALUE"        , HDFT_HASNOVALUE         },
};
#define nFlags_HDFT 	(sizeof (Flags_HDFT)/sizeof (Flags_HDFT[0]))


FLAGS Flags_LBN[] =
{
	{"LBN_ERRSPACE"      , (DWORD) LBN_ERRSPACE       , 0xFFFFFFFF},
	{"LBN_SELCHANGE"     ,         LBN_SELCHANGE      , 0xFFFFFFFF},
	{"LBN_DBLCLK"        ,         LBN_DBLCLK         , 0xFFFFFFFF},
	{"LBN_SELCANCEL"     ,         LBN_SELCANCEL      , 0xFFFFFFFF},
	{"LBN_SETFOCUS"      ,         LBN_SETFOCUS       , 0xFFFFFFFF},
	{"LBN_KILLFOCUS"     ,         LBN_KILLFOCUS      , 0xFFFFFFFF},
};
#define nFlags_LBN		(sizeof (Flags_LBN)/sizeof (Flags_LBN[0]))


FLAGS Flags_LVIF[] =
{
	{"LVIF_DI_SETITEM"        , LVIF_DI_SETITEM         },    
	{"LVIF_IMAGE"             , LVIF_IMAGE              },    
	{"LVIF_INDENT"            , LVIF_INDENT             },    
	{"LVIF_NORECOMPUTE"       , LVIF_NORECOMPUTE        },    
	{"LVIF_PARAM"             , LVIF_PARAM              },    
	{"LVIF_STATE"             , LVIF_STATE              },    
	{"LVIF_TEXT"              , LVIF_TEXT               },    
};
#define nFlags_LVIF 	(sizeof (Flags_LVIF)/sizeof (Flags_LVIF[0]))


FLAGS Flags_LVKF[] =
{
	{"LVKF_ALT"               , LVKF_ALT                },    
	{"LVKF_CONTROL"           , LVKF_CONTROL            },    
	{"LVKF_SHIFT"             , LVKF_SHIFT              },    
};
#define nFlags_LVKF 	(sizeof (Flags_LVKF)/sizeof (Flags_LVKF[0]))


FLAGS Flags_ODA[] =
{
	{"ODA_DRAWENTIRE"         , ODA_DRAWENTIRE          },    
	{"ODA_FOCUS"              , ODA_FOCUS               },    
	{"ODA_SELECT"             , ODA_SELECT              },    
};
#define nFlags_ODA		(sizeof (Flags_ODA)/sizeof (Flags_ODA[0]))


FLAGS Flags_ODS[] =
{
	{"ODS_CHECKED"            , ODS_CHECKED             },
	{"ODS_COMBOBOXEDIT"       , ODS_COMBOBOXEDIT        },
	{"ODS_DEFAULT"            , ODS_DEFAULT             },
	{"ODS_DISABLED"           , ODS_DISABLED            },
	{"ODS_FOCUS"              , ODS_FOCUS               },
	{"ODS_GRAYED"             , ODS_GRAYED              },
	{"ODS_HOTLIGHT"           , ODS_HOTLIGHT            },
	{"ODS_INACTIVE"           , ODS_INACTIVE            },
	{"ODS_NOACCEL"            , ODS_NOACCEL             },
	{"ODS_NOFOCUSRECT"        , ODS_NOFOCUSRECT         },
	{"ODS_SELECTED"           , ODS_SELECTED            },
};
#define nFlags_ODS		(sizeof (Flags_ODS)/sizeof (Flags_ODS[0]))


FLAGS Flags_ODT[] =
{
	{"ODT_BUTTON"             , ODT_BUTTON              },
	{"ODT_COMBOBOX"           , ODT_COMBOBOX            },
	{"ODT_LISTBOX"            , ODT_LISTBOX             },
	{"ODT_MENU"               , ODT_MENU                },
	{"ODT_STATIC"             , ODT_STATIC              },
};
#define nFlags_ODT		(sizeof (Flags_ODT)/sizeof (Flags_ODT[0]))


FLAGS Flags_SBN[] =
{
	{"SB_LINEUPLEFT   "     , SB_LINEUP             , 0xFFFFFFFF},
////{"SB_LINEUP       "     , SB_LINEUP             , 0xFFFFFFFF},
////{"SB_LINELEFT     "     , SB_LINELEFT           , 0xFFFFFFFF},
	{"SB_LINEDOWNRIGHT"     , SB_LINEDOWN           , 0xFFFFFFFF},
////{"SB_LINEDOWN     "     , SB_LINEDOWN           , 0xFFFFFFFF},
////{"SB_LINERIGHT    "     , SB_LINERIGHT          , 0xFFFFFFFF},
	{"SB_PAGEUPLEFT   "     , SB_PAGEUP             , 0xFFFFFFFF},
////{"SB_PAGEUP       "     , SB_PAGEUP             , 0xFFFFFFFF},
////{"SB_PAGELEFT     "     , SB_PAGELEFT           , 0xFFFFFFFF},
	{"SB_PAGEDOWNRIGHT"     , SB_PAGEDOWN           , 0xFFFFFFFF},
////{"SB_PAGEDOWN     "     , SB_PAGEDOWN           , 0xFFFFFFFF},
////{"SB_PAGERIGHT    "     , SB_PAGERIGHT          , 0xFFFFFFFF},
	{"SB_THUMBPOSITION"     , SB_THUMBPOSITION      , 0xFFFFFFFF},
	{"SB_THUMBTRACK   "     , SB_THUMBTRACK         , 0xFFFFFFFF},
	{"SB_TOPLEFT      "     , SB_TOP                , 0xFFFFFFFF},
////{"SB_TOP          "     , SB_TOP                , 0xFFFFFFFF},
////{"SB_LEFT         "     , SB_LEFT               , 0xFFFFFFFF},
	{"SB_BOTTOMRIGHT  "     , SB_BOTTOM             , 0xFFFFFFFF},
////{"SB_BOTTOM       "     , SB_BOTTOM             , 0xFFFFFFFF},
////{"SB_RIGHT        "     , SB_RIGHT              , 0xFFFFFFFF},
	{"SB_ENDSCROLL    "     , SB_ENDSCROLL          , 0xFFFFFFFF},
};
#define nFlags_SBN		(sizeof (Flags_SBN)/sizeof (Flags_SBN[0]))


FLAGS Flags_STN[] =
{
	{"STN_CLICKED"     , STN_CLICKED      , 0xFFFFFFFF},
	{"STN_DBLCLK"      , STN_DBLCLK       , 0xFFFFFFFF},
	{"STN_ENABLE"      , STN_ENABLE       , 0xFFFFFFFF},
	{"STN_DISABLE"     , STN_DISABLE      , 0xFFFFFFFF},
};
#define nFlags_STN		(sizeof (Flags_STN)/sizeof (Flags_STN[0]))


FLAGS Flags_SWP[] =
{
	{"SWP_ASYNCWINDOWPOS"     , SWP_ASYNCWINDOWPOS      },
////{"SWP_DRAWFRAME"          , SWP_DRAWFRAME           }, EQ SWP_FRAMECHANGED
	{"SWP_DEFERERASE"         , SWP_DEFERERASE          },
	{"SWP_FRAMECHANGED"       , SWP_FRAMECHANGED        },
	{"SWP_HIDEWINDOW"         , SWP_HIDEWINDOW          },
	{"SWP_NOACTIVATE"         , SWP_NOACTIVATE          },
	{"SWP_NOCOPYBITS"         , SWP_NOCOPYBITS          },
	{"SWP_NOMOVE"             , SWP_NOMOVE              },
	{"SWP_NOOWNERZORDER"      , SWP_NOOWNERZORDER       },
	{"SWP_NOREDRAW"           , SWP_NOREDRAW            },
////{"SWP_NOREPOSITION"       , SWP_NOREPOSITION        }, EQ SWP_NOOWNERZORDER
	{"SWP_NOSENDCHANGING"     , SWP_NOSENDCHANGING      },
	{"SWP_NOSIZE"             , SWP_NOSIZE              },
	{"SWP_NOZORDER"           , SWP_NOZORDER            },
	{"SWP_SHOWWINDOW"         , SWP_SHOWWINDOW          },
};
#define nFlags_SWP		(sizeof (Flags_SWP)/sizeof (Flags_SWP[0]))

typedef enum
{
	EC_ANIMATE	   ,	//	0
	EC_DATETIMEPICK,	//	1
	EC_HOTKEY	   ,	//	2
	EC_MONTHCAL    ,	//	3
	EC_PROGRESS    ,	//	4
	EC_REBAR	   ,	//	5
	EC_STATUS	   ,	//	6
	EC_TOOLBAR	   ,	//	7
	EC_TOOLTIPS    ,	//	8
	EC_TRACKBAR    ,	//	9
	EC_UPDOWN	   ,	// 10
	EC_COMBOBOXEX  ,	// 11
	EC_HEADER	   ,	// 12
	EC_IPADDRESS   ,	// 13
	EC_LISTVIEW    ,	// 14
	EC_NATIVEFONT  ,	// 15
	EC_PAGESCROLLER,	// 16
	EC_TAB		   ,	// 17
	EC_TREEVIEW    ,	// 18
	EC_BUTTON	   ,	// 19
	EC_COMBOBOX    ,	// 20
	EC_EDITBOX	   ,	// 21
	EC_LISTBOX	   ,	// 22
	EC_SCROLLBAR   ,	// 23
	EC_STATIC	   ,	// 24
	EC_COMMON	   ,	// 25
} ECLASS;

typedef struct tagCLSTR
{
	LPSTR lpName;		// Ptr to class name
	LPSTR lpAbbr;		// Ptr to class abbreviation
	ECLASS eClass;		// Class index

} CLSTR, FAR* LPCLSTR;

CLSTR clstr[] =
{
	{ANIMATE_CLASS	   ,	 "(AC)"  , EC_ANIMATE       },
	{DATETIMEPICK_CLASS,	 "(DT)"  , EC_DATETIMEPICK  },
	{HOTKEY_CLASS	   ,	 "(HK)"  , EC_HOTKEY        },
	{MONTHCAL_CLASS    ,	 "(MC)"  , EC_MONTHCAL      },
	{PROGRESS_CLASS    ,	 "(PB)"  , EC_PROGRESS      },
	{REBARCLASSNAME    ,	 "(RB)"  , EC_REBAR         },
	{STATUSCLASSNAME   ,	 "(STB)" , EC_STATUS        },
	{TOOLBARCLASSNAME  ,	 "(TB)"  , EC_TOOLBAR       },
	{TOOLTIPS_CLASS    ,	 "(TT)"  , EC_TOOLTIPS      },
	{TRACKBAR_CLASS    ,	 "(TK)"  , EC_TRACKBAR      },
	{UPDOWN_CLASS	   ,	 "(UD)"  , EC_UPDOWN        },
	{WC_COMBOBOXEX	   ,	 "(CBX)" , EC_COMBOBOXEX    },
	{WC_HEADER		   ,	 "(HD)"  , EC_HEADER        },
	{WC_IPADDRESS	   ,	 "(IP)"  , EC_IPADDRESS     },
	{WC_LISTVIEW	   ,	 "(LV)"  , EC_LISTVIEW      },
	{WC_NATIVEFONTCTL  ,	 "(NF)"  , EC_NATIVEFONT    },
	{WC_PAGESCROLLER   ,	 "(PS)"  , EC_PAGESCROLLER  },
	{WC_TABCONTROL	   ,	 "(TC)"  , EC_TAB           },
	{WC_TREEVIEW	   ,	 "(TV)"  , EC_TREEVIEW      },
	{WC_TOOLTIPS	   ,	 "(TT)"  , EC_TOOLTIPS      },  // QualitasToolTips
////{				   ,	 "(CC)"  , EC_COMMON        },  // Common Control
	{"button"          ,     "(BN)"  , EC_BUTTON        },
	{"combobox"        ,     "(CB)"  , EC_COMBOBOX      },
	{"edit"            ,     "(EB)"  , EC_EDITBOX       },
	{"listbox"         ,     "(LB)"  , EC_LISTBOX       },
	{"scrollbar"       ,     "(SCB)" , EC_SCROLLBAR     },
	{"static"          ,     "(ST)"  , EC_STATIC        },
	{""                ,     ""      , 0xFFFFFFFF       },  // DO NOT FILL IN
};
// Define as one less so the last entry is used as a fall through
#define nCLSTR		((sizeof (clstr)/sizeof (clstr[0])) - 1)


//************************************************************************
//	LookupClass ()
//
//	Lookup a window class, returning its index.
//************************************************************************

int LookupClass (HWND hWnd)

{
	char szTemp[256];
	int i;

	// Get the class name
	GetClassName (hWnd, szTemp, sizeof (szTemp));

	// Loop through the class names
	for (i = 0; i < nCLSTR; i++)
	if (lstrcmpi (clstr[i].lpName, szTemp) EQ 0)
		break;

	return i;
} // End LookupClass ()


//************************************************************************
//	FormatClassName ()
//
//	Format a window's Class Name
//************************************************************************

LPSTR FormatClassName (HWND hWnd)

{
	return clstr[LookupClass (hWnd)].lpAbbr;
} // End FormatClassname ()


//************************************************************************
//	Format_POINT ()
//
//	Format POINT values
//************************************************************************

LPSTR Format_POINT (POINT pt, LPSTR lpsz)

{
	wsprintf (lpsz,
			  "(%X, %X)",
			  pt.x,
			  pt.y);

	return lpsz;
} // End Format_POINT ()


//************************************************************************
//	Format_RECT ()
//
//	Format a rectangle
//************************************************************************

LPSTR Format_RECT (const LPRECT lprc, LPSTR lpszTemp)

{
	wsprintf (lpszTemp,
			  "(%X, %X, %X, %X)",
			  lprc->left,
			  lprc->top,
			  lprc->right,
			  lprc->bottom);

	return lpszTemp;
} // End Format_RECT ()


//************************************************************************
//	Format_RGB ()
//
//	Format RGB values
//************************************************************************

LPSTR Format_RGB (COLORREF clr, LPSTR lpsz)

{
	wsprintf (lpsz,
			  "RGB (%X, %X, %X)",
			  GetRValue (clr),
			  GetGValue (clr),
			  GetBValue (clr));

	return lpsz;
} // End Format_RGB ()


//************************************************************************
//	SkipWhite ()
//
//	Skip over white space
//************************************************************************

static LPSTR SkipWhite (LPSTR lpsz)

{
	while (*lpsz && *lpsz EQ ' ')
		lpsz++;

	return lpsz;
} // End SkipWhite ()


//************************************************************************
//	DisplayText ()
//
//	Display an ASCIIZ string
//************************************************************************

void DisplayText (LPSTR lpsz)

{
	char szTemp[1024];

	wsprintf (szTemp,
			  "Text = \"%.1000s\"",
			  lpsz);

	OutputDebugString (FormatStr (szTemp));
} // End DisplayText ()


//************************************************************************
//	FormatFlags ()
//
//	Format names of flags
//************************************************************************

LPSTR FormatFlags (DWORD dwFlags, LPFLAGS lpFlags, int nFlags, LPSTR lpszTemp)

{
	int i;
	char *p;

	p = lpszTemp;
	p[0] = '\0';            // Initialize in case there's nothing

	// Loop through the flags
	for (i = 0; i < nFlags && dwFlags; i++)
	if ((lpFlags[i].dwMask NE 0
	  && (lpFlags[i].dwMask & dwFlags) EQ lpFlags[i].dwFlag)
	 || (lpFlags[i].dwMask EQ 0)
	  && dwFlags & lpFlags[i].dwFlag)
	{
		// Delete the flag so we know what we didn't handle
		dwFlags &= ~lpFlags[i].dwFlag;

		// Copy the separator if not the first item
		if (p NE lpszTemp)
		{
			lstrcpy (p, " | ");
			p += 3;
		} // End IF

		// Copy the flag name
		lstrcpy (p, lpFlags[i].szName);

		p += lstrlen (p);
	} // End FOR/IF

	// If there's anything left over, ...
	if (dwFlags)
	{
		// Copy the separator if not the first item
		if (p NE lpszTemp)
		{
			lstrcpy (p, " | ");
			p += 3;
		} // End IF

		// Format the flags remainder
		wsprintf (p, "%08X", dwFlags);

		p += lstrlen (p);
	} // End IF

	if (p EQ lpszTemp)
		return "0";                 // Return something, even if it's zero

	return lpszTemp;

} // End FormatFlags ()


//************************************************************************
//	FormatStr ()
//
//	Format a string to fit within multiple lines
//	inserting INDENT at the beginning of the line and
//	"\r\n" at the end.
//************************************************************************

LPSTR FormatStr (LPSTR lpsz)

{
	static char szTemp[1024];
	int i;
	char *p,		// Current (uncopied) item in string
		 *q,		// End of ...
		 *t,		// Next copy target in szTemp
		 *l;		// Start of line in szTemp

	// Start off with an indent
	memcpy (szTemp, INDENT, INDLEN);
	l = &szTemp[0]; 				// The line starts here
	t = &szTemp[INDLEN];			// Start appending here

	for (p = lpsz; *p; )
	{
		// Find the end of the next item
		i = strcspn (p, ",|");      // Check for next item or flag separator
		q = p + i;					// Point to the separator
		if (*q) 					// If it's a separator, ...
			q++;					// ...include it

		if (((t - l) + (q - p)) > MAXLEN) // If it doesn't fit, ...
		{
			memcpy (t, "\r\n" INDENT, 2 + INDLEN); // Append EOL & INDENT
			l = t + 2;				// The line starts here
			t += 2 + INDLEN;		// Append here
			p = SkipWhite (p);		// New start of input
		} // End IF/ELSE
			
		memcpy (t, p, q - p);		// Copy to destination
		t += q - p; 				// Skip over it

		p = q;						// Skip over the last item
	} // End FOR

	lstrcpy (t, "\r\n");            // Append EOL

	return &szTemp[0];
} // End FormatStr ()


//************************************************************************
//	ODSDD ()
//
//	Output Debug String with dword cover function
//************************************************************************

void FAR ODSDD (LPSTR lpStr, DWORD dw)

{
	char szTemp[80];

	if (Debug)
	{
		wsprintf (szTemp, "%s (%08lX)\r\n", lpStr, dw);
		OutputDebugString (szTemp);
	} // End IF
		
} // End ODSDD ()
#endif		  


#ifdef DEBUG
//************************************************************************
//	ODS ()
//
//	Output Debug String cover function
//************************************************************************

void FAR ODS (LPSTR lpStr)

{
	if (Debug)
		OutputDebugString (lpStr);
		
} // End ODS ()
#endif		  


#ifdef DEBUG
//************************************************************************
//	ODSRECT ()
//
//	Output Debug String with rectangle cover function
//************************************************************************

void FAR ODSRECT (LPSTR lpStr, LPRECT lprc)

{
	char szTemp[80];

	if (Debug)
	{
		wsprintf (szTemp, "%s (%X, %X, %X, %X: %X, %X)\r\n",
				  lpStr,
				  lprc->left,
				  lprc->top,
				  lprc->right,
				  lprc->bottom,
				  lprc->right  - lprc->left,
				  lprc->bottom - lprc->top);
		OutputDebugString (szTemp);
	} // End IF
		
} // End ODSRECT ()
#endif		  


#ifdef DEBUG
//************************************************************************
//	APIMsg ()
//
//	Interpret a Windows WM_xxx message as text
//************************************************************************

static LPSTR APIMsg (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)

{
	static char szTemp[64];
	
#define WN(a,b) case WM_##a:				\
					lstrcpy (szTemp, b);	\
					break;
	
#define WM(a)	case WM_##a:					\
					lstrcpy (szTemp, "WM_" #a); \
					break;
	
#ifndef WM_SETVISIBLE
#define WM_SETVISIBLE				0x0009
#endif
#ifndef WM_SIZEWAIT
#define WM_SIZEWAIT 				0x0004
#endif
#ifndef WM_SYSTEMERROR
#define WM_SYSTEMERROR				0x0017
#endif
#ifndef WM_PAINTICON   
#define WM_PAINTICON				0x0026
#endif
#ifndef WM_ALTTABACTIVE
#define WM_ALTTABACTIVE 			0x0029
#endif
#ifndef WM_SETHOTKEY
#define WM_SETHOTKEY				0x0032
#endif
#ifndef WM_GETHOTKEY
#define WM_GETHOTKEY				0x0033
#endif
#ifndef WM_FILESYSCHANGE
#define WM_FILESYSCHANGE			0x0034
#endif
#ifndef WM_ISACTIVEICON
#define WM_ISACTIVEICON 			0x0035
#endif
#ifndef WM_QUERYPARKICON
#define WM_QUERYPARKICON			0x0036
#endif
#ifndef WM_QUERYSAVESTATE
#define WM_QUERYSAVESTATE			0x0038
#endif
#ifndef WM_GETOBJECT
#define WM_GETOBJECT				0x003D
#endif
#ifndef WM_TESTING		 
#define WM_TESTING					0x0040
#endif
#ifndef WM_OTHERWINDOWCREATED
#define WM_OTHERWINDOWCREATED		0x0042
#endif
#ifndef WM_OTHERWINDOWDESTROYED
#define WM_OTHERWINDOWDESTROYED 	0x0043
#endif
#ifndef WM_COPYDATA
#define WM_COPYDATA 				0x004A
#endif
#ifndef WM_CANCELJOURNAL
#define WM_CANCELJOURNAL			0x004B
#endif
#ifndef WM_NOTIFY
#define WM_NOTIFY					0x004E
#endif
#ifndef WM_INPUTLANGCHANGEREQUEST
#define WM_INPUTLANGCHANGEREQUEST	0x0050
#endif
#ifndef WM_INPUTLANGCHANGE
#define WM_INPUTLANGCHANGE			0x0051
#endif
#ifndef WM_TCARD
#define WM_TCARD					0x0052
#endif
#ifndef WM_HELP
#define WM_HELP 					0x0053
#endif
#ifndef WM_USERCHANGED
#define WM_USERCHANGED				0x0054
#endif
#ifndef WM_NOTIFYFORMAT
#define WM_NOTIFYFORMAT 			0x0055
#endif
#ifndef WM_CONTEXTMENU
#define WM_CONTEXTMENU				0x007B
#endif
#ifndef WM_STYLECHANGING
#define WM_STYLECHANGING			0x007C
#endif
#ifndef WM_STYLECHANGED
#define WM_STYLECHANGED 			0x007D
#endif
#ifndef WM_DISPLAYCHANGE
#define WM_DISPLAYCHANGE			0x007E
#endif
#ifndef WM_GETICON
#define WM_GETICON					0x007F
#endif
#ifndef WM_SETICON
#define WM_SETICON					0x0080
#endif
#ifndef WM_SYNCPAINT
#define WM_SYNCPAINT				0x0088
#endif
#ifndef WM_SYNCTASK
#define WM_SYNCTASK 				0x0089
#endif
#ifndef WM_NCXBUTTONDOWN
#define WM_NCXBUTTONDOWN			0x00AB
#endif
#ifndef WM_NCXBUTTONUP
#define WM_NCXBUTTONUP				0x00AC
#endif
#ifndef WM_NCXBUTTONDBLCLK
#define WM_NCXBUTTONDBLCLK			0x00AD
#endif
#ifndef WM_YOMICHAR
#define WM_YOMICHAR 				0x0108
#endif
#ifndef WM_CONVERTREQUEST
#define WM_CONVERTREQUEST			0x010A
#endif
#ifndef WM_CONVERTRESULT 
#define WM_CONVERTRESULT			0x010B
#endif
#ifndef WM_INTERIM
#define WM_INTERIM					0x010C
#endif
#ifndef WM_IME_STARTCOMPOSITION
#define WM_IME_STARTCOMPOSITION 	0x010D
#endif
#ifndef WM_IME_ENDCOMPOSITION
#define WM_IME_ENDCOMPOSITION		0x010E
#endif
#ifndef WM_IME_COMPOSITION
#define WM_IME_COMPOSITION			0x010F
#endif
#ifndef WM_SYSTIMER
#define WM_SYSTIMER 				0x0118
#endif
#ifndef WM_MENURBUTTONUP
#define WM_MENURBUTTONUP			0x0122
#endif
#ifndef WM_MENUDRAG
#define WM_MENUDRAG 				0x0123
#endif
#ifndef WM_MENUGETOBJECT
#define WM_MENUGETOBJECT			0x0124
#endif
#ifndef WM_UNINITMENUPOPUP
#define WM_UNINITMENUPOPUP			0x0125
#endif
#ifndef WM_MENUCOMMAND
#define WM_MENUCOMMAND				0x0126
#endif
#ifndef WM_CHANGEUISTATE
#define WM_CHANGEUISTATE			0x0127
#endif
#ifndef WM_UPDATEUISTATE
#define WM_UPDATEUISTATE			0x0128
#endif
#ifndef WM_QUERYUISTATE
#define WM_QUERYUISTATE 			0x0129
#endif
#ifndef WM_LBTRACKPOINT
#define WM_LBTRACKPOINT 			0x0131
#endif
#ifndef WM_CTLCOLORMSGBOX
#define WM_CTLCOLORMSGBOX			0x0132
#endif
#ifndef WM_CTLCOLOREDIT  
#define WM_CTLCOLOREDIT 			0x0133
#endif
#ifndef WM_CTLCOLORLISTBOX
#define WM_CTLCOLORLISTBOX			0x0134
#endif
#ifndef WM_CTLCOLORBTN
#define WM_CTLCOLORBTN				0x0135
#endif
#ifndef WM_CTLCOLORDLG
#define WM_CTLCOLORDLG				0x0136
#endif
#ifndef WM_CTLCOLORSCROLLBAR
#define WM_CTLCOLORSCROLLBAR		0x0137
#endif
#ifndef WM_CTLCOLORSTATIC
#define WM_CTLCOLORSTATIC			0x0138
#endif
#ifndef WM_MOUSEWHEEL
#define WM_MOUSEWHEEL				0x020A
#endif
#ifndef WM_XBUTTONDOWN
#define WM_XBUTTONDOWN				0x020B
#endif
#ifndef WM_XBUTTONUP
#define WM_XBUTTONUP				0x020C
#endif
#ifndef WM_XBUTTONDBLCLK
#define WM_XBUTTONDBLCLK			0x020D
#endif
#ifndef WM_ENTERMENULOOP
#define WM_ENTERMENULOOP			0x0211
#endif
#ifndef WM_EXITMENULOOP
#define WM_EXITMENULOOP 			0x0212
#endif
#ifndef WM_NEXTMENU
#define WM_NEXTMENU 				0x0213
#endif
#ifndef WM_SIZING
#define WM_SIZING					0x0214
#endif
#ifndef WM_CAPTURECHANGED
#define WM_CAPTURECHANGED			0x0215
#endif
#ifndef WM_MOVING
#define WM_MOVING					0x0216
#endif
#ifndef WM_POWERBROADCAST
#define WM_POWERBROADCAST			0x0218
#endif
#ifndef WM_DEVICECHANGE
#define WM_DEVICECHANGE 			0x0219
#endif
#ifndef WM_DROPOBJECT
#define WM_DROPOBJECT				0x022A
#endif
#ifndef WM_QUERYDROPOBJECT
#define WM_QUERYDROPOBJECT			0x022B
#endif
#ifndef WM_BEGINDRAG
#define WM_BEGINDRAG				0x022C
#endif
#ifndef WM_DRAGLOOP
#define WM_DRAGLOOP 				0x022D
#endif
#ifndef WM_DRAGSELECT
#define WM_DRAGSELECT				0x022E
#endif
#ifndef WM_DRAGMOVE
#define WM_DRAGMOVE 				0x022F
#endif
#ifndef WM_ENTERSIZEMOVE
#define WM_ENTERSIZEMOVE			0x0231
#endif
#ifndef WM_EXITSIZEMOVE
#define WM_EXITSIZEMOVE 			0x0232
#endif
#ifndef WM_MDIREFRESHMENU
#define WM_MDIREFRESHMENU			0x0234
#endif
#ifndef WM_KANJIFIRST
#define WM_KANJIFIRST				0x0280
#endif
#ifndef WM_IME_SETCONTEXT
#define WM_IME_SETCONTEXT			0x0281
#endif
#ifndef WM_IME_NOTIFY
#define WM_IME_NOTIFY				0x0282
#endif
#ifndef WM_IME_CONTROL
#define WM_IME_CONTROL				0x0283
#endif
#ifndef WM_IME_COMPOSITIONFULL
#define WM_IME_COMPOSITIONFULL		0x0284
#endif
#ifndef WM_IME_SELECT
#define WM_IME_SELECT				0x0285
#endif
#ifndef WM_IME_CHAR
#define WM_IME_CHAR 				0x0286
#endif
#ifndef WM_IME_REQUEST
#define WM_IME_REQUEST				0x0288
#endif
#ifndef WM_IME_KEYDOWN
#define WM_IME_KEYDOWN				0x0290
#endif
#ifndef WM_IME_KEYUP
#define WM_IME_KEYUP				0x0291
#endif
#ifndef WM_NCMOUSEHOVER
#define WM_NCMOUSEHOVER 			0x02A0
#endif
#ifndef WM_MOUSEHOVER
#define WM_MOUSEHOVER				0x02A1
#endif
#ifndef WM_NCMOUSELEAVE
#define WM_NCMOUSELEAVE 			0x02A2
#endif
#ifndef WM_MOUSELEAVE
#define WM_MOUSELEAVE				0x02A3
#endif

#ifndef WM_KANJILAST
#define WM_KANJILAST				0x028F
#endif
#ifndef WM_HOTKEY
#define WM_HOTKEY					0x0312
#endif
#ifndef WM_PRINT 
#define WM_PRINT					0x0317
#endif
#ifndef WM_PRINTCLIENT
#define WM_PRINTCLIENT				0x0318
#endif
#ifndef WM_APPCOMMAND
#define WM_APPCOMMAND				0x0319
#endif
#ifndef WM_HANDHELDFIRST
#define WM_HANDHELDFIRST			0x0358
#endif
#ifndef WM_HANDHELDLAST
#define WM_HANDHELDLAST 			0x035F
#endif
#ifndef WM_AFXFIRST
#define WM_AFXFIRST 				0x0360
#endif
#ifndef WM_AFXLAST
#define WM_AFXLAST					0x037F
#endif
#ifndef WM_RCRESULT
#define WM_RCRESULT 				0x0381
#endif
#ifndef WM_HOOKRCRESULT
#define WM_HOOKRCRESULT 			0x0382
#endif
#ifndef WM_SKB
#define WM_SKB						0x0384
#endif
#ifndef WM_COALESCE_FIRST
#define WM_COALESCE_FIRST			0x0390
#endif
#ifndef WM_COALESCE_LAST 
#define WM_COALESCE_LAST			0x039F
#endif
#ifndef WM_MM_RESERVED_FIRST
#define WM_MM_RESERVED_FIRST		0x03A0
#endif
#ifndef WM_MM_RESERVED_LAST
#define WM_MM_RESERVED_LAST 		0x03DF
#endif
#ifndef WM_CBT_RESERVED_FIRST
#define WM_CBT_RESERVED_FIRST		0x03F0
#endif
#ifndef WM_CBT_RESERVED_LAST
#define WM_CBT_RESERVED_LAST		0x03FF
#endif
#ifndef WM_APP
#define WM_APP						0x8000
#endif


	if (Debug)
	switch (message)
	{
		WM (NULL)						// 0000
		WM (CREATE) 					// 0001
		WM (DESTROY)					// 0002
		WM (MOVE)						// 0003
		WM (SIZEWAIT)					// 0004
		WM (SIZE)						// 0005
		WM (ACTIVATE)					// 0006
		WM (SETFOCUS)					// 0007
		WM (KILLFOCUS)					// 0008
		WM (SETVISIBLE) 				// 0009
		WM (ENABLE) 					// 000A
		WM (SETREDRAW)					// 000B
		WM (SETTEXT)					// 000C
		WM (GETTEXT)					// 000D
		WM (GETTEXTLENGTH)				// 000E
		WM (PAINT)						// 000F
		WM (CLOSE)						// 0010
		WM (QUERYENDSESSION)			// 0011
		WM (QUIT)						// 0012
		WM (QUERYOPEN)					// 0013
		WM (ERASEBKGND) 				// 0014
		WM (SYSCOLORCHANGE) 			// 0015
		WM (ENDSESSION) 				// 0016
		WM (SYSTEMERROR)				// 0017
		WM (SHOWWINDOW) 				// 0018
		WM (CTLCOLOR)					// 0019
#ifdef _WIN16
		WM (WININICHANGE)				// 001A
#else
		WM (SETTINGCHANGE)				// 001A
#endif
		WM (DEVMODECHANGE)				// 001B
		WM (ACTIVATEAPP)				// 001C
		WM (FONTCHANGE) 				// 001D
		WM (TIMECHANGE) 				// 001E
		WM (CANCELMODE) 				// 001F
		WM (SETCURSOR)					// 0020
		WM (MOUSEACTIVATE)				// 0021
		WM (CHILDACTIVATE)				// 0022
		WM (QUEUESYNC)					// 0023
		WM (GETMINMAXINFO)				// 0024
										// 0025
		WM (PAINTICON)					// 0026
		WM (ICONERASEBKGND) 			// 0027
		WM (NEXTDLGCTL) 				// 0028
		WM (ALTTABACTIVE)				// 0029
		WM (SPOOLERSTATUS)				// 002A
		WM (DRAWITEM)					// 002B
		WM (MEASUREITEM)				// 002C
		WM (DELETEITEM) 				// 002D
		WM (VKEYTOITEM) 				// 002E
		WM (CHARTOITEM) 				// 002F
		WM (SETFONT)					// 0030
		WM (GETFONT)					// 0031
		WM (SETHOTKEY)					// 0032
		WM (GETHOTKEY)					// 0033
		WM (FILESYSCHANGE)				// 0034
		WM (ISACTIVEICON)				// 0035
		WM (QUERYPARKICON)				// 0036
		WM (QUERYDRAGICON)				// 0037
		WM (QUERYSAVESTATE) 			// 0038
		WM (COMPAREITEM)				// 0039
										// 003A-003C
		WM (GETOBJECT)					// 003D
										// 003E-003F
		WM (TESTING)					// 0040
		WM (COMPACTING) 				// 0041
		WM (OTHERWINDOWCREATED) 		// 0042
		WM (OTHERWINDOWDESTROYED)		// 0043
		WM (COMMNOTIFY) 				// 0044
										// 0045
		WM (WINDOWPOSCHANGING)			// 0046
		WM (WINDOWPOSCHANGED)			// 0047
		WM (POWER)						// 0048
										// 0049
		WM (COPYDATA)					// 004A
		WM (CANCELJOURNAL)				// 004B
										// 004C-004D
		WM (NOTIFY) 					// 004E
										// 004F
		WM (INPUTLANGCHANGEREQUEST) 	// 0050
		WM (INPUTLANGCHANGE)			// 0051
		WM (TCARD)						// 0052
		WM (HELP)						// 0053
		WM (USERCHANGED)				// 0054
		WM (NOTIFYFORMAT)				// 0055
										// 0056-007A
		WM (CONTEXTMENU)				// 007B
		WM (STYLECHANGING)				// 007C
		WM (STYLECHANGED)				// 007D
		WM (DISPLAYCHANGE)				// 007E
		WM (GETICON)					// 007F
		WM (SETICON)					// 0080
		WM (NCCREATE)					// 0081
		WM (NCDESTROY)					// 0082
		WM (NCCALCSIZE) 				// 0083
		WM (NCHITTEST)					// 0084
		WM (NCPAINT)					// 0085
		WM (NCACTIVATE) 				// 0086
		WM (GETDLGCODE) 				// 0087
		WM (SYNCPAINT)					// 0088
		WM (SYNCTASK)					// 0089
										// 008A-009F
		WM (NCMOUSEMOVE)				// 00A0
		WM (NCLBUTTONDOWN)				// 00A1
		WM (NCLBUTTONUP)				// 00A2
		WM (NCLBUTTONDBLCLK)			// 00A3
		WM (NCRBUTTONDOWN)				// 00A4
		WM (NCRBUTTONUP)				// 00A5
		WM (NCRBUTTONDBLCLK)			// 00A6
		WM (NCMBUTTONDOWN)				// 00A7
		WM (NCMBUTTONUP)				// 00A8
		WM (NCMBUTTONDBLCLK)			// 00A9
										// 00AA
		WM (NCXBUTTONDOWN)				// 00AB
		WM (NCXBUTTONUP)				// 00AC
		WM (NCXBUTTONDBLCLK)			// 00AD
										// 00AE-00FF
/////// WM (KEYFIRST)					// 0100
		WM (KEYDOWN)					// 0100
		WM (KEYUP)						// 0101
		WM (CHAR)						// 0102
		WM (DEADCHAR)					// 0103
		WM (SYSKEYDOWN) 				// 0104
		WM (SYSKEYUP)					// 0105
		WM (SYSCHAR)					// 0106
		WM (SYSDEADCHAR)				// 0107
		WM (KEYLAST)					// 0108
/////// WM (YOMICHAR)					// 0108
										// 0109
		WM (CONVERTREQUEST) 			// 010A
		WM (CONVERTRESULT)				// 010B
		WM (INTERIM)					// 010C
		WM (IME_STARTCOMPOSITION)		// 010D
		WM (IME_ENDCOMPOSITION) 		// 010E
		WM (IME_COMPOSITION)			// 010F
/////// WM (IME_KEYLAST)				// 010F
		WM (INITDIALOG) 				// 0110
		WM (COMMAND)					// 0111
		WM (SYSCOMMAND) 				// 0112
		WM (TIMER)						// 0113
		WM (HSCROLL)					// 0114
		WM (VSCROLL)					// 0115
		WM (INITMENU)					// 0116
		WM (INITMENUPOPUP)				// 0117
		WM (SYSTIMER)					// 0118
										// 0119-011E
		WM (MENUSELECT) 				// 011F
		WM (MENUCHAR)					// 0120
		WM (ENTERIDLE)					// 0121
		WM (MENURBUTTONUP)				// 0122
		WM (MENUDRAG)					// 0123
		WM (MENUGETOBJECT)				// 0124
		WM (UNINITMENUPOPUP)			// 0125
		WM (MENUCOMMAND)				// 0126
		WM (CHANGEUISTATE)				// 0127
		WM (UPDATEUISTATE)				// 0128
		WM (QUERYUISTATE)				// 0129
										// 0130
		WM (LBTRACKPOINT)				// 0131
		WM (CTLCOLORMSGBOX) 			// 0132
		WM (CTLCOLOREDIT)				// 0133
		WM (CTLCOLORLISTBOX)			// 0134
		WM (CTLCOLORBTN)				// 0135
		WM (CTLCOLORDLG)				// 0136
		WM (CTLCOLORSCROLLBAR)			// 0137
		WM (CTLCOLORSTATIC) 			// 0138
										// 0139-01FF
/////// WM (MOUSEFIRST) 				// 0200 (Duplicated)
		WM (MOUSEMOVE)					// 0200
		WM (LBUTTONDOWN)				// 0201
		WM (LBUTTONUP)					// 0202
		WM (LBUTTONDBLCLK)				// 0203
		WM (RBUTTONDOWN)				// 0204
		WM (RBUTTONUP)					// 0205
		WM (RBUTTONDBLCLK)				// 0206
		WM (MBUTTONDOWN)				// 0207
		WM (MBUTTONUP)					// 0208
		WM (MBUTTONDBLCLK)				// 0209
		WM (MOUSEWHEEL) 				// 020A
		WM (XBUTTONDOWN)				// 020B
		WM (XBUTTONUP)					// 020C
		WM (XBUTTONDBLCLK)				// 020D
////////WM (MOUSELAST)					// 020D (Duplicated)
										// 020E-020F
		WM (PARENTNOTIFY)				// 0210
		WM (ENTERMENULOOP)				// 0211
		WM (EXITMENULOOP)				// 0212
		WM (NEXTMENU)					// 0213
		WM (SIZING) 					// 0214
		WM (CAPTURECHANGED) 			// 0215
		WM (MOVING) 					// 0216
										// 0217
		WM (POWERBROADCAST) 			// 0218
		WM (DEVICECHANGE)				// 0219
										// 021A-021F
		WM (MDICREATE)					// 0220
		WM (MDIDESTROY) 				// 0221
		WM (MDIACTIVATE)				// 0222
		WM (MDIRESTORE) 				// 0223
		WM (MDINEXT)					// 0224
		WM (MDIMAXIMIZE)				// 0225
		WM (MDITILE)					// 0226
		WM (MDICASCADE) 				// 0227
		WM (MDIICONARRANGE) 			// 0228
		WM (MDIGETACTIVE)				// 0229
		WM (DROPOBJECT) 				// 022A
		WM (QUERYDROPOBJECT)			// 022B
		WM (BEGINDRAG)					// 022C
		WM (DRAGLOOP)					// 022D
		WM (DRAGSELECT) 				// 022E
		WM (DRAGMOVE)					// 022F
		WM (MDISETMENU) 				// 0230
		WM (ENTERSIZEMOVE)				// 0231
		WM (EXITSIZEMOVE)				// 0232
		WM (DROPFILES)					// 0233
		WM (MDIREFRESHMENU) 			// 0234
										// 0235-027F
		WM (KANJIFIRST) 				// 0280
		WM (IME_SETCONTEXT) 			// 0281
		WM (IME_NOTIFY) 				// 0282
		WM (IME_CONTROL)				// 0283
		WM (IME_COMPOSITIONFULL)		// 0284
		WM (IME_SELECT) 				// 0285
		WM (IME_CHAR)					// 0286
										// 0287
		WM (IME_REQUEST)				// 0288
										// 0289-028E
		WM (KANJILAST)					// 028F
		WM (IME_KEYDOWN)				// 0290
		WM (IME_KEYUP)					// 0291
										// 0290-029F
		WM (NCMOUSEHOVER)				// 02A0
		WM (MOUSEHOVER) 				// 02A1
		WM (NCMOUSELEAVE)				// 02A2
		WM (MOUSELEAVE) 				// 02A3
										// 02A4-02FF
		WM (CUT)						// 0300
		WM (COPY)						// 0301
		WM (PASTE)						// 0302
		WM (CLEAR)						// 0303
		WM (UNDO)						// 0304
		WM (RENDERFORMAT)				// 0305
		WM (RENDERALLFORMATS)			// 0306
		WM (DESTROYCLIPBOARD)			// 0307
		WM (DRAWCLIPBOARD)				// 0308
		WM (PAINTCLIPBOARD) 			// 0309
		WM (VSCROLLCLIPBOARD)			// 030A
		WM (SIZECLIPBOARD)				// 030B
		WM (ASKCBFORMATNAME)			// 030C
		WM (CHANGECBCHAIN)				// 030D
		WM (HSCROLLCLIPBOARD)			// 030E
		WM (QUERYNEWPALETTE)			// 030F
		WM (PALETTEISCHANGING)			// 0310
		WM (PALETTECHANGED) 			// 0311
		WM (HOTKEY) 					// 0312
										// 0313-0316
		WM (PRINT)						// 0317
		WM (PRINTCLIENT)				// 0318
		WM (APPCOMMAND) 				// 0319
										// 031A-0357
		WM (HANDHELDFIRST)				// 0358
										// 0359-035E
		WM (HANDHELDLAST)				// 035F
		WM (AFXFIRST)					// 0360
										// 0361-037E
		WM (AFXLAST)					// 037F
		WM (PENWINFIRST)				// 0380
		WM (RCRESULT)					// 0381
		WM (HOOKRCRESULT)				// 0382
		WM (GLOBALRCCHANGE) 			// 0383
		WM (SKB)						// 0384
		WM (HEDITCTL)					// 0385
										// 0386-038E
		WM (PENWINLAST) 				// 038F
		WM (COALESCE_FIRST) 			// 0390
										// 0391-039E
		WM (COALESCE_LAST)				// 039F
		WM (MM_RESERVED_FIRST)			// 03A0
										// 03A1-03DE
		WM (MM_RESERVED_LAST)			// 03DF
/////// WM (DDE_FIRST)					// 03E0
		WM (DDE_INITIATE)				// 03E0
		WM (DDE_TERMINATE)				// 03E1
		WM (DDE_ADVISE) 				// 03E2
		WM (DDE_UNADVISE)				// 03E3
		WM (DDE_ACK)					// 03E4
		WM (DDE_DATA)					// 03E5
		WM (DDE_REQUEST)				// 03E6
		WM (DDE_POKE)					// 03E7
		WM (DDE_EXECUTE)				// 03E8
/////// WM (DDE_LAST)					// 03E8
										// 03E9-03EF
		WM (CBT_RESERVED_FIRST) 		// 03F0
										// 03F1-03FE
		WM (CBT_RESERVED_LAST)			// 03FF
		WM (USER)						// 0400
		
		WM (CPL_LAUNCH) 				// 07E8
		WM (CPL_LAUNCHED)				// 07E9
		
		WM (DLGBORDER)					// 11EF
		WM (DLGSUBCLASS)				// 11F0
		
		WM (APP)						// 8000

		default:
			if (WM_USER <= message && message < WM_APP)
			{
				switch (clstr[LookupClass (hWnd)].eClass)
				{
////				case EC_COMMON:
////					// Handle Common Control messages
////					Format_CCM (szTemp, message);
////					break;
////
////				case EC_DATETIMEPICK:
////					// Handle Date Time Picker messages
////					Format_DTM (szTemp, message);
////					break;
////
					case EC_HEADER:
						// Handle Header messages
						Format_HDM (szTemp, message);
						break;

					case EC_LISTVIEW:
						// Handle ListView messages
						Format_LVM (szTemp, message);
						break;

////				case EC_MONTHCAL:
////					// Handle Month Calendar messages
////					Format_MCM (szTemp, message);
////					break;
////
////				case EC_PAGESCROLLER:
////					// Handle Page Scroller messages
////					Format_PGM (szTemp, message);
////					break;
////
////				case EC_TAB:
////					// Handle Tab Control messages
////					Format_TCM (szTemp, message);
////					break;
////
					case EC_TOOLTIPS:
						// Handle ToolTips messages
						Format_TTM (szTemp, message);
						break;

					case EC_TREEVIEW:
						// Handle TreeView messages
						Format_TVM (szTemp, message);
						break;

					default:
						wsprintf (szTemp, "WM_USER+%u", message - WM_USER);
						break;
				} // End SWITCH 
			} else
			if (WM_APP	<= message)
				wsprintf (szTemp, "WM_APP+%u",  message - WM_APP);
			else
				wsprintf (szTemp, "%04X",  message);
			break;
	} // End SWITCH
	
	return szTemp;

} // End APIMsg ()


//************************************************************************
//	Format_ HDM
//
//	Format Header message
//************************************************************************

void Format_HDM (char szTemp[], UINT message)

{
#define HDM(a)	case HDM_##a:					\
					lstrcpy (szTemp, "HDM_" #a);\
					break;

	switch (message)
	{
		HDM (GETITEMCOUNT)				// HDM_FIRST +	 0
		HDM (INSERTITEMA)				// HDM_FIRST +	 1
		HDM (INSERTITEMW)				// HDM_FIRST +	10
		HDM (DELETEITEM)				// HDM_FIRST +	 2
		HDM (GETITEMA)					// HDM_FIRST +	 3
		HDM (GETITEMW)					// HDM_FIRST +	11
		HDM (SETITEMA)					// HDM_FIRST +	 4
		HDM (SETITEMW)					// HDM_FIRST +	12
		HDM (LAYOUT)					// HDM_FIRST +	 5
		HDM (HITTEST)					// HDM_FIRST +	 6
		HDM (GETITEMRECT)				// HDM_FIRST +	 7
		HDM (SETIMAGELIST)				// HDM_FIRST +	 8
		HDM (GETIMAGELIST)				// HDM_FIRST +	 9
		HDM (ORDERTOINDEX)				// HDM_FIRST +	15
		HDM (CREATEDRAGIMAGE)			// HDM_FIRST +	16
		HDM (GETORDERARRAY) 			// HDM_FIRST +	17
		HDM (SETORDERARRAY) 			// HDM_FIRST +	18
		HDM (SETHOTDIVIDER) 			// HDM_FIRST +	19
		HDM (SETBITMAPMARGIN)			// HDM_FIRST +	20
		HDM (GETBITMAPMARGIN)			// HDM_FIRST +	21
		HDM (SETFILTERCHANGETIMEOUT)	// HDM_FIRST +	22
		HDM (EDITFILTER)				// HDM_FIRST +	23
		HDM (CLEARFILTER)				// HDM_FIRST +	24

		default:
			wsprintf (szTemp, "WM_USER+%u", message - WM_USER);
			break;
	} // End SWITCH
} // Format_HDM ()


//************************************************************************
//	Format_LVM
//
//	Format ListView message
//************************************************************************

void Format_LVM (char szTemp[], UINT message)

{
#define LVM(a)	case LVM_##a:					\
					lstrcpy (szTemp, "LVM_" #a);\
					break;

	switch (message)
	{
		LVM (GETBKCOLOR)				// LVM_FIRST +	 0
		LVM (SETBKCOLOR)				// LVM_FIRST +	 1
		LVM (GETIMAGELIST)				// LVM_FIRST +	 2
		LVM (SETIMAGELIST)				// LVM_FIRST +	 3
		LVM (GETITEMCOUNT)				// LVM_FIRST +	 4
		LVM (GETITEMA)					// LVM_FIRST +	 5
		LVM (SETITEMA)					// LVM_FIRST +	 6
		LVM (INSERTITEMA)				// LVM_FIRST +	 7
		LVM (DELETEITEM)				// LVM_FIRST +	 8
		LVM (DELETEALLITEMS)			// LVM_FIRST +	 9
		LVM (GETCALLBACKMASK)			// LVM_FIRST +	10
		LVM (SETCALLBACKMASK)			// LVM_FIRST +	11
		LVM (GETNEXTITEM)				// LVM_FIRST +	12
		LVM (FINDITEMA) 				// LVM_FIRST +	13
		LVM (GETITEMRECT)				// LVM_FIRST +	14
		LVM (SETITEMPOSITION)			// LVM_FIRST +	15
		LVM (GETITEMPOSITION)			// LVM_FIRST +	16
		LVM (GETSTRINGWIDTHA)			// LVM_FIRST +	17
		LVM (HITTEST)					// LVM_FIRST +	18
		LVM (ENSUREVISIBLE) 			// LVM_FIRST +	19
		LVM (SCROLL)					// LVM_FIRST +	20
		LVM (REDRAWITEMS)				// LVM_FIRST +	21
		LVM (ARRANGE)					// LVM_FIRST +	22
		LVM (EDITLABELA)				// LVM_FIRST +	23
		LVM (GETEDITCONTROL)			// LVM_FIRST +	24
		LVM (GETCOLUMNA)				// LVM_FIRST +	25
		LVM (SETCOLUMNA)				// LVM_FIRST +	26
		LVM (INSERTCOLUMNA) 			// LVM_FIRST +	27
		LVM (DELETECOLUMN)				// LVM_FIRST +	28
		LVM (GETCOLUMNWIDTH)			// LVM_FIRST +	29
		LVM (SETCOLUMNWIDTH)			// LVM_FIRST +	30
		LVM (GETHEADER) 				// LVM_FIRST +	31
		LVM (CREATEDRAGIMAGE)			// LVM_FIRST +	33
		LVM (GETVIEWRECT)				// LVM_FIRST +	34
		LVM (GETTEXTCOLOR)				// LVM_FIRST +	35
		LVM (SETTEXTCOLOR)				// LVM_FIRST +	36
		LVM (GETTEXTBKCOLOR)			// LVM_FIRST +	37
		LVM (SETTEXTBKCOLOR)			// LVM_FIRST +	38
		LVM (GETTOPINDEX)				// LVM_FIRST +	39
		LVM (GETCOUNTPERPAGE)			// LVM_FIRST +	40
		LVM (GETORIGIN) 				// LVM_FIRST +	41
		LVM (UPDATE)					// LVM_FIRST +	42
		LVM (SETITEMSTATE)				// LVM_FIRST +	43
		LVM (GETITEMSTATE)				// LVM_FIRST +	44
		LVM (GETITEMTEXTA)				// LVM_FIRST +	45
		LVM (SETITEMTEXTA)				// LVM_FIRST +	46
		LVM (SETITEMCOUNT)				// LVM_FIRST +	47
		LVM (SORTITEMS) 				// LVM_FIRST +	48
		LVM (SETITEMPOSITION32) 		// LVM_FIRST +	49
		LVM (GETSELECTEDCOUNT)			// LVM_FIRST +	50
		LVM (GETITEMSPACING)			// LVM_FIRST +	51
		LVM (GETISEARCHSTRINGA) 		// LVM_FIRST +	52
		LVM (SETICONSPACING)			// LVM_FIRST +	53
		LVM (SETEXTENDEDLISTVIEWSTYLE)	// LVM_FIRST +	54
		LVM (GETEXTENDEDLISTVIEWSTYLE)	// LVM_FIRST +	55
		LVM (GETSUBITEMRECT)			// LVM_FIRST +	56
		LVM (SUBITEMHITTEST)			// LVM_FIRST +	57
		LVM (SETCOLUMNORDERARRAY)		// LVM_FIRST +	58
		LVM (GETCOLUMNORDERARRAY)		// LVM_FIRST +	59
		LVM (SETHOTITEM)				// LVM_FIRST +	60
		LVM (GETHOTITEM)				// LVM_FIRST +	61
		LVM (SETHOTCURSOR)				// LVM_FIRST +	62
		LVM (GETHOTCURSOR)				// LVM_FIRST +	63
		LVM (APPROXIMATEVIEWRECT)		// LVM_FIRST +	64
		LVM (SETWORKAREAS)				// LVM_FIRST +	65
		LVM (GETSELECTIONMARK)			// LVM_FIRST +	66
		LVM (SETSELECTIONMARK)			// LVM_FIRST +	67
		LVM (SETBKIMAGEA)				// LVM_FIRST +	68
		LVM (GETBKIMAGEA)				// LVM_FIRST +	69
		LVM (GETWORKAREAS)				// LVM_FIRST +	70
		LVM (SETHOVERTIME)				// LVM_FIRST +	71
		LVM (GETHOVERTIME)				// LVM_FIRST +	72
		LVM (GETNUMBEROFWORKAREAS)		// LVM_FIRST +	73
		LVM (SETTOOLTIPS)				// LVM_FIRST +	74
		LVM (GETITEMW)					// LVM_FIRST +	75
		LVM (SETITEMW)					// LVM_FIRST +	76
		LVM (INSERTITEMW)				// LVM_FIRST +	77
		LVM (GETTOOLTIPS)				// LVM_FIRST +	78
		LVM (SORTITEMSEX)				// LVM_FIRST +	81
		LVM (FINDITEMW) 				// LVM_FIRST +	83
		LVM (GETSTRINGWIDTHW)			// LVM_FIRST +	87
		LVM (GETCOLUMNW)				// LVM_FIRST +	95
		LVM (SETCOLUMNW)				// LVM_FIRST +	96
		LVM (INSERTCOLUMNW) 			// LVM_FIRST +	97
		LVM (GETITEMTEXTW)				// LVM_FIRST + 115
		LVM (SETITEMTEXTW)				// LVM_FIRST + 116
		LVM (GETISEARCHSTRINGW) 		// LVM_FIRST + 117
		LVM (EDITLABELW)				// LVM_FIRST + 118
		LVM (SETBKIMAGEW)				// LVM_FIRST + 138
		LVM (GETBKIMAGEW)				// LVM_FIRST + 139

		default:
			wsprintf (szTemp, "WM_USER+%u", message - WM_USER);
			break;
	} // End SWITCH
} // Format_LVM ()


//************************************************************************
//	Format_TTM
//
//	Format ToolTips message
//************************************************************************

void Format_TTM (char szTemp[], UINT message)

{
#define TTM(a)	case TTM_##a:					\
					lstrcpy (szTemp, "TTM_" #a);\
					break;

	switch (message)
	{
		TTM (ACTIVATE)			// WM_USER +  1
		TTM (SETDELAYTIME)		// WM_USER +  3
		TTM (ADDTOOLA)			// WM_USER +  4
		TTM (DELTOOLA)			// WM_USER +  5
		TTM (NEWTOOLRECTA)		// WM_USER +  6
		TTM (RELAYEVENT)		// WM_USER +  7
		TTM (GETTOOLINFOA)		// WM_USER +  8
		TTM (SETTOOLINFOA)		// WM_USER +  9
		TTM (HITTESTA)			// WM_USER + 10
		TTM (GETTEXTA)			// WM_USER + 11
		TTM (UPDATETIPTEXTA)	// WM_USER + 12
		TTM (GETTOOLCOUNT)		// WM_USER + 13
		TTM (ENUMTOOLSA)		// WM_USER + 14
		TTM (GETCURRENTTOOLA)	// WM_USER + 15
		TTM (WINDOWFROMPOINT)	// WM_USER + 16
		TTM (TRACKACTIVATE) 	// WM_USER + 17
		TTM (TRACKPOSITION) 	// WM_USER + 18
		TTM (SETTIPBKCOLOR) 	// WM_USER + 19
		TTM (SETTIPTEXTCOLOR)	// WM_USER + 20
		TTM (GETDELAYTIME)		// WM_USER + 21
		TTM (GETTIPBKCOLOR) 	// WM_USER + 22
		TTM (GETTIPTEXTCOLOR)	// WM_USER + 23
		TTM (SETMAXTIPWIDTH)	// WM_USER + 24
		TTM (GETMAXTIPWIDTH)	// WM_USER + 25
		TTM (SETMARGIN) 		// WM_USER + 26
		TTM (GETMARGIN) 		// WM_USER + 27
		TTM (POP)				// WM_USER + 28
		TTM (UPDATE)			// WM_USER + 29
		TTM (GETBUBBLESIZE) 	// WM_USER + 30
		TTM (ADJUSTRECT)		// WM_USER + 31
		TTM (SETTITLEA) 		// WM_USER + 32
		TTM (SETTITLEW) 		// WM_USER + 33
		TTM (ADDTOOLW)			// WM_USER + 50
		TTM (DELTOOLW)			// WM_USER + 51
		TTM (NEWTOOLRECTW)		// WM_USER + 52
		TTM (GETTOOLINFOW)		// WM_USER + 53
		TTM (SETTOOLINFOW)		// WM_USER + 54
		TTM (HITTESTW)			// WM_USER + 55
		TTM (GETTEXTW)			// WM_USER + 56
		TTM (UPDATETIPTEXTW)	// WM_USER + 57
		TTM (ENUMTOOLSW)		// WM_USER + 58
		TTM (GETCURRENTTOOLW)	// WM_USER + 59

		default:
			wsprintf (szTemp, "WM_USER+%u", message - WM_USER);
			break;
	} // End SWITCH
} // Format_TTM ()


//************************************************************************
//	Format_TVM
//
//	Format TreeView message
//************************************************************************

void Format_TVM (char szTemp[], UINT message)

{
#define TVM(a)	case TVM_##a:					\
					lstrcpy (szTemp, "TVM_" #a);\
					break;

	switch (message)
	{
		TVM (INSERTITEMA)		// TV_FIRST +  0
		TVM (DELETEITEM)		// TV_FIRST +  1
		TVM (EXPAND)			// TV_FIRST +  2
		TVM (GETITEMRECT)		// TV_FIRST +  4
		TVM (GETCOUNT)			// TV_FIRST +  5
		TVM (GETINDENT) 		// TV_FIRST +  6
		TVM (SETINDENT) 		// TV_FIRST +  7
		TVM (GETIMAGELIST)		// TV_FIRST +  8
		TVM (SETIMAGELIST)		// TV_FIRST +  9
		TVM (GETNEXTITEM)		// TV_FIRST + 10
		TVM (SELECTITEM)		// TV_FIRST + 11
		TVM (GETITEMA)			// TV_FIRST + 12
		TVM (SETITEMA)			// TV_FIRST + 13
		TVM (EDITLABELA)		// TV_FIRST + 14
		TVM (GETEDITCONTROL)	// TV_FIRST + 15
		TVM (GETVISIBLECOUNT)	// TV_FIRST + 16
		TVM (HITTEST)			// TV_FIRST + 17
		TVM (CREATEDRAGIMAGE)	// TV_FIRST + 18
		TVM (SORTCHILDREN)		// TV_FIRST + 19
		TVM (ENSUREVISIBLE) 	// TV_FIRST + 20
		TVM (SORTCHILDRENCB)	// TV_FIRST + 21
		TVM (ENDEDITLABELNOW)	// TV_FIRST + 22
		TVM (GETISEARCHSTRINGA) // TV_FIRST + 23
		TVM (SETTOOLTIPS)		// TV_FIRST + 24
		TVM (GETTOOLTIPS)		// TV_FIRST + 25
		TVM (SETINSERTMARK) 	// TV_FIRST + 26
		TVM (SETUNICODEFORMAT)	// TV_FIRST + 
		TVM (GETUNICODEFORMAT)	// TV_FIRST + 
		TVM (SETITEMHEIGHT) 	// TV_FIRST + 27
		TVM (GETITEMHEIGHT) 	// TV_FIRST + 28
		TVM (SETBKCOLOR)		// TV_FIRST + 29
		TVM (SETTEXTCOLOR)		// TV_FIRST + 30
		TVM (GETBKCOLOR)		// TV_FIRST + 31
		TVM (GETTEXTCOLOR)		// TV_FIRST + 32
		TVM (SETSCROLLTIME) 	// TV_FIRST + 33
		TVM (GETSCROLLTIME) 	// TV_FIRST + 34
		TVM (SETINSERTMARKCOLOR)// TV_FIRST + 37
		TVM (GETINSERTMARKCOLOR)// TV_FIRST + 38
		TVM (GETITEMSTATE)		// TV_FIRST + 39
		TVM (SETLINECOLOR)		// TV_FIRST + 40
		TVM (GETLINECOLOR)		// TV_FIRST + 41
		TVM (INSERTITEMW)		// TV_FIRST + 50
		TVM (GETITEMW)			// TV_FIRST + 62
		TVM (SETITEMW)			// TV_FIRST + 63
		TVM (GETISEARCHSTRINGW) // TV_FIRST + 64
		TVM (EDITLABELW)		// TV_FIRST + 65

		default:
			wsprintf (szTemp, "WM_USER+%u", message - WM_USER);
			break;
	} // End SWITCH
} // Format_TVM ()


//************************************************************************
//	Display_DRAWITEMSTRUCT ()
//
//	Display DRAWITEMSTRUCT structure
//************************************************************************

void Display_DRAWITEMSTRUCT (LPDRAWITEMSTRUCT lpdis)

{
	char szTemp[1024], szFlags1[256], szFlags2[256], szFlags3[256], szRect[80];

	wsprintf (szTemp,
			  "CtlType = %s, "
			  "CtlID = %X, "
			  "itemID = %X, "
			  "itemAction = %s, "
			  "itemState = %s, "
			  "hwndItem = %X, "
			  "hDC = %X, "
			  "rcItem = %s, "
			  "itemData = %X",
			  FormatFlags (lpdis->CtlType,	  Flags_ODT, nFlags_ODT, szFlags1),
			  lpdis->CtlID,
			  lpdis->itemID,
			  FormatFlags (lpdis->itemAction, Flags_ODA, nFlags_ODA, szFlags2),
			  FormatFlags (lpdis->itemState,  Flags_ODS, nFlags_ODS, szFlags3),
			  lpdis->hwndItem,
			  lpdis->hDC,
			  Format_RECT (&lpdis->rcItem, szRect),
			  lpdis->itemData);

	OutputDebugString (FormatStr (szTemp));
} // End Display_DRAWITEMSTRUCT ()


//************************************************************************
//	Display_Button ()
//
//	Display Button notifications
//************************************************************************

void Display_Button (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[256], szFlags[256];

	wsprintf (szTemp,
			  "Flags = %s",
			  FormatFlags (GET_WM_COMMAND_CMD (wParam, lParam),
						   Flags_BN,
						   nFlags_BN,
						   szFlags));
	OutputDebugString (FormatStr (szTemp));

} // End Display_Button ()


//************************************************************************
//	Display_ComboBox ()
//
//	Display ComboBox notifications
//************************************************************************

void Display_ComboBox (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[256], szFlags[256];

	wsprintf (szTemp,
			  "Flags = %s",
			  FormatFlags (GET_WM_COMMAND_CMD (wParam, lParam),
						   Flags_CBN,
						   nFlags_CBN,
						   szFlags));
	OutputDebugString (FormatStr (szTemp));

} // End Display_ComboBox ()


//************************************************************************
//	Display_EditBox ()
//
//	Display EditBox notifications
//************************************************************************

void Display_EditBox (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[256], szFlags[256];

	wsprintf (szTemp,
			  "Flags = %s",
			  FormatFlags (GET_WM_COMMAND_CMD (wParam, lParam),
						   Flags_EN,
						   nFlags_EN,
						   szFlags));
	OutputDebugString (FormatStr (szTemp));

} // End Display_EditBox ()


//************************************************************************
//	Display_ListBox ()
//
//	Display ListBox notifications
//************************************************************************

void Display_ListBox (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[256], szFlags[256];

	wsprintf (szTemp,
			  "Flags = %s",
			  FormatFlags (GET_WM_COMMAND_CMD (wParam, lParam),
						   Flags_LBN,
						   nFlags_LBN,
						   szFlags));
	OutputDebugString (FormatStr (szTemp));

} // End Display_ListBox ()


//************************************************************************
//	Display_ScrollBar ()
//
//	Display ScrollBar notifications
//************************************************************************

void Display_ScrollBar (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[256], szFlags[256];

	wsprintf (szTemp,
			  "Flags = %s",
			  FormatFlags (GET_WM_COMMAND_CMD (wParam, lParam),
						   Flags_SBN,
						   nFlags_SBN,
						   szFlags));
	OutputDebugString (FormatStr (szTemp));

} // End Display_ScrollBar ()


//************************************************************************
//	Display_Static ()
//
//	Display Static notifications
//************************************************************************

void Display_Static (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[256], szFlags[256];

	wsprintf (szTemp,
			  "Flags = %s",
			  FormatFlags (GET_WM_COMMAND_CMD (wParam, lParam),
						   Flags_STN,
						   nFlags_STN,
						   szFlags));
	OutputDebugString (FormatStr (szTemp));

} // End Display_Static ()


//************************************************************************
//	Display_HDITEM ()
//
//	Display HDITEM structure
//************************************************************************

void Display_HDITEM (HWND hWnd, LPHDITEM lphdi)

{
	char szTemp[1024], szHDI[256], szHDF[256], szHDFT[256];
#define lpnm		lphdi

	wsprintf (szTemp,
			  "mask = %s, "
			  "cxy = %X, "
			  "psztext = %X, "
			  "hbm = %X, "
			  "cchTextMax = %X, "
			  "fmt = %s, "
			  "lParam = %X, "
			  "iImage = %X, "
			  "iOrder = %X, "
			  "type = %s, "
			  "pvFilter = %X",
			  FormatFlags (lpnm->mask, Flags_HDI,  nFlags_HDI,	szHDI),
			  lpnm->cxy,
			  lpnm->pszText,
			  lpnm->hbm,
			  lpnm->cchTextMax,
			  FormatFlags (lpnm->fmt,  Flags_HDF,  nFlags_HDF,	szHDF),
			  lpnm->lParam,
			  lpnm->iImage,
			  lpnm->iOrder,
			  FormatFlags (lpnm->type, Flags_HDFT, nFlags_HDFT, szHDFT),
			  lpnm->pvFilter);
	OutputDebugString (FormatStr (szTemp));

#undef	lpnm
} // End Display_HDITEM ()


//************************************************************************
//	Display_LV_DISPINFO ()
//
//	Display LV_DISPINFO structure
//************************************************************************

void Display_LV_DISPINFO (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_LV_DISPINFO ()


//************************************************************************
//	Display_LV_FINDINFO ()
//
//	Display LV_FINDINFO structure
//************************************************************************

void Display_LV_FINDINFO (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_LV_FINDINFO ()


//************************************************************************
//	Display_LV_KEYDOWN ()
//
//	Display LV_KEYDOWN structure
//************************************************************************

void Display_LV_KEYDOWN (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_LV_KEYDOWN ()


//************************************************************************
//	Display_NM_CHAR ()
//
//	Display NM_CHAR structure
//************************************************************************

void Display_NM_CHAR (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NM_CHAR ()


//************************************************************************
//	Display_NM_CLICK ()
//
//	Display NM_CLICK structure
//************************************************************************

void Display_NM_CLICK (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	switch (clstr[LookupClass (((LPNMHDR) lParam)->hwndFrom)].eClass)
	{
		case EC_LISTVIEW:
			// Handle ListView as NMITEMACTIVATE
			Display_NM_ITEMACTIVATE (hWnd, wParam, lParam);
			break;

		case EC_STATUS:
			// Handle StatusBar as NMMOUSE
			Display_NM_MOUSE (hWnd, wParam, lParam);
			break;

		default:
			// Ignore others
			break;
	} // End SWITCH 
} // End Display_NM_CLICK ()


//************************************************************************
//	Display_NM_CUSTOMDRAW_SUB ()
//
//	Display NM_CUSTOMDRAW_SUB structure
//************************************************************************

void Display_NM_CUSTOMDRAW_SUB (LPARAM lParam,
								LPSTR (*lpfnCustom)(LPARAM))

{
	char szTemp[1024], szRECT[256], szFlags1[256], szFlags2[256];
#define lpnm		((LPNMCUSTOMDRAW) lParam)

	wsprintf (szTemp,
			  "dwDrawStage = %s, "
			  "hdc = %X, "
			  "rc = %s, "
			  "dwItemSpec = %X, "
			  "uItemState = %s, "
			  "iItemlParam = %X%s",
			  FormatFlags (lpnm->dwDrawStage, Flags_CDDS, nFlags_CDDS, szFlags1),
			  lpnm->hdc,
			  Format_RECT (&lpnm->rc, szRECT),
			  lpnm->dwItemSpec,
			  FormatFlags (lpnm->uItemState,  Flags_CDIS, nFlags_CDIS, szFlags2),
			  lpnm->lItemlParam,
			  (LPSTR)(lpfnCustom?(*lpfnCustom) (lParam):""));
	OutputDebugString (FormatStr (szTemp));

#undef	lpnm
} // End Display_NM_CUSTOMDRAW_SUB ()


//************************************************************************
//	Display_NM_CUSTOMDRAW ()
//
//	Display NM_CUSTOMDRAW structure
//************************************************************************

void Display_NM_CUSTOMDRAW (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	switch (clstr[LookupClass (((LPNMHDR) lParam)->hwndFrom)].eClass)
	{
		case EC_LISTVIEW:
			// Handle ListView as NMLVCUSTOMDRAW
			Display_NM_LVCUSTOMDRAW (lParam);
			break;

		case EC_TOOLBAR:
			// Handle ToolBar  as NMTBCUSTOMDRAW
			Display_NM_TBCUSTOMDRAW (lParam);
			break;

		case EC_TOOLTIPS:
			// Handle ToolTip  as NMTTCUSTOMDRAW
			Display_NM_TTCUSTOMDRAW (lParam);
			break;

		case EC_TREEVIEW:
			// Handle TreeView as NMTVCUSTOMDRAW
			Display_NM_TVCUSTOMDRAW (lParam);
			break;
		default:
			// Handle all else as NMCUSTOMDRAW
			Display_NM_CUSTOMDRAW_SUB (lParam, NULL);
			break;
	} // End SWITCH 

} // End Display_NM_CUSTOMDRAW ()


//************************************************************************
//	Format_NM_LVCUSTOMDRAW ()
//
//	Format special ListView tail to NM_CUSTOMDRAW
//************************************************************************

LPSTR Format_NM_LVCUSTOMDRAW (LPARAM lParam)

{
	static char szTemp[256];
	char szRGB1[80], szRGB2[80];
#define lpnm		((LPNMLVCUSTOMDRAW) lParam)

	wsprintf (szTemp, ", "
			  "clrText = %s, "
			  "clrTextBk = %s, "
			  "iSubItem = %X",
			  Format_RGB (lpnm->clrText,   szRGB1),
			  Format_RGB (lpnm->clrTextBk, szRGB2),
			  lpnm->iSubItem);

	return &szTemp[0];
#undef	lpnm
} // End Format_NM_LVCUSTOMDRAW ()


//************************************************************************
//	Display_NM_LVCUSTOMDRAW ()
//
//	Display NM_LVCUSTOMDRAW structure
//************************************************************************

void Display_NM_LVCUSTOMDRAW (LPARAM lParam)

{
	Display_NM_CUSTOMDRAW_SUB (lParam, &Format_NM_LVCUSTOMDRAW);
} // End Display_NM_LVCUSTOMDRAW ()


//************************************************************************
//	Format_NM_TBCUSTOMDRAW ()
//
//	Format special ToolBar tail to NM_CUSTOMDRAW
//************************************************************************

LPSTR Format_NM_TBCUSTOMDRAW (LPARAM lParam)

{
	static char szTemp[256];
	char szRGB1[80],
		 szRGB2[80],
		 szRGB3[80],
		 szRGB4[80],
		 szRGB5[80],
		 szRGB6[80],
		 szRect[80];
#define lpnm		((LPNMTBCUSTOMDRAW) lParam)

	wsprintf (szTemp, ", "
			  "hbrMonoDither = %x, "
			  "hbrLines = %X, "
			  "hpenLines = %X, "
			  "clrText = %s, "
			  "clrMark = %s, "
			  "clrTextHighLight = %s, "
			  "clrBtnFace = %s, "
			  "clrBtnHighLight = %s, "
			  "clrHighLightHotTrack = %s, "
			  "rcText = %s, "
			  "nStringBkMode = %X, "
			  "nHLStringBkMode = %X",
			  lpnm->hbrMonoDither,
			  lpnm->hbrLines,
			  lpnm->hpenLines,
			  Format_RGB (lpnm->clrText,			  szRGB1),
			  Format_RGB (lpnm->clrMark,			  szRGB2),
			  Format_RGB (lpnm->clrTextHighlight,	  szRGB3),
			  Format_RGB (lpnm->clrBtnFace, 		  szRGB4),
			  Format_RGB (lpnm->clrBtnHighlight,	  szRGB5),
			  Format_RGB (lpnm->clrHighlightHotTrack, szRGB6),
			  Format_RECT (&lpnm->rcText, szRect),
			  lpnm->nStringBkMode,
			  lpnm->nHLStringBkMode);

	return &szTemp[0];
#undef	lpnm
} // End Format_NM_TBCUSTOMDRAW ()


//************************************************************************
//	Display_NM_TBCUSTOMDRAW ()
//
//	Display NM_TBCUSTOMDRAW structure
//************************************************************************

void Display_NM_TBCUSTOMDRAW (LPARAM lParam)

{
	Display_NM_CUSTOMDRAW_SUB (lParam, &Format_NM_TBCUSTOMDRAW);
} // End Display_NM_TBCUSTOMDRAW ()


//************************************************************************
//	Format_NM_TTCUSTOMDRAW ()
//
//	Format special ToolTip tail to NM_CUSTOMDRAW
//************************************************************************

LPSTR Format_NM_TTCUSTOMDRAW (LPARAM lParam)

{
	static char szTemp[256];
	char szFlags[256];
#define lpnm		((LPNMTTCUSTOMDRAW) lParam)

	wsprintf (szTemp, ", "
			  "uDrawFlags = %s",
			  FormatFlags (lpnm->uDrawFlags, Flags_DT, nFlags_DT, szFlags));

	return &szTemp[0];
#undef	lpnm
} // End Format_NM_TTCUSTOMDRAW ()


//************************************************************************
//	Display_NM_TTCUSTOMDRAW ()
//
//	Display NM_TTCUSTOMDRAW structure
//************************************************************************

void Display_NM_TTCUSTOMDRAW (LPARAM lParam)

{
	Display_NM_CUSTOMDRAW_SUB (lParam, &Format_NM_TTCUSTOMDRAW);
} // End Display_NM_TTCUSTOMDRAW ()


//************************************************************************
//	Format_NM_TVCUSTOMDRAW ()
//
//	Format special TreeView tail to NM_CUSTOMDRAW
//************************************************************************

LPSTR Format_NM_TVCUSTOMDRAW (LPARAM lParam)

{
	static char szTemp[256];
	char szRGB1[80],
		 szRGB2[80];
#define lpnm		((LPNMTVCUSTOMDRAW) lParam)

	wsprintf (szTemp, ", "
			  "clrText = %s, "
			  "clrTextBk = %s, "
			  "iLevel = %X",
			  Format_RGB (lpnm->clrText,   szRGB1),
			  Format_RGB (lpnm->clrTextBk, szRGB2),
			  lpnm->iLevel);

	return &szTemp[0];
#undef	lpnm
} // End Format_NM_TVCUSTOMDRAW ()


//************************************************************************
//	Display_NM_TVCUSTOMDRAW ()
//
//	Display NM_TVCUSTOMDRAW structure
//************************************************************************

void Display_NM_TVCUSTOMDRAW (LPARAM lParam)

{
	Display_NM_CUSTOMDRAW_SUB (lParam, &Format_NM_TVCUSTOMDRAW);
} // End Display_NM_TVCUSTOMDRAW ()


//************************************************************************
//	Display_NM_HEADER ()
//
//	Display NM_HEADER structure
//************************************************************************

void Display_NM_HEADER (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[256];
#define lpnm		((LPNMHEADER) lParam)

	wsprintf (szTemp,
			  "iItem = %X, "
			  "iButton = %X, "
			  "pitem = %X",
			  lpnm->iItem,
			  lpnm->iButton,
			  lpnm->pitem);
	OutputDebugString (FormatStr (szTemp));

	// Display optional HDITEM structure
	if (lpnm->pitem)
		Display_HDITEM (hWnd, lpnm->pitem);

#undef	lpnm
} // End Display_NM_HEADER ()


//************************************************************************
//	Display_NM_ITEMACTIVATE ()
//
//	Display NM_ITEMACTIVATE structure
//************************************************************************

void Display_NM_ITEMACTIVATE (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[1024], szLVIF[256], szLVKF[256], szPOINT[256];
#define lpnm		((LPNMITEMACTIVATE) lParam)

	wsprintf (szTemp,
			  "iItem = %X, "
			  "iSubItem = %X, "
			  "uNewState = %X, "
			  "uOldState = %X, "
			  "uChanged = %s, "
			  "ptAction = %s, "
			  "lParam = %X, "
			  "uKeyFlags = %s",
			  lpnm->iItem,
			  lpnm->iSubItem,
			  lpnm->uNewState,
			  lpnm->uOldState,
			  FormatFlags (lpnm->uChanged, Flags_LVIF, nFlags_LVIF, szLVIF),
			  Format_POINT (lpnm->ptAction, szPOINT),
			  lpnm->lParam,
			  FormatFlags (lpnm->uKeyFlags, Flags_LVKF, nFlags_LVKF, szLVKF));
	OutputDebugString (FormatStr (szTemp));

#undef	lpnm
} // End Display_NM_ITEMACTIVATE ()


//************************************************************************
//	Display_NM_KEY ()
//
//	Display NM_KEY structure
//************************************************************************

void Display_NM_KEY (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NM_KEY ()


//************************************************************************
//	Display_NM_LISTVIEW ()
//
//	Display NM_LISTVIEW structure
//************************************************************************

void Display_NM_LISTVIEW (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[1024], szLVIF[256], szPOINT[256];
#define lpnm		((LPNM_LISTVIEW) lParam)

	wsprintf (szTemp,
			  "iItem = %X, "
			  "iSubItem = %X, "
			  "uNewState = %X, "
			  "uOldState = %X, "
			  "uChanged = %s, "
			  "ptAction = %s, "
			  "lParam = %X",
			  lpnm->iItem,
			  lpnm->iSubItem,
			  lpnm->uNewState,
			  lpnm->uOldState,
			  FormatFlags (lpnm->uChanged, Flags_LVIF, nFlags_LVIF, szLVIF),
			  Format_POINT (lpnm->ptAction, szPOINT),
			  lpnm->lParam);
	OutputDebugString (FormatStr (szTemp));

#undef	lpnm
} // End Display_NM_LISTVIEW ()


//************************************************************************
//	Display_NM_MOUSE ()
//
//	Display NM_MOUSE structure
//************************************************************************

void Display_NM_MOUSE (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[1024], szPOINT[256];
#define lpnm		((LPNMMOUSE) lParam)

	wsprintf (szTemp,
			  "dwItemSpec = %X, "
			  "dwItemData = %X, "
			  "pt = %s, "
			  "dwHitInfo = %X",
			  lpnm->dwItemSpec,
			  lpnm->dwItemData,
			  Format_POINT (lpnm->pt, szPOINT),
			  lpnm->dwHitInfo);
	OutputDebugString (FormatStr (szTemp));
#undef	lpnm
} // End Display_NM_MOUSE ()


//************************************************************************
//	Display_NM_RCLICK ()
//
//	Display NM_RCLICK structure
//************************************************************************

void Display_NM_RCLICK (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	switch (clstr[LookupClass (((LPNMHDR) lParam)->hwndFrom)].eClass)
	{
		case EC_LISTVIEW:
			// Handle ListView as NMITEMACTIVATE
			Display_NM_ITEMACTIVATE (hWnd, wParam, lParam);
			break;

		case EC_STATUS:
			// Handle StatusBar as NMMOUSE
			Display_NM_MOUSE (hWnd, wParam, lParam);
			break;

		case EC_TOOLBAR:
			// Handle ToolBar as NMMOUSE
			Display_NM_MOUSE (hWnd, wParam, lParam);
			break;

		default:
			// Ignore others
			break;
	} // End SWITCH 
} // End Display_NM_RCLICK ()


//************************************************************************
//	Display_NM_RDBLCLK ()
//
//	Display NM_RDBLCLK structure
//************************************************************************

void Display_NM_RDBLCLK (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	switch (clstr[LookupClass (((LPNMHDR) lParam)->hwndFrom)].eClass)
	{
		case EC_LISTVIEW:
			// Handle ListView as NMITEMACTIVATE
			Display_NM_ITEMACTIVATE (hWnd, wParam, lParam);
			break;
	
		case EC_STATUS:
			// Handle StatusBar as NMMOUSE
			Display_NM_MOUSE (hWnd, wParam, lParam);
			break;

		default:
			// Ignore others
			break;
	} // End SWITCH
} // End Display_NM_RDBLCLK ()


//************************************************************************
//	Display_NM_TOOLTIPSCREATED ()
//
//	Display NM_TOOLTIPSCREATED structure
//************************************************************************

void Display_NM_TOOLTIPSCREATED (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NM_TOOLTIPSCREATED ()


//************************************************************************
//	Display_NM_TREEVIEW ()
//
//	Display NM_TREEVIEW structure
//************************************************************************

void Display_NM_TREEVIEW (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	char szTemp[1024], szPOINT[256];
#define lpnm		((LPNMTREEVIEW) lParam)

	wsprintf (szTemp,
			  "action = %X, "
			  "itemOld = %X, "
			  "itemNew = %X, "
			  "ptDrag = %s",
			  lpnm->action,
			  &lpnm->itemOld,
			  &lpnm->itemNew,
			  Format_POINT (lpnm->ptDrag, szPOINT));
	OutputDebugString (FormatStr (szTemp));

	// Display the TVITEM structures
	Display_TVITEM (&lpnm->itemOld);
	Display_TVITEM (&lpnm->itemNew);

#undef	lpnm
} // End Display_NM_TREEVIEW ()


//************************************************************************
//	Display_NMHD_DISPINFO ()
//
//	Display NMHD_DISPINFO structure
//************************************************************************

void Display_NMHD_DISPINFO (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NMHD_DISPINFO ()


//************************************************************************
//	Display_NMHD_FILTERBTNCLICK ()
//
//	Display NMHD_FILTERBTNCLICK structure
//************************************************************************

void Display_NMHD_FILTERBTNCLICK (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NMHD_FILTERBTNCLICK ()


//************************************************************************
//	Display_NMLV_CACHEHINT ()
//
//	Display NMLV_CACHEHINT structure
//************************************************************************

void Display_NMLV_CACHEHINT (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NMLV_CACHEHINT ()


//************************************************************************
//	Display_NMLV_GETINFOTIP ()
//
//	Display NMLV_GETINFOTIP structure
//************************************************************************

void Display_NMLV_GETINFOTIP (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NMLV_GETINFOTIP ()


//************************************************************************
//	Display_NMLV_ODSTATECHANGED ()
//
//	Display NMLV_ODSTATECHANGED structure
//************************************************************************

void Display_NMLV_ODSTATECHANGED (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NMLV_ODSTATECHANGED ()


//************************************************************************
//	Display_NMTV_DISPINFO ()
//
//	Display NMTV_DISPINFO structure
//************************************************************************

void Display_NMTV_DISPINFO (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NMTV_DISPINFO ()


//************************************************************************
//	Display_NMTV_GETINFOTIP ()
//
//	Display NMTV_GETINFOTIP structure
//************************************************************************

void Display_NMTV_GETINFOTIP (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NMTV_GETINFOTIP ()


//************************************************************************
//	Display_NMTV_KEYDOWN ()
//
//	Display NMTV_KEYDOWN structure
//************************************************************************

void Display_NMTV_KEYDOWN (HWND hWnd, WPARAM wParam, LPARAM lParam)

{
	// *FIXME*
} // End Display_NMTV_KEYDOWN ()


//************************************************************************
//	Display_TVITEM ()
//
//	Display TVITEM structure
//************************************************************************

void Display_TVITEM (LPTVITEM lptvi)

{
	// *FIXME*
} // End Display_TVITEM ()


//************************************************************************
//	Display_WINDOWPOS ()
//
//	Display the WINDOWPOS data structure.
//************************************************************************

void Display_WINDOWPOS (LPWINDOWPOS lpwp)

{
	char szTemp[256], szFlags[256];

	wsprintf (szTemp,
			  "hwnd = %X, "
			  "hwndInsertAfter = %X, "
			  "x = %X, "
			  "y = %X, "
			  "cx = %X, "
			  "cy = %X, "
			  "flags = %s",
			  lpwp->hwnd,
			  lpwp->hwndInsertAfter,
			  lpwp->x,
			  lpwp->y,
			  lpwp->cx,
			  lpwp->cy,
			  FormatFlags (lpwp->flags, Flags_SWP, nFlags_SWP, szFlags));
	OutputDebugString (FormatStr (szTemp));
} // End Display_WINDOWPOS ()


#define Display_HDN_BEGINDRAG			Display_NM_HEADER
#define Display_HDN_BEGINTRACKA 		Display_NM_HEADER
#define Display_HDN_BEGINTRACKW 		Display_NM_HEADER
#define Display_HDN_DIVIDERDBLCLICKA	Display_NM_HEADER
#define Display_HDN_DIVIDERDBLCLICKW	Display_NM_HEADER
#define Display_HDN_ENDDRAG 			Display_NM_HEADER
#define Display_HDN_ENDTRACKA			Display_NM_HEADER
#define Display_HDN_ENDTRACKW			Display_NM_HEADER
#define Display_HDN_FILTERBTNCLICK		Display_NMHD_FILTERBTNCLICK
#define Display_HDN_FILTERCHANGE		Display_NM_HEADER
#define Display_HDN_GETDISPINFOA		Display_NMHD_DISPINFO
#define Display_HDN_GETDISPINFOW		Display_NMHD_DISPINFO
#define Display_HDN_ITEMCHANGEDA		Display_NM_HEADER
#define Display_HDN_ITEMCHANGEDW		Display_NM_HEADER
#define Display_HDN_ITEMCHANGINGA		Display_NM_HEADER
#define Display_HDN_ITEMCHANGINGW		Display_NM_HEADER
#define Display_HDN_ITEMCLICKA			Display_NM_HEADER
#define Display_HDN_ITEMCLICKW			Display_NM_HEADER
#define Display_HDN_ITEMDBLCLICKA		Display_NM_HEADER
#define Display_HDN_ITEMDBLCLICKW		Display_NM_HEADER
#define Display_HDN_TRACKA				Display_NM_HEADER
#define Display_HDN_TRACKW				Display_NM_HEADER


#define Display_LVN_BEGINDRAG			Display_NM_LISTVIEW
#define Display_LVN_BEGINLABELEDITA 	Display_LV_DISPINFO
#define Display_LVN_BEGINLABELEDITW 	Display_LV_DISPINFO
#define Display_LVN_BEGINRDRAG			Display_NM_LISTVIEW
#define Display_LVN_COLUMNCLICK 		Display_NM_LISTVIEW
#define Display_LVN_DELETEALLITEMS		Display_NM_LISTVIEW
#define Display_LVN_DELETEITEM			Display_NM_LISTVIEW
#define Display_LVN_ENDLABELEDITA		Display_LV_DISPINFO
#define Display_LVN_ENDLABELEDITW		Display_LV_DISPINFO
#define Display_LVN_GETDISPINFOA		Display_LV_DISPINFO
#define Display_LVN_GETDISPINFOW		Display_LV_DISPINFO
#define Display_LVN_GETINFOTIPA 		Display_NMLV_GETINFOTIP
#define Display_LVN_GETINFOTIPW 		Display_NMLV_GETINFOTIP
#define Display_LVN_HOTTRACK			Display_NM_LISTVIEW
#define Display_LVN_INSERTITEM			Display_NM_LISTVIEW
#define Display_LVN_ITEMACTIVATE		Display_NM_ITEMACTIVATE
#define Display_LVN_ITEMCHANGED 		Display_NM_LISTVIEW
#define Display_LVN_ITEMCHANGING		Display_NM_LISTVIEW
#define Display_LVN_KEYDOWN 			Display_LV_KEYDOWN
#define Display_LVN_MARQUEEBEGIN		NULL
#define Display_LVN_ODCACHEHINT 		Display_NMLV_CACHEHINT
#define Display_LVN_ODFINDITEMA 		Display_LV_FINDINFO
#define Display_LVN_ODFINDITEMW 		Display_LV_FINDINFO
#define Display_LVN_ODSTATECHANGED		Display_NMLV_ODSTATECHANGED
#define Display_LVN_SETDISPINFOA		Display_LV_DISPINFO
#define Display_LVN_SETDISPINFOW		Display_LV_DISPINFO


#define Display_NM_CHAR 				Display_NM_CHAR
//efine Display_NM_CLICK				Display_NM_CLICK
#define Display_NM_CUSTOMDRAW			Display_NM_CUSTOMDRAW
#define Display_NM_DBLCLK				Display_NM_CLICK
#define Display_NM_HOVER				NULL
#define Display_NM_KEYDOWN				Display_NM_KEY
#define Display_NM_KILLFOCUS			NULL
#define Display_NM_LDOWN				NULL
#define Display_NM_NCHITTEST			Display_NM_MOUSE
#define Display_NM_OUTOFMEMORY			NULL
//efine Display_NM_RCLICK				Display_NM_RCLICK
//efine Display_NM_RDBLCLK				Display_NM_RDBLCLK
#define Display_NM_RDOWN				NULL
#define Display_NM_RELEASEDCAPTURE		NULL
#define Display_NM_RETURN				NULL
#define Display_NM_SETCURSOR			Display_NM_MOUSE
#define Display_NM_SETFOCUS 			NULL
#define Display_NM_TOOLTIPSCREATED		Display_NM_TOOLTIPSCREATED


#define Display_TVN_BEGINDRAGA			Display_NM_TREEVIEW
#define Display_TVN_BEGINDRAGW			Display_NM_TREEVIEW
#define Display_TVN_BEGINLABELEDITA 	Display_NMTV_DISPINFO
#define Display_TVN_BEGINLABELEDITW 	Display_NMTV_DISPINFO
#define Display_TVN_BEGINRDRAGA 		Display_NM_TREEVIEW
#define Display_TVN_BEGINRDRAGW 		Display_NM_TREEVIEW
#define Display_TVN_DELETEITEMA 		Display_NM_TREEVIEW
#define Display_TVN_DELETEITEMW 		Display_NM_TREEVIEW
#define Display_TVN_ENDLABELEDITA		Display_NMTV_DISPINFO
#define Display_TVN_ENDLABELEDITW		Display_NMTV_DISPINFO
#define Display_TVN_GETDISPINFOA		Display_NMTV_DISPINFO
#define Display_TVN_GETDISPINFOW		Display_NMTV_DISPINFO
#define Display_TVN_GETINFOTIPA 		Display_NMTV_GETINFOTIP
#define Display_TVN_GETINFOTIPW 		Display_NMTV_GETINFOTIP
#define Display_TVN_ITEMEXPANDEDA		Display_NM_TREEVIEW
#define Display_TVN_ITEMEXPANDEDW		Display_NM_TREEVIEW
#define Display_TVN_ITEMEXPANDINGA		Display_NM_TREEVIEW
#define Display_TVN_ITEMEXPANDINGW		Display_NM_TREEVIEW
#define Display_TVN_KEYDOWN 			Display_NMTV_KEYDOWN
#define Display_TVN_SELCHANGEDA 		Display_NM_TREEVIEW
#define Display_TVN_SELCHANGEDW 		Display_NM_TREEVIEW
#define Display_TVN_SELCHANGINGA		Display_NM_TREEVIEW
#define Display_TVN_SELCHANGINGW		Display_NM_TREEVIEW
#define Display_TVN_SETDISPINFOA		Display_NMTV_DISPINFO
#define Display_TVN_SETDISPINFOW		Display_NMTV_DISPINFO
#define Display_TVN_SINGLEEXPAND		Display_NM_TREEVIEW


//************************************************************************
//	ODSAPI ()
//
//	Output Debug String cover function for WINAPI calls
//************************************************************************

void FAR ODSAPI (LPSTR	lpStr,
				 HWND	hWnd,
				 UINT	message,
				 WPARAM wParam,
				 LPARAM lParam)

{
	char szTemp[256];
	void (*Display) (HWND, WPARAM, LPARAM) = NULL;

	if (Debug)
	{
		wsprintf (szTemp,
#ifdef _WIN32
				  "%4u:  %s %04X, %s, wParam = %08X, lParam = %08lX\r\n",
#else
				  "%4u:  %s %04X, %s, wParam = %04X, lParam = %08lX\r\n",
#endif
				  APICount++,
				  lpStr,
				  (WORD) hWnd,
				  APIMsg (hWnd, message, wParam, lParam),
				  wParam,
				  lParam);
		OutputDebugString (szTemp);

		// Handle special cases
		switch (message)
		{
			case WM_COMMAND:
				switch (clstr[LookupClass (GET_WM_COMMAND_HWND (wParam, lParam))].eClass)
				{
					case EC_BUTTON:
						Display = Display_Button;
						break;

					case EC_COMBOBOX:
						Display = Display_ComboBox;
						break;

					case EC_EDITBOX:
						Display = Display_EditBox;
						break;

					case EC_LISTBOX:
						Display = Display_ListBox;
						break;

					case EC_SCROLLBAR:
						Display = Display_ScrollBar;
						break;

					case EC_STATIC:
						Display = Display_Static;
						break;

				} // End SWITCH

				break;

			case WM_DRAWITEM:
#define lpdis	((LPDRAWITEMSTRUCT) lParam)
				Display_DRAWITEMSTRUCT (lpdis);

				break;
#undef	lpdis

#ifdef _WIN32
			case WM_NOTIFY:
			{
#define lpnmh	((LPNMHDR) lParam)

				wsprintf (szTemp,
						  INDENT "hwndFrom = %04X%s, idFrom = %X, code = ",
						  lpnmh->hwndFrom,
						  FormatClassName (lpnmh->hwndFrom),
						  lpnmh->idFrom);

#define CBEN(a) case CBEN_##a:					 \
					lstrcat (szTemp, "CBEN_" #a);\
					break;

#define CDN(a)	case CDN_##a:					 \
					lstrcat (szTemp, "CDN_" #a); \
					break;
	
#define DTN(a)	case DTN_##a:					 \
					lstrcat (szTemp, "DTN_" #a); \
					break;

#define HDN(a)	case HDN_##a:					 \
					lstrcat (szTemp, "HDN_" #a); \
					Display = Display_HDN_##a;	 \
					break;

#define IPN(a) case IPN_##a:					 \
					lstrcat (szTemp, "IPN_" #a); \
					break;

#define LVN(a)	case LVN_##a:					 \
					lstrcat (szTemp, "LVN_" #a); \
					Display = Display_LVN_##a;	 \
					break;

#define MCN(a)	case MCN_##a:					 \
					lstrcat (szTemp, "MCN_" #a); \
					break;

#define NM(a)	case NM_##a:					 \
					lstrcat (szTemp, "NM_" #a);  \
					Display = Display_NM_##a;	 \
					break;

#define PGN(a) case PGN_##a:					 \
					lstrcat (szTemp, "PGN_" #a); \
					break;

#define RBN(a) case RBN_##a:					 \
					lstrcat (szTemp, "RBN_" #a); \
					break;

#define SBN(a) case SBN_##a:					 \
					lstrcat (szTemp, "SBN_" #a); \
					break;

#define TBN(a)	case TBN_##a:					 \
					lstrcat (szTemp, "TBN_" #a); \
					break;

#define TCN(a)	case TCN_##a:					 \
					lstrcat (szTemp, "TCN_" #a); \
					break;
	
#define TTN(a)	case TTN_##a:					 \
					lstrcat (szTemp, "TTN_" #a); \
					break;
	
#define TVN(a)	case TVN_##a:					 \
					lstrcat (szTemp, "TVN_" #a); \
					Display = Display_TVN_##a;	 \
					break;
	
#define UDN(a)	case UDN_##a:					 \
					lstrcat (szTemp, "UDN_" #a); \
					break;

				switch (lpnmh->code)
				{
///////////////////////////////////////////////////
					CBEN(GETDISPINFOA)		// -800 		CBEN_FIRST
					CBEN(INSERTITEM)		// -801
					CBEN(DELETEITEM)		// -802
											// -803
					CBEN(BEGINEDIT) 		// -804
					CBEN(ENDEDITA)			// -805
					CBEN(ENDEDITW)			// -806
					CBEN(GETDISPINFOW)		// -807
					CBEN(DRAGBEGINA)		// -808
					CBEN(DRAGBEGINW)		// -809
											// -810-830 	CBEN_LAST
///////////////////////////////////////////////////
/////////////////// CDN ()					// -601-699 	CDN_FIRST/CDN_LAST
///////////////////////////////////////////////////
											// -760 		DTN_FIRST
											// -799 		DTN_LAST
					DTN (FORMATQUERYW)		// -732 (not within DTN_FIRST to DTN_LAST)
					DTN (FORMATW)			// -733  ...
					DTN (WMKEYDOWNW)		// -734  ...
					DTN (USERSTRINGW)		// -735  ...
											// -736-752
					DTN (CLOSEUP)			// -753  ...
					DTN (DROPDOWN)			// -754  ...
					DTN (FORMATQUERYA)		// -755  ...
					DTN (FORMATA)			// -756  ...
					DTN (WMKEYDOWNA)		// -757  ...
					DTN (USERSTRINGA)		// -758  ...
					DTN (DATETIMECHANGE)	// -759  ...
///////////////////////////////////////////////////
					HDN (ITEMCHANGINGA) 	// -300 		HDN_FIRST
					HDN (ITEMCHANGEDA)		// -301
					HDN (ITEMCLICKA)		// -302
					HDN (ITEMDBLCLICKA) 	// -303
											// -304
					HDN (DIVIDERDBLCLICKA)	// -305
					HDN (BEGINTRACKA)		// -306
					HDN (ENDTRACKA) 		// -307
					HDN (TRACKA)			// -308
					HDN (GETDISPINFOA)		// -309
					HDN (BEGINDRAG) 		// -310
					HDN (ENDDRAG)			// -311
					HDN (FILTERCHANGE)		// -312
					HDN (FILTERBTNCLICK)	// -313
											// -314-319
					HDN (ITEMCHANGINGW) 	// -320
					HDN (ITEMCHANGEDW)		// -321
					HDN (ITEMCLICKW)		// -322
					HDN (ITEMDBLCLICKW) 	// -323
											// -324
					HDN (DIVIDERDBLCLICKW)	// -325
					HDN (BEGINTRACKW)		// -326
					HDN (ENDTRACKW) 		// -327
					HDN (TRACKW)			// -328
					HDN (GETDISPINFOW)		// -329
											// -330-399 	HDN_LAST
///////////////////////////////////////////////////
					IPN (FIELDCHANGED)		// -860 		IPN_FIRST
											// -861-879 	IPN_LAST
///////////////////////////////////////////////////
					LVN (ITEMCHANGING)		// -100 		LVN_FIRST
					LVN (ITEMCHANGED)		// -101
					LVN (INSERTITEM)		// -102
					LVN (DELETEITEM)		// -103
					LVN (DELETEALLITEMS)	// -104
					LVN (BEGINLABELEDITA)	// -105
					LVN (ENDLABELEDITA) 	// -106
					LVN (COLUMNCLICK)		// -108
					LVN (BEGINDRAG) 		// -109
											// -110
					LVN (BEGINRDRAG)		// -111
											// -112
					LVN (ODCACHEHINT)		// -113
					LVN (ITEMACTIVATE)		// -114
					LVN (ODSTATECHANGED)	// -115
					LVN (HOTTRACK)			// -115
											// -116-149
					LVN (GETDISPINFOA)		// -150
					LVN (SETDISPINFOA)		// -151
					LVN (ODFINDITEMA)		// -152
											// -153-154
					LVN (KEYDOWN)			// -155
					LVN (MARQUEEBEGIN)		// -156
					LVN (GETINFOTIPA)		// -157
					LVN (GETINFOTIPW)		// -158
											// -159-174
					LVN (BEGINLABELEDITW)	// -175
					LVN (ENDLABELEDITW) 	// -176
					LVN (GETDISPINFOW)		// -177
					LVN (SETDISPINFOW)		// -178
					LVN (ODFINDITEMW)		// -179
											// -180-199 	LVN_LAST
///////////////////////////////////////////////////
											// -750 		MCN_FIRST
											// -759 		MCN_LAST
					MCN (SELECT)			// -746 (not within MCN_FIRST to MCN_LAST)
					MCN (GETDAYSTATE)		// -747  ...
					MCN (SELCHANGE) 		// -749  ...
///////////////////////////////////////////////////
											// -0			NM_FIRST
					NM	(OUTOFMEMORY)		// -1
					NM	(CLICK) 			// -2
					NM	(DBLCLK)			// -3
					NM	(RETURN)			// -4
					NM	(RCLICK)			// -5
					NM	(RDBLCLK)			// -6
					NM	(SETFOCUS)			// -7
					NM	(KILLFOCUS) 		// -8
											// -9-11
					NM	(CUSTOMDRAW)		// -12
					NM	(HOVER) 			// -13
					NM	(NCHITTEST) 		// -14
					NM	(KEYDOWN)			// -15
					NM	(RELEASEDCAPTURE)	// -16
					NM	(SETCURSOR) 		// -17
					NM	(CHAR)				// -18
					NM	(TOOLTIPSCREATED)	// -19
					NM	(LDOWN) 			// -20
					NM	(RDOWN) 			// -21
											// -22-99		NM_LAST
///////////////////////////////////////////////////
											// -900 		PGN_FIRST
					PGN (SCROLL)			// -901
					PGN (CALCSIZE)			// -902
											// -950 		PGN_LAST
///////////////////////////////////////////////////
					RBN (HEIGHTCHANGE)		// -831 		RBN_FIRST
					RBN (GETOBJECT) 		// -832
					RBN (LAYOUTCHANGED) 	// -833
					RBN (AUTOSIZE)			// -834
					RBN (BEGINDRAG) 		// -835
					RBN (ENDDRAG)			// -836
					RBN (DELETINGBAND)		// -837
					RBN (DELETEDBAND)		// -838
					RBN (CHILDSIZE) 		// -839
											// -840
					RBN (CHEVRONPUSHED) 	// -841
											// -842-851
					RBN (MINMAX)			// -852
											// -853-859 	RBN_LAST
///////////////////////////////////////////////////
					SBN (SIMPLEMODECHANGE)	// -880 		SBN_FIRST
											// -881-899 	SBN_LAST
///////////////////////////////////////////////////
					TBN (GETBUTTONINFOA)	// -700 		TBN_FIRST
					TBN (BEGINDRAG) 		// -701
					TBN (ENDDRAG)			// -702
					TBN (BEGINADJUST)		// -703
					TBN (ENDADJUST) 		// -704
					TBN (RESET) 			// -705
					TBN (QUERYINSERT)		// -706
					TBN (QUERYDELETE)		// -707
					TBN (TOOLBARCHANGE) 	// -708
					TBN (CUSTHELP)			// -709
					TBN (DROPDOWN)			// -710
					TBN (GETOBJECT) 		// -711
											// -712
					TBN (HOTITEMCHANGE) 	// -713
					TBN (DRAGOUT)			// -714
					TBN (DELETINGBUTTON)	// -715
					TBN (GETDISPINFOA)		// -716
					TBN (GETDISPINFOW)		// -717
					TBN (GETINFOTIPA)		// -718
					TBN (GETINFOTIPW)		// -719
					TBN (GETBUTTONINFOW)	// -720 		TBN_LAST
					TBN (RESTORE)			// -721 (not within TBN_FIRST to TBN_LAST)
					TBN (SAVE)				// -722 (Duplicates UDN_DELTAPOS)
					TBN (INITCUSTOMIZE) 	// -723 (not within TBN_FIRST to TBN_LAST)
///////////////////////////////////////////////////
					TCN (KEYDOWN)			// -550 		TCN_FIRST
					TCN (SELCHANGE) 		// -551
					TCN (SELCHANGING)		// -552
					TCN (GETOBJECT) 		// -553
					TCN (FOCUSCHANGE)		// -554
											// -555-580 	TCN_LAST
///////////////////////////////////////////////////
					TTN (GETDISPINFOA)		// -520 		TTN_FIRST
					TTN (SHOW)				// -521
					TTN (POP)				// -522
											// -523-529
					TTN (GETDISPINFOW)		// -530
											// -531-549 	TTN_LAST
///////////////////////////////////////////////////
											// -400 		TVN_FIRST
					TVN (SELCHANGINGA)		// -401
					TVN (SELCHANGEDA)		// -402
					TVN (GETDISPINFOA)		// -403
					TVN (SETDISPINFOA)		// -404
					TVN (ITEMEXPANDINGA)	// -405
					TVN (ITEMEXPANDEDA) 	// -406
					TVN (BEGINDRAGA)		// -407
					TVN (BEGINRDRAGA)		// -408
					TVN (DELETEITEMA)		// -409
					TVN (BEGINLABELEDITA)	// -410
					TVN (ENDLABELEDITA) 	// -411
					TVN (KEYDOWN)			// -412
					TVN (GETINFOTIPA)		// -413
					TVN (GETINFOTIPW)		// -414
					TVN (SINGLEEXPAND)		// -415
											// -416-449
					TVN (SELCHANGINGW)		// -450
					TVN (SELCHANGEDW)		// -451
					TVN (GETDISPINFOW)		// -452
					TVN (SETDISPINFOW)		// -453
					TVN (ITEMEXPANDINGW)	// -454
					TVN (ITEMEXPANDEDW) 	// -455
					TVN (BEGINDRAGW)		// -456
					TVN (BEGINRDRAGW)		// -457
					TVN (DELETEITEMW)		// -458
					TVN (BEGINLABELEDITW)	// -459
					TVN (ENDLABELEDITW) 	// -460
											// -461-499 	TVN_LAST
///////////////////////////////////////////////////
											// -721 		UDN_FIRST
////////////////////UDN (DELTAPOS)			// -722 (Duplicates TBN_SAVE)
											// -723-740 	UDN_LAST
///////////////////////////////////////////////////
////////////////////WMN ()					// -1000		WMN_FIRST
											// -1200		WMN_LAST

					default:
						wsprintf (&szTemp[lstrlen (szTemp)],
								  "%08lX",
								  lpnmh->code);
						break;

				} // End SWITCH

				lstrcat (szTemp, "\r\n");
				OutputDebugString (szTemp);
				break;
#undef	lpnmh
			} // End WM_NOTIFY
#endif
			case WM_SETTEXT:				// 0 = wParam
											// lpsz = (LPSTR) lParam
				DisplayText ((LPSTR) lParam);

				break;

			case WM_WINDOWPOSCHANGED:		// 0 = wParam
											// lpwp = (LPWINDOWPOS) lParam
			case WM_WINDOWPOSCHANGING:		// 0 = wParam
											// lpwp = (LPWINDOWPOS) lParam
#define lpwp	((LPWINDOWPOS) lParam)
				Display_WINDOWPOS (lpwp);

				break;
#undef	lpwp

		} // End SWITCH(message)

		if (Display)			// If there's a special display routine, ...
			(*Display) (hWnd, wParam, lParam);// Call it
	} // End IF

} // End ODSAPI ()
#endif		  


//***************************************************************************
//	End of File: WINAPI.C
//***************************************************************************
