# Splunk AWS CloudFormation #

Easy-to-use AWS CloudFormation templates to deploy a pre-configured Splunk distributed cluster on AWS.

## Benefits ##

* Incorporates Splunk **best practices** for operations and administration
* **Hides all complexity** behind setting up distributed Splunk infrastructure
* **Extensible** and **customizable** templates to fit custom needs
* **Accelerates** test drive & deployment time down to minutes

## Usage ##

The following Getting Started Guides walk you through launching your own fully functional Splunk cluster (1 search head, N indexers) in less than 30 min.
You need to use an existing AWS account, and you have the choice between using either a GUI or a CLI. At the end of the guide, you will be able to access your new dedicated Splunk servers via web browser or SSH. You'll also receive a list of IPs for your Splunk Indexers which you can use to configure your Splunk Forwarders `outputs.conf` to start sending data immediately.

## Getting Started using AWS Console ##
The following is a step-by-step guide to create your own Splunk cluster using AWS CloudFormation console.<br/>

### Step 1: Setup Virtual Private Cloud (one-time setup) ###
This one-time step provisions your new VPC with proper connectivity & needed resources, including a NAT instance, a Bastion leap host, and a Chef server with all necessary recipes

1. Open Amazon CloudFormation console at https://console.aws.amazon.com/cloudformation
2. Click **Create Stack** button. In the **Create A New Stack** dialog, provide a name for your stack. For Template Source, you can select either:
  * **Upload template file** and browse to your local copy of [vpc_master.template](../master/templates/vpc_master.template)<br>
  OR,
  * **Provide an S3 URL to template** and paste the appropriate S3 link for `vpc_master.template` depending on your currently selected AWS region. For example, for the `us-west-1` region:<br>
`http://splunk-cloud-us-west-1.s3.amazonaws.com/cloudformation-templates/vpc_master.template`
2. Click **Next Step** button. In the **Specify Parameters** dialog, enter stack parameters, namely:
  * In the **KeyName** field, specify an EC2 keypair to access the Bastion host. If you don't have an EC2 keypair already, refer to [AWS EC2 keypair guide](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
  * (Optional) In the **BastionKeyName**, specify a unique EC2 keypair to access private instances from the Bastion host. You can leave the default value as is.
  * (Optional) In the **InstanceType**, specify instance type of Chef server. You can leave default value as is.
  * (Optional) In the **SSHFrom** field, specify the public IP address range that can SSH into your public instances. You can leave default value as is.
3. Check "**I acknowledge that this template may create IAM resources**", then Click **Next Step** button.
4. (Optional) In the **Options** dialog, add tags to your stack.
5. Click **Next Step** button. In the **Review** step, ensure all parameters are correct, and click **Create**. Grab a coffee and come back in ~20 min when status of your parent stack shows `CREATE_COMPLETE`. Note this is a one-time setup.
5. Select **Outputs** tab of this newly created stack and record the VPC ID, Public Subnet IDs, as well as Bastion's public IP and Chef server's private IP:
<div>
    <img src="https://raw.githubusercontent.com/splunk/splunk-aws-cloudformation/master/docs/vpc_master_output.png"/>
</div>

### Step 2: Create Splunk Cluster ###
Now you're ready to add a new Splunk cluster to your VPC including cluster master node, search head and N indexer peers

1. Click **Create Stack** button. In the **Create A New Stack** dialog, provide a name for your stack. For Template Source, you can select either:
  * **Upload template file** and browse to your local copy of [splunk_cluster.template](../master/templates/splunk_cluster.template)<br>
  OR,
  * **Provide an S3 URL to template** and paste the appropriate S3 link for `splunk_cluster.template` depending on your currently selected AWS region. For example, for the `us-west-1` region:<br>
