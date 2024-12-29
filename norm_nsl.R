args <- commandArgs(trailingOnly = TRUE)
sim_id <- as.integer(args[1])

input_file <- paste0("one_pop_stats/sel.hap.", sim_id, "_0_1.nsl.nsl.out")
output_file <- paste0("norm/temp.nsl.", sim_id, ".tsv")

# Read the input file
data <- read.table(input_file, header = FALSE)
colnames(data) <- c("locus", "pos", "daf", "sl1", "sl0", "nsl")

# Extract relevant columns
data <- data[, c("pos", "daf", "nsl")]

# Read the normalization file
norm_data <- read.table("norm/norm_nsl.bin", header = TRUE)

# Function to find the closest bin
find_closest_bin <- function(daf, norm_data) {
  idx <- which.min(abs(norm_data$bin - daf))
  return(norm_data[idx, ])
}

# Normalize nsl
data$norm_nsl <- apply(data, 1, function(row) {
  bin_info <- find_closest_bin(row["daf"], norm_data)
  mean <- bin_info$mean
  std <- bin_info$std
  norm_nsl <- (row["nsl"] - mean) / std
  return(round(norm_nsl, 4))
})

# Save the output
write.table(data, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
