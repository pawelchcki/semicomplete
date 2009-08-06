#include "rgrok.h"
#include <grok.h>

VALUE cGrokMatch;
extern VALUE cGrok;

static void rGrokMatch_free(void *p);

VALUE rGrokMatch_new(VALUE klass) {
  NEWOBJ(rgm, grok_match_t);
  OBJSETUP(rgm, klass, T_OBJECT);

  return (VALUE)rgm;
}

VALUE rGrokMatch_new_from_grok_match(grok_match_t *gm) {
  VALUE rgrokmatch;
  grok_match_t *my_gm = NULL;
  rgrokmatch = Data_Make_Struct(cGrokMatch, grok_match_t, 0,
                                rGrokMatch_free, my_gm);
  memcpy(my_gm, gm, sizeof(grok_match_t));
  rb_obj_call_init(rgrokmatch, 0, 0);
  return rgrokmatch;
}

VALUE rGrokMatch_initialize(VALUE self) {
  char *name;
  const char *data;
  int namelen, datalen;
  void *handle;
  grok_match_t *gm;
  VALUE captures;
  ID pred_include;
  
  Data_Get_Struct(self, grok_match_t, gm);

  rb_iv_set(self, "@start", INT2FIX(gm->start));
  rb_iv_set(self, "@end", INT2FIX(gm->end));
  rb_iv_set(self, "@subject", rb_str_new2(gm->subject));

  /* Set the @captures variable to a hash of array of strings */
  captures = rb_hash_new();
  rb_iv_set(self, "@captures", captures);

  pred_include = rb_intern("include?");
  handle = grok_match_walk_init(gm);
  while (grok_match_walk_next(gm, handle, &name, &namelen,
                              &data, &datalen) == 0) {
    VALUE key, value;
    VALUE ary;

#ifdef _TRIM_KEY_EXCESS_IN_C_
  /* This section will skip captures of %{FOO} and rename captures of
   * %{FOO:bar} to just 'bar' */
    size_t koff = 0;
    /* there is no 'strcspn' that takes a length, so do it ourselves */
    while (koff < namelen && name[koff] != ':' && name[koff] != '\0') {
      koff++;
    }

    /* Skip captures that aren't named specially */
    if (koff == namelen) {
      continue;
    }

    koff++;

    key = rb_str_new(name + koff, namelen - koff);
#endif

    key = rb_str_new(name, namelen);
    value = rb_str_new(data, datalen);
    if (rb_funcall(captures, pred_include, 1, key) == Qfalse) {
      rb_hash_aset(captures, key, rb_ary_new());
    }

    ary = rb_hash_aref(captures, key);
    rb_ary_push(ary, value);
  }

  return Qtrue;
}

VALUE rGrokMatch_captures(VALUE self) {
  return rb_iv_get(self, "@captures");
}

VALUE rGrokMatch_start(VALUE self) {
  return rb_iv_get(self, "@start");
}

VALUE rGrokMatch_end(VALUE self) {
  return rb_iv_get(self, "@end");
}

VALUE rGrokMatch_subject(VALUE self) {
  return rb_iv_get(self, "@subject");
}

void rGrokMatch_free(void *p) {
  /* empty */
}

void Init_GrokMatch() {
  cGrokMatch = rb_define_class("GrokMatch", rb_cObject);
  rb_define_singleton_method(cGrokMatch, "new", rGrokMatch_new, 0);
  rb_define_method(cGrokMatch, "initialize", rGrokMatch_initialize, 0);
  rb_define_method(cGrokMatch, "captures", rGrokMatch_captures, 0);
  rb_define_method(cGrokMatch, "start", rGrokMatch_start, 0);
  rb_define_method(cGrokMatch, "end", rGrokMatch_end, 0);
  rb_define_method(cGrokMatch, "subject", rGrokMatch_subject, 0);
}
