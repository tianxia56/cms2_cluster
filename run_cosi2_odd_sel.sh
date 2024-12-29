#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8000

# Read inputs from JSON file using Python
config_file="config.json"
selected_simulation_number=$(python3 -c "import json; print(json.load(open('$config_file'))['selected_simulation_number'])")
demographic_model=$(python3 -c "import json; print(json.load(open('$config_file'))['demographic_model'])")
selective_sweep=$(python3 -c "import json; print(json.load(open('$config_file'))['selective_sweep'])")

# Debugging output
echo "Selected Simulation Number: $selected_simulation_number"
echo "Demographic Model: $demographic_model"
echo "Selective Sweep: $selective_sweep"

# Export variables to be used inside Apptainer
export demographic_model
export selective_sweep
export selected_simulation_number

apptainer exec --bind $(pwd):/home cosi.sif /bin/bash <<EOF
echo "Inside Apptainer"
echo "Demographic Model: \$demographic_model"
echo "Selective Sweep: \$selective_sweep"

run_command() {
    local output_name=\$1
    local sim_id=\$2
    local demographic_model=\$3
    local sweep=\$4

    # Debugging output
    echo "Running command with:"
    echo "Output Name: \$output_name"
    echo "Simulation ID: \$sim_id"
    echo "Demographic Model: \$demographic_model"
    echo "Sweep: \$sweep"

    # Create the output directory if it doesn't exist
    mkdir -p ../sel

    # Make a copy of the .par file
    cp ../\${demographic_model} ../\${demographic_model}-\${sim_id}.par

    # Add the sweep to the copied .par file
    echo "\$sweep" >> ../\${demographic_model}-\${sim_id}.par

    # Run the command and record runtime
    while true; do
        start_time=\$(date +%s)
        env COSI_NEWSIM=1 COSI_MAXATTEMPTS=1000000 coalescent -p ../\${demographic_model}-\${sim_id}.par -v -g --genmapRandomRegions --drop-singletons .25 --tped ../sel/sel.\${output_name} -n 1 -M -r 0 &
        local cmd_pid=\$!

        # Wait for the command to finish or timeout after 60 seconds
        local timeout=60
        local elapsed=0
        while kill -0 \$cmd_pid 2>/dev/null; do
            sleep 1
            elapsed=\$((elapsed + 1))
            if [ \$elapsed -ge \$timeout ]; then
                echo "Command running too long, killing process..."
                kill -9 \$cmd_pid
                break
            fi
        done

        # Check if the command succeeded
        if wait \$cmd_pid; then
            break
        else
            echo "Retrying simulation ID \$sim_id..."
        fi
    done

    end_time=\$(date +%s)
    runtime=\$((end_time - start_time))

    # Record runtime
    echo "sim \$sim_id: \$runtime seconds" >> ../sel/sel.runtime.txt

    # Remove the copied .par file
    rm ../\${demographic_model}-\${sim_id}.par
}

# Loop to run the command for each odd output name in the specified range
for a in \$(seq 1 2 \$selected_simulation_number); do
    output_name="hap.\$a"
    run_command \$output_name \$a "\$demographic_model" "\$selective_sweep"
done

# Restart the loop from the last sequence if needed
for a in \$(seq \$((selected_simulation_number + 1)) 2 \$selected_simulation_number); do
    output_name="hap.\$a"
    run_command \$output_name \$a "\$demographic_model" "\$selective_sweep"
done
EOF