`http://splunk-cloud-us-west-1.s3.amazonaws.com/cloudformation-templates/splunk_cluster.template`
2. Click **Next Step** button. In the **Specify Parameters** dialog, enter stack parameters, namely:
  * In the **VpcId** field, enter VPC ID from previous stack's outputs.
  * In the **SubnetId** field, enter Public Subnet ID from previous stack's outputs.
  * In the **KeyName** field, enter value of BastionKeyName from previous stack's output. You can leave default value as is if you have not provided a custom **BastionKeyName** in previous stack parameters.
  * In the **ChefServerIP** field, enter Chef Private IP from previous stack's outputs.
  * (Optional) In the **ClusterSize** field, specify your deployment size between `small`, `medium`, and `large` (3, 5, 9 indexers respectively). You can leave default value as is.
  * (Optional) In the **InstanceType** field, specify the instance type for Splunk servers. You can leave default value as is.
  * (Optional) In the **CIDRBlock** field, specify the public IP address range that is allowed to send data to this cluster. You can leave default as is.
  * (Optional) In the **SplunkLicenseBucket** and **SplunkLicensePath** field, enter the private S3 bucket where you have your Splunk License along with the License file path. These fields can be left empty.
3. Check "**I acknowledge that this template may create IAM resources**", then Click **Next Step** button.
4. (Optional) You can Bring Your Own License by entering a private s3 bucket (accessible by AWS account holder) and path to license file
5. (Optional) In the **Options** dialog, add tags to your stack.
6. Click **Next Step** button. In the **Review** step, ensure all parameters are correct, and click **Create**. Wait for ~10 min until status of your parent stack shows `CREATE_COMPLETE`.
7. Select **Outputs** tab of this newly created stack and record the public IPs of cluster master, cluster search head, and list of cluster peers:
<div>
    <img src="https://raw.githubusercontent.com/splunk/splunk-aws-cloudformation/master/docs/splunk_cluster_output.png"/>
</div>
8. Type IP of cluster master in your favorite browser, and navigate to Settings >> Clustering to see all components of your newly created Splunk cluster. In few minutes, the cluster will become valid & complete as soon as initial index replication completes:
<div>
    <img src="https://raw.githubusercontent.com/splunk/splunk-aws-cloudformation/master/docs/splunk_clustering_snapshot.png"/>
</div>

Congratulations! You now have a new fully functional distributed Splunk cluster on AWS ready for your data!<br/>
Here are the various EC2 instances that you should see, say with a `large` deployment (9 indexers):
<div>
    <img src="https://raw.githubusercontent.com/splunk/splunk-aws-cloudformation/master/docs/ec2_instances_snapshot.png"/>
</div>

## Getting Started using AWS CLI ##
The following is a step-by-step guide to create your own Splunk cluster using AWS Command Line Interface.<br/>
First, you must install and configure [AWS CLI tool](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) if you haven't already.


### Step 1: Setup Virtual Private Cloud (one-time setup) ###
This one-time step provisions your new VPC with proper connectivity & needed resources, including a NAT instance, a Bastion leap host, and a Chef server with all necessary recipes

1. Create your master VPC stack, say `customerVPC-test`. Make sure to replace the parameter placeholders below with your desired values. Refer to template content for specific parameter description. Below is an example of creating the stack in `us-west-1` region. Notice that `--template-url` specifies the template version located in the S3 bucket of the same region in which you want to create this new stack:

        $ aws cloudformation create-stack --stack-name customerVPC-test \
        --template-url http://splunk-cloud-us-west-1.s3.amazonaws.com/cloudformation-templates/vpc_master.template \
        --parameters ParameterKey=KeyName,ParameterValue=<MyKeyName> \
                     ParameterKey=BastionKeyName,ParameterValue=<MyBastionKeyName> \
                     ParameterKey=InstanceType,ParameterValue=<MyInstanceType> \
                     ParameterKey=SSHFrom,ParameterValue=<SSHFrom> \
        --capabilities "CAPABILITY_IAM"

    Note: You could also point to your local copy of [vpc_master.template](../master/templates/vpc_master.template) using `--template-body` instead of `--template-url` in the previous command:

        --template-body file:///home/local/splunk-cloudformation/templates/vpc_master.template \

