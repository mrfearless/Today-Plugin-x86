;=====================================================================================
; x64dbg plugin SDK For Assembler x86 - fearless 2017 - www.LetTheLight.in
;
; Today.asm
;
;-------------------------------------------------------------------------------------

.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

;TRAYBALLOON EQU 1

;DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF




Include x64dbgpluginsdk.inc               ; Main x64dbg Plugin SDK for your program, and prototypes for the main exports 

Include Today.inc ; plugin's include file
include TodayIni.asm
include dayinfo.asm
include fooddays.asm


;=====================================================================================


.CONST
PLUGIN_VERSION      EQU 1

.DATA
PLUGIN_NAME         DB "Today",0

.DATA?
;-------------------------------------------------------------------------------------
; GLOBAL Plugin SDK variables
;-------------------------------------------------------------------------------------
PUBLIC              pluginHandle
PUBLIC              hwndDlg
PUBLIC              hMenu
PUBLIC              hMenuDisasm
PUBLIC              hMenuDump
PUBLIC              hMenuStack

pluginHandle        DD ?
hwndDlg             DD ?
hMenu               DD ?
hMenuDisasm         DD ?
hMenuDump           DD ?
hMenuStack          DD ?
;-------------------------------------------------------------------------------------


.CODE

;=====================================================================================
; Main entry function for a DLL file  - required.
;-------------------------------------------------------------------------------------
DllMain PROC hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:DWORD
    .IF fdwReason == DLL_PROCESS_ATTACH
        mov eax, hinstDLL
        mov hInstance, eax
        
        
        
    .ENDIF
    mov eax,TRUE
    ret
DllMain ENDP


;=====================================================================================
; pluginit - Called by debugger when plugin.dp32 is loaded - needs to be EXPORTED
; 
; Arguments: initStruct - a pointer to a PLUG_INITSTRUCT structure
;
; Notes:     you must fill in the pluginVersion, sdkVersion and pluginName members. 
;            The pluginHandle is obtained from the same structure - it may be needed in
;            other function calls.
;
;            you can call your own setup routine from within this function to setup 
;            menus and commands, and pass the initStruct parameter to this function.
;
;-------------------------------------------------------------------------------------
pluginit PROC C PUBLIC USES EBX initStruct:DWORD
    mov ebx, initStruct

    ; Fill in required information of initStruct, which is a pointer to a PLUG_INITSTRUCT structure
    mov eax, PLUGIN_VERSION
    mov [ebx].PLUG_INITSTRUCT.pluginVersion, eax
    mov eax, PLUG_SDKVERSION
    mov [ebx].PLUG_INITSTRUCT.sdkVersion, eax
    Invoke lstrcpy, Addr [ebx].PLUG_INITSTRUCT.pluginName, Addr PLUGIN_NAME
    
    mov ebx, initStruct
    mov eax, [ebx].PLUG_INITSTRUCT.pluginHandle
    mov pluginHandle, eax
    
    ; Do any other initialization here
    
    ; Construct plugin's .ini file from module filename
    Invoke GetModuleFileName, 0, Addr szModuleFilename, SIZEOF szModuleFilename
    Invoke GetModuleFileName, hInstance, Addr TodayIni, SIZEOF TodayIni
    Invoke szLen, Addr TodayIni
    lea ebx, TodayIni
    add ebx, eax
    sub ebx, 4 ; move back past 'dp32' extention
    mov byte ptr [ebx], 0 ; null so we can use lstrcat
    Invoke szCatStr, ebx, Addr szIni ; add 'ini' to end of string instead   

    
	mov eax, TRUE
	ret
pluginit ENDP


;=====================================================================================
; plugstop - Called by debugger when the plugin.dp32 is unloaded - needs to be EXPORTED
;
; Arguments: none
; 
; Notes:     perform cleanup operations here, clearing menus and other housekeeping
;
;-------------------------------------------------------------------------------------
plugstop PROC C PUBLIC 
    
    ; remove any menus, unregister any callbacks etc
    Invoke _plugin_menuclear, hMenu
    Invoke GuiAddLogMessage, Addr szTodayUnloaded
    
    .IF hTI != NULL
        Invoke TrayIconDestroy, hTI
    .ENDIF
    .IF hTM != NULL
        Invoke TrayMenuHideTrayIcon, hTM
    .ENDIF
    
    
    
    mov eax, TRUE
    ret
plugstop ENDP


