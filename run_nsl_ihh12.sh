#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8000

# Read inputs from JSON file using Python
config_file="config.json"
selected_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')
neutral_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["neutral_simulation_number"])')

# Debugging output
echo "Selected Simulation Number: $selected_simulation_number"
echo "Neutral Simulation Number: $neutral_simulation_number"

# Create the one_pop_stats directory if it doesn't exist
mkdir -p one_pop_stats

# Function to run selscan commands for a given TPED file
run_selscan() {
    local tped_file=$1
    local base_name=$(basename $tped_file .tped)
    
    start_time=$(date +%s)
    selscan --nsl --tped $tped_file --out one_pop_stats/$base_name.nsl --threads 4
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "nsl runtime for $base_name: $runtime seconds" >> one_pop_stats/runtime.txt
    
    start_time=$(date +%s)
    selscan --ihh12 --tped $tped_file --out one_pop_stats/$base_name.ihh12 --threads 4
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "ihh12 runtime for $base_name: $runtime seconds" >> one_pop_stats/runtime.txt
}

# Monitor the sel and neut directories for new TPED files and run selscan commands on them
processed_files=()
total_simulations=$((selected_simulation_number + neutral_simulation_number))
while true; do
    for ((sim_id=0; sim_id<=selected_simulation_number; sim_id++)); do
        tped_file="sel/sel.hap.${sim_id}_0_1.tped"
        if [[ ! " ${processed_files[@]} " =~ " ${tped_file} " ]]; then
            if [[ -f "$tped_file" ]]; then
                run_selscan "$tped_file"
                processed_files+=("$tped_file")
            fi
        fi
    done
    for ((sim_id=0; sim_id<=neutral_simulation_number; sim_id++)); do
        tped_file="neut/neut.hap.${sim_id}_0_1.tped"
        if [[ ! " ${processed_files[@]} " =~ " ${tped_file} " ]]; then
            if [[ -f "$tped_file" ]]; then
                run_selscan "$tped_file"
                processed_files+=("$tped_file")
            fi
        fi
    done
    if [[ ${#processed_files[@]} -ge $total_simulations ]]; then
        echo "Processed all required TPED files for NSL and IHH12. Exiting."
        break
    fi
    sleep 10
done

echo "NSL and IHH12 statistics have been calculated and saved in the one_pop_stats directory."
