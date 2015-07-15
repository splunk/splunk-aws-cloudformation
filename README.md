# Splunk AWS CloudFormation #

Easy-to-use AWS CloudFormation templates to deploy a pre-configured Splunk distributed cluster on AWS.

## Benefits ##

* Incorporates Splunk **best practices** for operations and administration
* **Hides all complexity** behind setting up distributed Splunk infrastructure
* **Extensible** and **customizable** templates to fit custom needs
* **Accelerates** test drive & deployment time down to minutes

## Usage ##

The following Getting Started Guides walk you through launching your own fully functional Splunk cluster (1 search head, N indexers) in about 20 min.
You need to use an existing AWS account, and you have the choice between using either a GUI or a CLI. At the end of the guide, you will be able to access your new dedicated Splunk servers via web browser or SSH. You'll also receive a list of IPs for your Splunk Indexers which you can use to configure your Splunk Forwarders `outputs.conf` to start sending data immediately.

## Create Splunk Cluster using AWS Console ##
The following is a step-by-step guide to create your own Splunk cluster using AWS CloudFormation console.<br/>

A single template will provision your new distributed Splunk cluster in a new VPC with a bastion host.

1. Open Amazon CloudFormation console at https://console.aws.amazon.com/cloudformation
2. Click **Create Stack** button. In the **Create A New Stack** dialog, provide a name for your stack. For Template Source, you can select either:
  * **Upload template file** and browse to your local copy of [master.template](../master/templates/master.template)<br>
  OR,
  * **Provide an S3 URL to template** and paste the appropriate S3 link for `master.template` depending on your currently selected AWS region. For example, for the `us-west-1` region:<br>
`http://splunk-cloud-us-west-1.s3.amazonaws.com/cloudformation-templates/master.template`
2. Click **Next Step** button. In the **Specify Parameters** dialog, enter stack parameters, namely:
  * For **KeyName** field, specify an EC2 keypair to access the Bastion host. If you don't have an EC2 keypair already, refer to [AWS EC2 keypair guide](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
  * For **BastionKeyName**, specify a unique EC2 keypair to access private instances from the Bastion host. You can leave the default value as is.
  * For **ClusterSecurityKey** field, specify security key which will be used to authenticate traffic between cluster nodes. You can leave default value as is.
  * For **ClusterSize** field, specify your deployment size between `small`, `medium`, and `large` (3, 5, 9 indexers respectively). You can leave default value as is.
  * For **InstanceType**, specify instance type for Splunk servers. You can leave default value as is.
  * For **SSHFrom**, specify the public IP address range that can SSH into your Bastion host. By default, Bastion host can be accessed from anywhere using **KeyName** keypair.
  * For **CIDRBlock**, specify the public IP address range that is allowed to send data to this cluster. By default, data can be received from anywhere.
  * (Optional) For **HostedZoneName**, enter a Route 53 Hosted Zone name from which DNS records set will be created to point to new cluster master, search heard, and indexer tier. If Left empty, no DNS records will be created.
  * (Optional) For **Subdomain**, enter an optional subdomain to use before the Hosted Zone domain.
  * (Optional) Through **SplunkLicenseBucket** and **SplunkLicensePath** fields, you can Bring Your Own License by entering a private S3 Bucket (accessible by AWS account holder) and path to license file respectively.
3. (Optional) In the **Options** dialog, add tags to your stack.
4. Click **Next Step** button. In the **Review** step, ensure all parameters are correct, and check "**I acknowledge that this template might cause AWS CloudFormation to create IAM resources.**".
5. Click **Create** button. Grab a coffee and come back in ~20 min when status of your parent stack shows `CREATE_COMPLETE`.
6. Select **Outputs** tab of this newly created stack and note the VPC ID, Public Subnet ID, Bastion's public IP as well as all Cluster node IPs - and optionally URL for Cluster Master, Search Head and Indexer Tier if **HostedZoneName** was set:
<div>
    <img src="https://raw.githubusercontent.com/splunk/splunk-aws-cloudformation/master/docs/master_output.png"/>
</div>

7. Type Cluster Master's IP (or URL, if HostedZoneName set, pending DNS propagation) in your favorite browser, and navigate to Settings >> Clustering to see all components of your newly created Splunk cluster. In few minutes, the cluster will become valid & complete as soon as initial index replication completes:
<div>
    <img src="https://raw.githubusercontent.com/splunk/splunk-aws-cloudformation/master/docs/splunk_clustering_snapshot.png"/>
</div>

Congratulations! You now have a new fully functional distributed Splunk cluster on AWS ready for your data!<br/>
Here are the various EC2 instances that you should see, say with a `large` deployment (9 indexers):
<div>
    <img src="https://raw.githubusercontent.com/splunk/splunk-aws-cloudformation/master/docs/ec2_instances_snapshot.png"/>
</div>

