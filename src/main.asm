.386

INCLUDE Irvine32.inc
INCLUDE WinWrapper.inc  

.data
	string DW 06E2Ch, 08A66h
    buffer HANDLE ?
    len DWORD 2
    charsWritten DWORD ?
.code
main PROC
    invoke CreateConsoleScreenBuffer, (GENERIC_READ OR GENERIC_WRITE), (FILE_SHARE_READ OR FILE_SHARE_WRITE), NULL, CONSOLE_TEXTMODE_BUFFER, NULL
    mov buffer, eax

    invoke WriteConsoleW, buffer, ADDR string, len, ADDR charsWritten, NULL

    invoke SetConsoleActiveScreenBuffer, buffer
    
    call WaitMsg
    exit
main ENDP
END main
