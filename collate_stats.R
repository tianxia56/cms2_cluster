args <- commandArgs(trailingOnly = TRUE)
demographic_model <- args[1]
simulation_serial_number <- as.integer(args[2])

# Create output directory if it doesn't exist
output_dir <- "output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

for (sim_id in sim_ids) {
  output_file <- paste0(output_dir, "/", demographic_model, "_cms_stats_", sim_id, ".tsv")
  
  # Read fst_deldaf file
  fst_deldaf_file <- paste0("two_pop_stats/", sim_id, "_fst_deldaf.tsv")
  fst_deldaf_data <- read.table(fst_deldaf_file, header = TRUE)
  
  # Initialize output data with fst_deldaf data
  output_data <- fst_deldaf_data
  
  # Read iSAFE file and merge
  isafe_file <- paste0("one_pop_stats/", sim_id, ".iSAFE.out")
  isafe_data <- read.table(isafe_file, header = TRUE)
  colnames(isafe_data)[1] <- "pos"
  isafe_data$iSAFE <- signif(isafe_data$iSAFE, 4) # Round iSAFE to 4 significant figures
  output_data <- merge(output_data, isafe_data[, c("pos", "iSAFE")], by = "pos", all = TRUE)
  
  # Read norm_ihs file and merge
  norm_ihs_file <- paste0("norm/temp.ihs.", sim_id, ".tsv")
  norm_ihs_data <- read.table(norm_ihs_file, header = TRUE)
  output_data <- merge(output_data, norm_ihs_data[, c("pos", "norm_ihs")], by = "pos", all = TRUE)
  
  # Read norm_nsl file and merge
  norm_nsl_file <- paste0("norm/temp.nsl.", sim_id, ".tsv")
  norm_nsl_data <- read.table(norm_nsl_file, header = TRUE)
  output_data <- merge(output_data, norm_nsl_data[, c("pos", "norm_nsl")], by = "pos", all = TRUE)
  
  # Read norm_ihh12 file and merge
  norm_ihh12_file <- paste0("norm/temp.ihh12.", sim_id, ".tsv")
  norm_ihh12_data <- read.table(norm_ihh12_file, header = TRUE)
  output_data <- merge(output_data, norm_ihh12_data[, c("pos", "norm_ihh12")], by = "pos", all = TRUE)
  
  # Read norm_delihh file and merge
  norm_delihh_file <- paste0("norm/temp.delihh.", sim_id, ".tsv")
  norm_delihh_data <- read.table(norm_delihh_file, header = TRUE)
  output_data <- merge(output_data, norm_delihh_data[, c("pos", "norm_delihh")], by = "pos", all = TRUE)
  
  # Read norm_mean_xpehh file and merge
  norm_mean_xpehh_file <- paste0("norm/temp.mean.xpehh.", sim_id, ".tsv")
  norm_mean_xpehh_data <- read.table(norm_mean_xpehh_file, header = TRUE)
  output_data <- merge(output_data, norm_mean_xpehh_data[, c("pos", "mean_xpehh")], by = "pos", all = TRUE)
  
  # Add sim_id and sim_batch_no as the first columns
  output_data$sim_id <- sim_id
  output_data$sim_batch_no <- simulation_serial_number
  output_data <- output_data[, c("sim_batch_no", "sim_id", setdiff(names(output_data), c("sim_batch_no", "sim_id")))]
  
  # Save the output data to file
  write.table(output_data, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
}

# Get the current date
current_date <- Sys.Date()

# Zip all the output files into one single tsv zip with the current date in the name
zipfile <- paste0(output_dir, "/", demographic_model, "_cms_stats_all_", current_date, ".zip")
system(paste("zip -j", zipfile, paste0(output_dir, "/", demographic_model, "_cms_stats_*.tsv")))

# Remove the individual tsv files after making the zip
file.remove(list.files(output_dir, pattern = "*.tsv", full.names = TRUE))
