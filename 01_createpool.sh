#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

if [ $# != 1 ]; then
    echo "Usage: $0 <paramsfile>"
    exit 1
fi

source $1
pool_template="pool.template.json"

required_envvars pool_id vm_size pool_container_name starttask node_count storage_account_name AZURE_BATCH_ACCOUNT
pooljson=${pool_id}-pool.json

if [ $vm_size != "Standard_HC44rs" ] && [ $vm_size != "Standard_HB60rs" ] && [ $vm_size != "Standard_HB120rs_v2" ]; then
	echo "invalid vm_size value: $vm_size"
	exit 1
fi

starttask_command_line="./$starttask"
echo $starttask_command_line
jq '.id=$poolId |
    .vmSize=$vmSize |
    .targetDedicatedNodes=$nodeCount |
    .startTask.resourceFiles[0].autoStorageContainerName=$containerName |
    .startTask.commandLine=$commandLine' $pool_template \
    --arg containerName "$pool_container_name" \
    --arg poolId "$pool_id" \
    --arg vmSize "$vm_size" \
    --arg nodeCount "$node_count" \
    --arg commandLine "$starttask_command_line" > $pooljson

# check for custom Image or Marketplace Image
if [ -n "$image_id" ]; then # Custom Image is specified
    jq '.virtualMachineConfiguration.imageReference.virtualMachineImageId=$imageId |
        .virtualMachineConfiguration.nodeAgentSKUId=$nodeAgent' $pooljson \
       --arg nodeAgent "$node_agent" \
       --arg imageId "$image_id" > tmp.json
else # Marketplace Image
    jq '.virtualMachineConfiguration.nodeAgentSKUId=$nodeAgent |
        .virtualMachineConfiguration.imageReference.publisher=$publisher |
        .virtualMachineConfiguration.imageReference.offer=$offer |
        .virtualMachineConfiguration.imageReference.sku=$sku' $pooljson \
                --arg nodeAgent "$node_agent" \
                --arg publisher "$(echo $vm_image | cut -d':' -f1)" \
                --arg offer "$(echo $vm_image | cut -d':' -f2)" \
                --arg sku "$(echo $vm_image | cut -d':' -f3)" > tmp.json
fi
mv tmp.json $pooljson

echo "creating container \"${pool_container_name}\"..."
az storage container create \
    -n ${pool_container_name} \
    --account-name ${storage_account_name}

echo "uploading starttask script \"$starttask\" to pool resource container \"$pool_container_name\""...
az storage blob upload \
    --account-name $storage_account_name \
    --container $pool_container_name \
    --file $starttask \
    --name $starttask

if [ -f ior.tgz ]; then
echo "uploading ior.tgz..."
az storage blob upload \
    --account-name $storage_account_name \
    --container $pool_container_name \
    --file ior.tgz \
    --name ior.tgz
fi

echo "creating pool \"${pool_id}\"..."
az batch pool create --json-file $pooljson