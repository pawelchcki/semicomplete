import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;

public class LogTest {
  private static Logger logger = Logger.getLogger(LogTest.class);

  public static void main(String[] args) {
    //BasicConfigurator.configure();
    PropertyConfigurator.configure("log4j.properties");

    while (true) {
      logger.info("Testing");
      try {
        Thread.sleep(1000);
      }  catch (Exception e) {
      }
    }
  } /* public static void main(String[]) */
} /* public class LogTest */
