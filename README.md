# Batch pool with scratch BeeOND shared filesystem
This repo offers scripts to easily deploy an Azure Batch pool with [BeeOND](https://www.beegfs.io/wiki/BeeOND) shared filesystem.  
You may find it useful if you need a high-performant shared scratch filesystem for your MPI jobs run on Azure Batch.  
BeeOND filesystem is hosted on pool nodes' local SSD disks and is rebuilt to utilize RDMA InfiniBand for BeeOND internal communication.  
The second NVME local disk of the VMs is used for BeeOND filesystem whenever present (e.g. in HB120rs_v2).

**Note:** This repo is dedicated for Azure VM SKUs with IB SR-IOV, currently: Standard_HB60rs, Standard_HC44rs and Standard_HB120rs_v2.

**Note2:** Credits are due to [HPC-azbatch](https://github.com/az-cat/HPC-azbatch) and [azurehpc/beeond](https://github.com/Azure/azurehpc/tree/master/examples/beeond) projects for inspiration and ideas ;-)

## Prequisites
1. Azure [subscription](https://azure.microsoft.com/en-us/) 
1. Azure [Batch account](https://azure.microsoft.com/en-us/services/batch/) and a [blob storage](https://azure.microsoft.com/en-us/services/storage/blobs/) account linked to it. 
2. Core quota for the VM SKUs that you want to use in chosen region, either in your Batch account or in your Azure subscription (for [user subscription allocation mode](https://docs.microsoft.com/en-us/azure/batch/batch-account-create-portal#additional-configuration-for-user-subscription-mode)).
## Quickstart
1. Open a [Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) (Bash) session from the Azure Portal, or open a Linux session with [Azure CLI v2.0](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) and [jq](https://stedolan.github.io/jq) packages installed.
2. Clone the repository: `git clone https://github.com/tojozefi/azurebatch-beeond.git`
3. Grant execute access to .sh scripts: `cd azurebatch-beeond; chmod +x *.sh`
## Procedure
1. Update the *params.tpl* file with the values specific to your environment:
* *subscription* : subscription id where your Azure Batch account is created
* *resource_group* : the Batch account's resource group 
* *AZURE_BATCH_ACCOUNT* : the name of the Batch account
* *AZURE_BATCH_ACCESS_KEY* : Batch account key (optional)
* *storage_account_name* : the name of storage account linked with your Batch account
2. Login to the Azure Batch account  
    `./00-login.sh params.tpl`
3. Create the Azure Batch pool  
    `./01-createpool.sh params.tpl`
4. Create a sample MPI job to mount the BeeOND filesystem and test its performance with IOR  
    `./02-createjob.sh params.tpl`
## Monitor your job
Use [Batch Explorer](https://azure.github.io/BatchExplorer/) to monitor your pools and jobs. 
