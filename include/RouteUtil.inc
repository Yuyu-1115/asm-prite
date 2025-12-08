ifndef ROUTEUTIL_INC_
ROUTEUTIL_INC_ EQU 1

; Error Messages
EXTERNDEF methodGet: BYTE
EXTERNDEF methodPost: BYTE
EXTERNDEF methodOptions: BYTE

EXTERNDEF routeCreate: BYTE
EXTERNDEF routeRead: BYTE
EXTERNDEF routeUpdate: BYTE

EXTERNDEF routeDownload: BYTE
EXTERNDEF paramId: BYTE
EXTERNDEF split: BYTE

FindString PROTO stdcall,
pString: PTR BYTE,
pTarget: PTR BYTE


endif