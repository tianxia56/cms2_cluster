#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16000

config_file="config.json"
selected_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')

# Monitor the one_pop_stats directory for _0_1.nsl.nsl.out files and run selscan commands on them
for ((sim_id=0; sim_id<=selected_simulation_number; sim_id++)); do
    Rscript norm_nsl.R $sim_id
done
