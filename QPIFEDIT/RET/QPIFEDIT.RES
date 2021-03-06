�
 �w 0�   Begin a new DOS session using the current Qualitas PIF editor settings.

Users do not need to save the Program Information File (PIF) before starting the DOS session to use current PIF settings.  This is useful for testing a new PIF. �
 �f 0X   Specify program filename, window title, start-up directory and any optional parameters. �
 �� 0�  Enter the name of the executable program or batch file with which this Program Information File (PIF) is to be associated.  The program name must have one of the following extensions: .BAT, .COM, or .EXE.

You may include the path indicating the location of the program (i.e.'C:\APPS\WP.EXE').  If you do not include the path in this field, and if the program file is not in the DOS path, you must specify the location of the file in the Start-up Directory.

If you wish to set up a PIF to start a DOS session without running a particular application, enter 'COMMAND.COM' in this field.

When adding a new program to Program Manager, you may specify the name of a PIF. �
 �� 05  Enter the text you would like to appear in the title bar when the DOS session is run in a windowed state.  This text is also used as the icon caption when the DOS session is minimized.

Any text entered in the Description field in Program Manager's Properties dialog box will override the PIF Window Title. �
 �� 0�  Enter any command line options for the program you are running.

For example, to create a PIF that runs the DOS editor with AUTOEXEC.BAT as the file to edit, enter EDIT.COM as the Program File Name and C:\AUTOEXEC.BAT as the Optional Parameter.

If you would like windows to prompt you for Optional Parameters each time the PIF is invoked then enter a question mark in this field. �
 �� 0}  Enter the complete directory path indicating from where you would like Windows to start the application.

Many applications use this directory as the default for File Open and File Save commands.

If you do not include the path as part of the Program Filename and if the program file is not in the DOS path, you must specify the location of the file as the Start-up Directory. �
 �g 0Y   Specify how much and what type(s) of memory should be made available in the DOS session. �
 �-0r  IMPORTANT!  Read this entire help screen to prevent accidental loss of work in memory.

This option enables Qualitas's DOSMAX feature.  DOSMAX provides text mode applications with as much as 736K conventional memory.

'Use Default' indicates that DOSMAX support is determined by the 'DOSMAXDefault=' switch in the [QUALITAS] section of SYSTEM.INI.  You may set this switch to 'ON' or 'OFF'. 'ON' enables DOSMAX support regardless of the SYSTEM.INI switch setting. 'OFF' disables DOSMAX support regardless of the SYSTEM.INI switch setting.

Keep in mind that many applications switch between graphics and text modes which can cause unpredictable results (including the loss of data in memory or a DOS session crash).  For example, WordPerfect DOS version is primarily a text mode application although it does switch into graphics mode for certain features (i.e. Page Preview). �
 �.0r  IMPORTANT!  Read this entire help screen to prevent accidental loss of work in memory.

This option enables Qualitas's DOSMAX feature.  DOSMAX provides text mode applications with as much as 736K conventional memory.

'Use Default' indicates that DOSMAX support is determined by the 'DOSMAXDefault=' switch in the [QUALITAS] section of SYSTEM.INI.  You may set this switch to 'ON' or 'OFF'. 'ON' enables DOSMAX support regardless of the SYSTEM.INI switch setting. 'OFF' disables DOSMAX support regardless of the SYSTEM.INI switch setting.

Keep in mind that many applications switch between graphics and text modes which can cause unpredictable results (including the loss of data in memory or a DOS session crash).  For example, WordPerfect DOS version is primarily a text mode application although it does switch into graphics mode for certain features (i.e. Page Preview). �
 �/0r  IMPORTANT!  Read this entire help screen to prevent accidental loss of work in memory.

This option enables Qualitas's DOSMAX feature.  DOSMAX provides text mode applications with as much as 736K conventional memory.

'Use Default' indicates that DOSMAX support is determined by the 'DOSMAXDefault=' switch in the [QUALITAS] section of SYSTEM.INI.  You may set this switch to 'ON' or 'OFF'. 'ON' enables DOSMAX support regardless of the SYSTEM.INI switch setting. 'OFF' disables DOSMAX support regardless of the SYSTEM.INI switch setting.

Keep in mind that many applications switch between graphics and text modes which can cause unpredictable results (including the loss of data in memory or a DOS session crash).  For example, WordPerfect DOS version is primarily a text mode application although it does switch into graphics mode for certain features (i.e. Page Preview). �
 �30�   Specifies the minimum amount of conventional memory required to start the DOS window.  If the indicated amount is not available, Windows will fail to start the DOS session.

