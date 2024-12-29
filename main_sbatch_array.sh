#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8000

# Create output directory if it doesn't exist
mkdir -p output

# Function to record job runtime
record_runtime() {
    job_name=$1
    start_time=$2
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    runtime_formatted=$(printf '%02d:%02d:%02d' $((runtime/3600)) $((runtime%3600/60)) $((runtime%60)))
    echo "Job name: $job_name, runtime: $runtime_formatted" >> output/totalruntime.txt
}

# Record the start time of the entire process
start_time_total=$(date +%s)

job_ids=()

# Submit tasks for selected simulations
start_time=$(date +%s)
job_id=$(sbatch --parsable run_cosi2_even_sel.sh)
job_ids+=($job_id)
record_runtime "run_cosi2_even_sel.sh" $start_time

start_time=$(date +%s)
job_id=$(sbatch --parsable run_cosi2_odd_sel.sh)
job_ids+=($job_id)
record_runtime "run_cosi2_odd_sel.sh" $start_time

# Submit a single task for neutral simulations
start_time=$(date +%s)
job_id=$(sbatch --parsable run_cosi2_neut.sh)
job_ids+=($job_id)
record_runtime "run_cosi2_neut.sh" $start_time

# Submit the one pop stats task (ihs, nsl, ihh12) for both sel and neut separately, optimize runtime
start_time=$(date +%s)
job_id=$(sbatch --parsable run_ihs_sel.sh)
job_ids+=($job_id)
record_runtime "run_ihs_sel.sh" $start_time

start_time=$(date +%s)
job_id=$(sbatch --parsable run_ihs_neut.sh)
job_ids+=($job_id)
record_runtime "run_ihs_neut.sh" $start_time

# Combine nsl and ihh12 into one job
start_time=$(date +%s)
job_id=$(sbatch --parsable run_nsl_ihh12.sh)
job_ids+=($job_id)
record_runtime "run_nsl_ihh12.sh" $start_time

# Submit the run_isafe.sh task to run in parallel (isafe, DAF) for selected sims
start_time=$(date +%s)
job_id=$(sbatch --parsable run_isafe.sh)
job_ids+=($job_id)
record_runtime "run_isafe.sh" $start_time

# Extract population IDs from the original par file
config_file="config.json"
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
simulation_serial_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["simulation_serial_number"])')
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))

# Submit fst deldaf.sh task before xpehh tasks
start_time=$(date +%s)
job_id=$(sbatch --parsable --export=ALL,pop_ids="${pop_ids[*]}" run_fst_deldaf.sh)
job_ids+=($job_id)
record_runtime "run_fst_deldaf.sh" $start_time

# Pass the pairwise population IDs for two pop stats tasks (xpehh for both sel and neut)
xpehh_job_ids=()
for ((i=0; i<${#pop_ids[@]}; i++)); do
    for ((j=i+1; j<${#pop_ids[@]}; j++)); do
        pop1=${pop_ids[$i]}
        pop2=${pop_ids[$j]}
        # Submit pairwise tasks for xpehh sel
        start_time=$(date +%s)
        job_id=$(sbatch --parsable --export=ALL,pop1=$pop1,pop2=$pop2 run_xpehh_sel.sh)
        xpehh_job_ids+=($job_id)
        record_runtime "run_xpehh_sel.sh ($pop1 vs $pop2)" $start_time

        # Submit pairwise tasks for xpehh neut
        start_time=$(date +%s)
        job_id=$(sbatch --parsable --export=ALL,pop1=$pop1,pop2=$pop2 run_xpehh_neut.sh)
        xpehh_job_ids+=($job_id)
        record_runtime "run_xpehh_neut.sh ($pop1 vs $pop2)" $start_time
    done
done

# Submit the final task to normalize, collate stats and format results
start_time=$(date +%s)
final_job_id=$(sbatch --parsable --dependency=afterok:${job_ids[*]} make_norm_file.sh)
record_runtime "make_norm_file.sh" $start_time
echo "Final job submitted with ID: $final_job_id"

# Submit parallel normalization jobs after make_norm_file.sh
norm_jobs=()
start_time=$(date +%s)
norm_jobs+=($(sbatch --parsable --dependency=afterok:$final_job_id norm_ihs.sh))
norm_jobs+=($(sbatch --parsable --dependency=afterok:$final_job_id norm_nsl.sh))
norm_jobs+=($(sbatch --parsable --dependency=afterok:$final_job_id norm_ihh12.sh))
norm_jobs+=($(sbatch --parsable --dependency=afterok:$final_job_id norm_delihh.sh))
record_runtime "norm_one_pop_stats.sh" $start_time

# Submit norm_xpehh.sh for each pair_id
for ((i=0; i<${#pop_ids[@]}; i++)); do
    for ((j=i+1; j<${#pop_ids[@]}; j++)); do
        pop1=${pop_ids[$i]}
        pop2=${pop_ids[$j]}
        pair_id=${pop1}_vs_${pop2}
        start_time=$(date +%s)
        norm_jobs+=($(sbatch --parsable --dependency=afterok:$final_job_id norm_xpehh.sh $pair_id))
        record_runtime "norm_xpehh.sh ($pair_id)" $start_time
    done
done

# Submit final_output.sh after all normalization jobs are done
start_time=$(date +%s)
final_output_job_id=$(sbatch --parsable --dependency=afterok:${norm_jobs[*]} final_output.sh)
record_runtime "final_output.sh" $start_time
echo "final_output.sh job submitted with ID: $final_output_job_id"

# Record the total runtime
end_time_total=$(date +%s)
total_runtime=$((end_time_total - start_time_total))
total_runtime_formatted=$(printf '%02d:%02d:%02d' $((total_runtime/3600)) $((total_runtime%3600/60)) $((total_runtime%60)))
echo "Total runtime: model $demographic_model serial number $simulation_serial_number $total_runtime_formatted, Date: $(date)" >> output/totalruntime.txt