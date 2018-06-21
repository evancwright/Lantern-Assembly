;object definitions

#define OFFSCREEN  0
#define PLAYER_ID  1

#define NO_OBJECT  255
#define ANY_OBJECT  254

;byte 1
#define PORTABLE_MASK  1
#define EDIBLE_MASK  2
#define BACKDROP_MASK  2
#define WEARABLE_MASK  4
#define BEINGWORN_MASK  8
#define LIGHTABLE_MASK  16
#define LIT_MASK  32	
#define EMITTING_LIGHT_MASK  32
#define DOOR_MASK  64
#define UNUSED_MASK  128

#define PORTABLE_BIT  0
#define EDIBLE_BIT  1
#define WEARABLE_BIT  2
#define WORN_BIT  3
#define LIGHTABLE_BIT  4
#define LIT_BIT	  5
#define DOOR_BIT  6
#define UNUSED_BIT  7

;(PROPERTY_BYTE_2)
#define SCENERY_MASK  1
#define SUPPORTER_MASK  2
#define CONTAINER_MASK  4
#define TRANSPARENT_MASK  8
#define OPENABLE_MASK  16
#define OPEN_MASK  32
#define LOCKABLE_MASK  64
#define LOCKED_MASK  128
#define OPEN_CONTAINER  OPEN+CONTAINER 

;byte 2
;#define SCENERY_BIT  0
;#define SUPPORTER_BIT  1
;#define CONTAINER_BIT  2
;#define TRANSPARENT_BIT  3
;#define OPENABLE_BIT  4
;#define OPEN_BIT  5
;#define LOCKABLE_BIT  6
;#define LOCKED_BIT	 7

; objdefs.asm

#define OBJ_ID  0
#define HOLDER_ID  1
#define INITIAL_DESC_ID   2
#define DESC_ID  3
#define NORTH  4
#define SOUTH  5
#define EAST  6
#define WEST  7
#define NORTHEAST  8
#define SOUTHEAST  9
#define SOUTHWEST  10
#define NORTHWEST  11
#define UP  12
#define DOWN  13
#define ENTER  14
#define OUT  15
#define MASS  16

#define OBJ_ENTRY_SIZE  19
#define PROPERTY_BYTE_1  17
#define PROPERTY_BYTE_2  18
;byte 1
#define SCENERY  1 
#define SUPPORTER  2
#define CONTAINER  3
#define TRANSPARENT  4
#define OPENABLE  5
#define OPEN  6
#define LOCKABLE  7
#define LOCKED  8
#define PORTABLE  9
#define BACKDROP  10
#define WEARABLE  11
#define BEINGWORN  12
#define LIGHTABLE  13
#define LIT  14
#define EMITTING_LIGHT  14
#define DOOR  15
#define UNUSED  16
;byte 2
#define PORTABLE_MASK  1
#define BACKDROP_MASK  2
#define DRINKABLE_MASK  4
#define FLAMMABLE_MASK  8
#define LIGHTABLE_MASK  16
#define LIT_MASK  32	
#define EMITTING_LIGHT_MASK  32
#define DOOR_MASK  64
#define UNUSED_MASK  128
