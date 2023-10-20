package oracle.appstack;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import com.oracle.bmc.Region;
import com.oracle.bmc.artifacts.ArtifactsClient;
import com.oracle.bmc.artifacts.model.GenericArtifactSummary;
import com.oracle.bmc.artifacts.requests.DeleteGenericArtifactRequest;
import com.oracle.bmc.artifacts.requests.ListGenericArtifactsRequest;
import com.oracle.bmc.artifacts.responses.DeleteGenericArtifactResponse;
import com.oracle.bmc.artifacts.responses.ListGenericArtifactsResponse;
import com.oracle.bmc.auth.AuthenticationDetailsProvider;
import com.oracle.bmc.auth.SimpleAuthenticationDetailsProvider;
import com.oracle.bmc.auth.StringPrivateKeySupplier;
import com.oracle.bmc.resourcemanager.ResourceManagerClient;
import com.oracle.bmc.resourcemanager.model.CreateApplyJobOperationDetails;
import com.oracle.bmc.resourcemanager.model.CreateDestroyJobOperationDetails;
import com.oracle.bmc.resourcemanager.model.CreateJobDetails;
import com.oracle.bmc.resourcemanager.model.CreateStackDetails;
import com.oracle.bmc.resourcemanager.model.CreateZipUploadConfigSourceDetails;
import com.oracle.bmc.resourcemanager.model.DestroyJobOperationDetails;
import com.oracle.bmc.resourcemanager.model.Job;
import com.oracle.bmc.resourcemanager.model.Stack;
import com.oracle.bmc.resourcemanager.model.ApplyJobOperationDetails.ExecutionPlanStrategy;
import com.oracle.bmc.resourcemanager.model.Job.Operation;
import com.oracle.bmc.resourcemanager.requests.CreateJobRequest;
import com.oracle.bmc.resourcemanager.requests.CreateStackRequest;
import com.oracle.bmc.resourcemanager.requests.GetJobRequest;
import com.oracle.bmc.resourcemanager.requests.GetStackTfStateRequest;
import com.oracle.bmc.resourcemanager.responses.CreateJobResponse;
import com.oracle.bmc.resourcemanager.responses.CreateStackResponse;
import com.oracle.bmc.resourcemanager.responses.GetJobResponse;
import com.oracle.bmc.resourcemanager.responses.GetStackTfStateResponse;

import jakarta.json.Json;
import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.json.stream.JsonParser;

public class TestRunner {

  // OCI configuration
  private static final String TENANCY_SECRET = "OCI_TENANCY_OCID";
  private static final String COMPARTMENT_SECRET = "OCI_COMPARTMENT_OCID";
  private static final String USER_SECRET = "OCI_USER_OCID";
  private static final String FINGERPRINT_SECRET = "OCI_FINGERPRINT";
  private static final String PRIVATE_KEY_SECRET = "OCI_PRIVATE_KEY_PEM";

  // Stack configuration
  private final String zipFileBase64Encoded;

  // OCI SDK
  private final AuthenticationDetailsProvider provider;
  private final ResourceManagerClient client;

  public TestRunner(String zipFileBase64Encoded) {
    this.zipFileBase64Encoded = zipFileBase64Encoded;

    String tenancy_ocid = System.getenv(TENANCY_SECRET);
    String user_ocid = System.getenv(USER_SECRET);
    String private_key = System.getenv(PRIVATE_KEY_SECRET);
    String fingerprint = System.getenv(FINGERPRINT_SECRET);

    provider = SimpleAuthenticationDetailsProvider.builder()
        .tenantId(tenancy_ocid)
        .userId(user_ocid)
        .fingerprint(fingerprint)
        .privateKeySupplier(new StringPrivateKeySupplier(private_key))
        .build();

    client = ResourceManagerClient.builder().region(Region.US_PHOENIX_1).build(provider);

  }

  public String runTestSuite(String testFile) {
    try {
      String status = "FAILED";
      TestInputList testInputList = TestInputList.fromJsonFile(testFile);
      for (TestInput testInput : testInputList.getTestInputList()) {
        status = run(testInput);
        if (status == "FAILED") {
          break;
        }
      }
      return status;
    } catch (IOException ex) {
      ex.printStackTrace();
      return "FAILED";
    }
  }

