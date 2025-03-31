import numpy as np
import click
import json
import itertools

# convert numpy types to native python types
def convert_to_native(obj):
    if isinstance(obj, np.generic):
        return obj.item()
    elif isinstance(obj, dict):
        return {convert_to_native(k): convert_to_native(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_to_native(i) for i in obj]
    else:
        return obj

# let the N people vote each other at random. with probability prob, a person does not vote
def compute(N, prob, rng):
    
    votes = np.zeros(N, dtype=int)
    abstained = 0
    for i in range(N):
        # if the random number is less than prob, the person does not vote
        if rng.random() < prob:
            abstained += 1
            continue
        else:
            # the person votes for another person (excluding i) at random
            eligible = set(range(N))
            eligible.remove(i)
            votes[rng.choice(list(eligible))] += 1

    return votes, abstained

# summarize the votes and abstained votes
def summarize(votes, abstained):
    
    # find the person with the most votes
    winner = np.argmax(votes)
    # find the number of votes the winner received
    winner_votes = votes[winner]
    # find the differnce between the number of votes of the winner and the second place
    runner_up = np.argsort(votes)[-2]
    runner_up_votes = votes[runner_up]
    diff = winner_votes - runner_up_votes
    # find the votes of voters 0 and 1
    votes_zeroone = votes[:2]

    return winner, winner_votes, diff, votes_zeroone

def read_params(config, index):

    # load the config file
    with open(config, "r") as f:
        config_data = json.load(f)
    
    # separate fixed and variable parameters
    fixed_params = {k: v for k, v in config_data.items() if not isinstance(v["values"], list)}
    variable_params = {k: v for k, v in config_data.items() if isinstance(v["values"], list)}

    # generate all combinations of variable parameters
    param_combinations = list(itertools.product(*[v["values"] for v in variable_params.values()]))

    # ensure index is within range
    if index >= len(param_combinations):
        raise ValueError(f"Index {index} is out of range. Only {len(param_combinations)} experiments available.")

    # construct parameter set
    experiment_params = {k: v["values"] for k, v in fixed_params.items()}  # copy fixed params
    experiment_params.update({
        k: param_combinations[index][i] for i, (k, v) in enumerate(variable_params.items())
    })  # add selected combination for variable params
    
    # copy short names
    short_names = {k: v["short"] for k, v in variable_params.items()}  

    return experiment_params, short_names, fixed_params, variable_params

# comment the click commands for testing
@click.command()
@click.option('--config', type=str, required=True, help="path to config JSON file")
@click.option('--index', type=int, required=True, help="index of the parameter set")
def experiment(config, index):

    # read the parameters from the config file
    experiment_params, short_names, fixed_params, variable_params = read_params(config, index)
    globals().update(experiment_params)
    
    # make sure N>1
    if N < 2:
        raise ValueError('N must be greater than 1')

    # initialize the random number generator
    rng = np.random.default_rng(seed=seed)

    summary = {}
    summary['parameters'] = {**experiment_params}

    # initialize the results arrays
    winner_results = np.zeros(iterations, dtype=int)
    winner_votes_results = np.zeros(iterations, dtype=int)
    diff_results = np.zeros(iterations, dtype=int)
    abstained_results = np.zeros(iterations, dtype=int)
    votes_zeroone_results = np.zeros((iterations, 2), dtype=int)

    print('Computing...')
    for i in range(iterations):
        # perform computation
        votes, abstained = compute(N, prob, rng)

        # summarize the quantities of interest
        winner, winner_votes, diff, votes_zeroone = summarize(votes, abstained)

        # save the results
        winner_results[i] = winner
        winner_votes_results[i] = winner_votes
        diff_results[i] = diff
        abstained_results[i] = abstained
        votes_zeroone_results[i] = votes_zeroone

    # save the results of all iterations
    summary['iteration_results'] = {
        'winner' : winner_results.tolist(),
        'winner_votes' : winner_votes_results.tolist(),
        'diff' : diff_results.tolist(),
        'abstained' : abstained_results.tolist(),
        'votes_zeroone' : votes_zeroone_results.T.tolist()  # this is to match with the julia json output (prints per column)
    }

    # perform some aggregation
    avg_num_abstained = np.mean(abstained_results)
    most_common_winner = np.argmax(np.bincount(winner_results))

    # save the aggregated results
    summary['total_results'] = {
        'avg_num_abstained' : avg_num_abstained,
        'most_common_winner' : most_common_winner
    }

    print('Converting to native Python types...')
    # convert all values in summary to native Python types
    summary = convert_to_native(summary)

    print('Saving results...')
    # include the variable parameters into the filename
    filename = f'{exp_name}_' + '_'.join([f'{short_names[key]}={summary["parameters"][key]}' for key in variable_params.keys()]) + '_.json'
    with open(f'{output_dir}/{filename}', 'w') as f:
        json.dump(summary, f)

    print('Done!')

    return


if __name__ == '__main__':
    # comment for testing
    experiment()
    # uncomment for testing
    # experiment('configs/experiment.json', 0)