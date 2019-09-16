;BASIC header for a C64 .prg file
;ORG needs to be set to 4096
 

	DB 11 ;link lo 4097
	DB 16 ;link hi
	DB 10  ;line# lo 4099
	DB 0 ;line# hi 4100
	DB 158 ;SYS TOKEN 4101
	DB 50  ; 2
	DB 48  ; 0
	DB 54  ; 6
	DB 49  ; 1
	DB 0  ; null terminator  address:4106
	DB 0 ;link lo  
	DB 0 ;link hi    4108
