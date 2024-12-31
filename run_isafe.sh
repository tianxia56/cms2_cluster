#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8000

# Read inputs from JSON file using Python
config_file="config.json"
selected_simulation_number=$(python3 -c "import json; print(json.load(open('$config_file'))['selected_simulation_number'])")

# Monitor the sel directory for new TPED files and run process_hap_and_run_isafe.py
processed_files=()
while true; do
    for ((sim_id=0; sim_id<=selected_simulation_number; sim_id++)); do
        tped_file="sel/sel.hap.${sim_id}_0_1.tped"
        if [[ ! " ${processed_files[@]} " =~ " ${tped_file} " ]]; then
            if [[ -f "$tped_file" ]]; then
                echo "Processing $tped_file"
                start_time=$(date +%s)
                python process_hap_and_run_isafe.py "$sim_id"
                end_time=$(date +%s)
                runtime=$((end_time - start_time))
                echo "process_hap_and_run_isafe.py runtime for $tped_file: $runtime seconds" >> one_pop_stats/isafe.runtime.txt
                processed_files+=("$tped_file")
            fi
        fi
    done
    if [[ ${#processed_files[@]} -ge $((selected_simulation_number + 1)) ]]; then
        echo "Processed all required TPED files. Exiting."
        break
    fi
    sleep 10
done
