import subprocess
import pandas as pd
import os
import random
import sys

def is_numeric(value):
    try:
        float(value)
        return True
    except ValueError:
        return False

def process_file(input_file, output_file):
    with open(input_file, 'r') as file, open(output_file, 'w') as new_file:
        for line in file:
            columns = line.split()[3:]
            if is_numeric(columns[0]):
                columns[0] = str(int(float(columns[0])))
            new_file.write('\t'.join(columns) + '\n')

def extract_10_percent_pairs(tped_file):
    with open(tped_file, 'r') as file:
        lines = file.readlines()

    selected_columns = []
    for line in lines:
        columns = line.split()[4:]  # Remove the first four columns
        pairs = [columns[i:i+2] for i in range(0, len(columns), 2)]  # Create pairs
        num_pairs = len(pairs)
        num_to_select = max(1, int(0.1 * num_pairs))  # Select 10% of the pairs, at least one pair
        selected_pairs = random.sample(pairs, num_to_select)
        selected_columns.append([item for sublist in selected_pairs for item in sublist])

    return selected_columns

def add_extra_columns(hap_file, tped_file):
    # Extract 10% of paired columns from the second .tped file
    extra_columns = extract_10_percent_pairs(tped_file)

    # Read the original hap file and append the extra columns to each line
    hap_df = pd.read_csv(hap_file, sep='\t', header=None)
    extra_columns_df = pd.DataFrame(extra_columns)
    # Concatenate the original hap file with the extra columns
    combined_df = pd.concat([hap_df, extra_columns_df], axis=1)
    
    # Save the combined dataframe to the hap file
    combined_df.to_csv(hap_file, sep='\t', header=False, index=False)

def run_isafe(input_file, output_prefix):
    command = f"isafe --input {input_file} --output {output_prefix} --format hap"
    subprocess.run(command, shell=True)

def main(sim_id):
    tped_file_1 = f"sel/sel.hap.{sim_id}_0_1.tped"
    
    if not os.path.exists(tped_file_1):
        print(f"Skipping {sim_id} as {tped_file_1} does not exist.")
        return

    output_hap_file = f"one_pop_stats/{sim_id}.hap"

    # Process .tped file into .hap format
    process_file(tped_file_1, output_hap_file)
    # Add extra columns to the .hap file
    add_extra_columns(output_hap_file, tped_file_1)
    # Run iSAFE tool
    print(f"Running iSAFE on {output_hap_file}")
    run_isafe(output_hap_file, f"one_pop_stats/{sim_id}")

    # Clean up intermediate files but keep iSAFE.out file
    os.remove(output_hap_file)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python process_hap_and_run_isafe.py <sim_id>")
        sys.exit(1)
    
    sim_id = sys.argv[1]
    main(sim_id)
