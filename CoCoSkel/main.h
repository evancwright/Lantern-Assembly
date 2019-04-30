void init();
void draw_status_bar();
void strtok();
BOOL parse_and_map();
void clear_buffers();
BYTE move_start();
BOOL streq(char  *src, char *dest);
void move_next();
void get_verb();
BYTE get_verb_id();
BYTE get_word_id(char *wordPtr, const char *table[], int tableSize);
void look_sub();
void inventory_sub();
BOOL is_prep(char *wrd);
BOOL found_prep();
void clear_scores();
void score_word(BYTE wordId);
BYTE get_prep_id(char *ptr);
void get_max_score();
BOOL is_noun_ambiguous();
BOOL is_visible(BYTE objectId);
BOOL can_see();
BOOL is_door(unsigned char objectId);

char fix_case(char ch);
void examine_sub();
void dump_matches();
void set_object_prop(BYTE objNum, BYTE propNum, BYTE val);
void set_object_attr(BYTE objNum, BYTE attrNum, BYTE  val);
BYTE get_object_prop(BYTE obj, BYTE propNum);
BYTE get_object_attr(BYTE obj, BYTE attrNum);
void quit_sub();
void get_sub();
void close_sub();
void wear_sub();
void unwear_sub();
void inventory_sub();
void print_obj_contents(BYTE objectId);
void list_any_contents(BYTE objectId);
void print_table_entry(BYTE entryNum, const char *table[]);
void execute();
void try_default_sentence();
void move_sub();
void enter_sub();
void enter_object(BYTE room, BYTE dir);
void restore_sub();
void save_sub();
void run_events();
void dump_dict();
BYTE stricmp(const char * str1,const char * str);
BYTE verb_to_dir(BYTE verbId);;
BYTE is_supporter(BYTE objectId);
BYTE is_container(BYTE objectId);
BOOL is_open_container(BYTE objectId);
BOOL is_open(BYTE objectId);
BOOL is_closed_container(BYTE objectId);
BOOL emitting_light(BYTE objId);
BOOL check_not_self_or_child();
BOOL check_dont_have_dobj();
BOOL check_have_dobj();
BOOL check_iobj_container();
BOOL check_dobj_lockable();
BOOL check_dobj_unlocked();
BOOL check_prep_supplied();
BOOL check_dobj_opnable();
BOOL check_iobj_open();
BOOL check_dobj_visible();
BOOL check_dobj_supplied();
BOOL check_iobj_supplied();
BOOL check_light();
BOOL is_ancestor(BYTE parent, BYTE child);
BOOL is_visible_to(BYTE roomId, BYTE objectId);
BOOL has_visible_children(BYTE objectId);
BOOL try_sentence(Sentence *table, int tableSize,  BOOL matchWildcards);
BOOL is_closed(BYTE objectId);
BOOL check_rules();

void get_obj_name(BYTE objectId, char *buffer);
void get_room_name(BYTE objectId, char *buffer);
void dbg_goto();
void purloin();
void dump_flags();
void fix_endianess();
BYTE rand8(BYTE divisor);
char to_uchar(char ch);
char to_lchar(char ch);
BYTE get_inv_weight(BYTE obj);
BOOL is_article_np();
void print_obj_name(BYTE id);