Use -1 to direct Windows to use as much memory as is available. �
 �50�   Specifies the amount of conventional memory to be provided if available.  If the indicated amount is not available, Windows will allocate as much as possible.

Use -1 to direct Windows to use as much memory as is available. �
 �@0�  Windows provides 'memory' by swapping inactive applications (both Windows and DOS) to disk. Locking DOS memory prevents Windows from swapping conventional memory used for the DOS session.  While this can improve performance within the DOS session, it will tend to decrease performance of the rest of Windows because it reduces the shared memory within Windows. Locking memory will also limit the number of applications (both Windows and DOS) which can be run at the same time.

It is appropriate to lock memory when the application is performance sensitive (as with many communications programs) and swapping to disk will create unacceptable delays. �
 �80�   Specifies the minimum amount of Expanded (EMS) memory required to start the DOS window.  If the indicated amount is not available, Windows will fail to start the DOS session.

Use -1 to direct Windows to use as much memory as is available. �
 �:0�   Specifies the amount of Expanded (EMS) memory desired if available.  If the indicated amount is not available, Windows will allocate as much as possible.

Use -1 to direct Windows to use as much memory as is available. �
 �A0�  Windows provides 'memory' by swapping inactive applications (both Windows and DOS) to disk. Locking EMS memory prevents Windows from swapping expanded memory used for the DOS session.  While this can improve performance within the DOS session, it will tend to decrease performance of the rest of Windows because it decreases the shared memory within Windows.  Locking memory will also limit the number of applications (both Windows and DOS) which can be run at the same time.

It is appropriate to lock memory when the application is performance sensitive (as with many communications programs) and swapping to disk will create unacceptable delays. �
 �=0�   Specifies the minimum amount of eXtended (XMS) memory required to start the DOS window.  If the indicated amount is not available, Windows will fail to start the DOS session.

Use -1 to direct Windows to use as much memory as is available. �
 �?0�   Specifies the amount of eXtended (XMS) memory desired if available.  If the indicated amount is not available, Windows will allocate as much as possible.

Use -1 to direct Windows to use as much memory as is available. �
 �B0�  Windows provides 'memory' by swapping inactive applications (both Windows and DOS) to disk. Locking XMS memory prevents Windows from swapping extended memory used for the DOS session.  While this can improve performance within the DOS session, it will tend to decrease performance of the rest of Windows because it decreases the shared memory within Windows.  Locking memory will also limit the number of applications (both Windows and DOS) which can be run at the same time.

It is appropriate to lock memory when the application is performance sensitive (as with many communications programs) and swapping to disk will create unacceptable delays. �
 �C0�  The High Memory Area (HMA) is a 64K region which starts at the very end of all DOS memory.  If you intend to use software within a DOS session that will use the HMA then you should select this option.

If you use DOS version 5.0 or later and enable DOS = HIGH in your CONFIG.SYS then the HMA is already in use and may not be used by other software.  In this case, do not select this option. �
 �h 0_   Specify information on display usage, video memory and other video related information topics. �
 ��0.  Select this option to start your DOS session in full screen mode.  Full screen mode has the following advantages over windowed mode:

     -  requires less memory
     -  applications run faster

Once a DOS session is running, ALT-ENTER toggles the session between windowed and full screen modes. �
 ��0�  Select this option to start your DOS session in windowed mode.  Windowed mode has the following advantages over full screen mode:

     -  users may cut and paste to and from the screen
        by pressing ALT-SPACE and E.
     -  users may change the display font by pressing
        ALT-SPACE and then F.

Once a DOS session is running, ALT-ENTER toggles the session between windowed and full screen modes. �
 ��0G  When Windows starts a DOS session, it allocates memory in which to store the information displayed in that DOS session.  Graphics programs require more memory than do text programs.  Some graphics programs (i.e. EGA and VGA) are referred to as 'high resolution' and require more memory than other 'low resolution' programs (i.e. CGA).

Select 'Text' to instruct Windows to allocate only enough video memory in which to store a text display.  If you attempt to run a graphics program in a session with this setting then Windows may display an error and fail to open the DOS window. �
 ��0�  When Windows starts a DOS session, it allocates memory in which to store the information displayed in that DOS session.  Graphics programs require more memory than do text programs.  Some graphics programs (i.e. EGA and VGA) are referred to as 'high resolution' and require more memory than other 'low resolution'programs (i.e. CGA).

