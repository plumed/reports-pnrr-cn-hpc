#!/bin/bash
#SBATCH -A CNHPC_1450168
#SBATCH -p boost_usr_prod
#SBATCH --qos boost_qos_dbg   # boost_qos_dbg
#SBATCH --time 00:15:00       # format: HH:MM:SS
#SBATCH -N 1                  # 1 node
#SBATCH --ntasks-per-node=@mpiproc@   # @threads@ tasks out of 32
#SBATCH --cpus-per-task=@threads@
#SBATCH --gres=gpu:1          # 1 gpus per node out of 4
#SBATCH --mem=@mem@          # memory per node out of 494000MB
#SBATCH --job-name=plmdbench_@fname@
#SBATCH -o %x.%j.out
#SBATCH -e %x.%j.err.out

@MODULEDEFINITIONS@

module load cuda/12.2

export PLUMED_NUM_THREADS=@threads@
export PLUMED_MAXBACKUP=0

@EXTRADEFINITIONS@

#export NVCOMPILER_ACC_NOTIFY=31

@plumed@ benchmark --plumed="@inputfiles@" \
    --kernel="this" \
    --maxtime=840 \
    --natoms=@natoms@ \
    --nsteps=@nsteps@ \
    --atom-distribution=@distr@ \
    >"@fname@.out"
