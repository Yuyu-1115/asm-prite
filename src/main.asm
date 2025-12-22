INCLUDE Irvine32.inc

INCLUDE WinWrapper.inc  
INCLUDE WinSocks.inc  
INCLUDE HttpUtil.inc
INCLUDE Redis.inc
INCLUDE RouteUtil.inc

.data
  REDIS_IP EQU 61EC4A64h;

  serviceData WSADATA <>
  hSocket SOCKET_HANDLE ?
  hClient SOCKET_HANDLE ?
  hRedis SOCKET_HANDLE ?

  service SOCKADDR_IN <>
  redisAddress SOCKADDR_IN <>
  clientAddress SOCKADDR_IN <>

  clientLength DWORD SIZEOF service

  buffer BYTE 131072 DUP(?)
  respBuffer BYTE 4096 DUP(?)
  bodyBuffer BYTE 4096 DUP(?)
  dataLen DWORD ?

  acceptMsg BYTE "Connection accepted...", 0
  redisInitMsg BYTE "[INFO] Successfully establish connection to Redis...", 0Dh, 0Ah, 0
  
  strContentLength BYTE "Content-Length: ", 0

.code
main PROC
  ; initializa windows sockets with version 2.2
  invoke WSAStartup, 0202h, ADDR serviceData

  ; initiate the server's in address
  mov service.sin_family, AF_INET; ipv4
  mov service.sin_addr, 0; 0.0.0.0
  invoke htons, 8080;
  mov service.sin_port, ax;

  ; initiate the redis server's address
  mov redisAddress.sin_family, AF_INET; ipv4
  mov redisAddress.sin_addr, REDIS_IP
  invoke htons, 6379;
  mov redisAddress.sin_port, ax;


  jnz exitProgram
  ; create TCP socket in IPv4
  invoke socket, AF_INET, SOCK_STREAM, 0
  mov hSocket, eax
  ; bind the socket into local addresses
  invoke bind, hSocket, ADDR service, SIZEOF service
  jnz ExitProgram
  ; start listening
  invoke listen, hSocket, SOMAXCONN
  jnz ExitProgram

  ; establish connection to redis
  invoke RedisConnect, ADDR redisAddress
  .IF eax == -1
    jmp exitProgram
  .ENDIF
  mov hRedis, eax

  mov edx, OFFSET redisInitMsg
  call WriteString

ServerLoop:
  ; establish connection
  invoke accept, hSocket, ADDR clientAddress, ADDR clientLength
  mov hClient, eax;

  mov edx, OFFSET acceptMsg
  call WriteString

  ; receiving HTTP request
  invoke recv, hClient, ADDR buffer, LENGTH buffer, 0

  ; store the size of request
  mov dataLen, eax

  ; add a trailing zero \0 for convenience
  mov esi, OFFSET buffer
  add esi, eax
  mov BYTE PTR [esi], 0

  invoke FindString, ADDR buffer, ADDR strContentLength
  cmp eax, -1
  je ProcessRequest

  ; Found Content-Length, parse it
  add eax, (LENGTHOF strContentLength) - 1 ; Skip "Content-Length: "
  mov edx, eax
  call ParseDecimal32
  mov ebx, eax ; ebx = content length

  ; Find Header End (\r\n\r\n) to calc header size
  invoke FindString, ADDR buffer, ADDR split
  cmp eax, -1
  je ProcessRequest
  
  ; Header size = (split ptr - buffer start) + 4
  sub eax, OFFSET buffer
  add eax, 4 
  
  ; Total Expected = HeaderSize + ContentLength
  add eax, ebx
  mov ecx, eax ; ecx = expected total bytes

RecvLoop:
  cmp dataLen, ecx
  jge ProcessRequest
  
  ; Recv more
  mov edx, OFFSET buffer
  add edx, dataLen
  
  mov eax, SIZEOF buffer
  sub eax, dataLen
  push ecx ; save expected count
  invoke recv, hClient, edx, eax, 0
  pop ecx
  
  cmp eax, 0
  jle ProcessRequest
  
  add dataLen, eax
  
  ; Null terminate again
  mov esi, OFFSET buffer
  add esi, dataLen
  mov BYTE PTR [esi], 0
  
  jmp RecvLoop

ProcessRequest:
  ; /create
  invoke FindString, ADDR buffer, ADDR routeCreate
  .IF eax != -1
      mov edx, OFFSET routeCreate
      call WriteString
      call Crlf
      jmp CREATE
  .ENDIF
  
  ; /read
  invoke FindString, ADDR buffer, ADDR routeRead
  .IF eax != -1
      mov edx, OFFSET routeRead
      call WriteString
      call Crlf
      jmp READ
  .ENDIF

  ; update
  invoke FindString, ADDR buffer, ADDR routeUpdate
  .IF eax != -1
      mov edx, OFFSET routeUpdate
      call WriteString
      call Crlf
      jmp UPDATE
  .ENDIF

  ; download
  invoke FindString, ADDR buffer, ADDR routeDownload
  .IF eax != -1
      mov edx, OFFSET routeDownload
      call WriteString
      call Crlf
      jmp DOWNLOAD
  .ENDIF

  ; Vue will send an request to test out
  invoke FindString, ADDR buffer, ADDR methodOptions
  .IF eax != -1
      mov edx, OFFSET methodOptions
      call WriteString
      call Crlf
      jmp SEND_OK
  .ENDIF


CREATE: 
; POST, return an id

; find the double CRLF
  invoke FindString, ADDR buffer, ADDR split
  add eax, 4
  mov esi, eax
  mov edx, dataLen
  add edx, OFFSET buffer
  sub edx, eax
  invoke CreateArt, hRedis, esi, edx
  mov ebx, eax ; ebx = new id

  ; prepare body
  invoke wsprintf, ADDR bodyBuffer, OFFSET createBody, ebx
  invoke Str_length, ADDR bodyBuffer
  mov ecx, eax ; ecx = body length

  ; send header
  invoke Str_length, OFFSET createHeader
  invoke send, hClient, OFFSET createHeader, eax, 0
  
  ; send content-length
  invoke wsprintf, ADDR respBuffer, OFFSET lengthFmt, ecx
  invoke send, hClient, ADDR respBuffer, eax, 0

  ; send body
  invoke send, hClient, ADDR bodyBuffer, ecx, 0

  jmp CloseConnection

UPDATE:
  ; get id
  invoke FindString, ADDR buffer, ADDR paramId
  ; skip "id="
  add eax, 3
  mov edx, eax
  call ParseDecimal32
  mov ebx, eax ; ebx = id

  ; find the start of body
  invoke FindString, ADDR buffer, ADDR split
  add eax, 4
  mov esi, eax ; esi = pBody

  ; calculate body length
  mov edx, esi
  sub edx, OFFSET buffer ; edx = header length
  mov ecx, dataLen
  sub ecx, edx ; ecx = body length
  mov edx, ecx

  invoke UpdateArt, hRedis, esi, edx, ebx

  ; Send OK response
  invoke Str_length, ADDR optionHeader
  invoke send, hClient, ADDR optionHeader, eax, 0

  jmp CloseConnection

READ:
  ; get id
  invoke FindString, OFFSET buffer, ADDR paramId
  ; skip "id="
  add eax, 3
  mov edx, eax
  call ParseDecimal32
  invoke ReadArt, hRedis, OFFSET buffer, eax
  ; preserve length
  mov ebx, eax

  ; part of header
  invoke Str_length, OFFSET readHeader
  invoke send, hClient, OFFSET readHeader, eax, 0
  ; content-length & separate CRLF
  invoke wsprintf, OFFSET respBuffer, OFFSET lengthFmt, ebx
  invoke send, hClient, OFFSET respBuffer, eax, 0
  ; actual content
  invoke send, hClient, OFFSET buffer, ebx, 0

  jmp CloseConnection
  
DOWNLOAD:
  ; get id
  invoke FindString, OFFSET buffer, ADDR paramId
  ; skip "id="
  add eax, 3
  mov edx, eax
  call ParseDecimal32

  invoke ReadArt, hRedis, OFFSET buffer, eax
  ; preserve length
  mov ebx, eax

  ; part of header
  invoke Str_length, OFFSET ppmHeader
  invoke send, hClient, OFFSET ppmHeader, eax, 0
  ; content-length & separate CRLF
  invoke wsprintf, OFFSET respBuffer, OFFSET lengthFmt, ebx
  invoke send, hClient, OFFSET respBuffer, eax, 0
  ; actual content
  invoke send, hClient, OFFSET Buffer, ebx, 0
  jmp CloseConnection

SEND_OK:
  invoke Str_length, ADDR optionHeader
  invoke send, hClient, ADDR optionHeader, eax, 0
  jmp CloseConnection

CloseConnection:
  invoke closesocket, hClient
  jmp ServerLoop


exitProgram:
  exit
main ENDP
END main
