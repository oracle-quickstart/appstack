package oracle.appstack;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import jakarta.json.JsonObject;
import jakarta.json.JsonValue;
import jakarta.json.JsonValue.ValueType;
import jakarta.json.JsonString;

public class TestInput {
  private Map<String, String> variables;
  private List<String> testUrls;
  private String testName;

  private TestInput() {
    variables = new HashMap<>();
    testUrls = new ArrayList<>();
  }

  public Map<String, String> getVariables() {
    return variables;
  }

  public List<String> getTestUrls() {
    return testUrls;
  }

  public String getTestName() {
    return this.testName;
  }

  public static TestInput fromJsonObject(JsonObject jsonObject) {
    TestInput testInput = new TestInput();
    if (jsonObject.containsKey("test-name")) {
      testInput.testName = jsonObject.getString("test-name");
    }
    if (jsonObject.containsKey("variables")) {
      JsonObject variables = jsonObject.getJsonObject("variables");
      for (String key : variables.keySet()) {
        testInput.getVariables().put(key, variables.getString(key));
      }
    }
    if (jsonObject.containsKey("test_urls")) {
      for (JsonValue item : jsonObject.getJsonArray("test_urls")) {
        if (item.getValueType() == ValueType.STRING)
          testInput.getTestUrls().add(((JsonString) item).getString());
      }
    }
    return testInput;
  }

}