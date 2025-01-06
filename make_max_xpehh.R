#!/usr/bin/env Rscript

library(data.table)

# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)
sim_id <- as.integer(args[1])
pair_id <- args[2]

# Define input and output file paths
input_files <- list.files(path = "norm", pattern = paste0("temp.xpehh.", sim_id, "_.*\\.tsv"), full.names = TRUE)
output_file <- paste0("norm/temp.max.xpehh.", sim_id, ".tsv")

# Read and rename columns to avoid duplication
data_list <- lapply(seq_along(input_files), function(i) {
  data <- fread(input_files[i], select = c("pos", "norm_xpehh"))
  setnames(data, "norm_xpehh", paste0("norm_xpehh_", i))
  return(data)
})

# Perform inner join by 'pos'
merged_data <- Reduce(function(x, y) merge(x, y, by = "pos", all = FALSE), data_list)

# Calculate max_xpehh for each position
merged_data$max_xpehh <- apply(merged_data[, -1, with = FALSE], 1, function(x) {
  max(x, na.rm = TRUE)
})

# Select relevant columns
max_xpehh <- merged_data[, .(pos, max_xpehh)]

# Save the output
fwrite(max_xpehh, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)

cat("Finished processing simulation ID:", sim_id, "\n")