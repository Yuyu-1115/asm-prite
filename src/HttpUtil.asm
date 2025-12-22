.386
.model flat, stdcall

INCLUDE HttpUtil.inc

.data
    LINE_BREAK EQU 0Dh, 0Ah
    ; htmlResp  BYTE "HTTP/1.1 200 OK", LINE_BREAK
    ;     BYTE "Content-Type: text/html", LINE_BREAK
    ;     BYTE "Connection: close", LINE_BREAK
    ;     BYTE LINE_BREAK
    ;     BYTE "<h1>Hello from Assembly!</h1><p>This is a test response</p>", 0
    ;     BYTE 0

    createHeader BYTE "HTTP/1.1 200 OK", LINE_BREAK
        BYTE "Access-Control-Allow-Origin: *", LINE_BREAK
        BYTE "Content-Type: application/json", LINE_BREAK


    createBody BYTE "{""id"": %d}", 0

       optionHeader BYTE "HTTP/1.1 200 OK", LINE_BREAK
           BYTE "Access-Control-Allow-Origin: *", LINE_BREAK
           BYTE "Access-Control-Allow-Methods: GET, POST, OPTIONS", LINE_BREAK
           BYTE "Access-Control-Allow-Headers: Content-Type", LINE_BREAK
           BYTE "Content-Length: 0", LINE_BREAK
           BYTE LINE_BREAK, 0
   
       readHeader BYTE "HTTP/1.1 200 OK", LINE_BREAK
           BYTE "Access-Control-Allow-Origin: *", LINE_BREAK
           BYTE "Content-Type: text/plain", LINE_BREAK
           BYTE "Connection: close", LINE_BREAK
           BYTE 0
   


; The header of .ppm response
    ppmHeader BYTE "HTTP/1.1 200 OK", LINE_BREAK
        BYTE "Content-Disposition: attachment; filename=""asmprite-download.ppm""", LINE_BREAK
        BYTE "Content-Type: image/x-portable-pixmap", LINE_BREAK
        BYTE "Connection: close", LINE_BREAK
        BYTE 0


    lengthFmt BYTE "Content-Length: %d", LINE_BREAK
        BYTE LINE_BREAK, 0



END
