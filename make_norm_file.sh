#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32000

#make norm bin files
# Read inputs from JSON file using Python
config_file="config.json"
neutral_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["neutral_simulation_number"])')
echo "Neutral Simulation Number: $neutral_simulation_number"

# Extract population IDs
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))

# Generate all possible pairs of population IDs and pass to make_norm_file.py
for ((i=0; i<${#pop_ids[@]}; i++)); do
    for ((j=i+1; j<${#pop_ids[@]}; j++)); do
        pop1=${pop_ids[$i]}
        pop2=${pop_ids[$j]}
        pair_ids="${pop1}_vs_${pop2}"
        
        # Assign sim_id correctly
        sim_id=$neutral_simulation_number
        
        # Pass sim_id and pair_ids to make_norm_file.py
        python make_norm_file.py "$sim_id" "$pair_ids"
    done
done