;=====================================================================================
; plugsetup - Called by debugger to initialize your plugins setup - needs to be EXPORTED
;
; Arguments: setupStruct - a pointer to a PLUG_SETUPSTRUCT structure
; 
; Notes:     setupStruct contains useful handles for use within x64dbg, mainly Qt 
;            menu handles (which are not supported with win32 api) and the main window
;            handle with this information you can add your own menus and menu items 
;            to an existing menu, or one of the predefined supported right click 
;            context menus: hMenuDisam, hMenuDump & hMenuStack
;            
;            plugsetup is called after pluginit. 
;-------------------------------------------------------------------------------------
plugsetup PROC C PUBLIC USES EBX setupStruct:DWORD
    LOCAL hIconData:ICONDATA
    LOCAL hIconDataOptions:ICONDATA
    
    mov ebx, setupStruct

    ; Extract handles from setupStruct which is a pointer to a PLUG_SETUPSTRUCT structure  
    mov eax, [ebx].PLUG_SETUPSTRUCT.hwndDlg
    mov hwndDlg, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenu
    mov hMenu, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDisasm
    mov hMenuDisasm, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDump
    mov hMenuDump, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuStack
    mov hMenuStack, eax

    Invoke GuiGetWindowHandle
    mov hwndDlg, eax
    mov hWndx64dbg, eax    
    
    ; Do any setup here: add menus, menu items, callback and commands etc
    
    Invoke _plugin_menuaddentry, hMenu, MENU_TODAY, Addr szTodayis

    Invoke _plugin_menuadd, hMenu, Addr szOptions
    mov hMenuOptions, eax
    Invoke _plugin_menuaddentry, hMenuOptions, MENU_TOGGLE_TITLE, Addr szToggleTitle
    Invoke _plugin_menuaddentry, hMenuOptions, MENU_TOGGLE_ICON, Addr szToggleIcon
    IFDEF TRAYBALLOON
    Invoke _plugin_menuaddentry, hMenuOptions, MENU_SHOW_TRAYICON, Addr szShowTrayIcon
    ENDIF
    Invoke _plugin_menuaddentry, hMenuOptions, MENU_PERSIST_ICON, Addr szPersistIconDebug

    Invoke _plugin_menuaddseparator, hMenu
    Invoke _plugin_menuaddentry, hMenu, MENU_ABOUT, Addr szAbout

    Invoke TD_LoadMenuIcon, IMG_MENU_LTLI, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_ABOUT, Addr hIconData
    .ENDIF

    Invoke TD_LoadMenuIcon, IMG_MENU_CHECK, Addr hImgCheck
    Invoke TD_LoadMenuIcon, IMG_MENU_NOCHECK, Addr hImgNoCheck
    Invoke TD_LoadMenuIcon, IMG_MENU_TODAY, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuseticon, hMenu, Addr hIconData
        Invoke _plugin_menuseticon, hMenuOptions, Addr hIconData
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_TODAY, Addr hIconData
    .ENDIF

    Invoke IniGetTodayToggleTitle
    mov g_TodayToggleTitle, eax
    .IF eax == 1
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_TOGGLE_TITLE, Addr hImgCheck
    .ELSE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_TOGGLE_TITLE, Addr hImgNoCheck
    .ENDIF
    
    Invoke IniGetTodayToggleIcon
    mov g_TodayToggleIcon, eax
    .IF eax == 1
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_TOGGLE_ICON, Addr hImgCheck
    .ELSE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_TOGGLE_ICON, Addr hImgNoCheck
    .ENDIF

    Invoke IniGetPersistIcon
    mov g_PersistIcon, eax
    .IF eax == 1
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_PERSIST_ICON, Addr hImgCheck
    .ELSE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_PERSIST_ICON, Addr hImgNoCheck
    .ENDIF
    
    IFDEF TRAYBALLOON
    Invoke IniGetShowTrayIconBalloon
    mov g_ShowTrayIcon, eax
    .IF eax == 1
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_SHOW_TRAYICON, Addr hImgCheck
    .ELSE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_SHOW_TRAYICON, Addr hImgNoCheck
    .ENDIF
    ENDIF
    
    Invoke LoadIcon, hInstance, ICO_X64DBG
    mov hx64dbgicon, eax
    
    Invoke GuiAddLogMessage, Addr szTodayInfo
    
    Invoke Today, TRUE
    
    ret
plugsetup ENDP


