#!/bin/bash
# SLURM job configuration
#SBATCH -c 1                   # Number of cores
#SBATCH -N 1                    # Ensure that all cores are on one machine
#SBATCH -t 0-02:59              # Maximum run-time in D-HH:MM
#SBATCH --mem=5G               # Memory pool for all cores (see also --mem-per-cpu)
#SBATCH -o outputs/slurm_logs/simulation_%j.out      # File to which STDOUT will be written
#SBATCH -e outputs/slurm_logs/simulation_%j.err      # File to which STDERR will be written

# print the parameters of the parent script (N, prob, seed)
echo "Job $SLURM_JOB_ID with parameters:"
echo "- N: $N"
echo "- prob: $prob"
echo "- seed: $seed"
echo ""

source env/bin/activate

# run python script
python src/experiment.py --exp_name=$exp_name --N=$N --iterations=$iterations --prob=$prob --seed=$seed --output_dir=$output_dir

# increase N by 1
N=$((N+1))

# run julia script
julia --project=. src/experiment.jl --exp_name=$exp_name --N=$N --iterations=$iterations --prob=$prob --seed=$seed --output_dir=$output_dir

deactivate