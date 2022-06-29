     echo off
     cls
     if %1.==. goto help

     if not exist OLDMAX.%1\*.* goto nofiles

     echo Y > rmoldmax.rsp
     erase OLDMAX.%1 < rmoldmax.rsp
     del rmoldmax.rsp

    :nofiles
     rmdir OLDMAX.%1 > nul
     cls
echo   зддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
echo   Ё    Directory OLDMAX.%1 has been removed.                         Ё
echo   юддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
     goto done

    :help
echo   зддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
echo   Ё                        RMOLDMAX.BAT                             Ё
echo   Ё                                                                 Ё
echo   Ё    This batch file will first erase all files in a selected     Ё
echo   Ё    directory containing backup files from your 386MAX or        Ё
echo   Ё    BLUEMAX installation, and then remove the directory.         Ё
echo   Ё                                                                 Ё
echo   Ё    The backup directories are named OLDMAX.n, with the          Ё
echo   Ё    latest backup directory being the one with largest number.   Ё
echo   Ё                                                                 Ё
echo   Ё    A directory of OLDMAX directories follows.  When you have    Ё
echo   Ё    selected a backup directory to remove, type:                 Ё
echo   Ё                                                                 Ё
echo   Ё    RMOLDMAX n                                                   Ё
echo   Ё                                                                 Ё
echo   Ё    Press any key to see the list of OLDMAX directories...       Ё
echo   юддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды

     pause > nul
     cls
echo   зддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
echo   Ё    OLDMAX backup directories:                                   Ё
echo   юддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
     dir OLDMAX.* /p
echo   зддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
echo   Ё    Type RMOLDMAX n to remove OLDMAX directory number n.         Ё
echo   юддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды

:done

