# Research Project Template

This repository serves as a template for research projects. It provides a structured way to organize data, experiment parameters, source code, and results. Additionally, it includes scripts for running experiments both locally and on SLURM clusters. The following sections act both as placeholders and as a quick start guide for running experiments using the provided scripts. Any of the following content can be edited and adapted for the specific project.

__Contents__:
- [Introduction](#introduction)
- [Dependencies](#dependencies)
- [Repository structure](#repository-structure)
- [Running experiments](#running-experiments)
- [Contact & attribution](#contact--attribution)


## Introduction

<!-- placeholder for an optional banner image -->
<!-- <div align="center">
  <img width="600" src="banner.png">
</div> -->

One paragraph motivating the project. This can be, for example, the paper abstract.

## Dependencies

### Python
All experiments were performed using Python 3.XX. To create a virtual environment and install dependencies:


```bash
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
```

*Note: The current `requirements.txt` contains commonly used packages. Remember to run `pip freeze > requirements.txt` before publishing the project.*

### Julia
All experiments were performed using Julia 1.XX.YY. To install dependencies, open the Julia REPL and run:


```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```
or equivalently
```julia
] activate .
] instantiate
```

*Note: The current `Project.toml` contains commonly used packages. Remember to also commit `Manifest.toml` before publishing the project.*

## Repository structure

```
├── configs/
│   └── experiment.json
├── data/
│   ├── original/
│   └── processed/
├── figures/
├── notebooks/
├── outputs/
├── scripts/
│   ├── run.sh
│   └── submit_slurm.sh
└── src/
    ├── executor.py
    ├── experiment.py
    ├── experiment.jl
    └── utils.py
```

- `configs/` — JSON files specifying experiment parameters
- `data/` — Raw data (`original/`) and their polished/organized versions (`processed/`)
- `figures/` — Generated figures
- `notebooks/` — Jupyter notebooks for analysis and visualization
- `outputs/` — Experiment results (JSON files)
- `scripts/` — Shell scripts for running experiments locally or on SLURM
- `src/` — Source code:
  - `executor.py` — Reads config, selects parameters, and runs the experiment script
  - `experiment.py` / `experiment.jl` — Main experiment logic (Python/Julia)
  - `utils.py` — Plotting utilities for LaTeX-compatible figures

## Running experiments

### Configuration

Experiments are configured via JSON files in `configs/`. Each config file specifies:
- **Experiment parameters**: Fixed values (e.g., `"iterations": 10`) or arrays for the variables of interest of the experiment (e.g., `"N": [10, 20]`)
- **SLURM settings**: Resource requirements for execution on compute clusters (see `_comments` in the `slurm` section for parameter descriptions) --- these are simply ignored if the experiment is executed locally.

### How it works

The executor creates a grid of all parameter combinations. Array values in the config
(e.g., `"N": [10, 20]`, `"prob": [0.1, 0.5]`) are combined into 4 experiments (2×2).
Each combination runs as a separate experiment, either sequentially (local) or in
parallel (SLURM array job).

### Local execution

To run all parameter combinations locally:

```bash
./scripts/run.sh -n experiment
```

By default, this runs `configs/experiment.json` using Python.

**Options:**
- `-n, --name NAME` — Experiment name (default: `experiment`). It tells the executor to look for the config `configs/NAME.json` and the Python/Julia script called `src/NAME.{py,jl}`
- `-l, --lang LANG` — Language: `python` or `julia` (default: `python`)
- `-h, --help` — Show help message
- `-c, --config FILE` — Direct path to config file (overrides derived path) --- this is obsolete and should be removed

**Examples:**
```bash

# Use Julia instead of Python
./scripts/run.sh -n experiment -l julia

# Use a different experiment
./scripts/run.sh -n my_other_experiment

# Combine options
./scripts/run.sh -n my_other_experiment -l julia
```

### SLURM execution

To submit experiments as a SLURM array job:

1. Configure SLURM settings in your config file (e.g., `configs/experiment.json`)
2. Submit the job:

```bash
./scripts/submit_slurm.sh
```

**Options** are the same as `run.sh`, plus:
- `-d, --dry-run` — Preview the sbatch command without executing

**Examples:**
```bash
# Preview what would be submitted
./scripts/submit_slurm.sh -n experiment --dry-run

# Submit Julia experiment
./scripts/submit_slurm.sh -n experiment -l julia

# Submit a different experiment
./scripts/submit_slurm.sh -n my_other_experiment
```

Monitor jobs with `squeue -u $USER` and check logs in the `log_dir` specified in your config (default: `outputs/slurm_logs`).

### Output

Results are saved to the `output_dir` specified in the config (default: `outputs/`). Output filenames are auto-generated from variable parameters:

```
{exp_name}__{param1}={value1}__{param2}={value2}.json
```

For example: `test__N=10__prob=0.5.json`

## Contact & attribution

If you use this code in your research, please cite:

```bibtex
<!-- Insert your paper's BibTeX here -->
```
---
*A last note: If you have any questions about this repository, spot any bugs, or there is something you would like to see improved, please write me an email (see [https://stsirtsis.github.io/](https://stsirtsis.github.io/) for my address).
