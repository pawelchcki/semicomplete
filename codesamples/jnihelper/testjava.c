#include <jni.h>
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>

#define PATH_SEPARATOR ":"
#define USER_CLASSPATH "." 

/* TODO(sissel): This is probably better off as something we can load 
 * it at runtime with the normal 'java' tool */

static JNIEnv *g_env;
void java_stacktrace(JNIEnv *env);

/* Override libc's abort() with our own, then try to call libc's abort.
 * Generated by liboverride (http://semicomplete.com/projects/liboverride/)
 */
void abort() {
  void *handle = NULL;
  //This will turn the function proto into a function pointer declaration
  void (*real_func)() = NULL;
  const char library[] = "/lib/libc.so.6";
  handle = dlopen(library, RTLD_LAZY);

  if (handle == NULL) {
    fprintf(stderr, "Failed to dlopen %s\n", library);
    fprintf(stderr, "dlerror says: %s\n", dlerror());
    return;
  }
  real_func = dlsym(handle, "abort");

  {
    java_stacktrace(g_env);
    printf("aborting!\n");
  }

  real_func();
}

void java_stacktrace(JNIEnv *env) {
  jclass cls;
  jmethodID method_id;
  jobject obj;

  cls = (*env)->FindClass(env, "java/lang/Thread");
  if (cls == NULL) {
    fprintf(stderr, "Cound not find class: java/lang/Thread\n");
    return;
  }
  /* method ()V */

  method_id = (*env)->GetStaticMethodID(env, cls, "dumpStack", "()V");
  if (method_id == NULL) {
    fprintf(stderr, "Cound not find public static methed 'dumpStack' in class: Thread\n");
    return;
  }
  (*env)->CallStaticVoidMethod(env, cls, method_id);
  return;
}

/**
 * Much of this taken from the java JNI guide.
 * http://java.sun.com/docs/books/jni/html/invoke.html
 */

int main(int argc, char **argv) {
  JNIEnv *env;
  JavaVM *jvm;
  jint res;
  jclass cls;
  jmethodID method_id;
  jstring jstr;
  jclass stringClass;
  jobjectArray args;

  JavaVMInitArgs vm_args; 
  JavaVMOption *options;
  options = calloc(argc - 1, sizeof(JavaVMOption));
  int i = 0;
  for (i = 1 ; i < argc; i++) {
    options[i - 1].optionString = argv[i];
  }
  vm_args.version = JNI_VERSION_1_2;
  vm_args.options = options;
  vm_args.nOptions = argc - 1;
  vm_args.ignoreUnrecognized = JNI_TRUE;

  JNI_GetDefaultJavaVMInitArgs(&vm_args); 
  res = JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
  if (res < 0) { 
    fprintf(stderr, "Failed creating Java VM\n");
    return 1;
  }

  /* So abort() can access it */
  g_env = env;

  cls = (*env)->FindClass(env, argv[argc - 1]);
  if (cls == NULL) {
    fprintf(stderr, "Cound not find class: %s\n", argv[argc - 1]);
    goto destroy;
  }

  method_id = (*env)->GetStaticMethodID(env, cls, "main", "([Ljava/lang/String;)V");
  if (method_id == NULL) {
    fprintf(stderr, "Cound not find public static method 'main' in class: %s\n", argv[argc - 1]);
    goto destroy;
  }

  stringClass = (*env)->FindClass(env, "java/lang/String");

  jstr = (*env)->NewStringUTF(env, " from C!");
  if (jstr == NULL) {
    goto destroy;
  }
  stringClass = (*env)->FindClass(env, "java/lang/String");

  args = (*env)->NewObjectArray(env, 1, stringClass, jstr);
  if (args == NULL) {
    goto destroy;
  }
  
  (*env)->CallStaticVoidMethod(env, cls, method_id, args);

  destroy:
  if ((*env)->ExceptionOccurred(env)) {
    (*env)->ExceptionDescribe(env);
  }

  (*jvm)->DestroyJavaVM(jvm);
}

