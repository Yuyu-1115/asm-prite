IFNDEF RENDER_INC_    
RENDER_INC_ EQU 1

INCLUDE SmallWin.inc
INCLUDE GraphWin.inc
INCLUDE WinWrapper.inc


; ======================================================
; Rounded Corner Character
; ======================================================

R_CORNER_TL EQU 256Dh  ; ╭
R_CORNER_TR EQU 256Eh  ; ╮
R_CORNER_BL EQU 256Fh  ; ╰
R_CORNER_BR EQU 2570h  ; ╯

; Box lines
LINE_HORI   EQU 2500h  ; ─
LINE_VERT   EQU 2502h  ; │

; ======================================================
; Procedure Declaration
; ======================================================

DrawLineV PROTO stdcall,
hConsoleOutput: HANDLE,
coord: POINTS,
len: DWORD

; NOTE:
; Draw a vertical lin using LINE_VERT (in X-positive direction)

DrawLineH PROTO stdcall,
hConsoleOutput: HANDLE,
coord: POINTS,
len: DWORD

; NOTE:
; Draw a horizontal lin using LINE_HORI (in Y-positive direction)

DrawBorder PROTO stdcall,
hConsoleOutput: HANDLE
coord: POINTS,
size: POINTS

; NOTE:
; Draw a box within given console buffer



ENDIF

