import os
import numpy as np
import pandas as pd
import sys
from itertools import combinations

def extract_columns(file_path, columns):
    """
    Extract specified columns from a file. If columns are missing, an exception is raised.
    """
    df = pd.read_csv(file_path, sep=r'\s+', header=None, engine='python')
    if df.shape[1] < max(columns) + 1:
        raise IndexError(f"File {file_path} does not have enough columns. Expected: {max(columns)+1}, Found: {df.shape[1]}")
    return df.iloc[:, columns]

def compute_delihh(df):
    """
    Compute delihh as the sum of columns 6 and 7 minus columns 8 and 9.
    """
    df['delihh'] = df[6] + df[7] - df[8] - df[9]
    return df[[1, 'delihh', 2]]

def create_bins_and_stats(scores, dafs, n_bins):
    """
    Create bins and calculate statistics for scores based on derived allele frequencies (DAFs).
    """
    dafs = pd.to_numeric(dafs, errors='coerce')
    scores = pd.to_numeric(scores, errors='coerce')
    valid_indices = ~np.isnan(dafs) & ~np.isnan(scores)
    dafs = dafs[valid_indices]
    scores = scores[valid_indices]
    
    bins = np.linspace(dafs.min(), dafs.max(), n_bins + 1)
    bin_means = []
    bin_stds = []
    for i in range(n_bins):
        bin_scores = scores[(dafs >= bins[i]) & (dafs < bins[i + 1])]
        if len(bin_scores) > 0:
            bin_means.append(bin_scores.mean())
            bin_stds.append(bin_scores.std())
        else:
            bin_means.append(np.nan)
            bin_stds.append(np.nan)
    return bins, bin_means, bin_stds

# Ensure the 'norm' directory exists
os.makedirs('norm', exist_ok=True)

# Read command-line arguments
sim_id = int(sys.argv[1])
pair_ids = sys.argv[2].split(',')

# Define file paths and parameters
sim_ids = [sim_id]
n_bins = 20

# Initialize lists to store combined data
combined_ihs = []
combined_nsl = []
combined_ihh12 = []
combined_delihh = []
combined_xpehh = {pair_id: [] for pair_id in pair_ids}

# Loop through each sim_id and extract data
for sim_id in sim_ids:
    ihs_file_path = f'one_pop_stats/neut.hap.{sim_id}_0_1.ihs.ihs.out'
    nsl_file_path = f'one_pop_stats/neut.hap.{sim_id}_0_1.nsl.nsl.out'
    ihh12_file_path = f'one_pop_stats/neut.hap.{sim_id}_0_1.ihh12.ihh12.out'

    # Check if files exist before attempting to read them
    if not os.path.exists(ihs_file_path):
        print(f"File not found: {ihs_file_path}")
        continue
    if not os.path.exists(nsl_file_path):
        print(f"File not found: {nsl_file_path}")
        continue
    if not os.path.exists(ihh12_file_path):
        print(f"File not found: {ihh12_file_path}")
        continue

    try:
        # Extract columns for ihs
        ihs_df = extract_columns(ihs_file_path, [1, 2, 5])
        combined_ihs.append(ihs_df)

        # Extract columns for nsl
        nsl_df = extract_columns(nsl_file_path, [1, 2, 5])
        combined_nsl.append(nsl_df)

        # Extract columns for ihh12
        ihh12_df = extract_columns(ihh12_file_path, [1, 2, 3])
        combined_ihh12.append(ihh12_df)

        # Compute delihh and extract columns
        delihh_df = compute_delihh(pd.read_csv(ihs_file_path, sep=r'\s+', header=None, engine='python'))
        combined_delihh.append(delihh_df)

    except IndexError as e:
        print(f"Skipping due to error: {e}")
        continue

    # Extract columns for xpehh for each pair_id
    for pair_id in pair_ids:
        xpehh_file_path = f'two_pop_stats/neut.{sim_id}_{pair_id}.xpehh.out'
        if not os.path.exists(xpehh_file_path):
            print(f"File not found: {xpehh_file_path}")
            continue
        try:
            xpehh_df = extract_columns(xpehh_file_path, [1, 3, 7])
            combined_xpehh[pair_id].append(xpehh_df)
        except IndexError as e:
            print(f"Skipping xpehh file {xpehh_file_path} due to error: {e}")
            continue

# Combine data from all sim_ids
combined_ihs_df = pd.concat(combined_ihs) if combined_ihs else pd.DataFrame()
combined_nsl_df = pd.concat(combined_nsl) if combined_nsl else pd.DataFrame()
combined_ihh12_df = pd.concat(combined_ihh12) if combined_ihh12 else pd.DataFrame()
combined_delihh_df = pd.concat(combined_delihh) if combined_delihh else pd.DataFrame()

# Extract DAFs from ihh data
dafs_ihh = combined_ihs_df.iloc[:, 1]  # Assuming column 1 in ihs_df is DAF

# Create bins and calculate statistics for each metric
if not combined_ihs_df.empty:
    bins_ihs, means_ihs, stds_ihs = create_bins_and_stats(combined_ihs_df.iloc[:, 2], combined_ihs_df.iloc[:, 1], n_bins)
    pd.DataFrame({'bin': bins_ihs[:-1], 'mean': means_ihs, 'std': stds_ihs}).to_csv('norm/norm_ihs.bin', sep='\t', index=False)
if not combined_nsl_df.empty:
    bins_nsl, means_nsl, stds_nsl = create_bins_and_stats(combined_nsl_df.iloc[:, 2], combined_nsl_df.iloc[:, 1], n_bins)
    pd.DataFrame({'bin': bins_nsl[:-1], 'mean': means_nsl, 'std': stds_nsl}).to_csv('norm/norm_nsl.bin', sep='\t', index=False)
if not combined_ihh12_df.empty:
    bins_ihh12, means_ihh12, stds_ihh12 = create_bins_and_stats(combined_ihh12_df.iloc[:, 2], combined_ihh12_df.iloc[:, 1], n_bins)
    pd.DataFrame({'bin': bins_ihh12[:-1], 'mean': means_ihh12, 'std': stds_ihh12}).to_csv('norm/norm_ihh12.bin', sep='\t', index=False)
if not combined_delihh_df.empty:
    bins_delihh, means_delihh, stds_delihh = create_bins_and_stats(combined_delihh_df['delihh'], dafs_ihh, n_bins)
    pd.DataFrame({'bin': bins_delihh[:-1], 'mean': means_delihh, 'std': stds_delihh}).to_csv('norm/norm_delihh.bin', sep='\t', index=False)

# Process and save xpehh data for each pair_id
for pair_id in pair_ids:
    if combined_xpehh[pair_id]:
        combined_xpehh_df = pd.concat(combined_xpehh[pair_id])
        bins_xpehh, means_xpehh, stds_xpehh = create_bins_and_stats(combined_xpehh_df.iloc[:, 2], combined_xpehh_df.iloc[:, 1], n_bins)
        pd.DataFrame({'bin': bins_xpehh[:-1], 'mean': means_xpehh, 'std': stds_xpehh}).to_csv(f'norm/norm_xpehh_{pair_id}.bin', sep='\t', index=False)

print("Bin files have been successfully saved in the 'norm' directory.")
