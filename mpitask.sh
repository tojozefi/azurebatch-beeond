#!/bin/bash


source /etc/profile

SHAREMOUNT=/mnt/beeond
WORKDIR=$SHAREMOUNT/$AZ_BATCH_JOB_ID/$AZ_BATCH_TASK_ID
export LD_LIBRARY_PATH=/opt/ior/lib:$LD_LIBRARY_PATH

mountpoint -q $SHAREMOUNT
if [ $? -ne 0 ]; then echo "BeeOND mountpoint $BEEONDMOUNT not found, exiting" ; exit 1 ; fi
if [ -d $WORKDIR ]; then rm -rf $WORKDIR ; fi
mkdir -p $WORKDIR

echo $AZ_BATCH_HOST_LIST | tr "," "\n" > hostfile
NNODES=$(cat hostfile | wc -l)
NPROCS=$(nproc)
PPN=$((NPROCS - 4)) # leaving 4 cores per node for BeeOND 
NP=$((NNODES * PPN))
sed -i 's/$/ slots='"$NPROCS"'/g' hostfile

module load mpi/openmpi-4.0.3
module load gcc-9.2.0

echo "*** Throughput test random N-N ***"
mpirun -x LD_LIBRARY_PATH -np $NP --hostfile $AZ_BATCH_TASK_WORKING_DIR/hostfile /opt/ior/bin/ior -z -B -C -e -F -r -w -t32m -b1G -o $WORKDIR/throughput_random.$(date +"%Y-%m-%d_%H-%M-%S")
sleep 2

echo
echo "*** Throughput test sequential N-N"
mpirun -x LD_LIBRARY_PATH -np $NP --hostfile $AZ_BATCH_TASK_WORKING_DIR/hostfile /opt/ior/bin/ior -B -C -e -F -r -w -t32m -b1G -o $WORKDIR/throughput_seq.$(date +"%Y-%m-%d_%H-%M-%S")
sleep 2

echo
echo "*** IOPS test"
mpirun -x LD_LIBRARY_PATH -np $NP --hostfile $AZ_BATCH_TASK_WORKING_DIR/hostfile /opt/ior/bin/ior -B -C -e -F -r -w -t4k -b128M -o $WORKDIR/iops.$(date +"%Y-%m-%d_%H-%M-%S")

echo "Finished."