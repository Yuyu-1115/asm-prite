.386
.model flat, stdcall

INCLUDE Irvine32.inc
INCLUDE RouteUtil.inc

.data
methodGet BYTE "GET", 0
methodPost BYTE "POST", 0
methodOptions BYTE "OPTIONS", 0

routeCreate BYTE " /create", 0
routeRead BYTE " /read", 0
routeUpdate BYTE " /update", 0
routeDownload BYTE " /download", 0
paramId BYTE "id=", 0

split BYTE 0Dh, 0Ah, 0Dh, 0Ah, 0

notFoundMsg BYTE "not found", 0Dh, 0Ah, 0

.code 

FindString PROC stdcall,
pString: PTR BYTE,
pTarget: PTR BYTE

	mov esi, pString
    xor ecx, ecx
OuterLoop:
	; check if the string has end
    mov al, [esi]
    cmp al, 0
    je  NotFound

	; initiate target 
    mov edi, pTarget
    mov edx, esi

InnerLoop:
	; check if target reach \0
    mov al, [edi]
    cmp al, 0
    je  Found

	; invalid
    cmp al, BYTE PTR [edx]
    jne NextChar

	; continue
    inc edi
    inc edx
    jmp InnerLoop

NextChar:
	; ecx indicate index
    inc esi
    inc ecx
    jmp OuterLoop

Found:
    mov eax, ecx
    add eax, pString
    ret

NotFound:
    mov eax, -1

    ret

FindString ENDP

END
