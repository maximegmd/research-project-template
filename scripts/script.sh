#!/bin/bash

source env/bin/activate

exp_name="test"
N=10
iterations=10
prob=0.5
seed=42
output_dir="outputs"

# individual run (python)
python src/experiment.py --exp_name=$exp_name --N=$N --iterations=$iterations --prob=$prob --seed=$seed --output_dir=$output_dir

# individual run (julia)
N=11
julia --project=. src/experiment.jl --exp_name=$exp_name --N=$N --iterations=$iterations --prob=$prob --seed=$seed --output_dir=$output_dir

# loop over configurations
# N_seq=(10 20)
# prob_seq=(0.1 0.5)
# for N in "${N_seq[@]}"
# do
#     for prob in "${prob_seq[@]}"
#     do
#         python src/experiment.py --exp_name=$exp_name --N=$N --iterations=$iterations --prob=$prob --seed=$seed --output_dir=$output_dir
#     done
# done