;=====================================================================================
; CBMENUENTRY - Called by debugger when a menu item is clicked - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - a pointer to a PLUG_CB_MENUENTRY structure. The hEntry contains 
;            the resource id of menu item identifiers
;  
; Notes:     hEntry can be used to determine if the user has clicked on your plugins
;            menu item(s) and to do something in response to it.
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBMENUENTRY PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    LOCAL hIcon:DWORD
    ;LOCAL hWndx64dbg:DWORD
    
    mov ebx, cbInfo
    mov eax, [ebx].PLUG_CB_MENUENTRY.hEntry
    
    .IF eax == MENU_TODAY
        Invoke Today, FALSE
        mov g_MainIconChanged, 1
        ;Invoke DialogBoxParam, hInstance, IDD_PluginDlg, hwndDlg, OFFSET TodayDlgProc, NULL
;        Invoke GuiGetWindowHandle
;        mov hWndx64dbg, eax
;        Invoke GetWindowText, hWndx64dbg, Addr szMainTitle, SIZEOF szMainTitle
;        Invoke szCatStr, Addr szMainTitle, Addr szPausedTitle
;        Invoke SetWindowText, hWndx64dbg, Addr szMainTitle
;        Invoke LoadIcon, hInstance, ICO_PAUSE
;        mov hIcon, eax
;        Invoke SendMessage, hWndx64dbg, WM_SETICON, ICON_SMALL, hIcon
;        Invoke GuiAddLogMessage, Addr szLogPaused

    .ELSEIF eax == MENU_TOGGLE_TITLE
        Invoke IniGetTodayToggleTitle
        .IF eax == 1
            mov g_TodayToggleTitle, 0
            Invoke IniSetTodayToggleTitle, 0
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_TOGGLE_TITLE, Addr hImgNoCheck
        .ELSE
            mov g_TodayToggleTitle, 1
            Invoke IniSetTodayToggleTitle, 1
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_TOGGLE_TITLE, Addr hImgCheck
        .ENDIF

    .ELSEIF eax == MENU_TOGGLE_ICON
        Invoke IniGetTodayToggleIcon
        .IF eax == 1
            mov g_TodayToggleIcon, 0
            Invoke IniSetTodayToggleIcon, 0
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_TOGGLE_ICON, Addr hImgNoCheck
            
            ; reset icon back to x64dbg one
            Invoke SendMessage, hWndx64dbg, WM_SETICON, ICON_SMALL, hx64dbgicon
            mov g_MainIconChanged, 0
            
        .ELSE
            mov g_TodayToggleIcon, 1
            Invoke IniSetTodayToggleIcon, 1
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_TOGGLE_ICON, Addr hImgCheck
        .ENDIF

    .ELSEIF eax == MENU_PERSIST_ICON
        Invoke IniGetPersistIcon
        .IF eax == 1
            mov g_PersistIcon, 0
            Invoke IniSetPersistIcon, 0
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_PERSIST_ICON, Addr hImgNoCheck
        .ELSE
            mov g_PersistIcon, 1
            Invoke IniSetPersistIcon, 1
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_PERSIST_ICON, Addr hImgCheck
        .ENDIF
     IFDEF TRAYBALLOON   
    .ELSEIF eax == MENU_SHOW_TRAYICON
        Invoke IniGetShowTrayIconBalloon
        .IF eax == 1
            mov g_ShowTrayIcon, 0
            Invoke IniSetShowTrayIconBalloon, 0
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_SHOW_TRAYICON, Addr hImgNoCheck
        .ELSE
            mov g_ShowTrayIcon, 1
            Invoke IniSetShowTrayIconBalloon, 1
            Invoke _plugin_menuentryseticon, pluginHandle, MENU_SHOW_TRAYICON, Addr hImgCheck
        .ENDIF
    ENDIF
    .ELSEIF eax == MENU_ABOUT
        Invoke MessageBox, hwndDlg, Addr szTodayMsgText, Addr szTodayMsgTitle, MB_OK

    .ENDIF
    
    mov eax, TRUE
    ret

CBMENUENTRY ENDP


;=====================================================================================
; CBRESUMEDEBUG
;-------------------------------------------------------------------------------------
CBRESUMEDEBUG PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    .IF g_MainIconChanged == 1 && g_PersistIcon == 0
        ; reset icon back to x64dbg one
        Invoke SendMessage, hWndx64dbg, WM_SETICON, ICON_SMALL, hx64dbgicon
        mov g_MainIconChanged, 0
    .ENDIF

    mov eax, TRUE
    ret
