#!/bin/bash

mydate=$(date +'%h%d_%H-%M')
if [[ $1 != "run" ]]; then
    mydate=date_test
fi

export mydate
export cudaSo=/leonardo/pub/userexternal/drapetti/plumed_cuda/lib/CudaCoordination.so
MODULEDEFINITIONS_CPU='export MODULEPATH=:/leonardo/pub/userexternal/drapetti/plumed_cuda/modules/$MODULEPATH

module load gcc/12.2.0
module load openmpi/4.1.6--gcc--12.2.0-cuda-12.2
#in /leonardo/pub/userexternal/drapetti/plumed_cuda/modules the plumed installed is called "myplumed" to not conflict with the official leonardo version
module load myplumed/v2.10
'

export MODULEDEFINITIONS_CPU

./createPerf_cudacoord.sh "$1" no

export natoms_max=40000
./createPerf_cudacoord.sh "$1" yes
