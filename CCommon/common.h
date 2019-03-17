void get_verb();
void clear_scores();
void score_word(BYTE wordId);
BOOL found_prep();
void get_max_score();
int  max_score_matches(int max);
BOOL is_visible(BYTE objectId);
BOOL can_see();
BYTE is_supporter(BYTE objectId);
BYTE is_container(BYTE objectId);
void get_sub();
void drop_sub();
void put_sub();
void open_sub();
void close_sub();
void wear_sub();
void unwear_sub();
void examine_sub();
void look_in_sub();
void list_any_contents(BYTE objectId);
void print_obj_contents(BYTE objectId);
BOOL check_rules();
void init();
void get_obj_name(unsigned char objectId, char *buffer);
void get_room_name(BYTE objectId, char *buffer);
BOOL is_open(BYTE objectId);
BOOL is_visible_to(BYTE roomId, BYTE objectId);
BOOL is_ancestor(BYTE parent, BYTE child);
BOOL has_visible_children(BYTE objectId);
BOOL is_closed_container(BYTE objectId);
BOOL is_open_container(BYTE objectId);
BOOL emitting_light(unsigned char objId);
BOOL is_article(char *wrd);
void print_table_entry(BYTE entryNum, const char *table[]);
void look_sub();
BYTE get_word_id(char *wordPtr, const char *table[], int tableSize);
BYTE get_prep_id(char *wordPtr);
void execute();
void dump_flags();
void dbg_goto();
void try_default_sentence();
BOOL try_sentence(Sentence *table, int tableSize,  BOOL matchWildcards);
void purloin();
void try_default_sentence();
void move_sub();
void enter_sub();
void enter_object(BYTE tgtRoom, BYTE dir);
BOOL is_door(BYTE obj);
BOOL is_closed(BYTE obj);
BYTE verb_to_dir(BYTE verbId);
void inventory_sub();
void dump_matches();
BYTE get_inv_weight(BYTE obj);
BYTE get_verb_id();
BOOL is_prep(char *wrd);
BOOL parse_and_map();
void dump_dict();
BOOL any_visible();
void fix_endianess();