2. Check on stack status by retrieving list of stack events as follows (`vpc_master` stack completes in ~20 min):

        $ aws cloudformation describe-stack-events --stack-name customerVPC-test

    When stack is complete, the last event should display `CREATE_COMPLETE` status associated with 'customerVPC-test' logical resource:

    ```javascript
{
    "StackEvents": [
        {
            "StackId": "arn:aws:cloudformation:us-west-1:931162419331:stack/customerVPC-test/f06ecc70-ae1b-11e3-b0cf-50fa003f9896", 
            "EventId": "7baf8840-ae1e-11e3-94b6-50fa00441096", 
            "ResourceStatus": "CREATE_COMPLETE", 
            "ResourceType": "AWS::CloudFormation::Stack", 
            "Timestamp": "2014-03-17T21:52:49.618Z", 
            "StackName": "customerVPC-test", 
            "PhysicalResourceId": "arn:aws:cloudformation:us-west-1:931162419331:stack/customerVPC-test/f06ecc70-ae1b-11e3-b0cf-50fa003f9896", 
            "LogicalResourceId": "customerVPC-test"
        }, 
        ....
    ]
}
    ```

3. When stack is complete, retrieve its outputs and record the VPC ID, Public Subnet IDs, as well as Bastion's public IP and Chef server's private IP:

        $ aws cloudformation describe-stacks --stack-name customerVPC-test

    You should get something similar to:

    ```javascript
    {
        "Stacks": [
            {
                "StackId": "arn:aws:cloudformation:us-west-1:931162419331:stack/customerVPC-test/f06ecc70-ae1b-11e3-b0cf-50fa003f9896", 
                "Description": "",
                "Parameters": [
                ...
                ], 
                "Tags": [], 
                "Outputs": [
                    { "Description": "VPC ID of newly created VPC", "OutputKey": "VpcID", "OutputValue": "vpc-cb677ba9" }, 
                    { "Description": "Public subnet ID", "OutputKey": "PublicSubnetID", "OutputValue": "subnet-24c02541" }, 
                    { "Description": "Private Subnet ID", "OutputKey": "PrivateSubnetID", "OutputValue": "subnet-27c02542" }, 
                    ...
                    { "Description": "Bastion Host Public IP address", "OutputKey": "BastionPublicIp", "OutputValue": "54.193.109.23" }, 
                    { "Description": "Bastion Internal KeyPair name", "OutputKey": "BastionKeyName", "OutputValue": "bastion_key" },
                    { "Description": "Chef Server Private IP address", "OutputKey": "ChefServerPrivateIp", "OutputValue": "192.168.10.117" }
                ], 
                "StackStatusReason": null, 
                "CreationTime": "2014-03-17T21:34:37.298Z", 
                "Capabilities": [
                    "CAPABILITY_IAM"
                ], 
                "StackName": "customerVPC-test", 
                "NotificationARNs": [], 
                "StackStatus": "CREATE_COMPLETE", 
                "DisableRollback": false
            }
        ]
    }
    ```

### Step 2: Create Splunk Cluster ###
Now you're ready to add a new Splunk cluster to your VPC including cluster master node, search head and N indexer peers

1. Create your Splunk cluster stack using the outputs from previous stack as parameters: the VPC ID, the Public Subnet ID, Chef server's private IP, and newly created Bastion key for KeyName. Below is an example of creating the stack in `us-west-1` region using outputs from `customerVPC-test` stack above. Notice that `--template-url` specifies the template version located in the S3 bucket of the same region in which you want to create this new stack:

        $ aws cloudformation create-stack --stack-name customerVPC-test-SplunkCluster \
        --template-url http://splunk-cloud-us-west-1.s3.amazonaws.com/cloudformation-templates/splunk_cluster.template
        --parameters ParameterKey=VpcId,ParameterValue=vpc-cb677ba9 \
                     ParameterKey=SubnetId,ParameterValue=subnet-24c02541 \
                     ParameterKey=ClusterSize,ParameterValue=<MyClusterSize> \
                     ParameterKey=KeyName,ParameterValue=bastion_key \
                     ParameterKey=InstanceType,ParameterValue=<MyInstanceType> \
                     ParameterKey=CIDRBlock,ParameterValue=<CIDRBlock> \
                     ParameterKey=ChefServerIP,ParameterValue=192.168.10.117 \
                     ParameterKey=SplunkLicensePath,ParameterValue="" \
                     ParameterKey=SplunkLicenseBucket,ParameterValue="" \
        --capabilities "CAPABILITY_IAM"

    Note: You could also point to your local copy of [splunk_cluster.template](../master/templates/splunk_cluster.template) using `--template-body` instead of `--template-url` in the previous command:

        --template-body file:///home/local/splunk-cloudformation/templates/splunk_cluster.template \

