#!/bin/bash

source env/bin/activate

LANG="python"  # set the language to either "python" or "julia"
NAME="experiment"  # set the name of the experiment

CONFIG_FILE="configs/${NAME}.json"  # set the path to the configuration file
# set the source file depending on the language
if [ "$LANG" == "python" ]; then
  SRC="${NAME}.py"  # set the source file to be executed
elif [ "$LANG" == "julia" ]; then
  SRC="${NAME}.jl"  # set the source file to be executed
else
  echo "Unsupported language: $LANG"
  exit 1
fi

# get the number of parameter combinations
PARAM_COMBINATIONS=$(jq -r '
  to_entries 
  | map(select(.value | type == "array"))  # Only select parameters where "values" is an array
  | map(.value | length)  # Get the length of each array
  | reduce .[] as $item (1; . * $item)  # Multiply the lengths of all arrays to get the total number of combinations
' $CONFIG_FILE)

# submit each combination with the corresponding index
sbatch --array=0-$((PARAM_COMBINATIONS - 1)) --export=ALL,CONFIG_FILE=$CONFIG_FILE,LANG=$LANG,SRC=$SRC scripts/script_slurm.sh

deactivate
