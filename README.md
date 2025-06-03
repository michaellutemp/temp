This is the README.md

DevOps Engineer Home Assignment

Below are the steps, issues and decisions taken during the home assigment.

1. Basic Web Application

I started with the simlpy asking Google for the sample Flask app
The improvements were:
a. To listen on all interfaces (0.0.0.0)
b. To listen on port 8080 (the default is 5000, you cannot listen on 80 or any other privileged port because we will run conainter as non root).

2. Containerization

I provide two Dockerfiles:
a. Distroless image where I use multi stage build. I choose it as a default. It is more secure but has longer build time.
b. Python3 slim image. I keep this option in order to be able to debug the issues inside the container as it has bash. Althouth a lot of techiques exist to debug such images on modern k8s versions.
Note: from my experience I stopped using Alpine. Alpine musl is not 100% with glibc and therefore some applications can require software modifications which is not optimal for RnD. Before distroless images gained popularity I liked Ubuntu, they have quick CVE image updates.
I created ECR with defaults (in eu-central-1/Frankfurt).

3. CI/CD Pipeline for Application / Application Verification

The GitHub pipelne is pretty simple, although I failed many times on typos.
For this home assigment I trigger a pipelien on push to master, but the logic can be further customized.
I created GitHub secrets for AWS Credentials (access key id and secret access key).
I borrowed from someone a script that updates git tag and also tags the docker image. It uses git command, I allowed Workflow and Actions permissions.
During pipeline run I saw some warnings and I upgraded some actions to the newer versions when it was applicable.
I used helm chart created by helm create command and customized it a bit for my needs. Helm is preferred over k8s manifests, it allows upgrades tracking/rollback etc.. The removal and customization is simpler.
I apply helm command over helm chart that resides in the code. In general we can also keep helm charts in OCI registry.

The last step in the pipeline runs kubectl get all resources in the myapp namespace.
From there you can see a status of the running pods and the URL of the Classic Load Balancer.
Open a browser or run cURL with the CLB IP (do remember to append a port if different from 80).

4. Infrastructure Provisioning / Documentation & Verification

The structure of the project:
build              -- a script for some git/docker tags used in the pipeline 
chart              -- helm chart for the myapp
Dockerfile         -- main Dockerfile (there is also another Dockerfile with different build)
README.md          -- this file
source             -- source code for the Flask application
terraform/s3       -- Terraform code for S3 bucket which is used as TF Backend
terraform/eks      -- Terraform code for the EKS

Steps to provision infrastructure (and test application locally).
Make sure you install the latest versions of AWS CLI v2, Helm, and your Kubectl aligns with the K8S version.
I failed to connect to the EKS after installation because I had old AWS CLI v2 and it created bad eks config file.
After AWS CLI v2 upgrade and refetching eks config file, I was able to connect. Lost 15 minutes here trying to find a solution.
Old Helm version generates sample helm chart with old APIs. Make sure not to lose here time.
Install the latest Terraform binary. (In this assigment we do not need specific version or openTofu).

a. Configure your AWS CLI v2 by running `aws configurea`, specify your credentials and the region.
Verify that you can connect with simple command (for example `aws s3 ls`).

b. Go to the terraform/s3 directory and run `terraform init`. Verify your region, choose your desired S3 bucket name, check if tags are ok for you. Run `terraform apply` to create the bucket (answer yes when asked).
Note: The terraform state file is created locally. You can in general migrate it to keep it in the created bucket. I do not see much sense in it but I provide a code. Simply uncomment the lines for S3 backend, and run `terraform init`. Terraform will ask you if you want to migrate the backend, answer yes if you indeed want to migrate the backend.

c. Go to the terraform/eks firectory and run `terraform init`.
The files 0-locals.tf and 1-providers.tf contain information about region, name, zones, s3 backend, eks version.
Adust them if necessary.
Run the `terraform apply` to create VPC and EKS.
VPC has 2 private and 2 public networks, we create one NAT GW (to reduce costs).

NOTE about implementation: I wanted to use AWS VPC and EKS official modules but decided to use AWS Provider files. For this task it is easier to track what is done. Also it seems I do not have sufficient IAM permissions to create policy, delete role assigment, etc... so it is a bit easier to remove unnecessary things when AWS TF Provider is used and not modules.
Because of the IAM permissions I could not install things that are in general needed in production like EBS CSI driver, EFS driver, Auto Scaler, etc, ALC and Ingress NGINX...
For this task a managed group with one node is enough. We can use LoadBalancer Service type and it will create CLB, good enough for this assigment


BONUS:
When installing EKS, I also installed metrics-server needed by HPA.
I did not use a benchmarking tool (it is possible from outside the cluster and it is possible to run some ubuntu pod inside the myapp namespace and run load test from there). Instead I simply configured HPA to scale on low CPU consumption. As the output below shows, the scaling works.

kubectl get all --namespace myapp
NAME                         READY   STATUS    RESTARTS   AGE
pod/myapp-54f858d947-8lbjf   1/1     Running   0          4m31s
pod/myapp-54f858d947-v5dcz   1/1     Running   0          3m

NAME            TYPE           CLUSTER-IP       EXTERNAL-IP                                                                  PORT(S)          AGE
service/myapp   LoadBalancer   172.20.112.155   ae181050e17cd4acc8316efa9fbfd4d9-1052897149.eu-central-1.elb.amazonaws.com   8080:30148/TCP   4m31s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/myapp   2/2     2            2           4m31s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/myapp-54f858d947   2         2         2       4m31s

NAME                                        REFERENCE          TARGETS                       MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/myapp   Deployment/myapp   cpu: 5%/5%, memory: 31%/80%   1         3         2          4m31s
