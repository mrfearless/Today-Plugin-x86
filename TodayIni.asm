include advapi32.inc
includelib advapi32.lib

utoa_ex                           PROTO :DWORD, :DWORD

IniGetTodayToggleTitle            PROTO
IniSetTodayToggleTitle            PROTO :DWORD
IniGetTodayToggleIcon             PROTO
IniSetTodayToggleIcon             PROTO :DWORD
IniGetShowTrayIconBalloon         PROTO
IniSetShowTrayIconBalloon         PROTO :DWORD
IniGetPersistIcon                 PROTO
IniSetPersistIcon                 PROTO :DWORD

.CONST


.DATA


.DATA?


.CODE


;**************************************************************************
;
;**************************************************************************
IniGetTodayToggleTitle PROC
    Invoke GetPrivateProfileInt, Addr szToday, Addr szCheckToggleTitle, 1, Addr TodayIni
    ret
IniGetTodayToggleTitle ENDP

;**************************************************************************
;
;**************************************************************************
IniSetTodayToggleTitle PROC dwValue:DWORD
    LOCAL szValue[16]:BYTE
    Invoke utoa_ex, dwValue, Addr szValue  
    Invoke WritePrivateProfileString, Addr szToday, Addr szCheckToggleTitle, Addr szValue, Addr TodayIni
    mov eax, dwValue
    ret
IniSetTodayToggleTitle ENDP

;**************************************************************************
;
;**************************************************************************
IniGetTodayToggleIcon PROC
    Invoke GetPrivateProfileInt, Addr szToday, Addr szCheckToggleIcon, 1, Addr TodayIni
    ret
IniGetTodayToggleIcon ENDP

;**************************************************************************
;
;**************************************************************************
IniSetTodayToggleIcon PROC dwValue:DWORD
    LOCAL szValue[16]:BYTE
    Invoke utoa_ex, dwValue, Addr szValue  
    Invoke WritePrivateProfileString, Addr szToday, Addr szCheckToggleIcon, Addr szValue, Addr TodayIni
    mov eax, dwValue
    ret
IniSetTodayToggleIcon ENDP

IFDEF TRAYBALLOON
;**************************************************************************
;
;**************************************************************************
IniGetShowTrayIconBalloon PROC
    Invoke GetPrivateProfileInt, Addr szToday, Addr szCheckTrayIconBalloon, 0, Addr TodayIni
    ret
IniGetShowTrayIconBalloon ENDP

;**************************************************************************
;
;**************************************************************************
IniSetShowTrayIconBalloon PROC dwValue:DWORD
    LOCAL szValue[16]:BYTE
    Invoke utoa_ex, dwValue, Addr szValue  
    Invoke WritePrivateProfileString, Addr szToday, Addr szCheckTrayIconBalloon, Addr szValue, Addr TodayIni
    mov eax, dwValue
    ret
IniSetShowTrayIconBalloon ENDP
ENDIF

;**************************************************************************
;
;**************************************************************************
IniGetPersistIcon PROC
    Invoke GetPrivateProfileInt, Addr szToday, Addr szCheckPersistIcon, 0, Addr TodayIni
    ret
IniGetPersistIcon ENDP

;**************************************************************************
;
;**************************************************************************
IniSetPersistIcon PROC dwValue:DWORD
    LOCAL szValue[16]:BYTE
    Invoke utoa_ex, dwValue, Addr szValue  
    Invoke WritePrivateProfileString, Addr szToday, Addr szCheckPersistIcon, Addr szValue, Addr TodayIni
    mov eax, dwValue
    ret
IniSetPersistIcon ENDP




; Paul Dixon's utoa_ex function. unsigned dword to ascii. 

OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE

    align 16

