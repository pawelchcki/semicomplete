
class JNIHelperExample {
  private native void abort();

  public static void main(String[] args) {
    JNIHelperExample helper = new JNIHelperExample();
    System.out.println("Hello!");
    helper.abort();
  }

  static {
    System.loadLibrary("JNIHelperExample");
  }
}