Select 'Low Graphics' to instruct Windows to allocate only enough video memory in which to store a low resolution graphics display.  If you attempt to run a high resolution graphics program in a session with this setting then Windows may display an error and fail to open the DOS window.  If you intend to run only text applications in DOS sessions started with this PIF then selecting 'Low Graphics' may waste memory. �
 ��0  When Windows starts a DOS session, it allocates memory in which to store the information displayed in that DOS session.  Graphics programs require more memory than do text programs.  Some graphics programs (i.e. EGA and VGA) are referred to as 'high resolution' and require more memory than other 'low resolution'programs (i.e. CGA).

Select 'High Graphics' to instruct Windows to allocate enough video memory in which to store a high resolution graphics display.  If you attempt to run a high resolution graphics program in a session with this setting then Windows may display an error and fail to open the DOS window.  If you intend to run only text or low resolution graphics applications in DOS sessions started with this PIF then selecting 'High Graphics' may waste memory. �
 ��0#  Select 'Monitor Ports' to instruct Windows to verify that information displayed on your monitor, while in full screen DOS mode, is as expected by the application.  Under most circumstances it is unnecessary to monitor ports and doing so will only slow down performance within the DOS session.

If you experience problems (i.e. characters or the mouse cursor not appearing correctly), then instructing Windows to monitor the video ports may correct the problem.  If you do not run graphics programs in the DOS session then select 'Text'.  If you run low resolution graphics (CGA) and text only then select 'Low Graphics' to monitor both text and low resolution graphics operations.  If you run high resolution graphics (EGA and VGA) then select 'High Graphics', which will monitor all video operations �
 ��0#  Select 'Monitor Ports' to instruct Windows to verify that information displayed on your monitor, while in full screen DOS mode, is as expected by the application.  Under most circumstances it is unnecessary to monitor ports and doing so will only slow down performance within the DOS session.

If you experience problems (i.e. characters or the mouse cursor not appearing correctly), then instructing Windows to monitor the video ports may correct the problem.  If you do not run graphics programs in the DOS session then select 'Text'.  If you run low resolution graphics (CGA) and text only then select 'Low Graphics' to monitor both text and low resolution graphics operations.  If you run high resolution graphics (EGA and VGA) then select 'High Graphics', which will monitor all video operations �
 ��0#  Select 'Monitor Ports' to instruct Windows to verify that information displayed on your monitor, while in full screen DOS mode, is as expected by the application.  Under most circumstances it is unnecessary to monitor ports and doing so will only slow down performance within the DOS session.

If you experience problems (i.e. characters or the mouse cursor not appearing correctly), then instructing Windows to monitor the video ports may correct the problem.  If you do not run graphics programs in the DOS session then select 'Text'.  If you run low resolution graphics (CGA) and text only then select 'Low Graphics' to monitor both text and low resolution graphics operations.  If you run high resolution graphics (EGA and VGA) then select 'High Graphics', which will monitor all video operations �
 ��0*  Most DOS text applications use standard BIOS services for displaying text.  For these applications, selecting this option tells Windows to provide a faster emulation of these services.

If your text based application does not appear on screen correctly then you should try disabling this option. �
 ��0  Normally, Windows may return unused video memory to the system.  This may cause problems for applications which switch between different video modes while running.  For example, Windows may reduce allocated video memory for a program running in text mode.  When this program switches into graphics mode (such as a in a 'page preview') then there may not be enough available memory.  Selecting 'Retain Video Memory' instructs Windows to maintain the amount of memory required for DOS application based on its initial video mode. �
 �i 0E   Specify information on task prioritization and background execution. �
 ��0O  The background priority value indicates how often, when the DOS session is NOT the active window, the processor is directed to perform work for the DOS session.

This value is ignored:

     -  if background execution is disabled
     -  if a the active DOS session is set to exclusive.

The value must be between 1 and 10,000. �
 ��0�   The foreground priority value indicates how often, when the DOS session is the active window, the processor is directed to perform work for the DOS session.

The value must be between 1 and 10,000. �
 ��0�   DOS sessions with 'detect idle time' enabled are allocated less processor time while their keyboard is inactive.  This improves performance for other applications. �
 ��0X  Background execution allows your DOS application to continue activity while you work in other DOS or Windows applications.

An example of when background execution is useful is an application which performs an extended task, such as a database sort, while unattended.  Most DOS communication programs must also be allowed to execute in the background.

Background execution can significantly slow overall system performance.  Do not enable the option unless required.

