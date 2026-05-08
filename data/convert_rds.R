library(sf)       # for map data (has geometry)
library(readr)    # for writing CSVs

input_dir  <- "data/dataverse_files"
output_dir <- "data/alarm_csv"
dir.create(output_dir, showWarnings = FALSE)

dirs <- list.dirs(input_dir, recursive = FALSE)

for (d in dirs) {
  state_tag <- basename(d)
  
  # --- plans.rds (data frame of simulated district plans) ---
  plans_file <- file.path(d, paste0(state_tag, "_plans.rds"))
  if (file.exists(plans_file)) {
    plans <- readRDS(plans_file)
    write_csv(as.data.frame(plans),
              file.path(output_dir, paste0(state_tag, "_plans.csv")))
  }
  
  # --- map.rds (sf spatial object — drop geometry for tabular export) ---
  map_file <- file.path(d, paste0(state_tag, "_map.rds"))
  if (file.exists(map_file)) {
    map_obj <- readRDS(map_file)
    write_csv(sf::st_drop_geometry(map_obj),
              file.path(output_dir, paste0(state_tag, "_map.csv")))
  }
}

cat("Done! CSVs written to", output_dir, "\n")