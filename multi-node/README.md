**Splunk AWS CloudFormation Templates**
-----------------------------------

#####**Simple AWS CloudFormation templates for automated Splunk deployments.**


***Splunk License***<br>
Before getting started with the template configuration, you will need to make your Splunk license available via an http(s) download.  The simplest way to do this is to upload your license file to S3.  The following steps will guide you through that process.

 1. From the AWS Console, select "S3" under the "Storage & Content Delivery" heading.
 2. Click "Create Bucket" 
   3. (You can either select an existing bucket to upload to, or create a new one.  For this exercise, create a new bucket.)
 3. Name your bucket, and select your region.  In this example, I will use "bbartlett-splunk-config".  Your bucket name must be unique, and you should select the same region where you plan on deploying Splunk. ![enter image description here](https://s3-us-west-2.amazonaws.com/splk-bbartlett/splunk_newbucket.png)
 4. From the bucket list, select your new bucket name.
 5. Click "Upload" on the upper left of the page
 6. Click "Add Files"
 7. Select your license file.
 8. Click "Start Upload" on the lower right of the page.
 9. Once the file has finished uploading, it will be shown.   Select your license file, right click, and select"make public"
 10. Click the properties tab on the upper right.  Here you will find the URL for your license file.  This is the URL we will use in the template itself.  (e.g. https://s3-us-west-2.amazonaws.com/bbartlett-splunk-config/license) 

<br>
**Template Usage**
-----
This guide will show you how to launch a fully functioning Splunk deployment in just a few minutes.  Our templates require an AWS account with permission to create new VPCs and associated ACLs, create security groups, create elastic IP addresses, and launch instances.  If your account does not have these permissions, please consult with your AWS administrator.  These instructions assume that you have downloaded the template to your local machine.

There are two templates to choose from: splunk_simple_deployment.json and splunk_with_idc_cm_failover.json, and each of them provide a fully functional splounk deployment.  


## splunk_simple_deployment.json:
The instructions that follow will create a new VPC, with a single search head and up to 10 indexers.  There will be VPC network ACLs, security groups, and an elastic IP address created as well.  Each instance type will have the appropriate security group(s) attached.  All indexers will know their license server, and the search head will configure distributed search across all indexers.  The finished architecture, using default settings, will look like this:<br>
<img src=https://s3-us-west-2.amazonaws.com/splk-bbartlett/splunk_cf_arch.png width="510" height="500px">

If you're new to AWS and VPC, please take a quick look at their VPC documentation: http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html


 1. Visit the AWS CloudFormation console: https://console.aws.amazon.com/cloudformation
 2. Click "**Create Stack**"
 3. Under "Upload a template to Amazon S3" select "**Choose File**" and navigate to the template.
 4. Click "**Next**"
 4. "**Stack Name**" What would you like to name the collection of CloudFormation resources launched with this template?  The example will use "*cf-splunk-deployment*".
 5. "**Instance Type**" refers to the instance type for your indexers and search head.  We provide some guidance on instance types in our "Deploying Splunk Enterprise on AWS" technical brief.  You can find that brief here: https://www.splunk.com/content/dam/splunk2/pdfs/technical-briefs/deploying-splunk-enterprise-on-amazon-web-services-technical-brief.pdf
 6. "**KeyName**" refers to an existing EC2 key pair name that you will use to access the instances launched with the CloudFormation template.
     7. If you're unfamiliar with how to setup a key pair, please visit the AWS documentation page on EC2 key pairs: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html
 8. "**LicenseURL**" This is the URL to download your Splunk license.  It can be any http(s) endpoint, including the S3 configuration that was explained earlier in this document.  
 9. "**SplunkAdminPassword**" Self-explanatory - there is a minimum 8 character requirement when using this template, and alphanumeric characters only.
 10. **SplunkIndexerCount**" How many Splunk indexers would you like to create.  Please reference the technical brief linked earlier for guidance.  
 11. "**SplunkSubnetCIDR**" In the new VPC, dedicate this network address space for the Splunk cluster.  
 12. "**SSHLocation**" The IP range here will be added to the Security group to connect on port 22.  It's recommended that you make this range as narrow as reasonably possible.  If you must allow ssh from anywhere, use 0.0.0.0/0.  
 13. "**VPCCIDR**" The network address space for the new VPC.  We recommend that this is at least a /16 to make it very simple to add /24 subnets if expansion becomes necessary.


----------


When you've filled everything in, you should have a page that looks similar to this.  If that's right, click "**Next**"
![Splunk CloudFormation Stack](https://s3-us-west-2.amazonaws.com/splk-bbartlett/aws_stack.png)


----------


Your last consideration with this template is what Amazon calls tags.  (documentation link: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html) It's recommended, at minimum, to use at least one tag that makes it easy to search for your Splunk resources.  In this example, the key is "splunk-deployment" and the value is "CF-Oregon".  Once you've created your tags, click "**Next**" to review.

Provided everything looks OK here, click "**Create**" and your new Splunk deployment will be built in just a few minutes.

As the resources are created, they will show up on the "**Events**" tab of your CloudFormation stack.  
![CF Events](https://s3-us-west-2.amazonaws.com/splk-bbartlett/cf_events.png)

Once your new stack shows a status of "**CREATE_COMPLETE**" the resources have finished being provisioned.  About 90 seconds after the stack has completed building, the Splunk deployment should be fully functional and configured.

##splunk_with_idc_cm_failover.json:
The instructions for this template are essentially the same as the previous, with a couple of different fields to fill out.  

<img src=https://s3-us-west-2.amazonaws.com/splk-bbartlett/splunk_idc_shc_template.png width="510" height="500px">


This template will create a new VPC, with either a single search head or a search head cluster (SHC) with up to 10 nodes.  An indexer cluster (IDC) will also be provisioned with between 3 and 10 indexers.  The cluster master node will be deployed in an auto scaling group, which will automatically relaunch on a node faiulre.  Similar to the previous template, there will be VPC network ACLs, security groups, and an elastic IP address created.  Additionally, there are two elastic load balancers (ELB) createdEach instance type will have the appropriate security group(s) attached.  All indexers will know their license server, and the search head will configure distributed search across all indexers.


 1. Visit the AWS CloudFormation console: https://console.aws.amazon.com/cloudformation
 2. Click "**Create Stack**"
 3. Under "Upload a template to Amazon S3" select "**Choose File**" and navigate to the splunk_with_idc_cm_failover.json template.
 4. Click "**Next**"
 4. "**Stack Name**" What would you like to name the collection of CloudFormation resources launched with this template? 
 5. "**Instance Type**" refers to the instance type for your indexers and search head.  We provide guidance on instance types in both our ["Deploying Splunk Enterprise on AWS" technical brief](https://www.splunk.com/content/dam/splunk2/pdfs/technical-briefs/deploying-splunk-enterprise-on-amazon-web-services-technical-brief.pdf) and ["Splunk Enterprise on AWS: Deployment Guide"](https://www.splunk.com/pdfs/white-papers/splunk-enterprise-on-aws-deployment-guidelines.pdf)  
 6. "**KeyName**" refers to an existing EC2 key pair name that you will use to access the instances launched with the CloudFormation template.
     7. If you're unfamiliar with how to setup a key pair, please visit the AWS documentation page on EC2 key pairs: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html
 7. "**SHCCount**" If you'd like an SHC, how many peers for the cluster.  The default is 3, with a maximum of 10.
 8. "**SHCEnabled**" Would you like an SHC.  If "No" is selected, a single search head is deployed.
 9. "**SplunkIndexerCount**" How many Splunk indexers would you like to create.   
 10. "**SplunkLicenseBucket**" This template uses a more secure method for retrieving the Splunk license from S3 that our other templates will be migrated to.  This field represents the bucket name where the Splunk license is found.
 11. "**SplunkLicensePath**" The (optional path) and filename of the Splunk license file in the bucket defined previously.
 12. "**SplunkSubnet1CIDR**"  This template defines two Subnets across two separate AZs.  This is the first subnet.  
 13. "**SplunkSubnet2CIDR**"  This template defines two Subnets across two separate AZs.  This is the second subnet. 
 14. "**SSHLocation**" The IP range here will be added to the Security group to connect on port 22.  It's recommended that you make this range as narrow as reasonably possible.  If you must allow ssh from anywhere, use 0.0.0.0/0.  
 15. "**VPCCIDR**" The network address space for the new VPC.  We recommend that this is at least a /16 to make it very simple to add /24 subnets if expansion becomes necessary.

**Next Steps**
-----
To find the Splunk search head URL, click the "**Outputs**" tab of your stack.  Visit that URL, and use the credentials shown to log in.  

Next, you will need to know your indexer IP addresses, as you'll need to point your forwarders here to start indexing data.  The easiest way is via the [EC2 Console](https://us-west-2.console.aws.amazon.com/ec2).  From the EC2 Console, select "**Auto Scaling Groups**" and then select your Splunk autoscaling group from the list.  (The name will be in the format YOUR_STACK_NAME-SplunkIndexerNodesASG) From here, there is an indexer tab at the bottom of the page that will show you each indexer in your deployment.  You can click each indexer to get information about them , including both private and public IP addresses.  If you need to ssh to any of these machines, you will need to use the key pair that you created earlier, and log in as the user "ec2-user".  

**Help**
-----

 - If you have any problems or general questions, please file them on the issues page of this project: https://github.com/splunk/splunk-cloudformation-templates/issues







