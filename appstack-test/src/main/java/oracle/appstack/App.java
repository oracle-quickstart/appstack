package oracle.appstack;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Base64;

public class App {
  public static void main(String[] args) {
    if (args.length != 2) {
      System.out.println("Wrong number of parameter.");
      System.exit(-2);
    }
    try (FileInputStream zipFileInputStream = new FileInputStream(
        args[0])) {
      String testInput = args[1];
      byte[] bytes = zipFileInputStream.readAllBytes();
      String zipFileBase64Encoded = Base64.getEncoder().encodeToString(bytes);

      TestRunner testRunner = new TestRunner(zipFileBase64Encoded);
      String deployResult = testRunner.runTestSuite(testInput);
      System.out.println(deployResult);
      if (deployResult != "SUCCEDED") {
        System.exit(-1);
      }

    } catch (IOException ex) {
      ex.printStackTrace();
      System.exit(-1);
    }

  }
}