# App Stack for Java tutorial

In this tutorial we'll deploy a sample SpringBoot application using the stack.

## 1. Prepare the code repository

In GitHub, fork the following repo: [oci-react-samples](https://github.com/oracle/oci-react-samples/tree/spring-appstack). Note that we will only used the branch "spring-appstack" for this tutorial.

![](./screenshots/1_springbootrepo.png)

If you don't already have Personal Token, create one and note it down. We'll use it in the next step.

![](./screenshots/2_githubtoken.png)

## 2. Create the compartment, vault and dynamic group in OCI

### Compartment

Create a compartment called "appstack". All the resources created by the stack will be created under this compartment. Note the compartment's OCID as it will be used later.

![](./screenshots/3_compartment.png)

### Create a vault

Create a vault called "appstack":

![](./screenshots/4_vault.png)


Add a key called "appstack":

![](./screenshots/5_vault_createkey.png)

 ... and add the GitHub token as a secret.

![](./screenshots/6_vault_createsecret.png)

### Create the dynamic group

This dynamic group called "appstack" will match the DevOps resources needed to execute the build pipeline. This is where the compartment's OCID is needed:

```
All {resource.compartment.id = 'ocid1.compartment.oc1..............', Any {resource.type = 'devopsdeploypipeline', resource.type = 'devopsbuildpipeline', resource.type = 'devopsrepository', resource.type = 'devopsconnection', resource.type = 'devopstrigger'}}
```

ocid1.compartment.oc1..aaaaaaaajdsrhcul44hm25l3covur5hjs3sfcaek26inmjkntriwm2ee23ua

![](./screenshots/7_dynamicgroup.png)

### Create the policy for this dynamic group

Create a new policy under the "appstack" compartment called "appstack"
```
Allow dynamic-group appstack to read secret-family in compartment appstack
Allow dynamic-group appstack to read devops-family in compartment appstack
```

![](./screenshots/8_policy.png)

## Create project in DevOps

### Create a new project 

Create a new DevOps project called "appstacktutorial". This involves creating a topic "appstacktutorial".
![](./screenshots/9_devopsproject.png)

Be sure to turn on logging:

![](./screenshots/10_devopslogging.png)

### Setup the connection to GitHub

![](./screenshots/11_externalconnection.png)

![](./screenshots/12_validateexternalconnection.png)

### Mirror the repo

![](./screenshots/13_createrepo.png)
![](./screenshots/14_mirrorrepo.png)

Your repo should now be created. Note its OCID as it will be used later.
![](./screenshots/15_repo.png)

## Configure the stack

Go to the ![App Stack Product page](https://github.com/oracle-quickstart/appstack) and click on the "Deploy" button:

![](./screenshots/16_stackbutton.png)
![](./screenshots/17_createstack.png)
![](./screenshots/18_generalconfig.png)
![](./screenshots/19_appconfig.png)
![](./screenshots/20_apm.png)
![](./screenshots/21_db.png)
![](./screenshots/22_vault.png)
![](./screenshots/23_url.png)
![](./screenshots/24_network.png)
