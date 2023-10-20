package oracle.appstack;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import jakarta.json.Json;
import jakarta.json.JsonValue;
import jakarta.json.stream.JsonParser;
import jakarta.json.stream.JsonParser.Event;

public class TestInputList {

  private List<TestInput> input;

  private TestInputList() {
    input = new ArrayList<>();
  }

  public static TestInputList fromJsonFile(String fileName) throws IOException {
    TestInputList testInputList = new TestInputList();
    try (FileInputStream fileInputStream = new FileInputStream(fileName);
        JsonParser jsonParser = Json.createParser(fileInputStream)) {
      if (jsonParser.hasNext()) {
        if (jsonParser.next() == Event.START_ARRAY) {
          for (JsonValue item : jsonParser.getArray()) {
            TestInput testInput = TestInput.fromJsonObject(item.asJsonObject());
            testInputList.input.add(testInput);
          }
        }
      }
      return testInputList;
    } catch (IOException ex) {
      throw ex;
    }
  }

  public List<TestInput> getTestInputList() {
    return this.input;
  }

}
