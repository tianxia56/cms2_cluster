#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32000

# Define variables
config_file="config.json"
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
simulation_serial_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["simulation_serial_number"])')
selected_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')

# Loop through simulations and populations
for ((sim_id=0; sim_id<=selected_simulation_number; sim_id++)); do
    pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))
    for ((i=0; i<${#pop_ids[@]}; i++)); do
        for ((j=i+1; j<${#pop_ids[@]}; j++)); do
            pop1=${pop_ids[$i]}
            pop2=${pop_ids[$j]}
            pair_id=${pop1}_vs_${pop2}
            Rscript make_mean_xpehh.R $sim_id $pair_id
        done
    done
done

# Call make-output.R
Rscript make-output.R
