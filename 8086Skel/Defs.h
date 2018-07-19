/*defs.h*/
#ifndef DEFS_H
#define DEFS_H

#define OFFSCREEN  0
#define PLAYER_ID  1

#define NO_OBJECT  255
#define ANY_OBJECT  254

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
/*byte 1 */

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
/*
#define SCENERY  0 
#define SUPPORTER  1
#define CONTAINER  2
#define TRANSPARENT  3
#define OPENABLE  4
#define OPEN  5
#define LOCKABLE  6
#define LOCKED  7
#define PORTABLE  8
#define BACKDROP  9
#define WEARABLE  10
#define BEINGWORN  11
#define LIGHTABLE  12
#define LIT  13
#define EMITTING_LIGHT  13
#define DOOR  14
#define UNUSED 15
*/ 
 
 
#define SCENERY_MASK  1
#define SUPPORTER_MASK  2
#define CONTAINER_MASK  4
#define TRANSPARENT_MASK  8
#define OPENABLE_MASK  16
#define OPEN_MASK  32
#define LOCKABLE_MASK  64
#define LOCKED_MASK  128
#define OPEN_CONTAINER  OPEN_MASK+CONTAINER_MASK
#define PORTABLE_MASK  256
#define BACKDROP_MASK  512
#define WEARABLE_MASK  1024
#define BEINGWORN_MASK  2048
#define LIGHTABLE_MASK  4096
#define LIT_MASK  8192	
#define EMITTING_LIGHT_MASK  8192
#define DOOR_MASK  16348
#define USER_2 32768
 


#endif
