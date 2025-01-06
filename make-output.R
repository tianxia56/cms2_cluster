# Load necessary libraries
library(jsonlite)
library(dplyr)

# Define variables
config_file <- "config.json"
config <- fromJSON(config_file)
demographic_model <- config$demographic_model
simulation_serial_number <- config$simulation_serial_number
selected_simulation_number <- config$selected_simulation_number

# Define output directory
output_dir <- "output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Function to collate stats
collate_stats <- function(sim_id, demographic_model, simulation_serial_number) {
  output_file <- paste0(output_dir, "/", demographic_model, "_batch", simulation_serial_number, "_cms_stats_", sim_id, ".tsv")
  print(paste("Processing simulation ID:", sim_id))
  
  # Read fst_deldaf file
  fst_deldaf_file <- paste0("two_pop_stats/", sim_id, "_fst_deldaf.tsv")
  print(paste("Reading fst_deldaf file:", fst_deldaf_file))
  fst_deldaf_data <- read.table(fst_deldaf_file, header = TRUE)
  
  # Initialize output data with fst_deldaf data
  output_data <- fst_deldaf_data
  
  # Read iSAFE file and merge
  isafe_file <- paste0("one_pop_stats/", sim_id, ".iSAFE.out")
  print(paste("Reading iSAFE file:", isafe_file))
  isafe_data <- read.table(isafe_file, header = TRUE)
  colnames(isafe_data)[1] <- "pos"
  isafe_data$iSAFE <- signif(isafe_data$iSAFE, 4) # Round iSAFE to 4 significant figures
  output_data <- merge(output_data, isafe_data[, c("pos", "iSAFE")], by = "pos", all = TRUE)
  
  # Read norm_ihs file and merge
  norm_ihs_file <- paste0("norm/temp.ihs.", sim_id, ".tsv")
  print(paste("Reading norm_ihs file:", norm_ihs_file))
  norm_ihs_data <- read.table(norm_ihs_file, header = TRUE)
  output_data <- merge(output_data, norm_ihs_data[, c("pos", "norm_ihs")], by = "pos", all = TRUE)
  
  # Read norm_nsl file and merge
  norm_nsl_file <- paste0("norm/temp.nsl.", sim_id, ".tsv")
  print(paste("Reading norm_nsl file:", norm_nsl_file))
  norm_nsl_data <- read.table(norm_nsl_file, header = TRUE)
  output_data <- merge(output_data, norm_nsl_data[, c("pos", "norm_nsl")], by = "pos", all = TRUE)
  
  # Read norm_ihh12 file and merge
  norm_ihh12_file <- paste0("norm/temp.ihh12.", sim_id, ".tsv")
  print(paste("Reading norm_ihh12 file:", norm_ihh12_file))
  norm_ihh12_data <- read.table(norm_ihh12_file, header = TRUE)
  output_data <- merge(output_data, norm_ihh12_data[, c("pos", "norm_ihh12")], by = "pos", all = TRUE)
  
  # Read norm_delihh file and merge
  norm_delihh_file <- paste0("norm/temp.delihh.", sim_id, ".tsv")
  print(paste("Reading norm_delihh file:", norm_delihh_file))
  norm_delihh_data <- read.table(norm_delihh_file, header = TRUE)
  output_data <- merge(output_data, norm_delihh_data[, c("pos", "norm_delihh")], by = "pos", all = TRUE)
  
  # Read norm_max_xpehh file and merge
  norm_max_xpehh_file <- paste0("norm/temp.max.xpehh.", sim_id, ".tsv")
  print(paste("Reading norm_max_xpehh file:", norm_max_xpehh_file))
  norm_max_xpehh_data <- read.table(norm_max_xpehh_file, header = TRUE)
  output_data <- merge(output_data, norm_max_xpehh_data[, c("pos", "max_xpehh")], by = "pos", all = TRUE)
  
  # Add sim_id and sim_batch_no as the first columns
  output_data$sim_id <- sim_id
  output_data$sim_batch_no <- simulation_serial_number
  output_data <- output_data[, c("sim_batch_no", "sim_id", setdiff(names(output_data), c("sim_batch_no", "sim_id")))]
  
  # Save the output data to file
  print(paste("Saving output data to file:", output_file))
  write.table(output_data, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
}

# Loop through simulations and populations
for (sim_id in 0:selected_simulation_number) {
  pop_ids <- readLines(demographic_model) %>%
    grep("^pop_define", ., value = TRUE) %>%
    sapply(function(x) strsplit(x, " ")[[1]][2])
  
  for (i in seq_along(pop_ids)) {
    for (j in (i + 1):length(pop_ids)) {
      pop1 <- pop_ids[i]
      pop2 <- pop_ids[j]
      pair_id <- paste0(pop1, "_vs_", pop2)
      # Here you would call the make_max_xpehh function in R
      # make_max_xpehh(sim_id, pair_id)
    }
  }
  
  # Call collate_stats function
  collate_stats(sim_id, demographic_model, simulation_serial_number)
}

# Zip all the output files into one single tsv zip with the current date in the name
current_date <- format(Sys.Date(), "%Y-%m-%d")
zipfile <- paste0(output_dir, "/", demographic_model, "_batch", simulation_serial_number, "_cms_stats_all_", current_date, ".zip")
print(paste("Creating zip file:", zipfile))

# List files to zip
files_to_zip <- list.files(output_dir, pattern = paste0(demographic_model, "_batch", simulation_serial_number, "_cms_stats_.*\\.tsv$"), full.names = TRUE)

# Print the files to zip for debugging
print("Files to zip:")
print(files_to_zip)

# Check if files_to_zip is empty
if (length(files_to_zip) == 0) {
  stop("No files found to zip. Please check the output directory and file pattern.")
}

# Create the zip file using the system zip command
zip_command <- paste("zip -j", zipfile, paste(files_to_zip, collapse = " "))
print(paste("Running command:", zip_command))
system(zip_command)

# Print completion message
print("Zip file created successfully")

# Remove the individual tsv files after making the zip
print("Removing individual tsv files")
file.remove(list.files(output_dir, pattern = paste0(demographic_model, "_batch", simulation_serial_number, "_cms_stats_.*\\.tsv$"), full.names = TRUE))

# Run clean.sh after all jobs are done
# print("Running clean.sh")
# system("bash clean.sh")