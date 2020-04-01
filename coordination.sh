#!/bin/bash

echo "### start of coordination script ###"
echo 

NVMEMOUNT=/mnt/nvme
SSDMOUNT=/mnt/resource
beeondmount=/mnt/beeond

# checking for NVME disk mount
if [ -d $NVMEMOUNT ]; then
	beeonddata=$NVMEMOUNT/beeond # placing BeeOND data on NVME local disk (HBv2)
else
	beeonddata=$SSDMOUNT/beeond # placing BeeOND data on local SSD disk (HB/HC)
fi

if $AZ_BATCH_IS_CURRENT_NODE_MASTER; then
	mountpoint -q $beeondmount 
	if [ $? -ne 0 ]; then 
		echo "starting BeeOND..."
		echo $AZ_BATCH_HOST_LIST | tr "," "\n" > hostlist
		sudo beeond start -n hostlist -d $beeonddata -c $beeondmount
		if [ $? -eq 0 ]; then 
			echo "BeeOND started"
		else
		echo "failed to start BeeOND"
		# exit 1
		fi
	else
		echo "found BeeOND mountpoint $beeondmount"
	fi
fi 

echo
df -h
echo
echo "### end of coordindation script. ###"