Note that you can re-use the same VPC from the above master stack, to add as many Splunk cluster stacks as needed by directly using [splunk_cluster.template](../master/templates/splunk_cluster.template) template, and following the same steps as above. Make sure to specify the outputs VPC ID and Public Subnet ID of above master stack, as parameters for Splunk cluster stacks.

## Create Splunk Cluster using AWS CLI ##
The following is a step-by-step guide to create your own Splunk cluster using AWS Command Line Interface.<br/>
First, you must install and configure [AWS CLI tool](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) if you haven't already.

A single template will provision your new distributed Splunk cluster in a new VPC with a bastion host.

1. Create your master VPC stack, say `customerVPC-test`. Make sure to replace the parameter placeholders below with your desired values. Refer to template content for specific parameter description. Below is an example of creating the stack in `us-west-1` region. Notice that `--template-url` specifies the template version located in the S3 bucket of the same region in which you want to create this new stack:

        $ aws cloudformation create-stack --stack-name customerVPC-test \
        --template-url http://splunk-cloud-us-west-1.s3.amazonaws.com/cloudformation-templates/master.template \
        --parameters ParameterKey=KeyName,ParameterValue=<MyKeyName> \
                     ParameterKey=BastionKeyName,ParameterValue=<MyBastionKeyName> \
                     ParameterKey=ClusterSecurityKey,ParameterValue=<MyClusterSecurityKey> \
                     ParameterKey=ClusterSize,ParameterValue=<MyClusterSize> \
                     ParameterKey=InstanceType,ParameterValue=<MyInstanceType> \
                     ParameterKey=SSHFrom,ParameterValue=<SSHFrom> \
                     ParameterKey=CIDRBlock,ParameterValue=<CIDRBlock> \
                     ParameterKey=HostedZoneName,ParameterValue="" \
                     ParameterKey=Subdomain,ParameterValue="" \
                     ParameterKey=SplunkLicensePath,ParameterValue="" \
                     ParameterKey=SplunkLicenseBucket,ParameterValue="" \
        --capabilities "CAPABILITY_IAM"

    Note: You could also point to your local copy of [master.template](../master/templates/master.template) using `--template-body` instead of `--template-url` in the previous command:

        --template-body file:///home/local/splunk-cloudformation/templates/master.template \

3. (Optional) You can Bring Your Own License by entering a private s3 bucket (accessible by AWS account holder) and path to license file as values for `SplunkLicensePath` and `SplunkLicenseBucket`.


4. Check on stack status by retrieving list of stack events as follows (`master` stack completes in ~20 min):

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

5. When stack is complete, retrieve its outputs and record the VPC ID, Public Subnet ID, Bastion's public IP as well as all Cluster node IPs - and optionally URL for Cluster Master, Search Head and Indexer Tier if **HostedZoneName** was set:

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
                    { "Description": "Bastion Host Public IP address", "OutputKey": "BastionPublicIp", "OutputValue": "54.193.109.23" },
                    { "Description": "Splunk URL of cluster master", "OutputKey": "MasterNodeURL", "OutputValue": "http://cm.splunk.example.com" }, 
                    { "Description": "Public IP address of cluster master", "OutputKey": "MasterNodeIpAddress", "OutputValue": "54.165.231.139" }, 
                    ...
                    { "Description": "Indexer tier address to forward data to", "OutputKey": "PeerNodesURL", "OutputValue": "peers.splunk.feedferry.com:9997" }, 
                    { "Description": "List of public IP address of all cluster peer nodes", "OutputKey": "PeerNodesIpAddresses", "OutputValue": "54.172.10.225, 54.164.135.120, 54.165.177.122" }
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

6. Type Cluster Master's IP (or URL, if HostedZoneName set, pending DNS propagation) in your favorite browser, and navigate to Settings >> Clustering to see all components of your newly created Splunk cluster. In few minutes, the cluster will become valid & complete as soon as initial index replication completes.

## Template Reference List ##

