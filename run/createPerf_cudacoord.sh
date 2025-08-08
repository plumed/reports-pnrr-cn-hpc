#!/bin/bash

# _____ _____ _____ _   _______
#/  ___|  ___|_   _| | | | ___ \
#\ `--.| |__   | | | | | | |_/ /
# `--. \  __|  | | | | | |  __/
#/\__/ / |___  | | | |_| | |
#\____/\____/  \_/  \___/\_|

#INFO:first argument should be "run" if you want to run the benchmark
#secund argument should be yes if you want to run also CPU benchmark,
#NOTE:know that over 32k atoms you will start to have memory ploblems (solved in the GPU implementation)

#mydate can be exported before running this
mydate=${mydate:-$(date +'%h%d_%H-%M')}

cudaSo=${cudaSo:-/leonardo/pub/userexternal/drapetti/plumed_cuda/lib/CudaCoordination.so}
useDistr=("sc" "line")
list_of_natoms=(100 1000 2000 4000 6000 8000 12000 16000 24000 32000 48000 64000 96000 128000)
natoms_max=${natoms_max:-128001}
natoms_min=${natoms_min:-0}
list_of_threads=(1 2 4 8 16 32)

nsteps=500
run=""
if [[ $1 != "run" ]]; then
    list_of_natoms=(50 8000 128000)
    useDistr=("line")
else
    run=yes
fi
if [[ $2 == "yes" ]]; then
    cpurun=yes
fi
CPUKernel=${CPUKernel:-this}
GPUKernel=${GPUKernel:-this}

# _    _  ___________ _   __
#| |  | ||  _  | ___ \ | / /
#| |  | || | | | |_/ / |/ /
#| |/\| || | | |    /|    \
#\  /\  /\ \_/ / |\ \| |\  \
# \/  \/  \___/\_| \_\_| \_/

benchdir=cudacoord

for natoms in "${list_of_natoms[@]}"; do
    if ((natoms > natoms_max)); then
        continue
    fi
    if ((natoms < natoms_min)); then
        continue
    fi
    mem=64000
    for distr in "${useDistr[@]}"; do
        for strategy in "${list_of_threads[@]}"; do
            dir="${mydate}/${benchdir}/threads${strategy}"
            if [[ $cpurun == "yes" ]]; then
                dir="${mydate}/${benchdir}_cpu/threads${strategy}"
            fi
            mkdir -p "${dir}"
            echo "*" >"${dir}/.gitignore"
            threads=$strategy
            mpi="plumed --no-mpi "
            mpiproc=1
            kernels=${CPUKernel}
            MODULEDEFINITIONS=$MODULEDEFINITIONS_CPU

            for f in plumedCuda plumedCudaFloat plumedCPU; do
                sed -e "s%@cudaSO@%${cudaSo}%g" \
                    -e "s/@natoms@/${natoms}/g" \
                    <"${benchdir}/${f}.dat" \
                    >"${dir}/${f}${natoms}.dat"
            done
            inputfiles="plumedCuda${natoms}.dat:plumedCudaFloat${natoms}.dat"
            if [[ $cpurun == "yes" ]]; then
                inputfiles="plumedCPU${natoms}.dat:${inputfiles}"
            fi
            runName=${distr}_${natoms}_${strategy}
            runfile=${runName}.sh
            #extra passage because EXTRADEFINITIONS might be multiline
            awk -v r="$EXTRADEFINITIONS" -v md="$MODULEDEFINITIONS" \
                '{gsub(/@EXTRADEFINITIONS@/,r)}1 {gsub(/@MODULEDEFINITIONS@/,md)}1' \
                <"${benchdir}/submit.sh" \
                | sed -e "s/@natoms@/$natoms/g" \
                    -e "s/@nsteps@/$nsteps/g" \
                    -e "s/@mem@/$mem/g" \
                    -e "s/@plumed@/$mpi/g" \
                    -e "s/@mpiproc@/$mpiproc/g" \
                    -e "s/@threads@/$threads/g" \
                    -e "s%@distr@%$distr%g" \
                    -e "s%@inputfiles@%$inputfiles%g" \
                    -e "s%@kernels@%$kernels%g" \
                    -e "s%@fname@%$runName%g" \
                    >"${dir}/${runfile}"
            if [[ $run == "yes" ]]; then
                (
                    echo "in \"${dir}\"> sbatch \"${runfile}\""
                    cd "${dir}" || exit
                    sbatch "${runfile}"
                )
            fi
        done
    done
done
