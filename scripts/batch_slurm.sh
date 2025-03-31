#!/bin/bash

source env/bin/activate

# set the path to the configuration file
CONFIG_FILE="configs/experiment.json"

# get the number of parameter combinations
PARAM_COMBINATIONS=$(jq -r '
  to_entries 
  | map(select(.value.values | type == "array"))  # Only select parameters where "values" is an array
  | map(.value.values | length)  # Get the length of each array
  | reduce .[] as $item (1; . * $item)  # Multiply the lengths of all arrays to get the total number of combinations
' $CONFIG_FILE)

# submit each combination with the corresponding index
for INDEX in $(seq 0 $((PARAM_COMBINATIONS - 1))); do
    sbatch --export=ALL,config_file=$CONFIG_FILE,index=$INDEX scripts/script_slurm.sh
done

deactivate