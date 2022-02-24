#!/bin/bash

N_seq=(10 100 1000)
seeds=10
njobs=5

# Loop
for i in {0..2}
do
    N=${N_seq[$i]}
    python -m src.experiment --output=outputs/experiment_N_${N} --n=$N --seeds=$seeds --njobs=$njobs
done