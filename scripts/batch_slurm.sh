#!/bin/bash

source env/bin/activate

# set fixed parameters
seeds=10
njobs=5

# define parameter sets
declare -a Ns=(10 100 1000)

# Loop over parameter sets and submit jobs
for N in "${Ns[@]}"; do
    sbatch --export=ALL,N=$N,seeds=$seeds,njobs=$njobs scripts/script_slurm.sh
done