utoa_ex proc uvar:DWORD,pbuffer:DWORD

  ; --------------------------------------------------------------------------------
  ; this algorithm was written by Paul Dixon and has been converted to MASM notation
  ; --------------------------------------------------------------------------------

    mov eax, [esp+4]                ; uvar      : unsigned variable to convert
    mov ecx, [esp+8]                ; pbuffer   : pointer to result buffer

    push esi
    push edi

    jmp udword

  align 4
  chartab:
    dd "00","10","20","30","40","50","60","70","80","90"
    dd "01","11","21","31","41","51","61","71","81","91"
    dd "02","12","22","32","42","52","62","72","82","92"
    dd "03","13","23","33","43","53","63","73","83","93"
    dd "04","14","24","34","44","54","64","74","84","94"
    dd "05","15","25","35","45","55","65","75","85","95"
    dd "06","16","26","36","46","56","66","76","86","96"
    dd "07","17","27","37","47","57","67","77","87","97"
    dd "08","18","28","38","48","58","68","78","88","98"
    dd "09","19","29","39","49","59","69","79","89","99"

  udword:
    mov esi, ecx                    ; get pointer to answer
    mov edi, eax                    ; save a copy of the number

    mov edx, 0D1B71759h             ; =2^45\10000    13 bit extra shift
    mul edx                         ; gives 6 high digits in edx

    mov eax, 68DB9h                 ; =2^32\10000+1

    shr edx, 13                     ; correct for multiplier offset used to give better accuracy
    jz short skiphighdigits         ; if zero then don't need to process the top 6 digits

    mov ecx, edx                    ; get a copy of high digits
    imul ecx, 10000                 ; scale up high digits
    sub edi, ecx                    ; subtract high digits from original. EDI now = lower 4 digits

    mul edx                         ; get first 2 digits in edx
    mov ecx, 100                    ; load ready for later

    jnc short next1                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZeroSupressed              ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    inc esi                         ; update pointer by 1
    jmp  ZS1                        ; continue with pairs of digits to the end

  align 16
  next1:
    mul ecx                         ; get next 2 digits
    jnc short next2                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZS1a                       ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    add esi, 1                      ; update pointer by 1
    jmp  ZS2                        ; continue with pairs of digits to the end

  align 16
  next2:
    mul ecx                         ; get next 2 digits
    jnc short next3                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZS2a                       ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    add esi, 1                      ; update pointer by 1
    jmp  ZS3                        ; continue with pairs of digits to the end

  align 16
  next3:

  skiphighdigits:
    mov eax, edi                    ; get lower 4 digits
    mov ecx, 100

    mov edx, 28F5C29h               ; 2^32\100 +1
    mul edx
    jnc short next4                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja  short ZS3a                  ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    inc esi                         ; update pointer by 1
    jmp short  ZS4                  ; continue with pairs of digits to the end

  align 16
  next4:
    mul ecx                         ; this is the last pair so don; t supress a single zero
    cmp edx, 9                      ; 1 digit or 2?
    ja  short ZS4a                  ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    mov byte ptr [esi+1], 0         ; zero terminate string

    pop edi
    pop esi
    ret 8

  align 16
  ZeroSupressed:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx
    add esi, 2                      ; write them to answer

  ZS1:
    mul ecx                         ; get next 2 digits
  ZS1a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write them to answer
    add esi, 2

  ZS2:
    mul ecx                         ; get next 2 digits
  ZS2a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write them to answer
    add esi, 2

  ZS3:
    mov eax, edi                    ; get lower 4 digits
    mov edx, 28F5C29h               ; 2^32\100 +1
    mul edx                         ; edx= top pair
  ZS3a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write to answer
    add esi, 2                      ; update pointer

  ZS4:
    mul ecx                         ; get final 2 digits
  ZS4a:
    mov edx, chartab[edx*4]         ; look them up
    mov [esi], dx                   ; write to answer

    mov byte ptr [esi+2], 0         ; zero terminate string

  sdwordend:

    pop edi
    pop esi

    ret 8

utoa_ex endp

OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef





