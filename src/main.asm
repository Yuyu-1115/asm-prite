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

  buffer BYTE 65536 DUP(?)
  respBuffer BYTE 4096 DUP(?)
  bodyBuffer BYTE 4096 DUP(?)
  dataLen DWORD ?

  acceptMsg BYTE "Connection accepted...", 0
  redisInitMsg BYTE "[INFO] Successfully establish connection to Redis...", 0Dh, 0Ah, 0
  testMsg BYTE "[INFO] test...", 0Dh, 0Ah, 0
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
  mov ebx, eax
  invoke wsprintf, ADDR bodyBuffer, OFFSET createBody, ebx
  ; header
  invoke wsprintf, ADDR respBuffer, OFFSET createHeader, eax
  invoke send, hClient, ADDR respBuffer, eax, 0
  invoke Str_length, ADDR bodyBuffer
  invoke send, hClient, ADDR bodyBuffer, eax, 0

  jmp CloseConnection

UPDATE:
  ; get id
  invoke FindString, ADDR buffer, ADDR paramId
  ; skip "id="
  add eax, 3
  mov edx, eax
  call ParseDecimal32
  mov ebx, eax
  ; find the start of body
  invoke FindString, ADDR buffer, ADDR split
  add eax, 4
  mov edx, eax
  sub edx, dataLen
  ; eax: buffer, edx: len, ebx: id
  invoke UpdateArt, hRedis, eax, edx, ebx

  jmp CloseConnection

READ:
  ; get id
  invoke FindString, OFFSET buffer, ADDR paramId
  ; skip "id="
  add eax, 3
  mov edx, eax
  call ParseDecimal32
  invoke ReadArt, hRedis, OFFSET buffer, eax
  ; construct response

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