2. (Optional) You can Bring Your Own License by entering a private s3 bucket (accessible by AWS account holder) and path to license file as values for `SplunkLicensePath` and `SplunkLicenseBucket`.

3. Similarly to previous `vpc_master` stack, check status of new `splunk_cluster` stack by retrieving list of stack events as follows (`splunk_cluster` stack completes in ~10 min):

        $ aws cloudformation describe-stack-events --stack-name customerVPC-test-SplunkCluster

4. Similarly to previous `vpc_master` stack, when stack is complete, retrieve its outputs and record the public IPs of cluster master, cluster search head, and list of cluster peers:

        $ aws cloudformation describe-stacks --stack-name customerVPC-test-SplunkCluster

5. Type IP of cluster master in your favorite browser, and navigate to Settings >> Clustering to see all components of your newly created Splunk cluster. In few minutes, the cluster will become valid & complete as soon as initial index replication completes.

## Template Reference List ##

| Template | Description | Launch in US East Region
| --- | --- |:---:
| [vpc_master.template](../master/templates/vpc_master.template) | **Master** CF template to create a VPC with Public and Private subnets in a single AZ. This includes 1) a NAT instance in Public subnet to enable Private subnet instances to access the Internet, 2) a Bastion host micro instance in Public subnet and 3) a Chef server in Private subnet. Uses sub-templates `vpc_two_subnets.template`, `bastion_host.template`, `chef_server.template` | [Launch Stack][vpc_master_us_east_1]
| [splunk_cluster.template](../master/templates/splunk_cluster.template) | **Master** CF template to create Splunk cluster of 1 master node, 1 search head and the option of 3, 5 or 9 peer nodes in a specified VPC. Uses sub-stacks `splunk_server.template` and `splunk_server_with_license.template` | [Launch Stack][splunk_cluster_us_east_1]
| [vpc_two_subnets.template](../master/templates/vpc_two_subnets.template) | CF template to create a VPC with Public and Private subnets in a single AZ. This includes a NAT instance in Public subnet to enable Private subnet instances to access the Internet. Used by `vpc_master.template` | [Launch Stack][vpc_two_subnets_us_east_1]
| [splunk_server.template](../master/templates/splunk_server.template) | CF template to add a Splunk server to specified VPC and subnet given a Splunk role: cluster-master, cluster-peer or cluster-search-head. Used by `splunk_cluster.template` | [Launch Stack][splunk_server_us_east_1]
| [splunk_server_with_license.template](../master/templates/splunk_server_with_license.template) | CF template equivalent to `splunk_server.template` with the addition of specifying a license from a private S3 bucket, for example when creating a splunk license master. Used by `splunk_cluster.template` | [Launch Stack][splunk_server_with_license_us_east_1]
| [splunk_server_via_chef_solo.template](../master/templates/splunk_server_via_chef_solo.template) | CF template equivalent to `splunk_server.template` but without the need for a separate Chef Server. Does does not support roles yet | [Launch Stack][splunk_server_via_chef_solo_us_east_1]
| [bastion_host.template](../master/templates/bastion_host.template) | CF template to add a Bastion host micro instance to specified VPC. It creates a new EC2 keypair to access further instances. Used by `vpc_master.template` | [Launch Stack][bastion_host_us_east_1]
| [chef_server.template](../master/templates/chef_server.template) | CF template to add a Chef server to specified VPC. It references remote cookbooks and config files stored in public S3 bucket https://splunk-cloud.s3.amazonaws.com/. Used by `vpc_master.template` | [Launch Stack][chef_server_us_east_1]

