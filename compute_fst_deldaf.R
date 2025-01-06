#!/usr/bin/env Rscript

library(data.table)

# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)
sim_id <- args[1]
pop1 <- as.integer(args[2])
pop_ids <- as.integer(args[3:length(args)])

# Function to compute FST between two populations
compute_fst <- function(daf1, daf2) {
  H_s <- (daf1 * (1 - daf1) + daf2 * (1 - daf2)) / 2
  H_t <- ((daf1 + daf2) / 2) * (1 - (daf1 + daf2) / 2)
  if (H_t == 0) {
    return(0)
  } else {
    return((H_t - H_s) / H_t)
  }
}

# Check if TPED files exist
for (pop_id in pop_ids) {
  tped_file <- paste0("sel/sel.hap.", sim_id, "_0_", pop_id, ".tped")
  if (!file.exists(tped_file)) {
    stop(paste("File", tped_file, "does not exist or is non-readable."))
  }
}

# Read the position column (4th column) from one TPED file (all files share the same positions)
pos_list <- fread(paste0("sel/sel.hap.", sim_id, "_0_", pop1, ".tped"), select = 4)[[1]]

# Read the genetic data (5th column onward) for each population
pop_data_list <- lapply(pop_ids, function(pop_id) {
  tped_file <- paste0("sel/sel.hap.", sim_id, "_0_", pop_id, ".tped")
  fread(tped_file, select = 5:ncol(fread(tped_file)))
})

# Compute derived allele frequency (DAF) for each population
daf_list <- lapply(pop_data_list, function(pop_data) {
  rowMeans(pop_data == 1)
})

# Combine DAF values into a matrix for easier computation
daf_matrix <- do.call(cbind, daf_list)

# Create a results table using the positions from the TPED file
results <- data.table(sim_id = sim_id, pos = pos_list)

# Compute FST for pop1 versus other populations
for (i in 1:length(pop_ids)) {
  if (pop_ids[i] != pop1) {
    fst_values <- mapply(compute_fst, daf_matrix[, which(pop_ids == pop1)], daf_matrix[, i])
    results[, paste0("fst_", pop1, "_vs_", pop_ids[i]) := fst_values]
  }
}

# Compute mean FST for each position
results[, mean_fst := rowMeans(.SD, na.rm = TRUE), .SDcols = patterns("^fst_")]

# Compute ΔDAF as the difference between the highest and lowest DAF across populations
results[, deldaf := apply(daf_matrix, 1, function(daf_values) {
  max(daf_values, na.rm = TRUE) - min(daf_values, na.rm = TRUE)
})]

# Compute DAF and MAF for each position (using the first population as reference)
results[, daf := daf_matrix[, which(pop_ids == pop1)]]  # Reference population (pop1's DAF)
results[, maf := pmin(daf, 1 - daf)]

# Format numerical columns to 4 decimal places or scientific notation if < 0.001
format_value <- function(x) {
  ifelse(x < 0.001, format(x, scientific = TRUE, digits = 4), round(x, 4))
}

results[, mean_fst := as.character(sapply(mean_fst, format_value))]
results[, deldaf := as.character(sapply(deldaf, format_value))]
results[, daf := as.character(sapply(daf, format_value))]
results[, maf := as.character(sapply(maf, format_value))]

# Write results to a file
output_file <- paste0("two_pop_stats/", sim_id, "_fst_deldaf.tsv")
fwrite(results[, .(sim_id, pos, mean_fst, deldaf, daf, maf)], output_file, sep = "\t", quote = FALSE)

cat("Finished processing simulation ID:", sim_id, "\n")