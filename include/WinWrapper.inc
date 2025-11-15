; ======================================================
; Virtual Key Code Constants for Windows API
; ======================================================


; --- Number Keys (0-9) ---
VK_0             = 030h     ; 0 key
VK_1             = 031h     ; 1 key
VK_2             = 032h     ; 2 key
VK_3             = 033h     ; 3 key
VK_4             = 034h     ; 4 key
VK_5             = 035h     ; 5 key
VK_6             = 036h     ; 6 key
VK_7             = 037h     ; 7 key
VK_8             = 038h     ; 8 key
VK_9             = 039h     ; 9 key

; --- Letter Keys (A-Z) ---
VK_A             = 041h     ; A key
VK_B             = 042h     ; B key
VK_C             = 043h     ; C key
VK_D             = 044h     ; D key
VK_E             = 045h     ; E key
VK_F             = 046h     ; F key
VK_G             = 047h     ; G key
VK_H             = 048h     ; H key
VK_I             = 049h     ; I key
VK_J             = 04Ah     ; J key
VK_K             = 04Bh     ; K key
VK_L             = 04Ch     ; L key
VK_M             = 04Dh     ; M key
VK_N             = 04Eh     ; N key
VK_O             = 04Fh     ; O key
VK_P             = 050h     ; P key
VK_Q             = 051h     ; Q key
VK_R             = 052h     ; R key
VK_S             = 053h     ; S key
VK_T             = 054h     ; T key
VK_U             = 055h     ; U key
VK_V             = 056h     ; V key
VK_W             = 057h     ; W key
VK_X             = 058h     ; X key
VK_Y             = 059h     ; Y key
VK_Z             = 05Ah     ; Z key


; ======================================================
; Windows API's Other Constant
; ======================================================

; ----- VT Sequences Related -----
ENABLE_VIRTUAL_TERMINAL_INPUT      = 200h
ENABLE_PROCESSED_OUTPUT            = 1h
ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4h

; ----- Rendering (Console Screen Buffer) -----
GENERIC_READ  = 80000000h
GENERIC_WRITE = 40000000h


GENERIC_RW = 0C0000000h
FILE_SHARE_RW = 3h
CONSOLE_TEXTMODE_BUFFER = 1h; used by the dwFlags in CreateConsoleScreenBuffer


; ======================================================
; Windows API's typedef Set
; ======================================================

LPVOID TEXTEQU <DWORD>
;
; ----- Unicode String -----
;
WCHAR TEXTEQU <WORD>

; ======================================================
; Windows API Declaration
; ======================================================

; ----- Read Input -----

;
GetAsyncKeyState PROTO stdcall,
vKey: DWORD

; NOTE:
; Get the states of given keys (vKey)
;
; NOTE:
; RETURN: If the function succeeds,
;         the return value specifies whether the key was pressed since the last call 
;         to GetAsyncKeyState, and whether the key is currently up or down. 
; 1. If MSB is set, the key is **down**
; 2. If LSB is set, the key was pressed after the previous call to GetAsyncKeyState. 
;
; WARN: However, you should not rely on 2.
; The return value is zero for the following cases:
; 1. The current desktop is not the active desktop
; 2. The foreground thread belongs to another process and the desktop does not allow the hook or the journal record.


; ----- Rendering (ConsoleBuffer) -----

CreateConsoleScreenBuffer PROTO stdcall,
dwDesiredAccess: DWORD,
dwShareMode: DWORD,
lpSecurityAttributes: DWORD, ; SECURITY_ATTRIBUTES in C, but it's fine to pass NULL in my use case
dwFlags: DWORD,
lpScreenBufferData: LPVOID    ; LPVOID in C, passing NULL is fine
;
; NOTE:
; constant for dwShareMode is defined in SmallWin.inc (FILE_SHARE_READ, FILE_SHARE_WRITE)
; NULL should be passed to lpSecurityAttributes and lpScreenBufferData
;
; NOTE:
; RETURN: a handle to the newly created ConsoleScreenBuffer

SetConsoleActiveScreenBuffer PROTO stdcall,
hConsoleOutput: DWORD
;：ㄆ
; NOTE: 
; Sets the specified screen buffer to be the currently displayed console screen buffer.
;
; NOTE:
; RETURN: NONZERO value if the function succeeds

SetConsoleMode PROTO stdcall,
hConsoleHandle: HANDLE,
dwMode: DWORD
;
; NOTE:
; Sets the input mode of a console's input buffer or the output mode of a console screen buffer.
;
; NOTE:
; RETURN: NONZERO value if the function succeeds

WriteConsoleW PROTO stdcall,
hConsoleOutput: HANDLE,
lpBuffer: PTR WCHAR,
nNumberOfCharsToWrite: DWORD,
lpNumberOfCharsWritten: PTR DWORD,
lpReserved: DWORD; pass NULL
;
; NOTE:
; Writes a character string to a console screen buffer beginning at the current cursor location.
;
; NOTE:
; RETURN: NONZERO value if the function succeeds
