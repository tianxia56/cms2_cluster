args <- commandArgs(trailingOnly = TRUE)
sim_id <- as.integer(args[1])
pair_id <- args[2]

input_file <- paste0("two_pop_stats/sel.", sim_id, "_", pair_id, ".xpehh.out")
output_file <- paste0("norm/temp.xpehh.", sim_id, "_", pair_id, ".tsv")

# Read the input file
data <- read.table(input_file, header = TRUE)
colnames(data) <- c("id", "pos", "gpos", "daf", "ihh1", "p2", "ihh2", "xpehh")

# Extract relevant columns
data <- data[, c("pos", "daf", "xpehh")]

# Read the normalization file
norm_file <- paste0("norm/norm_xpehh_", pair_id, ".bin")
norm_data <- read.table(norm_file, header = TRUE)

# Function to find the closest bin
find_closest_bin <- function(daf, norm_data) {
  idx <- which.min(abs(norm_data$bin - daf))
  return(norm_data[idx, ])
}

# Normalize xpehh
data$norm_xpehh <- apply(data, 1, function(row) {
  bin_info <- find_closest_bin(row["daf"], norm_data)
  mean <- bin_info$mean
  std <- bin_info$std
  norm_xpehh <- (row["xpehh"] - mean) / std
  return(round(norm_xpehh, 4))
})

# Save the output
write.table(data, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
