#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/common.sh"

if [ $# != 1 ]; then
    echo "Usage: $0 <paramsfile>"
    exit 1
fi

source $1
task_template="mpitask.template.json"

required_envvars pool_id job_id node_count job_container_name task_id task_script coordination_script storage_account_name AZURE_BATCH_ACCOUNT

taskjson=${task_id}-task.json

echo "creating job container \"${job_container_name}\"..."
az storage container create \
    -n ${job_container_name} \
    --account-name ${storage_account_name}

echo "uploading task script \"task_script\" to job container \"${job_container_name}\"..."
az storage blob upload \
    --account-name $storage_account_name \
    --container $job_container_name \
    --file $task_script \
    --name "$task_script"

echo "uploading coordination script \"coordination_script\" to job container \"${job_container_name}\"..."
az storage blob upload \
	--account-name $storage_account_name \
	--container $job_container_name \
	--file $coordination_script \
	--name "$coordination_script"


echo "creating job \"$job_id\"..."
az batch job create \
    --id $job_id \
    --pool-id $pool_id

expiry_date=$(date -u -d "1 month" '+%Y-%m-%dT%H:%M:%SZ')
saskey=$(az storage account generate-sas --permissions rlw --services b --resource-types sco --expiry $expiry_date -o tsv --account-name $storage_account_name)
job_container_uri="https://${storage_account_name}.blob.core.windows.net/${job_container_name}"
task_script_uri="${job_container_uri}/${task_script}?${saskey}"
task_resource=$(jq -n '.httpUrl=$uri | .filePath=$script' --arg uri "$task_script_uri" --arg script $task_script)
coordination_script_uri="${job_container_uri}/${coordination_script}?${saskey}"
common_resource=$(jq -n '.httpUrl=$uri | .filePath=$script' --arg uri "$coordination_script_uri" --arg script $coordination_script)
task_cmd_line="bash \$AZ_BATCH_TASK_WORKING_DIR/$task_script"
coord_cmd_line="bash \$AZ_BATCH_TASK_DIR/$coordination_script"

jq '.id=$taskId | 
    .commandLine=$taskCmdLine | 
	.resourceFiles[0]=$taskResource' \
	--arg taskId "$task_id" \
	--arg taskCmdLine "$task_cmd_line" \
	--argjson taskResource "$task_resource" $task_template > tmp.json

jq '.multiInstanceSettings.numberOfInstances=$nodeCount | 
	.multiInstanceSettings.coordinationCommandLine=$coordCmdLine | 
	.multiInstanceSettings.commonResourceFiles[0]=$commonResource' \
	--arg coordCmdLine "$coord_cmd_line" \
	--arg nodeCount "$node_count" \
	--argjson commonResource "$common_resource" tmp.json > $taskjson

echo "starting task \"task_id\"..."
az batch task create \
    --job-id $job_id \
    --json-file $taskjson 