CBRESUMEDEBUG ENDP


;=====================================================================================
; CBSTEPPED
;-------------------------------------------------------------------------------------
CBSTEPPED PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    .IF g_MainIconChanged == 1 && g_PersistIcon == 0
        ; reset icon back to x64dbg one
        Invoke SendMessage, hWndx64dbg, WM_SETICON, ICON_SMALL, hx64dbgicon
        mov g_MainIconChanged, 0
    .ENDIF

    mov eax, TRUE
    ret
CBSTEPPED ENDP


;=====================================================================================
; CBINITDEBUG
;-------------------------------------------------------------------------------------
CBINITDEBUG PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    .IF g_MainIconChanged == 1 && g_PersistIcon == 0
        ; reset icon back to x64dbg one
        Invoke SendMessage, hWndx64dbg, WM_SETICON, ICON_SMALL, hx64dbgicon
        mov g_MainIconChanged, 0
    .ENDIF

    mov eax, TRUE
    ret
CBINITDEBUG ENDP


;=====================================================================================
; CBATTACH
;-------------------------------------------------------------------------------------
CBATTACH PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    .IF g_MainIconChanged == 1 && g_PersistIcon == 0
        ; reset icon back to x64dbg one
        Invoke SendMessage, hWndx64dbg, WM_SETICON, ICON_SMALL, hx64dbgicon
        mov g_MainIconChanged, 0
    .ENDIF
    
    mov eax, TRUE
    ret
CBATTACH ENDP


;=====================================================================================
; Today Dialog Procedure
;-------------------------------------------------------------------------------------
TodayDlgProc PROC hWin:HWND,iMsg:DWORD,wParam:WPARAM, lParam:LPARAM

    mov eax, iMsg
    .IF eax == WM_INITDIALOG
        ; Any initialization here
        
	.ELSEIF eax == WM_CLOSE
        Invoke EndDialog, hWin, NULL
        
	.ELSEIF eax == WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh
        .IF eax == IDC_PLUGINDLG_OK
            Invoke SendMessage, hWin, WM_CLOSE, NULL, NULL
        .ENDIF
    .ELSE
        mov eax, FALSE
        ret
	.ENDIF
    mov eax, TRUE
    ret
TodayDlgProc ENDP


