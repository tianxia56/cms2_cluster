args <- commandArgs(trailingOnly = TRUE)
sim_id <- as.integer(args[1])
pair_id <- args[2]

input_file <- paste0("norm/temp.xpehh.", sim_id, "_", pair_id, ".tsv")
output_file <- paste0("norm/temp.mean.xpehh.", sim_id, ".tsv")

# Read the input file
data <- read.table(input_file, header = TRUE)

# Calculate mean_xpehh for each position
mean_xpehh <- aggregate(norm_xpehh ~ pos, data, mean)

# Select relevant columns
mean_xpehh <- mean_xpehh[, c("pos", "norm_xpehh")]
colnames(mean_xpehh) <- c("pos", "mean_xpehh")

# Save the output
write.table(mean_xpehh, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
