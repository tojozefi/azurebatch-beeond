# subscription id of the batch account
subscription=<TO BE FILLED>

# resource group of the batch account
resource_group=<TO BE FILLED>

# batch account credentials - if key is empty Azure AD authentication will be used
AZURE_BATCH_ACCOUNT=<TO BE FILLED>
AZURE_BATCH_ACCESS_KEY=

# azure storage account linked to the batch account
storage_account_name=<TO BE FILLED>


## MODIFY OPTIONS BELOW IF NEEDED
 
# Azure VM size - allowed values: Standard_HC44rs, Standard_HB60rs, Standard_HB120rs_v2
vm_size=Standard_HC44rs 

# The image reference is in the format: {publisher}:{offer}:{sku}:{version} where {version} is
# optional and will default to 'latest'.
# To list available images use: az vm image list --output table
vm_image="OpenLogic:CentOS-HPC:7.7"

# To list supported node agents use: az batch pool node-agent-skus list --output table
node_agent="batch.node.centos 7"

# pool name to create
pool_id=mpipool

# container name to store pool resources, by default the pool name
pool_container_name=$pool_id

# number of nodes
node_count=2

# start task script
starttask=starttask.sh

# job name to create
job_id=mpijob

# container name to store job resources, by default the job name 
job_container_name=$job_id

# task name to create
task_id=mpitask

# multi-instance task script
task_script=mpitask.sh

# multi-instance coordination script
coordination_script=coordination.sh