;=====================================================================================
; Today 
;-------------------------------------------------------------------------------------
Today PROC USES EBX bInitFlag:DWORD
    LOCAL dwCurrentIndex:DWORD
    LOCAL dwTodayInfoAddress:DWORD
    LOCAL dwTodayDate:DWORD
    LOCAL pTodayIsData:DWORD
    LOCAL lpszTodayEntry:DWORD
    LOCAL nIcons:DWORD
    LOCAL dwIcon:DWORD
    LOCAL hIcon:DWORD

    
    Invoke RtlZeroMemory, Addr szTodayIsLineMsg, SIZEOF szTodayIsLineMsg
    
    mov dwTodayInfoAddress, 0
    mov dwTodayDate, 0
    mov nIcons, 0
    
    Invoke DTGetDateTime, Addr szDateTimeTitle, LONGDDMM
    Invoke DTGetDateTime, Addr szDateTime, MMDD
    
    Invoke DTDateToDwordDateTime, Addr szDateTime, MMDD
    bswap eax
    shr eax, 16d
    ;PrintDec eax
    mov dwTodayDate, eax
    IFDEF DEBUG32
    PrintDec dwTodayDate
    ENDIF
    ;lea eax, dbTestDate
    ;mov ebx, [eax]
    ;PrintDec ebx
    
    ;lea eax, dwTestDate
    ;mov ebx, [eax]
    ;PrintDec ebx
    
    
    lea eax, TodayIs
    mov pTodayIsData, eax
    
    mov dwCurrentIndex, -1
    mov eax, 0
    .WHILE eax != -1
        IFDEF DEBUG32
        PrintText 'ALL DAYS'
        ENDIF
        Invoke FindTodayIndexInList, dwTodayDate, Addr AllDays, dwCurrentIndex, Addr dwTodayInfoAddress
        mov dwCurrentIndex, eax
        .IF eax != -1
            mov eax, dwTotalTodayIs
            .IF eax < MAX_TODAYIS_ENTRIES
                .IF eax > 0
                    Invoke IsTodayIsEntryUnique, dwTodayInfoAddress, Addr TodayIs
                    .IF eax == TRUE
                        Invoke RtlMoveMemory, pTodayIsData, dwTodayInfoAddress, SIZEOF DAYINFO
                        add pTodayIsData, SIZEOF DAYINFO
                        inc dwTotalTodayIs
                    .ELSE
                        IFDEF DEBUG32
                        PrintText 'Duplicate'
                        ENDIF
                    .ENDIF
                .ELSE
                    Invoke RtlMoveMemory, pTodayIsData, dwTodayInfoAddress, SIZEOF DAYINFO
                    add pTodayIsData, SIZEOF DAYINFO
                    inc dwTotalTodayIs
                .ENDIF
            .ENDIF
        .ENDIF
        mov eax, dwCurrentIndex
    .ENDW
    IFDEF DEBUG32
    PrintDec dwTotalTodayIs
    ENDIF
    
 
    
    mov dwCurrentIndex, -1
    mov eax, 0
    .WHILE eax != -1
        IFDEF DEBUG32
        PrintText 'FOOD_DAYS'
        ENDIF
        Invoke FindTodayIndexInList, dwTodayDate, Addr FOOD_DAYS , dwCurrentIndex, Addr dwTodayInfoAddress
        mov dwCurrentIndex, eax
        .IF eax != -1
            mov eax, dwTotalTodayIs
            .IF eax < MAX_TODAYIS_ENTRIES
                .IF eax > 0
                    Invoke IsTodayIsEntryUnique, dwTodayInfoAddress, Addr TodayIs
                    .IF eax == TRUE
                        Invoke RtlMoveMemory, pTodayIsData, dwTodayInfoAddress, SIZEOF DAYINFO
                        add pTodayIsData, SIZEOF DAYINFO
                        inc dwTotalTodayIs
                    .ELSE
                        IFDEF DEBUG32
                        PrintText 'Duplicate'
                        ENDIF
                    .ENDIF
                .ELSE
                    Invoke RtlMoveMemory, pTodayIsData, dwTodayInfoAddress, SIZEOF DAYINFO
                    add pTodayIsData, SIZEOF DAYINFO
                    inc dwTotalTodayIs
                .ENDIF
            .ENDIF
        .ENDIF
        mov eax, dwCurrentIndex
    .ENDW
    IFDEF DEBUG32
    PrintDec dwTotalTodayIs
    ENDIF
