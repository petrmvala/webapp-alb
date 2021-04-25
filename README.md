----------------------------------------------------------------------------------------------------
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
* Ideally, design the webservers so they can be managed without logging in with the root key
* We should have some sort of alarm mechanism indicating whether application is having any issues
* Configure autoscaling based on load
* You should assume that the webserver may receive high volumes of web traffic; you should appropriately manage the storaga / growth of logs


----------------------------------------------------------------------------------------------------

Design considerations
=====================

Network
-------

The VPC with CIDR 10.0.0.0/16 accomodates for 65534 hosts and is divided into subnets in the following fashion:

Public subnets: 10.0.1.0/24 (and onwards incrementing 3rd byte up to 9, up to 10.0.9.0/24)
Compute subnets (private): 10.0.11.0/24 (and onwards incrementing 3rd byte up to 19, up to 10.0.19.0/24)

All the subnets have the same size, accomodating 254 hosts each, minus some AWS reserved addresses. The subnets past 10.0.20.0/24 can be used for e.g. more compute resources or database resources.

The subnets where 3rd byte is divisible by 10 (10.0.0.0/24, 10.0.10.0/24) are reserved for VPC related/global services.

Naming convention:
Public subnets: `public-<x>`
Compute subnets: `compute-<x>`

where `<x>` stands for 3rd byte. Example: `10.0.1.0/24 -> public-1`.
