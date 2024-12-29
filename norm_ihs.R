args <- commandArgs(trailingOnly = TRUE)
sim_id <- as.integer(args[1])

input_file <- paste0("one_pop_stats/sel.hap.", sim_id, "_0_1.ihs.ihs.out")
output_file <- paste0("norm/temp.ihs.", sim_id, ".tsv")

# Read the input file
data <- read.table(input_file, header = FALSE)
colnames(data) <- c("locus", "pos", "daf", "ihh_1", "ihh_0", "ihs", "derived_ihh_left", "derived_ihh_right", "ancestral_ihh_left", "ancestral_ihh_right")

# Extract relevant columns
data <- data[, c("pos", "daf", "ihs")]

# Read the normalization file
norm_data <- read.table("norm/norm_ihs.bin", header = TRUE)

# Function to find the closest bin
find_closest_bin <- function(daf, norm_data) {
  idx <- which.min(abs(norm_data$bin - daf))
  return(norm_data[idx, ])
}

# Normalize ihs
data$norm_ihs <- apply(data, 1, function(row) {
  bin_info <- find_closest_bin(row["daf"], norm_data)
  mean <- bin_info$mean
  std <- bin_info$std
  norm_ihs <- (row["ihs"] - mean) / std
  return(round(norm_ihs, 4))
})

# Save the output
write.table(data, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
