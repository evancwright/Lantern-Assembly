;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; check rules table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_table
	DB 38 ; burn
	DW check_dobj_supplied
	DB 38 ; burn
	DW check_see_dobj
	DB 23 ; close
	DW check_dobj_supplied
	DB 23 ; close
	DW check_dobj_open
	DB 23 ; close
	DW check_see_dobj
	DB 25 ; drink
	DW check_dobj_supplied
	DB 25 ; drink
	DW check_see_dobj
	DB 25 ; drink
	DW check_have_dobj
	DB 15 ; drop
	DW check_dobj_supplied
	DB 15 ; drop
	DW check_see_dobj
	DB 15 ; drop
	DW check_have_dobj
	DB 24 ; eat
	DW check_dobj_supplied
	DB 24 ; eat
	DW check_see_dobj
	DB 10 ; enter
	DW check_dobj_supplied
	DB 10 ; enter
	DW check_see_dobj
	DB 18 ; examine
	DW check_dobj_supplied
	DB 18 ; examine
	DW check_see_dobj
	DB 33 ; fill
	DW check_see_dobj
	DB 41 ; flush
	DW check_see_dobj
	DB 12 ; get
	DW check_dobj_supplied
	DB 12 ; get
	DW check_see_dobj
	DB 12 ; get
	DW check_dont_have_dobj
	DB 12 ; get
	DW check_dobj_portable
	DB 14 ; kill
	DW check_dobj_supplied
	DB 14 ; kill
	DW check_see_dobj
	DB 16 ; light
	DW check_dobj_supplied
	DB 16 ; light
	DW check_see_dobj
	DB 16 ; light
	DW check_have_dobj
	DB 20 ; open
	DW check_dobj_supplied
	DB 20 ; open
	DW check_see_dobj
	DB 37 ; pick
	DW check_dobj_supplied
	DB 37 ; pick
	DW check_see_dobj
	DB 26 ; put
	DW check_dobj_supplied
	DB 26 ; put
	DW check_see_dobj
	DB 26 ; put
	DW check_prep_supplied
	DB 26 ; put
	DW check_iobj_supplied
	DB 26 ; put
	DW check_not_self_or_child
	DB 39 ; turn on
	DW check_dobj_supplied
	DB 39 ; turn on
	DW check_see_dobj
	DB 39 ; turn on
	DW check_have_dobj
	DB 43 ; unbolt
	DW check_dobj_supplied
	DB 43 ; unbolt
	DW check_see_dobj
	DB 22 ; unlock
	DW check_dobj_supplied
	DB 22 ; unlock
	DW check_see_dobj
	DB 32 ; wear
	DW check_see_dobj
	DB 32 ; wear
	DW check_have_dobj
	DB 32 ; wear
	DW check_dobj_wearable
	DB 17 ; look
	DW check_light
	DB 20 ; open
	DW check_dobj_closed
	DB 255