  public String run(TestInput testInput) {

    System.out.println("Running : " + testInput.getTestName());
    Stack stack = createStack(testInput.getTestName(), testInput.getVariables());
    CreateJobResponse createJobResponse = createApplyJob(stack.getId());
    String status = waitForJobCompleted(createJobResponse);
    System.out.println("Create Stack:" + status);
    Map<String, String> terraformState = null;
    if (status == "SUCCEDED") {
      try {
        terraformState = getTerraformState(stack.getId());
        String url = terraformState.get("url");
        System.out.println(url);
        for (String path : testInput.getTestUrls()) {
          status = checkUrl(url + path);
          System.out.println("Check url(" + url + path + "): " + status);
          if (status == "FAILED") {
            break;
          }
        }
      } catch (Exception ex) {
        ex.printStackTrace();
        status = "FAILED";
      }

      if (terraformState != null) {
        // delete artifact
        String artifact_registry_id = terraformState.get("application_repository_id");
        System.out.println(artifact_registry_id);
        String compartment_id = terraformState.get("compartment_id");
        System.out.println(compartment_id);
        status = deleteArtifact(artifact_registry_id, compartment_id);
        System.out.println("Delete Artifact:" + status);
        // destroy stack
        CreateJobResponse destroyJobResponse = createDestroyJob(stack.getId());
        status = waitForJobCompleted(destroyJobResponse);
        System.out.println(status);
        System.out.println("Delete Stack:" + status);
      }

    }

    return status;
  }

  public String deleteArtifact(String artifact_registry_id, String compartment_id) {

    ArtifactsClient client = ArtifactsClient.builder().region(Region.US_PHOENIX_1).build(provider);
    ListGenericArtifactsRequest listGenericArtifactsRequest = ListGenericArtifactsRequest.builder()
        .compartmentId(compartment_id)
        .repositoryId(artifact_registry_id)
        .build();

    ListGenericArtifactsResponse response = client.listGenericArtifacts(listGenericArtifactsRequest);
    for (GenericArtifactSummary item : response.getGenericArtifactCollection().getItems()) {
      DeleteGenericArtifactRequest deleteGenericArtifactRequest = DeleteGenericArtifactRequest.builder()
          .artifactId(item.getId())
          .opcRequestId(UUID.randomUUID().toString()).build();
      DeleteGenericArtifactResponse deleteResponse = client.deleteGenericArtifact(deleteGenericArtifactRequest);
      int statusCode = deleteResponse.get__httpStatusCode__();
      if (statusCode < 200 || statusCode > 300) {
        return "FAILED";
      }
    }
    return "SUCCEDED";
  }

  public Map<String, String> getTerraformState(String stackId) throws IOException {
    Map<String, String> values = new HashMap<>();
    try {
      GetStackTfStateRequest getStackTfStateRequest = GetStackTfStateRequest.builder()
          .stackId(stackId)
          .opcRequestId(UUID.randomUUID().toString()).build();

      /* Send request to the Client */
      GetStackTfStateResponse response = client.getStackTfState(getStackTfStateRequest);

      // Parse JSON
      JsonParser jsonParser = Json.createParser(response.getInputStream());

      while (jsonParser.hasNext()) {
        JsonParser.Event next = jsonParser.next();
        if (next == JsonParser.Event.START_OBJECT) {
          JsonObject object = jsonParser.getObject();
          if (object.containsKey("outputs")) {
            String url = object.getJsonObject("outputs").getJsonObject("app_url").getString("value");
            values.put("url", url);
            System.out.println("Got url");
          }
          if (object.containsKey("resources")) {
            JsonArray resources = object.getJsonArray("resources");
            for (int i = 0; i < resources.size(); i++) {
              JsonObject resourceObject = resources.get(i).asJsonObject();
              if (resourceObject.getString("name").equals("application_repository")) {
                String id = resourceObject.getJsonArray("instances").get(0).asJsonObject().getJsonObject("attributes")
                    .getString("id");
                values.put("application_repository_id", id);
                System.out.println("Got application repository OCID");

                String compartment_id = resourceObject.getJsonArray("instances").get(0).asJsonObject()
                    .getJsonObject("attributes")
                    .getString("compartment_id");
                values.put("compartment_id", compartment_id);
                System.out.println("Got compartment OCID");
                break;
              }
            }
          }
        }
      }
      return values;
    } catch (Exception ex) {
      ex.printStackTrace();
      throw ex;
    }
  }

