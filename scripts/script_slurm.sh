#!/bin/bash
# SLURM job configuration
#SBATCH -c 1                   # Number of cores
#SBATCH -N 1                    # Ensure that all cores are on one machine
#SBATCH -t 0-02:59              # Maximum run-time in D-HH:MM
#SBATCH --mem=5G               # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH -o outputs/slurm_logs/simulation_%j.out      # File to which STDOUT will be written
#SBATCH -e outputs/slurm_logs/simulation_%j.err      # File to which STDERR will be written

source env/bin/activate

# run python script
python -m src.experiment --output=outputs/experiment_N_${N} --n=$N --seeds=$seeds --njobs=$njobs