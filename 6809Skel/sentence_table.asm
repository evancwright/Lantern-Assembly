;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sentence jump table
;verb, d.o., prep, i.o 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sentence_table 
	.db look_verb_id
	.dw look_sub
	.db inventory_verb_id
	.dw inventory_sub
	.db n_verb_id
	.dw move_player
	.db ne_verb_id
	.dw move_player
	.db nw_verb_id
	.dw move_player	
	.db s_verb_id
	.dw move_player
	.db e_verb_id
	.dw move_player
	.db w_verb_id
	.dw move_player
	.db se_verb_id
	.dw move_player	
	.db sw_verb_id
	.dw move_player	
	.db up_verb_id
	.dw move_player	
	.db down_verb_id
	.dw move_player	
	.db get_verb_id
	.dw get_sub
	.db out_verb_id
	.dw move_player	
	.db enter_verb_id
	.dw enter_sub
	.db drop_verb_id
	.dw drop_sub
	.db examine_verb_id
	.dw look_at_sub
	.db put_verb_id
	.dw put_sub
	.db open_verb_id
	.dw open_sub
	.db close_verb_id
	.dw close_sub	
	.db open_verb_id
	.dw open_sub 
	.db close_verb_id
	.dw close_sub
	.db smell_verb_id
	.dw smell_sub
	.db listen_verb_id
	.dw listen_sub
	.db enter_verb_id
	.dw enter_sub
	.db quit_verb_id
	.dw quit_sub
	.db wear_verb_id
	.dw wear_sub
	.db 255