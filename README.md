Repository structure:
=====================

```
/modules    -> individual terraform modules
/examples   -> examples to terraform modules
```

Tasks
=====

Using TF v12, build a module to deploy a web application supporting following

* include VPC allowing future growth / scale
* include public (for ALB) & private subnet (for compute)
* assuming end users only contact albs and the ec2s are accessed for management purposes, design SG scheme supporting minimal set of ports
* ALB generated hostname will be used for requests to the public facing webapp
* an ASG utilizing latest AWS AMI should be used
* instances in the ASG
    * must contain both a root volume to store application / services
    * must contain secondary volume meant to store any log data bound in /var/log
    * must include web server of choice
* module should include a readme explaining the module inputs and any important design decisions you made which may assist in evaluation

All requirements in this task for configuring the OS should be defined in the launch configuration and/or the user data script ( no external tools like chef, puppet, etc. )

Module should not be tightly coupled to your AWS account, it should be designed so that it can be deployed to any arbitrary AWS account.

Extra Credits
-------------

* Ensure all data is encrypted at rest
    * devices are set to be encrypted
* Ideally, design the webservers so they can be managed without logging in with the root key
    * I didn't have time for that, there are several possible approaches as discussed in "Security"
* We should have some sort of alarm mechanism indicating whether application is having any issues
    * Health checks are configured to be from ALB to ASG, but some CloudWatch alarms could be set too. Also we could have some automatic reaction on the alarms.
* Configure autoscaling based on load
    * This is coupled with alarms. I would set ASG to scale with CPU metric up and down (above 70% and below 30%)
* You should assume that the webserver may receive high volumes of web traffic; you should appropriately manage the storaga / growth of logs
    * This really depends on how valuable the data is. If it is not, it could be just logrotated and kept for example last 7 days (or last x logs with limited size).
    If it was valuable, then it should be pused somewhere anyway. E.g. with filebeat.


Design considerations
=====================

Network
-------

The VPC with CIDR 10.0.0.0/16 accomodates for 65534 hosts and is divided into subnets in the following fashion:

* Public subnets: 10.0.1.0/24 (and onwards incrementing 3rd byte up to 9, up to 10.0.9.0/24)
* Compute subnets (private): 10.0.11.0/24 (and onwards incrementing 3rd byte up to 19, up to 10.0.19.0/24)

All the subnets have the same size, accomodating 254 hosts each, minus some AWS reserved addresses. The subnets past 10.0.20.0/24 can be used for e.g.
more compute resources or database resources.

The subnets where 3rd byte is divisible by 10 (10.0.0.0/24, 10.0.10.0/24) are reserved for VPC related/global services.

Naming convention:
* Public subnets: `public-<x>`
* Compute subnets: `compute-<x>`

where `<x>` stands for 3rd byte. Example: `10.0.1.0/24 -> public-1`. Subnets are assigned into AZs incrementally, in round robin fashion.
This is restarted for each group of subnets:
* `public-1 -> us-east-1a`, `public-2 -> us-east-1b`, ...
* `compute-11 -> us-east-1a`, ...

Security
--------

There are two security groups; first for ALB, allowing HTTP access on standard port to ALB. Second security group is used for the compute instances,
with allowed ingress from loadbalancer to the webserver port only, and SSH port from everywhere. Egress permitted everywhere.

This is of course not the final nor the best state. Future ideas:
* Request SSL certificate from ACM and redirect HTTP traffic to HTTPS on the ALB, but that would also require DNS name, which would not be for free.
* Tighten the security group egress rules, compute probably just to NAT gateway (SGs keep session reply traffic)
* Figure out a way to login to instances without SSH key (HashiCorp Boundary? LDAP? List of allowed users in TF deployed directly to access.conf?)
    * Systems Manager would be another option

How to run this module
======================

```
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
cd examples/webapp-alb
terraform init
terraform apply
```

Output will be the bastion host ip and ALB dns name with running application. You need to create the SSH key by yourself (can be tunelled through bastion to compute)

Future Ideas
============

* Enroll instances in Systems manager for patching and for the console
* I haven't touched IAM at all, instances should have their instance role, ALB should have it's policy, there should be something like a deployment role
* Terraform should have a shared state probably in S3 with DynamoDB lock
* There should be tests written in golang going alongside this module
* The module should be split into submodules, which would be used. For example VPC is a story of it's own
* ALB should be improved, currently there is just HTTP/1, access logs bucket is not deployed, and everything goes over HTTP. Port 80 should be redirected to 443 for HTTPS in ALB, certificate should be obtained from ACM.
This would of course require a DNS name (Route 53).
* Launch template could be used instead of launch configuration, bringing improvements such as template versioning and rolling deployments
* elastic scaling, but also instance refresh after fixed time period might be interesting
* depending on the state, spot instances might be used, but that may need some handoff. For example SQS queue and lifecycle hook.
* many, many more...
