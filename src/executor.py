import click
import json
import itertools
import os

# comment the click commands for testing
@click.command()
@click.option('--config', type=str, required=True, help="path to config JSON file")
@click.option('--index', type=int, required=True, help="index of the parameter set")
@click.option('--lang', type=str, default='python', help="language to use for the experiment")
@click.option('--source', type=str, default='experiment.py', help="name of the source file")
def experiment(config, index, lang, source):

    # load the config file
    with open(config, "r") as f:
        config_data = json.load(f)
    
    # separate fixed and variable parameters
    fixed_params = {k: v for k, v in config_data.items() if not isinstance(v, list)}
    variable_params = {k: v for k, v in config_data.items() if isinstance(v, list)}

    # generate all combinations of variable parameters
    param_combinations = list(itertools.product(*[v for v in variable_params.values()]))

    # ensure index is within range
    if index >= len(param_combinations):
        raise ValueError(f"Index {index} is out of range. Only {len(param_combinations)} experiments available.")

    # construct parameter set
    experiment_params = {k: v for k, v in fixed_params.items()}  # copy fixed params
    experiment_params.update({
        k: param_combinations[index][i] for i, (k, v) in enumerate(variable_params.items())
    })  # add selected combination for variable params

    # create args string
    args = ' '.join([f'--{k} "{v}"' for k, v in experiment_params.items()])
    # check that the lang is either python or julia
    if lang not in ['python', 'julia']:
        raise ValueError(f"Language {lang} is not supported. Supported languages are python and julia.")

    # pass the names of the variable parameters to the command
    variable_param_names = ','.join(variable_params.keys())
    args += f' --vars {variable_param_names}'
    
    # create and run the command
    command = f'{lang} src/{source} {args}'
    os.system(command)

    return


if __name__ == '__main__':
    # comment for testing
    experiment()
    # uncomment for testing
    # experiment('configs/experiment.json', 0)