#include <ruby.h>
#include <time.h>
#include <stdio.h>

/* from ruby time.c */
struct time_object {
  struct timeval tv;
  struct tm tm;
  int gmt;
  int tm_got;
};


VALUE rCTime_strptime(VALUE klass, VALUE input, VALUE format) {
  VALUE rctime;
  char *c_input;
  char *c_format;
  char *c_remainder;
  int input_len;
  int format_len;
  char *remainder;
  VALUE time_obj;
  c_input = StringValueCStr(input);
  c_format = StringValueCStr(format);

  
  /* copied from ruby time.c */
  struct time_object *tobj;
  time_obj = rb_eval_string("Time.new");
  Data_Get_Struct(time_obj, struct time_object, tobj);
  remainder = strptime(c_input, (const char *)c_format, &(tobj->tm));

  //if (remainder != NULL) {
    //printf("%s\n", remainder);
  //}
  //tobj->tm.tm_year += 1900;
  tobj->tm_got = 1;
  tobj->gmt = 0;
  //printf("year: %d\n", tobj->tm.tm_year);

  return time_obj;
}

void Init_CTime() {
  rb_define_singleton_method(rb_cTime, "strptime", rCTime_strptime, 2);
}