;    
    ;mov eax, dwTotalTodayIs
    ;mov ebx, SIZEOF DAYINFO
    ;mul ebx
    
    lea ebx, TodayIs
    mov pTodayIsData, ebx
    ;DbgDump ebx, eax
    
    
    .IF dwTotalTodayIs > 0
    
        ;Invoke szCopy, Addr szTodayIsHeading, Addr szTodayIsLineMsg
        Invoke szCopy, Addr szTodayIsHead1, Addr szTodayIsLineMsg
        Invoke szCatStr, Addr szTodayIsLineMsg, Addr szDateTimeTitle
        Invoke szCatStr, Addr szTodayIsLineMsg, Addr szTodayIsBody
        Invoke GuiAddLogMessage, Addr szTodayIsLineMsg

        Invoke szCopy, Addr szTodayIsTrayHead1, Addr szTrayTitle
        Invoke szCatStr, Addr szTrayTitle, Addr szDateTimeTitle
     
        Invoke RtlZeroMemory, Addr szTrayMessage, SIZEOF szTrayMessage
     
        mov dwCurrentIndex, 0
        mov eax, dwCurrentIndex
        .WHILE eax < dwTotalTodayIs
            mov ebx, pTodayIsData
            
            mov eax, [ebx].DAYINFO.DayIcon
            mov dwIcon, eax
            .IF eax != 0
                mov eax, nIcons
                mov ebx, 4d
                mul ebx
                lea ebx, IconArray
                add ebx, eax
                mov eax, pTodayIsData
                mov [ebx], eax
                inc nIcons
            .ENDIF
            
            mov ebx, pTodayIsData
            lea eax, [ebx].DAYINFO.DayName
            mov lpszTodayEntry, eax
            
            Invoke szCopy, Addr szTodayIsEntryMark, Addr szTodayIsLineMsg
            Invoke szCatStr, Addr szTodayIsLineMsg, lpszTodayEntry
            Invoke szCatStr, Addr szTodayIsLineMsg, Addr szCRLF
            Invoke GuiAddLogMessage, Addr szTodayIsLineMsg
            
            Invoke szCatStr, Addr szTrayMessage, Addr szTodayIsTrayEntry
            Invoke szCatStr, Addr szTrayMessage, lpszTodayEntry
            Invoke szCatStr, Addr szTrayMessage, Addr szCRLF


            add pTodayIsData, SIZEOF DAYINFO 
            inc dwCurrentIndex
            mov eax, dwCurrentIndex
        .ENDW
        
        Invoke szCopy, Addr szCRLF, Addr szTodayIsLineMsg     
        Invoke GuiAddLogMessage, Addr szTodayIsLineMsg
        

        
    .ELSE
    
        Invoke szCopy, Addr szTodayIsHead1, Addr szTodayIsLineMsg
        Invoke szCatStr, Addr szTodayIsLineMsg, Addr szDateTimeTitle    
        Invoke szCatStr, Addr szTodayIsLineMsg, Addr szTodayIsNormal
        ;Invoke szCopy, Addr szTodayIsNothing, Addr szTodayIsLineMsg
        Invoke GuiAddLogMessage, Addr szTodayIsLineMsg
        
    .ENDIF
    
    ;PrintDec nIcons
    .IF nIcons > 0

        .IF nIcons > 1
            invoke GetTickCount
            invoke nseed, eax
            invoke nrandom, nIcons
            mov ebx, 4
            mul ebx
            lea ebx, IconArray
            add ebx, eax
            mov eax, [ebx]
        .ELSE
            lea ebx, IconArray
            mov eax, [ebx]
        .ENDIF
        
        mov pTodayIsData, eax
        mov ebx, eax
        mov eax, [ebx].DAYINFO.DayIcon        
        mov dwIcon, eax
        
        .IF g_TodayToggleIcon == 1    
            Invoke LoadIcon, hInstance, dwIcon
            mov hIcon, eax
            
            Invoke SendMessage, hWndx64dbg, WM_SETICON, ICON_SMALL, hIcon
            
            mov g_MainIconChanged, 1
            
        .ENDIF

        .IF g_TodayToggleTitle == 1
            mov ebx, pTodayIsData
            lea eax, [ebx].DAYINFO.DayName
            mov lpszTodayEntry, eax
            
            Invoke DTGetDateTime, Addr szDateTimeTitle, LONGDDMM

            Invoke szCopy, Addr szx64dbgTitle, Addr szTitle
            Invoke szCatStr, Addr szTitle, Addr szDateTimeTitle
            Invoke szCatStr, Addr szTitle, Addr szTitleDateBreak
            Invoke szCatStr, Addr szTitle, lpszTodayEntry
            Invoke SetWindowText, hWndx64dbg, Addr szTitle

        .ENDIF
        
        .IF bInitFlag == TRUE
            IFDEF TRAYBALLOON
            .IF g_ShowTrayIcon == 1
                mov ebx, pTodayIsData
                lea eax, [ebx].DAYINFO.DayName
                mov lpszTodayEntry, eax
                Invoke TrayIconCreate, NULL, TRAYICON, hx64dbgicon, NULL ;hWndx64dbg Addr szTodayTrayInfo
                mov hTI, eax
                Invoke TrayIconShowNotification, hTI, lpszTodayEntry, Addr szTrayTitle, 5000, TMNI_INFO
                
            .ENDIF
            ENDIF
        .ENDIF
        
    .ENDIF
    
    
    ret

Today ENDP


