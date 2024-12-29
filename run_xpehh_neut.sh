#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8000

# Read inputs from JSON file using Python
config_file="config.json"
neutral_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["neutral_simulation_number"])')

# Debugging output
echo "Neutral Simulation Number: $neutral_simulation_number"

# Create the two_pop_stats directory if it doesn't exist
mkdir -p two_pop_stats

# Function to run selscan xpehh commands for a given pair of TPED files
run_selscan_xpehh() {
    local tped_file1=$1
    local tped_file2=$2
    local sim_id=$3
    local pop1=$4
    local pop2=$5
    
    start_time=$(date +%s)
    selscan --xpehh --tped $tped_file1 --tped-ref $tped_file2 --out two_pop_stats/neut.${sim_id}_${pop1}_vs_${pop2} --threads 8
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "xpehh neut runtime for ${sim_id}_${pop1}_vs_${pop2}: $runtime seconds" >> two_pop_stats/xpehh.runtime.txt
}

# Monitor the neut directory for new TPED files and run selscan xpehh commands on them
processed_files=()
while true; do
    for ((sim_id=0; sim_id<=neutral_simulation_number; sim_id++)); do
        tped_file1="neut/neut.hap.${sim_id}_0_${pop1}.tped"
        tped_file2="neut/neut.hap.${sim_id}_0_${pop2}.tped"
        if [[ ! " ${processed_files[@]} " =~ " ${tped_file1}_${tped_file2} " ]]; then
            if [[ -f "$tped_file1" && -f "$tped_file2" ]]; then
                run_selscan_xpehh "$tped_file1" "$tped_file2" "$sim_id" "$pop1" "$pop2"
                processed_files+=("${tped_file1}_${tped_file2}")
            fi
        fi
    done
    if [[ ${#processed_files[@]} -ge $((neutral_simulation_number + 1)) ]]; then
        echo "Processed all required TPED files for XPEHH. Exiting."
        break
    fi
    sleep 10
done

echo "XPEHH statistics for neutral simulations have been calculated and saved in the two_pop_stats directory."
