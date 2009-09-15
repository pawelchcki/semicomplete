#include <ruby.h>
#ifndef __USE_BSD
#define __USE_BSD
#endif
#include <time.h>
#include <stdio.h>

/* from ruby time.c 
 * ruby.h doesn't have this struct defined, so we have to redefine it. */
struct time_object {
  struct timeval tv;
  struct tm tm;
  int gmt;
  int tm_got;
};

VALUE rb_new_intern;


VALUE rCTime_strptime(VALUE klass, VALUE input, VALUE format) {
  VALUE rctime;
  char *c_input;
  char *c_format;
  char *c_remainder;
  VALUE time_obj;
  c_input = StringValueCStr(input);
  c_format = StringValueCStr(format);
  
  /* copied from ruby time.c */
  struct time_object *tobj;

  /* call Time.new */
  time_obj = rb_funcall(rb_cTime, rb_new_intern, 0);

  /* Pull the time_object struct out of the object */
  Data_Get_Struct(time_obj, struct time_object, tobj);
  (void) strptime(c_input, (const char *)c_format, &(tobj->tm));

  tobj->tm_got = 1;
  tobj->gmt = 0;
  return time_obj;
}

void Init_CTime() {
  rb_define_singleton_method(rb_cTime, "strptime", rCTime_strptime, 2);
  rb_new_intern = rb_intern("new");
}
