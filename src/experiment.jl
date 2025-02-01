using Random
using JSON
using Statistics
using ArgParse

function compute(N, prob)

    votes = zeros(Int, N)
    abstained = 0
    
    for i in 1:N
        if rand() < prob
            abstained += 1
        else
            eligible = collect(setdiff(1:N, [i]))
            votes[rand(eligible)] += 1
        end 
    end

    return votes, abstained
end

function summarize(votes, abstained)
    sorted_votes = sortperm(votes)
    winner = sorted_votes[end]
    winner_votes = votes[winner]
    runner_up = sorted_votes[end-1]
    diff = winner_votes - votes[runner_up]
    votes_zeroone = votes[1:2]
    return winner, winner_votes, diff, votes_zeroone
end


function experiment(args)

    # comment out the parsing for testing and set the arguments manually
    # exp_name = "test"
    # N = 10
    # iterations = 10
    # prob = 0.5
    # seed = 42
    # output_dir = "outputs"

    # parse the command line arguments
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--exp_name"
            help="Name of the experiment"
            required=true
            arg_type=String
        "--N"
            help="Number of voters"
            required=true
            arg_type=Int
        "--iterations"
            help="Number of iterations"
            required=true
            arg_type=Int
        "--prob"
            help="Probability of abstaining"
            required=true
            arg_type=Float64
        "--seed"
            help="Random seed"
            required=true
            arg_type=Int
        "--output_dir"
            help="Output directory"
            required=true
            arg_type=String
    end

    # parse the arguments
    parsed_args = parse_args(args, s)
    exp_name = parsed_args["exp_name"]
    N = parsed_args["N"]
    iterations = parsed_args["iterations"]
    prob = parsed_args["prob"]
    seed = parsed_args["seed"]
    output_dir = parsed_args["output_dir"]

    # make sure N>1
    if N < 2
        error("N must be greater than 1")
    end

    # set the random seed
    Random.seed!(seed)
    
    # initialize parameters in a dictionary
    parameters = Dict("N" => N,
                      "iterations" => iterations,
                      "prob" => prob,
                      "seed" => seed)

    # initialize iteration results in a separate dictionary (do not merge with parameters yet)
    iteration_results = Dict(
        "winner" => zeros(Int, iterations),
        "winner_votes" => zeros(Int, iterations),
        "diff" => zeros(Int, iterations),
        "abstained" => zeros(Int, iterations),
        "votes_zeroone" => zeros(Int, iterations, 2)
    )

    println("Computing...")
    for i in 1:iterations

        # perform computation
        votes, abstained = compute(N, prob)

        # summarize the quantities of interest
        w, wv, d, vz = summarize(votes, abstained)

        # save the iteration results
        iteration_results["winner"][i] = w
        iteration_results["winner_votes"][i] = wv
        iteration_results["diff"][i] = d
        iteration_results["abstained"][i] = abstained
        iteration_results["votes_zeroone"][i, :] = vz
    end

    # perform some aggregation
    avg_num_abstained = mean(iteration_results["abstained"])
    num_of_wins = zeros(Int, N)
    for val in iteration_results["winner"]
        num_of_wins[val] += 1
    end
    most_common_winner = argmax(num_of_wins)

    # save the aggregated results in a separate dictionary
    total_results = Dict(
        "avg_num_abstained" => avg_num_abstained,
        "most_common_winner" => most_common_winner,
    )
    
    # merge the parameters, iteration results, and total results into a single summary dictionary
    summary = Dict(
        "parameters" => parameters,
        "iteration_results" => iteration_results,
        "total_results" => total_results
    )

    println("Saving results...")
    # select which parameters will go into the filename and set their short names
    short_names = Dict("N" => "N", "prob" => "p")
    filename = string(exp_name, "_",
                      join([string(short_names[k], "|", summary["parameters"][k]) for k in keys(short_names)], "_"),
                      "_.json")
    open(joinpath(output_dir, filename), "w") do f
        write(f, JSON.json(summary))
    end

    println("Done!")
end

# uncomment the following line for testing
experiment(ARGS)