;-------------------------------------------------------------------------------------
; Finds todays date in list and returns an index to that entry, or -1 if no more found
; index can be passed into dwStartIndex to continue searching from that point on for
; other calls. 
;-------------------------------------------------------------------------------------
FindTodayIndexInList PROC USES EBX dwDate:DWORD, lpdwList:DWORD, dwStartIndex:DWORD, lpIndexAddress:DWORD
    LOCAL dwCurrentIndex:DWORD
    LOCAL pDayInfoData:DWORD
    

    .IF lpdwList == NULL
        .IF lpIndexAddress != NULL
            mov ebx, lpIndexAddress
            mov eax, 0
            mov [ebx], eax
        .ENDIF
        mov eax, -1
        ret
    .ENDIF
    
    .IF dwDate == NULL
        .IF lpIndexAddress != NULL
            mov ebx, lpIndexAddress
            mov eax, 0
            mov [ebx], eax
        .ENDIF
        mov eax, -1
        ret
    .ENDIF
    
    .IF dwStartIndex == -1
        mov dwCurrentIndex, 0
        mov eax, lpdwList
        mov pDayInfoData, eax
    .ELSE
        mov eax, dwStartIndex
        inc eax
        mov dwCurrentIndex, eax
        mov ebx, SIZEOF DAYINFO
        mul ebx
        add eax, lpdwList
        mov pDayInfoData, eax
    .ENDIF
    
    .WHILE TRUE
        
        mov ebx, pDayInfoData
        movzx eax, word ptr [ebx].DAYINFO.DayDate
        .IF eax == 0
            .IF lpIndexAddress != NULL
                mov ebx, lpIndexAddress
                mov eax, 0
                mov [ebx], eax
            .ENDIF        
            mov eax, -1
            ret
        .ENDIF
        
        ;PrintDec eax
        ;PrintDec dwDate
        
        .IF eax == dwDate
            .IF lpIndexAddress != NULL
                mov ebx, lpIndexAddress
                mov eax, pDayInfoData
                mov [ebx], eax
            .ELSE
                mov eax, -1
                ret
            .ENDIF
            mov eax, dwCurrentIndex
            ret
        .ENDIF
        
        add pDayInfoData, SIZEOF DAYINFO
        inc dwCurrentIndex
    .ENDW


    ret
FindTodayIndexInList ENDP


;-------------------------------------------------------------------------------------
; Returns TRUE or FALSE
;-------------------------------------------------------------------------------------
IsTodayIsEntryUnique PROC USES EBX ECX EDX lpIndexAddress:DWORD, lpTodayIs:DWORD
    LOCAL dwCurrentIndex:DWORD
    LOCAL pTodayIsData:DWORD
    
    mov eax, lpTodayIs 
    mov pTodayIsData, eax
    
    mov dwCurrentIndex, 0
    mov eax, 0
    
    .WHILE eax < MAX_TODAYIS_ENTRIES
        mov ebx, pTodayIsData
        lea eax, [ebx].DAYINFO.DayName
        mov edx, lpIndexAddress
        lea ecx, [edx].DAYINFO.DayName
        Invoke szCmp, eax, ecx
        .IF eax == 0 ; no match
        
        .ELSE
            mov eax, FALSE
            ret
        .ENDIF
        
        add pTodayIsData, SIZEOF DAYINFO
        inc dwCurrentIndex
        mov eax, dwCurrentIndex
    .ENDW
    
    mov eax, TRUE
    
    ret

IsTodayIsEntryUnique ENDP



;=====================================================================================
; TD_LoadMenuIcon - Loads RT_RCDATA png resource and assigns it to ICONDATA
; Returns TRUE in eax if succesful or FALSE otherwise.
;-------------------------------------------------------------------------------------
TD_LoadMenuIcon PROC USES EBX dwImageResourceID:DWORD, lpIconData:DWORD
    LOCAL hRes:DWORD
    
    ; Load image for our menu item
    Invoke FindResource, hInstance, dwImageResourceID, RT_RCDATA ; load png image as raw data
    .IF eax != NULL
        mov hRes, eax
        Invoke SizeofResource, hInstance, hRes
        .IF eax != 0
            .IF lpIconData != NULL
                mov ebx, lpIconData
                mov [ebx].ICONDATA.size_, eax
            .ELSE
                mov eax, FALSE
                ret
            .ENDIF
            Invoke LoadResource, hInstance, hRes
            .IF eax != NULL
                Invoke LockResource, eax
                .IF eax != NULL
                    .IF lpIconData != NULL
                        mov ebx, lpIconData
                        mov [ebx].ICONDATA.data, eax
                        mov eax, TRUE
                    .ELSE
                        mov eax, FALSE
                    .ENDIF
                .ELSE
                    ;PrintText 'Failed to lock resource'
                    mov eax, FALSE
                .ENDIF
            .ELSE
                ;PrintText 'Failed to load resource'
                mov eax, FALSE
            .ENDIF
        .ELSE
            ;PrintText 'Failed to get resource size'
            mov eax, FALSE
        .ENDIF
    .ELSE
        ;PrintText 'Failed to find resource'
        mov eax, FALSE
    .ENDIF    
    ret

TD_LoadMenuIcon ENDP


END DllMain
















