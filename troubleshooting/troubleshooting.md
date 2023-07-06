# Troubleshooting

This document lists the common errors seen when using the stack.

## The job failed due to an error in the Terraform configuration. To troubleshoot this issue, view the job log.

![](./screenshots/1_statefailed.png)

If this error shows up at the end of the stack execution

```
Error: During creation, Terraform expected the resource to reach state(s): SUCCEEDED, but the service reported unexpected state: FAILED.
  with oci_devops_build_run.create_docker_image[0],
  on devops.tf line 219, in resource "oci_devops_build_run" "create_docker_image" 
 219: resource "oci_devops_build_run" "create_docker_image" {
```

![](./screenshots/2_logerror.png)

This indicates that the build pipeline failed. Go to the build pipeline log to see the error. In this case the git project branch was not found:

![](./screenshots/3_buildpipelinelog.png)

