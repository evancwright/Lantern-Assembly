;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OBJECT_TABLE
; FORMAT: ID,HOLDER,INITIAL DESC,DESC,N,S,E,W,NE,SE,SW,NW,UP,DOWN,OUT,MASS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

obj_table
	.byte 0,0,255,0,255,255,255,255,255,255,255,255,255,255,255,255,0   ; OFFSCREEN
	.byte 0    ;  flags 1 - 8
	.byte 0    ;  flags 9 - 16
	.byte 1,2,255,1,255,255,255,255,255,255,255,255,255,255,255,255,0   ; PLAYER
	.byte 0    ;  flags 1 - 8
	.byte 0    ;  flags 9 - 16
	.byte 2,0,255,2,6,254,254,254,254,254,254,254,255,255,255,255,0   ; NARROW ALLEY
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 3,2,4,3,255,255,255,255,255,255,255,255,255,255,255,255,0   ; TARDIS
	.byte CONTAINER_MASK+OPENABLE_MASK ; flags 1-8
	.byte 0    ;  flags 9 - 16
	.byte 4,0,255,5,255,255,255,2,255,255,255,255,255,255,255,2,0   ; INSIDE TARDIS
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 5,4,7,6,255,255,255,255,255,255,255,255,255,255,255,255,0   ; NOTE
	.byte 0    ;  flags 1 - 8
	.byte PORTABLE_MASK ; flags 9-16
	.byte 6,0,255,8,7,2,8,253,255,255,255,255,255,255,255,255,0   ; BUSY INTERSECTION
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 7,0,255,9,253,6,255,14,253,255,255,253,255,255,255,255,0   ; NORTH STREET
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 8,0,255,10,9,255,253,6,253,253,255,255,255,255,255,255,0   ; EAST STREET
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 9,0,255,11,255,8,255,255,255,255,255,255,10,11,255,255,0   ; 1ST FLOOR
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 10,0,255,12,255,255,255,255,255,255,255,255,255,9,255,255,0   ; 2ND FLOOR
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 11,0,255,13,255,13,255,255,255,255,255,255,9,255,255,255,0   ; BASEMENT
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 12,0,255,14,11,255,255,255,255,255,255,255,255,255,255,255,0   ; INVENTORY ROOM
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 13,11,255,6,255,12,255,255,255,255,255,255,255,255,255,255,0   ; DOOR
	.byte SCENERY_MASK+OPENABLE_MASK+LOCKABLE_MASK+LOCKED_MASK ; flags 1-8
	.byte DOOR_MASK ; flags 9-16
	.byte 14,0,255,15,255,255,7,15,255,255,255,255,255,255,255,255,0   ; LOBBY
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 15,0,255,16,255,255,14,255,255,255,255,255,255,255,255,255,0   ; ELEVATOR
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 16,15,17,6,255,255,255,255,255,255,255,255,255,255,255,255,0   ; BUTTON
	.byte 0    ;  flags 1 - 8
	.byte 0    ;  flags 9 - 16
	.byte 17,0,255,18,255,255,29,15,255,255,255,255,255,255,255,255,0   ; HALLWAY
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 18,0,255,19,255,255,255,17,255,255,255,255,255,255,255,17,0   ; ROSE'S APARTMENT
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 19,9,21,20,255,255,255,255,255,255,255,255,255,255,255,255,0   ; MANNEQUIN
	.byte 0    ;  flags 1 - 8
	.byte 0    ;  flags 9 - 16
	.byte 20,10,23,22,255,255,255,255,255,255,255,255,255,255,255,255,0   ; CRICKET BAT
	.byte 0    ;  flags 1 - 8
	.byte PORTABLE_MASK ; flags 9-16
	.byte 21,12,24,6,255,255,255,255,255,255,255,255,255,255,255,255,0   ; ROSE
	.byte 0    ;  flags 1 - 8
	.byte 0    ;  flags 9 - 16
	.byte 22,0,26,25,255,255,255,255,255,255,255,255,255,255,255,255,0   ; DALEK
	.byte SUPPORTER_MASK ; flags 1-8
	.byte 0    ;  flags 9 - 16
	.byte 23,9,28,27,255,255,255,255,255,255,255,255,255,255,255,255,0   ; STYLISH HAT
	.byte CONTAINER_MASK ; flags 1-8
	.byte PORTABLE_MASK ; flags 9-16
	.byte 24,0,30,29,255,255,255,255,255,255,255,255,255,255,255,255,0   ; PLASTIC HEAD
	.byte 0    ;  flags 1 - 8
	.byte PORTABLE_MASK ; flags 9-16
	.byte 25,0,32,31,255,255,255,255,255,255,255,255,255,255,255,255,0   ; TORSO
	.byte 0    ;  flags 1 - 8
	.byte 0    ;  flags 9 - 16
	.byte 26,18,255,33,255,255,255,255,255,255,255,255,255,255,255,255,0   ; SONIC SCREWDRIVER
	.byte 0    ;  flags 1 - 8
	.byte PORTABLE_MASK ; flags 9-16
	.byte 27,22,255,34,255,255,255,255,255,255,255,255,255,255,255,255,0   ; EYESTALK
	.byte SCENERY_MASK ; flags 1-8
	.byte 0    ;  flags 9 - 16
	.byte 28,0,255,35,255,255,255,255,255,255,255,255,255,255,255,255,0   ; TRENZALORE
	.byte 0    ;  flags 1 - 8
	.byte EMITTING_LIGHT_MASK ; flags 9-16
	.byte 29,17,255,36,255,255,18,255,255,255,255,255,255,255,255,255,0   ; ROSE'S DOOR
	.byte SCENERY_MASK+OPENABLE_MASK+LOCKABLE_MASK+LOCKED_MASK ; flags 1-8
	.byte DOOR_MASK ; flags 9-16
	.byte 30,0,255,37,255,255,255,255,255,255,255,255,255,255,255,255,0   ; KEY
	.byte 0    ;  flags 1 - 8
	.byte PORTABLE_MASK ; flags 9-16
	.byte 31,2,255,38,255,255,255,255,255,255,255,255,255,255,255,255,0   ; TRAFFIC
	.byte SCENERY_MASK ; flags 1-8
	.byte BACKDROP_MASK ; flags 9-16
	.byte 255  ; end of array indicator
