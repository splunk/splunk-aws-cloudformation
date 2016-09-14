#!/bin/bash
#- get_ebs_volumes.sh

#- splunk variables
splunk_db=/opt/splunk
warm_directory=$splunk_db/my_index/db
cold_directory=$splunk_db/my_index/cold_db

#- extract region so that the EBS queries are made against the correct region
ec2_azone=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
ec2_region=`echo $ec2_azone | sed -e 's/[a-z]$//'`

#- assign instance_id variable from AWS metadata
instance_id=`wget -q -O- http://169.254.169.254/latest/meta-data/instance-id`

#- list of ebs volumes attached to this instance
ebs_volumes=`aws ec2 describe-volumes \
--filters Name=attachment.instance-id,Values=$instance_id \
--query Volumes[].VolumeId --region $ec2_region --output text`

#- assign variables to the device name for the warm and cold mountpoints.
warm_device=`df -P "$warm_directory" | awk 'NR==2 {print $1}' | sed 's/[0-9]*$//g'`
cold_device=`df -P "$cold_directory" | awk 'NR==2 {print $1}' | sed 's/[0-9]*$//g'`

#- cycle through EBS volumes and see if the attached device matches the warm and/or cold device
for i in `echo $ebs_volumes`
do
	#- $i = EBS volume id.  Query the AWS API for the linux device that the volume
	#- has attached to the instance
	ebs_device=`aws ec2 describe-volumes --filters Name=volume-id,Values=$i \
	--query Volumes[].Attachments[].Device --region $ec2_region --output text`

	#- some versions of linux will mount the EBS volume as /dev/xvdN 
#- instead of /dev/sdN. -- test for that case.
	ebs_devicex=`echo $ebs_device | sed 's/\/dev\/sd/\/dev\/xvd/g'`

	if   [[ "$ebs_device" = "$cold_device" || "$ebs_devicex" = "$cold_device" ]]
	then
		cold_volume=$i
	elif [[ "$ebs_device" = "$warm_device" || "$ebs_devicex" = "$warm_device" ]]
	then
		warm_volume=$i
	else
		echo "nomatch: $i [$ebs_device] c: $cold_device  w: $warm_device"
	fi
done

#- test if warm and cold volumes are the same
if [ "$cold_volume" = "$warm_volume" ]
then
	#- they are
	echo "warm & cold volume ID: $cold_volume"
else
	#- they aren't
	echo "warm volume id: $warm_volume"
	echo "cold volume id: $cold_volume"
fi

