#!/bin/bash

source env/bin/activate

exp_name="test"
N_seq=(10 20)
iterations=10
prob_seq=(0.1 0.5)
seed=42
output_dir="outputs"

# loop over configurations
for N in "${N_seq[@]}"
do
    for prob in "${prob_seq[@]}"
    do
        python src/experiment.py --exp_name=$exp_name --N=$N --iterations=$iterations --prob=$prob --seed=$seed --output_dir=$output_dir
    done
done