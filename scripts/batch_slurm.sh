#!/bin/bash

source env/bin/activate

LANG="python"  # set the language to either "python" or "julia"
CONFIG_FILE="configs/experiment.json" # set the path to the configuration file
SRC="experiment.py" # set the source file to be executed

# get the number of parameter combinations
PARAM_COMBINATIONS=$(jq -r '
  to_entries 
  | map(select(.value | type == "array"))  # Only select parameters where "values" is an array
  | map(.value | length)  # Get the length of each array
  | reduce .[] as $item (1; . * $item)  # Multiply the lengths of all arrays to get the total number of combinations
' $CONFIG_FILE)

# submit each combination with the corresponding index
for INDEX in $(seq 0 $((PARAM_COMBINATIONS - 1))); do
  sbatch --export=ALL,CONFIG_FILE=$CONFIG_FILE,INDEX=$INDEX,LANG=$LANG,SRC=$SRC scripts/script_slurm.sh
done

deactivate
