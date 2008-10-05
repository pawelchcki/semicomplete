#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <db.h>

void foo() { printf("Testing\n"); }

int main() {
  DB *db;

  DBT key, value, ret;
  memset(&key, 0, sizeof(DBT));
  
  memset(&value, 0, sizeof(DBT));
  memset(&ret, 0, sizeof(DBT));

  key.data = "test";
  key.size = sizeof("test");
  value.data = foo;
  value.size = sizeof(foo);

  db_create(&db, NULL, 0);
  db->open(db, NULL, NULL, "data", DB_BTREE, DB_CREATE, 0);
  db->put(db, NULL, &key, &value, 0);
  db->get(db, NULL, &key, &ret, 0);
  
  printf("stored: %x\n", ret.data);
  printf("actual: %x\n", foo);

  db->close(db, 0);

  return 0;
}