| Template | Description | Launch in US East Region
| --- | --- |:---:
| [master.template](../master/templates/master.template) | **Master** CF template to create a Splunk Cluster in a VPC with Public subnet in a single AZ. This also includes a Bastion host micro instance. Uses sub-templates `vpc_one_subnet.template`, `bastion_host.template`, `splunk_cluster.template` | [Launch Stack][master_us_east_1]
| [splunk_cluster.template](../master/templates/splunk_cluster.template) | CF template to create Splunk cluster of 1 master node, 1 search head and the option of 3, 5 or 9 peer nodes in a specified VPC. Uses sub-stacks `splunk_server.template` and `splunk_server_with_license.template` and used by `master.template` | [Launch Stack][splunk_cluster_us_east_1]
| [vpc_two_subnets.template](../master/templates/vpc_two_subnets.template) | CF template to create a VPC with Public and Private subnets in a single AZ. This includes a NAT instance in Public subnet to enable Private subnet instances to access the Internet. | [Launch Stack][vpc_two_subnets_us_east_1]
| [vpc_one_subnet.template](../master/templates/vpc_one_subnet.template) | CF template to create a VPC with one Public subnet in a single AZ. Used by `master.template` | [Launch Stack][vpc_one_subnet_us_east_1]
| [splunk_server.template](../master/templates/splunk_server.template) | CF template to add a Splunk server to specified VPC and subnet given a Splunk role: cluster-master, cluster-peer or cluster-search-head. Used by `splunk_cluster.template` | [Launch Stack][splunk_server_us_east_1]
| [splunk_server_via_chef.template](../master/templates/splunk_server_via_chef.template) | CF template equivalent to `splunk_server.template` but requires a separate Chef Server. Used by `splunk_cluster_via_chef.template` | [Launch Stack][splunk_server_via_chef_us_east_1]
| [splunk_server_with_license.template](../master/templates/splunk_server_with_license.template) | CF template equivalent to `splunk_server.template` with the addition of specifying a license from a private S3 bucket, for example when creating a splunk license master. Used by `splunk_cluster.template` | [Launch Stack][splunk_server_with_license_us_east_1]
| [bastion_host.template](../master/templates/bastion_host.template) | CF template to add a Bastion host micro instance to specified VPC. It creates a new EC2 keypair to access further instances. Used by `master.template` | [Launch Stack][bastion_host_us_east_1]
| [chef_server.template](../master/templates/chef_server.template) | CF template to add a Chef server to specified VPC. It references remote cookbooks and config files stored in public S3 bucket https://splunk-cloud.s3.amazonaws.com/. | [Launch Stack][chef_server_us_east_1]

[master_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Master|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/master.template "Launch Master Stack"
[splunk_cluster_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Splunk-Cluster|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/splunk_cluster.template "Launch Splunk Cluster Stack"
[vpc_two_subnets_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~VPC-Two-Subnets|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/vpc_two_subnets.template "Launch VPC Two Subnets Stack"
[vpc_one_subnet_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~VPC-One-Subnet|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/vpc_one_subnet.template "Launch VPC One Subnet Stack"
[splunk_server_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Splunk-Server|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/splunk_server.template "Launch Splunk Server Stack"
[splunk_server_via_chef_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Splunk-Server-Via-Chef|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/splunk_server_via_chef.template "Launch Splunk Server Via Chef Stack"
[splunk_server_with_license_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Splunk-Server-With-License|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/splunk_server_with_license.template "Launch Splunk Server With License Stack"
[bastion_host_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Bastion-Host|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/bastion_host.template "Launch Bastion Host Stack"
[chef_server_us_east_1]: https://console.aws.amazon.com/cloudformation/home?#cstack=sn~Chef-Server|turl~https://splunk-cloud-us-east-1.s3.amazonaws.com/cloudformation-templates/chef_server.template "Launch Chef Server Stack"

## TODOs ##

* ~~Support indexer clustering~~ (DONE)
* ~~Support new & updated instances types, e.g. i2.xlarge~~ (DONE)
* Support search head clustering to go from 1:N searcher/indexer to N:N searcher/indexer topology
* Support multi-AZ and multi-site indexer clustering
* Add HA to potential single points of failure such as cluster master, license master
* Apply auto scaling to search head cluster
* Apply recommended EC2 instance type & proper sizing
* Support Splunk AMIs
* Support Windows AMIs
* More testing

## Known Issues & Caveats ##

### DNS Propagation ###

Since Amazon Route 53 has no control over caching of DNS resolvers, it may take up to 10 minutes or more for DNS to propagate globally. This means that, if you have set **HostedZoneName** and DNS records are created, initial clustering setup & data replication may be delayed since nodes cannot communicate with each other until their internal DNS records resolve properly to their private IPs.

### Bringing your own License (BYOL) ###

As mentioned above, you can optionally provide you own license in Step 2. Currently there is an intermittent bug with Splunk's linking to license master which occurs during machine bootstrap (only applicable when providing a license).


## Support ##

1. Splunk CloudFormation templates are community supported
2. Help can be found through the broader community at [Splunk Answers](http://answers.splunk.com/)
3. Issues should be filed here: https://github.com/splunk/splunk-cloudformation/issues

## Additional Info ##

* Splunk Chef Cookbook: While AWS Cloudformation is used to launch and connect various AWS resources, Chef recipes for Splunk are used to provision the deployed machines based on corresponding role such as Splunk indexer, search head, etc. For more info, see [Splunk Cookbook](https://github.com/rarsan/splunk_cookbook) a fork from the great work by [BestBuy.Com](https://github.com/bestbuycom/splunk_cookbook)

* Splunk Cluster & Index Replication: The above templates deploy Splunk in a cluster topology to achieve data availability & recovery. For more info, see [Basic Cluster Architecture](http://docs.splunk.com/Documentation/Splunk/latest/Indexer/Basicclusterarchitecture) in Splunk Enterprise guides

## License ##

The Splunk AWS CloudFormation is licensed under the Apache License 2.0. Details can be found in the file LICENSE.
