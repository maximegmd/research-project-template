#!/bin/bash
# Unified experiment runner
# - When SLURM_ARRAY_TASK_ID is set: runs single experiment (SLURM worker mode)
# - Otherwise: loops through all parameter combinations (local mode)

set -e

show_help() {
    cat << 'EOF'
Usage: run.sh [OPTIONS]

Run experiments locally (all combinations) or as a SLURM worker (single task).

Options:
  -n, --name NAME       Experiment name (default: experiment)
                        Config file is derived as configs/NAME.json
  -l, --lang LANG       Language: python or julia (default: python)
  -c, --config FILE     Config file path (overrides derived path)
  -h, --help            Show this help message

Examples:
  run.sh                              # Run with defaults
  run.sh -n my_experiment             # Different experiment
  run.sh -n my_exp -l julia           # Julia experiment
  run.sh --config=custom/path.json    # Custom config path

SLURM worker mode:
  When SLURM_ARRAY_TASK_ID is set (running as SLURM job),
  configuration is read from environment variables passed by sbatch.
EOF
}

# TODO: remove config option, this should be derived by the name
# TODO: since we are passing the name, the config does not need to include a name, that is confusing
# TODO: the user should ALWAYS specify the name of the experiment, language is fine to be optional
# TODO: make sure that whatever we change here remains consistent in submit_slurm.sh

# Parse arguments (skip if in SLURM worker mode - uses env vars from sbatch)
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                ARG_NAME="$2"
                shift 2
                ;;
            --name=*)
                ARG_NAME="${1#*=}"
                shift
                ;;
            -l|--lang)
                ARG_LANG="$2"
                shift 2
                ;;
            --lang=*)
                ARG_LANG="${1#*=}"
                shift
                ;;
            -c|--config)
                ARG_CONFIG="$2"
                shift 2
                ;;
            --config=*)
                ARG_CONFIG="${1#*=}"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                echo "Try 'run.sh --help' for more information." >&2
                exit 2
                ;;
            *)
                echo "Error: Unexpected argument '$1'" >&2
                echo "Try 'run.sh --help' for more information." >&2
                exit 2
                ;;
        esac
    done
fi

source env/bin/activate

# Set configuration variables
if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
    # SLURM worker mode: use env vars passed by sbatch
    EXPERIMENT_LANG="${EXPERIMENT_LANG:-python}"
    NAME="${NAME:-experiment}"
    CONFIG_FILE="${CONFIG_FILE:-configs/${NAME}.json}"
else
    # Local mode: CLI args > defaults only
    EXPERIMENT_LANG="${ARG_LANG:-python}"
    NAME="${ARG_NAME:-experiment}"
    CONFIG_FILE="${ARG_CONFIG:-configs/${NAME}.json}"
fi

# Validate language
if [[ ! "$EXPERIMENT_LANG" =~ ^(python|julia)$ ]]; then
    echo "Error: Invalid language '$EXPERIMENT_LANG'. Use 'python' or 'julia'." >&2
    exit 1
fi

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Determine source file
if [ "$EXPERIMENT_LANG" == "python" ]; then
    SRC="${NAME}.py"
elif [ "$EXPERIMENT_LANG" == "julia" ]; then
    SRC="${NAME}.jl"
fi

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
    # SLURM worker mode: run single experiment
    python src/executor.py --config="$CONFIG_FILE" --index="$SLURM_ARRAY_TASK_ID" --lang="$EXPERIMENT_LANG" --source="$SRC"
else
    # Local mode: loop through all combinations
    PARAM_COMBINATIONS=$(jq -r '
        to_entries
        | map(select(.value | type == "array"))
        | map(.value | length)
        | reduce .[] as $item (1; . * $item)
    ' "$CONFIG_FILE")

    echo "Running $PARAM_COMBINATIONS experiments locally..."
    for INDEX in $(seq 0 $((PARAM_COMBINATIONS - 1))); do
        echo "[$((INDEX + 1))/$PARAM_COMBINATIONS]"
        python src/executor.py --config="$CONFIG_FILE" --index="$INDEX" --lang="$EXPERIMENT_LANG" --source="$SRC"
    done
fi

deactivate
