# Load necessary libraries
library(data.table)
library(jsonlite)

# Function to safely read and process files
safe_read_file <- function(file, ...) {
  if (!file.exists(file)) {
    warning("File not found: ", file)
    return(NULL)
  }
  return(fread(file, ...))
}

# Main processing function
create_output_file <- function(sim_id) {
  output_dir <- "output"
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  # Read normalized temp files
  ihs_data <- safe_read_file(paste0("norm/temp_ihs_", sim_id, ".tsv"))
  nsl_data <- safe_read_file(paste0("norm/temp_nsl_", sim_id, ".tsv"))
  ihh12_data <- safe_read_file(paste0("norm/temp_ihh12_", sim_id, ".tsv"))
  delihh_data <- safe_read_file(paste0("norm/temp_delihh_", sim_id, ".tsv"))
  xpehh_data <- safe_read_file(paste0("norm/temp_xpehh_", sim_id, ".tsv"))
  
  # Rename daf columns to avoid duplication
  setnames(ihs_data, "daf", "daf_ihs")
  setnames(nsl_data, "daf", "daf_nsl")
  setnames(ihh12_data, "daf", "daf_ihh12")
  setnames(delihh_data, "daf", "daf_delihh")
  setnames(xpehh_data, "daf", "daf_xpehh")
  
  # Combine data
  combined_data <- Reduce(function(x, y) merge(x, y, by = "pos", all = TRUE),
                          list(ihs_data, nsl_data, ihh12_data, delihh_data, xpehh_data))
  
  # Add FST and iSAFE data
  fst_deldaf_file <- paste0("two_pop_stats/", sim_id, "_fst_deldaf.tsv")
  fst_deldaf_data <- safe_read_file(fst_deldaf_file)
  
  isafe_file <- paste0("one_pop_stats/", sim_id, ".iSAFE.out")
  isafe_data <- safe_read_file(isafe_file)
  
  combined_data <- merge(combined_data, fst_deldaf_data, by = "pos", all.x = TRUE)
  combined_data <- merge(combined_data, isafe_data, by.x = "pos", by.y = "POS", all.x = TRUE)
  
  # Save output
  demographic_model <- fromJSON("config.json")$demographic_model
  output_file <- paste0(output_dir, "/", demographic_model, "_", sim_id, "_", Sys.Date(), ".tsv")
  fwrite(combined_data, output_file, sep
