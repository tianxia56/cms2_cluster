#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4000

# Extract population IDs from the config file
config_file="config.json"
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))
simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')

echo "Starting FST and ΔDAF computation script..."

# Function to run FST and ΔDAF computations for all population pairs
run_fst_deldaf() {
    local sim_id=$1
    
    echo "Processing simulation ID: $sim_id"
    
    start_time=$(date +%s)
    Rscript compute_fst_deldaf.R "$sim_id" "${pop_ids[@]}"
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "Runtime for simulation ID $sim_id: $runtime seconds" >> "two_pop_stats/fst.runtime.txt"
}

# Function to check if all TPED files exist for a simulation
check_files_exist() {
    local sim_id=$1
    for pop_id in "${pop_ids[@]}"; do
        tped_file="sel/sel.hap.${sim_id}_0_${pop_id}.tped"
        if [[ ! -f "$tped_file" ]]; then
            return 1
        fi
    done
    return 0
}

# Monitor and process simulations
processed_files=()
while true; do
    # Process TPED files for each simulation
    for ((sim_id=0; sim_id<=simulation_number; sim_id++)); do
        if check_files_exist "$sim_id"; then
            if [[ ! " ${processed_files[@]} " =~ " ${sim_id} " ]]; then
                run_fst_deldaf "$sim_id"
                processed_files+=("${sim_id}")
            fi
        fi
    done

    # Check if all simulations have been processed
    if [[ ${#processed_files[@]} -eq $((simulation_number + 1)) ]]; then
        echo "Processed all required TPED files. Exiting."
        break  # Exit the while loop
    fi

    sleep 10  # Wait before checking for new files
done

echo "FST and ΔDAF statistics for selected simulations have been calculated and saved in the two_pop_stats directory."