Background execution for an active DOS session can be toggled by pressing ALT-SPACE and E and making the appropriate change. �
 ��0u  Selecting exclusive execution causes all other applications (DOS and Windows), including those designated to run in the background, to 'freeze' while the exclusive session is active.  Applications running in exclusive session usually run faster.

Exclusive execution for an active DOS session can be toggled by pressing ALT-SPACE and E and making the appropriate change. �
 �j 0{   Specify information on application shortcut keys, pasting into a DOS session and how and when a DOS session may be closed. �
 �g0w   If you experience trouble pasting from the Windows clipboard into your DOS application you should disable this option. �
 �h0�   DOS sessions with 'allow close on exit' enabled are closed AUTOMATICALLY when exiting Windows.

NEVER enable this option for programs which write information to disk.  This includes most applications. �
 �i0>  Select this option if you want the DOS session to end when the program specified in the PIF file ends.  Do not select this option if you would like to be at a DOS prompt when the program ends.

If you do not select this option then you will need to type 'exit' at the DOS prompt and press enter to close the window. �
 �_0�  ALT-TAB switches among applications

Windows reserves certain keyboard combinations for its own use.  Normally these shortcut keys are active during DOS sessions under Windows.  If your DOS application has its own shortcut keys which conflict with Windows, you may disable Windows' use of this key combination while the DOS session is active. The Windows shortcut key is disabled only while you work in the DOS session. �
 �`0�  ALT-ESC sends the active window behind all others and gives the next window the keyboard input focus

Windows reserves certain keyboard combinations for its own use.  Normally these shortcut keys are active during DOS sessions under Windows.  If your DOS application has its own shortcut keys which conflict with Windows, you may disable Windows' use of this key combination while the DOS session is active. The Windows shortcut key is disabled only while you work in the DOS session. �
 �a0�  CTRL-ESC invokes the Windows Task List

Windows reserves certain keyboard combinations for its own use.  Normally these shortcut keys are active during DOS sessions under Windows.  If your DOS application has its own shortcut keys which conflict with Windows, you may disable Windows' use of this key combination while the DOS session is active. The Windows shortcut key is disabled only while you work in the DOS session. �
 �b0�  PrtSc (print screen) copies the contents of the entire screen to the Windows clipboard.

Windows reserves certain keyboard combinations for its own use.  Normally these shortcut keys are active during DOS sessions under Windows.  If your DOS application has its own shortcut keys which conflict with Windows, you may disable Windows' use of this key combination while the DOS session is active. The Windows shortcut key is disabled only while you work in the DOS session. �
 �c0�  ALT-Space invokes the system menu which is in the upper left corner of most windows.

Windows reserves certain keyboard combinations for its own use.  Normally these shortcut keys are active during DOS sessions under Windows.  If your DOS application has its own shortcut keys which conflict with Windows, you may disable Windows' use of this key combination while the DOS session is active. The Windows shortcut key is disabled only while you work in the DOS session. �
 �d0�  ALT-Enter toggles a DOS session between windowed and full screen modes.

Windows reserves certain keyboard combinations for its own use.  Normally these shortcut keys are active during DOS sessions under Windows.  If your DOS application has its own shortcut keys which conflict with Windows, you may disable Windows' use of this key combination while the DOS session is active. The Windows shortcut key is disabled only while you work in the DOS session. �
 �e0�  ALT-PrtSc copies the contents of the active window to the Windows clipboard.

Windows reserves certain keyboard combinations for its own use.  Normally these shortcut keys are active during DOS sessions under Windows.  If your DOS application has its own shortcut keys which conflict with Windows, you may disable Windows' use of this key combination while the DOS session is active. The Windows shortcut key is disabled only while you work in the DOS session. �
 �Y0�  You may specify a shortcut or 'hot' key combination for any DOS session.  Pressing the shortcut key combination from anywhere in Windows (except as explained below) will cause the DOS session to become the active application.

You may use most combinations of CTRL, ALT, SHIFT and some other key.  All shortcut keys must include CTRL or ALT (and may include both). Shortcut keys may NOT include any of the following: BACKSPACE, ESC, ENTER, PRINT SCREEN, SPACEBAR or TAB.

Shortcut keys will not work under the following circumstances:

     -  the active Windows application uses the same key
        combination and the key combination is an active choice
     -  a different shortcut key was specified in the program's
        Program Manager properties �
 �Z0�  You may specify a shortcut or 'hot' key combination for any DOS session.  Pressing the shortcut key combination from anywhere in Windows (except as explained below) will cause the DOS session to become the active application.

You may use most combinations of CTRL, ALT, SHIFT and some other key.  All shortcut keys must include CTRL or ALT (and may include both). Shortcut keys may NOT include any of the following: BACKSPACE, ESC, ENTER, PRINT SCREEN, SPACEBAR or TAB.

Shortcut keys will not work under the following circumstances:

     -  the active Windows application uses the same key
        combination and the key combination is an active choice
     -  a different shortcut key was specified in the program's
        Program Manager properties �
 �[0�  You may specify a shortcut or 'hot' key combination for any DOS session.  Pressing the shortcut key combination from anywhere in Windows (except as explained below) will cause the DOS session to become the active application.

You may use most combinations of CTRL, ALT, SHIFT and some other key.  All shortcut keys must include CTRL or ALT (and may include both). Shortcut keys may NOT include any of the following: BACKSPACE, ESC, ENTER, PRINT SCREEN, SPACEBAR or TAB.

Shortcut keys will not work under the following circumstances:

     -  the active Windows application uses the same key        combination and the key combination is an active choice
     -  a different shortcut key was specified in the program's
        Program Manager properties �
 �]0�  You may specify a shortcut or 'hot' key combination for any DOS session.  Pressing the shortcut key combination from anywhere in Windows (except as explained below) will cause the DOS session to become the active application.

You may use most combinations of CTRL, ALT, SHIFT and some other key.  All shortcut keys must include CTRL or ALT (and may include both). Shortcut keys may NOT include any of the following: BACKSPACE, ESC, ENTER, PRINT SCREEN, SPACEBAR or TAB.

Shortcut keys will not work under the following circumstances:

     -  the active Windows application uses the same key        combination and the key combination is an active choice
     -  a different shortcut key was specified in the programs Program        Manager properties � � 0 �  �4 VS_VERSION_INFO ���           ?                        Q  StringFileInfo  =  040904E4      CompanyName Qualitas, Inc.  (  FileDescription Qualitas PIF Editor   FileVersion 8.03     	 InternalName    QPIFEdit    L 8 LegalCopyright  Copyright � 1995-97 Qualitas, Inc. All rights reserved. %  OriginalFilename    QPIFEdit.exe      ProductName Qualitas Max 8    ProductVersion  8.03    $   VarFileInfo   Translation 	�� � �  (       @         �                        �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ���                                                 �������������������������������  � � ���������������������� �� ��� ������������������wwwwwwwwwwwwww�������������������������������������������������������������������������������������������������������������������������AAAAAAAAAAAAAA@wwxwwxwwxwwvff`��������v��`������������ff`                ������������������������������                ����������������������������                                                ��������                                                                                                                ��������� �d 0            �   � � �  (       @         �                        �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ���                                           p       �P   3  30	   �P   �  �0	�  	U  �p�0	  	�P �P�0�w	�  	�UU�P���� 	  	����P��0 	� 	��� �P ��  			�  P ��  	����� � ��0 	�����U ���� 	�������� ���w	�� ��P�p�0	�� � ��P�  �0	�   ��P�  �0          p     wwwp www ���   ���w���p�  �p  �  �p p�  p  �  �p p   �p  �  �p p  �   �  �p p ��    �  �p p�p     �  �p p�      �  �p p�  p  �ww��wxp�p �p  ���� ���  ��p                                                  ���������p�`�`�`          �  �          `  `  `   � �  � Æ��� � ?�À À  � �p8��������� �e 0            �   � MENUAPP p       &File   L&New   �&Open...   &Save   xSave &As...      � �E&xit  Sett&ings   f &General   g &Memory   h &Video   i Multi&task   j &Other      � w &Run PIF � &Help   4&Overview   5&Search for Help on...        6&Technical Support      � 7&About Qualitas PIF Editor... � �e 0@  ` �P    � MenuApp    MS Sans Serif     -  f   P�General  -   -  g   P�Memory  Z   -  h   P�Video  �   -  i   P�Multitask  �   -  j   P�Other  �  (  w   P�Run PIF   d _ x D  P�    =  �    P�&Program Filename:  X  �  � � �P�   1 .  �    P�&Window Title:  X 1 �  � � �P�   E E  �    P�Optional Para&meters:  X E �  � � �P�   Y =  �    P�&Start-up Directory:  X Y �  � � �P�     ,  P�&Qualitas DOSMAX for Windows  = ! 7  -	 P�Use Default  � !   .	 P�ON  � !   /	 P�OFF   5 F 0  P�Memory Options (Sizes in KB)   E   1   P�&DOS:  . E   2   P�Min  K C   3� �P�  g E   4   P�De&sired  � C   5� �P�  � D ( 
 @ P�&Locked   W   6   P�&EMS:  . W   7   P�Min  D U   8� �P�  g W   9   P�Limi&t  � U   :� �P�  � V ( 
 A P�Lo&cked   i   ;   P�&XMS:  . i   <   P�Min  D g   =� �P�  g i   >   P�Li&mit  � g   ?� �P�  � h ( 
 B P�Loc&ked  � h / 
 C P�&Uses HMA  
  S % �  P�&Display Usage   % 2 
 �	 P�Full Screen   / / 
 �	 P�Windowed  
 A S . �  P�&Video Memory   N  
 �	 P�Text   X 9 
 �	 P�Low Graphics   b ; 
 �	 P�High Graphics  p  � - �  P�Monitor Ports  � #  
 � P�Te&xt  � - 9 
 � P�Low Gra&phics  � 7 ; 
 � P�High Graphi&cs  p K � $ �  P�Other  � U K 
 � P�Em&ulate Text Mode  � _ R 
 � P�Retain Video &Memory    / �  P�Priority   $ C  �   P�&Background Priority:  V "   �� �P�  � $ A  �   P�Foreground &Priority:  � "   �� �P�  f 5 C 
 � P�&Detect Idle Time   M  �  P�Execution   Y 4 
 � P�Bac&kground  � X , 
 � P�&Exclusive    � ! X  P�Application Shortcut Key   &  
 Y P�&Alt  ' &  
 Z P�&Ctrl  E &  
 [ P�&Shift  g '   \   P�&Key:  x % $  ]� �P�   ? � / f  P�Options   I @ 
 g P�All&ow fast paste   S [ 
 h P�Allo&w close when active   ] S 
 i P�Close Window on e&xit  �  ^ V ^  P�Reserve Shortcut Keys  � $ $ 
 _ P�Alt-Ta&b  � .  
 b P�&PrtSc  � 8 ) 
 d P�Alt-E&nter  � B $ 
 ` P�Alt-&Esc  � L ' 
 a P�Ct&rl-Esc  � V , 
 c P�A&lt-Space  � ` * 
 e P�Al&t-PrtSc  � �d 0  � Ȁ  � w   About Qualitas PIF Editor  MS Sans Serif �  2    P�OK  � 8   ��  P��d    p  ��  P�Qualitas PIF Editor
Version 8.03   $ }  ��  P�Copyright � 1995-97 Qualitas, Inc.
All rights reserved.   D p  e   P�This product is licensed to:    T �  f   P�  � �k 0�  � Ȑ	  � �   Qualitas PIF Editor  Helv +  �  ��  P�The Qualitas PIF Editor will only edit  +  y  ��  P�386 Enhanced mode PIF features.  + # �  ��  P�You may edit a PIF file but the      �  P�� + ,   ��  P�enhanced mode features will not be  + 5   ��  P�available while you remain in  + >   ��  P�Standard mode.  L s       P�OK   S �  l  P�&Don't display this message in the future.  � �� pB            QPIFEDITQualitas PIF EditorThe Qualitas PIF Editor    � � p2    "No help available for this control              � � pL      
KB Minimum 
KB Desired  EMS Minimum 	EMS Limit  XMS Minimum 	XMS Limit� �  p6         Background Priority Foreground Priority       � �� p�       Register class failed  <QPIFEDIT doesn't support the editting of Standard mode .PIFsFQPIFEDIT requires Windows 3.x running in Standard or 386 Enhanced modeSave changes to %s?
<Untitled>PIF Files(*.PIF)
*.pif
    � � p�   Can't open %s%s is not a valid .PIF file"File is too big to be a valid .PIFThis is an old Windows PIF -.PIF internal structure appears to be damagedBThe Qualitas PIF Extension file, %s, associated with %s is invalid         � � p)        $'%s' value must be between %d and %d+'%s' value must be -1, or between %d and %d*The required program filename is required.�Invalid filename. 
Check to ensure the filename has no more than 8 characters followed by a period and a 3-letter extension.  Press OK to ignore this warning.      � � p�             *Problem using COMMDLG.DLL for OPEN or SAVEOut of memoryOut of memoryOut of memoryQPIFEDIT is not compatible with Windows 95.  To edit PIF values in Win95, right click on the icon and edit the Property sheets. 