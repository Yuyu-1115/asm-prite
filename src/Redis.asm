.386
.model flat, stdcall

INCLUDE Irvine32.inc
INCLUDE WinSocks.inc
INCLUDE Redis.inc

.data
	LINE_BREAK EQU 0Dh, 0Ah

	errorSocketMsg BYTE "Fail to create socket to Redis", LINE_BREAK, 0
	errorRedisMsg BYTE "Fail to establish connection to Redis", LINE_BREAK, 0


	keyFmt BYTE "art:%d", 0
	bodyFmt BYTE "$%d", LINE_BREAK, 0

	incrCmd BYTE "*2", LINE_BREAK
		BYTE "$4", LINE_BREAK, "INCR", LINE_BREAK
		BYTE "$9", LINE_BREAK, "global_id", LINE_BREAK, 0

	setHeader BYTE "*3", LINE_BREAK
		BYTE "$3", LINE_BREAK, "SET", LINE_BREAK
		BYTE "$%d", LINE_BREAK, 0

	getHeader BYTE "*2", LINE_BREAK
		BYTE "$3", LINE_BREAK, "GET", LINE_BREAK
		BYTE "$%d", LINE_BREAK, 0

	NEXT_LINE BYTE LINE_BREAK, 0

	keyBuffer BYTE 4096 DUP(?)
	cmdBuffer BYTE 4096 DUP(?)
	respBuffer BYTE 65536 DUP(?)
.code
RedisConnect PROC stdcall,
hostAddress: LPSOCKADDR_IN
; establish an TCP connection to the server
	invoke socket, AF_INET, SOCK_STREAM, 0

	.IF eax == -1
		mov edx, OFFSET errorSocketMsg
		call WriteString
		mov eax, -1
		ret
	.ENDIF

	mov ebx, eax

	invoke connect, ebx, hostAddress, SIZEOF SOCKADDR_IN

	.IF eax == -1
		mov edx, OFFSET errorRedisMsg
		call WriteString
		mov eax, -1
		ret
	.ENDIF

	mov eax, ebx
	ret
RedisConnect ENDP

CreateArt PROC stdcall,
hRedis: HANDLE,
artData: PTR BYTE,
dataLen: DWORD
	LOCAL setLen: DWORD
	LOCAL artID: DWORD

	invoke Str_length, ADDR incrCmd
	invoke send, hRedis, ADDR incrCmd, eax, 0
	invoke recv, hRedis, ADDR respBuffer, SIZEOF respBuffer, 0
	; skip +
	inc edx
	call ParseDecimal32
	mov artID, eax

	; art:%d
	invoke wsprintf, ADDR keyBuffer, ADDR keyFmt, artID
	mov setLen, eax

	; properly format header with full length
	invoke wsprintf, ADDR cmdBuffer, ADDR getHeader, setLen
	; get length for RESP
	invoke Str_length, ADDR cmdBuffer
	; send header
	invoke send, hRedis, ADDR cmdBuffer, eax, 0
	; send art:%d
	invoke Str_length, ADDR keyBuffer
	invoke send, hRedis, ADDR keyBuffer, eax, 0
	invoke send, hRedis, ADDR NEXT_LINE, 2, 0
	; send the actual data (body)
	invoke wsprintf, ADDR cmdBuffer, ADDR bodyFmt, dataLen
	invoke Str_length, ADDR cmdBuffer
	invoke send, hRedis, ADDR cmdBuffer, eax, 0
	invoke send, hRedis, artData, dataLen, 0
	invoke send, hRedis, ADDR NEXT_LINE, 2, 0

	invoke recv, hRedis, ADDR respBuffer, SIZEOF respBuffer, 0

	mov eax, artID

	ret

CreateArt ENDP

ReadArt PROC stdcall,
hRedis: HANDLE,
buffer: PTR BYTE,
artID: DWORD

	LOCAL setLen: DWORD
	LOCAL totalBytes: DWORD

	invoke wsprintf, ADDR keyBuffer, ADDR keyFmt, artID
	mov setLen, eax

	; properly format header with full length
	invoke wsprintf, ADDR cmdBuffer, ADDR getHeader, setLen
	; send header
	invoke send, hRedis, ADDR cmdBuffer, eax, 0
	; send art:%d
	invoke Str_length, ADDR keyBuffer
	invoke send, hRedis, ADDR keyBuffer, eax, 0
	invoke send, hRedis, ADDR NEXT_LINE, 2, 0

	; receive the data
	invoke recv, hRedis, ADDR respBuffer, SIZEOF respBuffer, 0
	mov totalBytes, eax
	; parse till the first \n

	mov esi, OFFSET respBuffer 
	xor edx, edx
parse:
	mov al, BYTE PTR [esi]
	.IF al != 0Ah
		inc esi
		inc edx
		jmp parse
	.ENDIF

	; esi is at \n, so one more inc
	inc esi

	; artSize = totalBytes - headerSize = totalBytes - edx
	mov eax, totalBytes
	sub eax, edx
	mov ecx, eax


	mov edi, buffer
	rep movsb

	ret

ReadArt ENDP


UpdateArt PROC stdcall,
hRedis: HANDLE,
artData: PTR BYTE,
dataLen: DWORD,
artID: DWORD

	LOCAL setLen: DWORD

	invoke wsprintf, ADDR keyBuffer, ADDR keyFmt, artID
	mov setLen, eax

	; properly format header with full length
	invoke wsprintf, ADDR cmdBuffer, ADDR setHeader, setLen
	; get length for RESP
	invoke Str_length, ADDR cmdBuffer
	; send header
	invoke send, hRedis, ADDR cmdBuffer, eax, 0
	; send art:%d
	invoke Str_length, ADDR keyBuffer
	invoke send, hRedis, ADDR keyBuffer, eax, 0
	invoke send, hRedis, ADDR NEXT_LINE, 2, 0
	; send the actual data (body)
	invoke wsprintf, ADDR cmdBuffer, ADDR bodyFmt, dataLen
	invoke Str_length, ADDR cmdBuffer
	invoke send, hRedis, ADDR cmdBuffer, eax, 0
	invoke send, hRedis, artData, dataLen, 0
	invoke send, hRedis, ADDR NEXT_LINE, 2, 0

	invoke recv, hRedis, ADDR respBuffer, SIZEOF respBuffer, 0

	ret
UpdateArt ENDP

END