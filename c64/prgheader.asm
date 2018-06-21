;BASIC header for a C64 .prg file
;ORG needs to be set to 4096
 

.byte 11d ;link lo 4097
.byte 16d ;link hi
.byte 10d  ;line# lo 4099
.byte 0d ;line# hi 4100
.byte 158d ;SYS TOKEN 4101
.byte 50d  ; 2
.byte 48d  ; 0
.byte 54d  ; 6
.byte 49d  ; 1
.byte 0d  ; null terminator  address:4106
.byte 0d ;link lo  
.byte 0d ;link hi    4108