[vpc_master_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~VPC-Master|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/vpc_master.template "Launch VPC Master Stack"
[splunk_cluster_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Splunk-Cluster|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/splunk_cluster.template "Launch Splunk Cluster Stack"
[vpc_two_subnets_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~VPC-Two-Subnets|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/vpc_two_subnets.template "Launch VPC Two Subnets Stack"
[splunk_server_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Splunk-Server|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/splunk_server.template "Launch Splunk Server Stack"
[splunk_server_with_license_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Splunk-Server-With-License|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/splunk_server_with_license.template "Launch Splunk Server With License Stack"
[splunk_server_via_chef_solo_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Splunk-Server-Via-Chef-Solo|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/splunk_server_via_chef_solo.template "Launch Splunk Server Via Chef Solo Stack"
[bastion_host_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Bastion-Host|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/bastion_host.template "Launch Bastion Host Stack"
[chef_server_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Chef-Server|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/chef_server.template "Launch Chef Server Stack"

## TODOs ##

* Support Search Head Pooling to go from 1:N searcher/indexer to N:N searcher/indexer topology
* Add HA to potential single points of failure such as Cluster Master, License Master or Chef Server
* Add Auto Scale to Splunk Indexer and/or Search Head tier
* Apply recommended EC2 instance type & proper sizing
* Support Splunk AMIs
* Support Windows AMIs
* More testing

## Known Issues & Caveats ##

### Using same VPC stack for successive Splunk Cluster creations ###

As mentioned above, creating VPC with Chef (Step 1) is meant to be a one-time setup. You can create and teardown Splunk Clusters (Step 2) as many times as you want using the same VPC and keeping the same Chef server. However the only caveat is you must reset the internal state of Chef. In order to do so:

1. SSH to Bastion host using the keypair you specified in Step 1:

        $ ssh -i ~/.ssh/<MyKeyName>.pem ec2-user@<BastionHostPublicIP>

2. SSH to Chef server from Bastion Host using the keypair created by Bastion host in Step 1:

        $ ssh -i ~/.ssh/<MyBastionKeyName>.pem ec2-user@<ChefServerPrivateIP>

3. Reset Chef state by deleting all Splunk-related clients & nodes added in Step 2:

        $ sudo /usr/local/bin/knife node bulk delete "ip-*"
        Are you sure you want to delete these nodes? (Y/N) Y
        $ sudo /usr/local/bin/knife client bulk delete "ip-*"
        Are you sure you want to delete these clients? (Y/N) Y

### Bringing your own License (BYOL) ###

As mentioned above, you can optionally provide you own license in Step 2. Currently there is an intermittent bug with Splunk's linking to license master which occurs during machine bootstrap (only applicable when providing a license).


## Support ##

1. Splunk CloudFormation templates will not be Splunk supported
2. Help can be found through the broader community at [Splunk Answers](http://answers.splunk.com/)
3. Issues should be filed here: https://github.com/splunk/splunk-cloudformation/issues

## Additional Info ##

* Splunk Chef Cookbook: While AWS Cloudformation is used to launch and connect various AWS resources, Chef recipes for Splunk are used to provision the deployed machines based on corresponding role such as Splunk indexer, search head, etc. For more info, see [Splunk Cookbook](https://github.com/rarsan/splunk_cookbook) a fork from the great work by [BestBuy.Com](https://github.com/bestbuycom/splunk_cookbook)

* Splunk Cluster & Index Replication: The above templates deploy Splunk in a cluster topology to achieve data availability & recovery. For more info, see [Basic Cluster Architecture](http://docs.splunk.com/Documentation/Splunk/latest/Indexer/Basicclusterarchitecture) in Splunk Enterprise guides

## License ##

The Splunk AWS CloudFormation is licensed under the Apache License 2.0. Details can be found in the file LICENSE.