  public String checkUrl(String urlString) {
    try {
      URL url = new URL(urlString);
      HttpURLConnection connection = (HttpURLConnection) url.openConnection();
      connection.setRequestMethod("GET");
      int statusCode = connection.getResponseCode();
      if (statusCode < 200 || statusCode > 300) {
        System.out.println("Status code: " + statusCode);
        return "FAILED";
      }
      return "SUCCEDED";
    } catch (Exception ex) {
      ex.printStackTrace();
      return "FAILED";
    }
  }

  private String waitForJobCompleted(CreateJobResponse createJobResponse) {

    if (createJobResponse != null && createJobResponse.getJob() != null) {
      Job.LifecycleState state = createJobResponse.getJob().getLifecycleState();
      System.out.println("Job state : " + state.toString());

      while (state != Job.LifecycleState.Succeeded && state != Job.LifecycleState.Failed
          && state != Job.LifecycleState.Canceled) {
        try {
          TimeUnit.MINUTES.sleep(3);
          state = getJobStatus(createJobResponse.getJob().getId(), createJobResponse.getOpcRequestId());
        } catch (InterruptedException e) {
          System.out.println("Sleep error");
        }

        System.out.println("Job state : " + state.toString());
      }

      return state == Job.LifecycleState.Succeeded ? "SUCCEDED" : "FAILED";
    } else {
      return "FAILED";
    }
  }

  private CreateJobResponse createApplyJob(String stackId) {
    CreateJobDetails createJobDetails = CreateJobDetails.builder()
        .stackId(stackId)
        .displayName("app-stack-test-apply-job-" + UUID.randomUUID().toString())
        .operation(Operation.Apply)
        .jobOperationDetails(CreateApplyJobOperationDetails.builder()
            .executionPlanStrategy(ExecutionPlanStrategy.AutoApproved)
            .build())
        .build();

    CreateJobRequest createJobRequest = CreateJobRequest.builder()
        .createJobDetails(createJobDetails)
        .opcRequestId("app-stack-test-apply-job-request-" + UUID.randomUUID()
            .toString())
        .opcRetryToken("app-stack-test-apply-job-retry-" + UUID.randomUUID().toString())
        .build();

    /* Send request to the Client */
    return client.createJob(createJobRequest);

  }

  private CreateJobResponse createDestroyJob(String stackId) {
    CreateJobDetails createJobDetails = CreateJobDetails.builder()
        .stackId(stackId)
        .displayName("app-stack-test-destroy-job-" + UUID.randomUUID().toString())
        .operation(Operation.Destroy)
        .jobOperationDetails(CreateDestroyJobOperationDetails.builder()
            .executionPlanStrategy(DestroyJobOperationDetails.ExecutionPlanStrategy.AutoApproved)
            .build())
        .build();

    CreateJobRequest createJobRequest = CreateJobRequest.builder()
        .createJobDetails(createJobDetails)
        .opcRequestId("app-stack-test-destroy-job-request-" + UUID.randomUUID()
            .toString())
        .opcRetryToken("app-stack-test-destroy-job-retry-" + UUID.randomUUID().toString())
        .build();

    /* Send request to the Client */
    return client.createJob(createJobRequest);

  }

  private Job.LifecycleState getJobStatus(String jobId, String opcRequestId) {
    GetJobRequest getJobRequest = GetJobRequest.builder()
        .jobId(jobId)
        .opcRequestId(opcRequestId).build();

    GetJobResponse response = client.getJob(getJobRequest);
    return response.getJob() == null ? Job.LifecycleState.Failed : response.getJob().getLifecycleState();

  }

  private Stack createStack(String name, Map<String, String> variables) {

    String compartment_id = System.getenv(COMPARTMENT_SECRET);

    CreateStackDetails createStackDetails = CreateStackDetails.builder()
        .compartmentId(compartment_id)
        .displayName(LocalDateTime.now().toString() + name)
        .description(name)
        .configSource(CreateZipUploadConfigSourceDetails.builder()
            .zipFileBase64Encoded(zipFileBase64Encoded).build())
        .variables(variables)
        .build();

    CreateStackRequest createStackRequest = CreateStackRequest.builder()
        .createStackDetails(createStackDetails)
        .opcRequestId("app-stack-test-create-stack-request-"
            + UUID.randomUUID()
                .toString())
        .opcRetryToken("app-stack-test-create-stack-retry-token-" + UUID.randomUUID().toString())
        .build();

    /* Send request to the Client */
    CreateStackResponse response = client.createStack(createStackRequest);
    return response.getStack();

  }

}
