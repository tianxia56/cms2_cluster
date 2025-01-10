#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16000

# Define variables
config_file="config.json"
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
simulation_serial_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["simulation_serial_number"])')
selected_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')

# Extract population IDs
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))

# Loop through simulations and populations
for ((sim_id=0; sim_id<=selected_simulation_number; sim_id++)); do
    for ((i=0; i<${#pop_ids[@]}; i++)); do
        if [[ ${pop_ids[$i]} != $pop1 ]]; then
            pop2=${pop_ids[$i]}
            pair_id=${pop1}_vs_${pop2}
            Rscript make_max_xpehh.R $sim_id $pair_id
        fi
    done
done

# Call make-output.R
Rscript make-output.R

# upload to gcloud
/home/tx56/google-cloud-sdk/bin/gsutil cp ${demographic_model}_batch${selected_simulation_number}_cms_stats_all_*.zip gs://fc-97de97ff-f4ee-414a-bf2d-a5f045b20a79/yale_cluster_sim_stats/${demographic_model%.par}
