library(tidyverse)
library(googlesheets4)
library(janitor)

# Auto-detect base data path
if (dir.exists("G:/.shortcut-targets-by-id/1R_jaR_bY959F-kVkmoRlCS4npFhRrr4k/2025-msc-thesis-teufeng/data")) {
  base_path <- "G:/.shortcut-targets-by-id/1R_jaR_bY959F-kVkmoRlCS4npFhRrr4k/2025-msc-thesis-teufeng/data"
} else {
  base_path <- "data"
}

#excel energy systems

#read data from csv
tidy_energy_systems <- read_csv(file.path(base_path, "raw_data/Energy Systems Excel/Complete_HC_EnergySystems.csv")) |>
  clean_names()

#data tidying ------------------------------------------

tidy_energy_systems <- tidy_energy_systems |> 
  mutate(repair_duty = case_when(
    repair_duty %in% c("DHO", "DHO, trained", "Donor, hired dho personnel", "MoH", "Donor, DHO", "Escom", "Staff") ~ "DHO/MoH/Gov",
    is.na(repair_duty) ~ "Unknown",  # make NA visible as its own category
    TRUE ~ repair_duty),
    # Explicit factor ordering
    repair_duty = factor(repair_duty, levels = c("DHO/MoH/Gov", "Unknown", "Donor"))) |> 
  mutate(
    type = case_when(
      type %in% c("Grid (three phase)", "Grid (single phase)") ~ "Grid",
      type %in% c("Solar, Inverter, Battery", "Solar, Wind, Inverter, Battery") ~ "Solar, Battery, Inverter",
      type %in% c("Solar, Inverter", "Solar only") ~ "Solar",     # example extra grouping
      is.na(type) ~ "Unknown",                                   # handle NAs too
      TRUE ~ type                                                # keep others unchanged
    )
  )

# Reorder funders by frequency
tidy_energy_systems <- tidy_energy_systems |> 
  mutate(funding = fct_infreq(funding) |> 
           fct_rev())


#save files in processed folder
write_csv(tidy_energy_systems, file.path(base_path, "derived_data/HC_EnergySystems.csv"))
write_rds(tidy_energy_systems, file.path(base_path, "derived_data/HC_EnergySystems.rds"))

#--------------------------------------------------------------------------
#--------------------------------------------------------------------------

#kobo questionnaire

#Read data from csv
kobo_questionnaire <- read_csv(file.path(base_path, "raw_data/Kobo/Healthcare_Questionnaire.csv"))

#column remapping------------------------------------------------------------

# colnames remapping 1) Load the mapping (with columns: original_name, short_name)
mapping <- read_csv(file.path(base_path, "raw_data/Kobo/column_mapping.csv"))

# 2) Replace column names using the mapping
names(kobo_questionnaire) <- mapping$short_name[match(names(kobo_questionnaire), mapping$original_name)]

# 3) Inspect the result
head(names(kobo_questionnaire))
glimpse(kobo_questionnaire)

# 4) Check uniqueness of all names
stopifnot(!any(duplicated(names(kobo_questionnaire))))

# 
kobo_questionnaire <- kobo_questionnaire |> 
  mutate(main_elec = recode(main_elec,
                                                  "Central supply (national/community grid)" = "Grid",
                                                  "On-site solar system (except lanterns)" = "Solar",
                                                  "Local mini-grid (i.e., the facility shares electricity supply, typically a renewable source or a generator, with other nearby buildings) Specify the supply modality if known." = "Mini-grid"
  ))
unique(kobo_questionnaire$main_elec)



#kobo tidying------------------------------------------------------------------------

kobo_questionnaire[kobo_questionnaire == -99] <- NA
sum(kobo_questionnaire == -99, na.rm = TRUE)



#save files in processed folder----------------------
write_csv(kobo_questionnaire, file.path(base_path, "derived_data/Kobo_Questionnaire.csv"))
write_rds(kobo_questionnaire, file.path(base_path, "derived_data/Kobo_Questionnaire.rds"))


#--------------------------------------------------------------------------
#--------------------------------------------------------------------------

#joining both datasets

# 1) Sanity checks: make sure the key exists
stopifnot("facility_id" %in% names(kobo_questionnaire))
stopifnot("facility_id" %in% names(tidy_energy_systems))

# 2) Perform the many-to-one join:
#    - left_join keeps all rows from energy
#    - All questionnaire columns are appended for matching facility_id
#    - If both tables share a column name (other than the key), suffix them to avoid collisions
combined <- tidy_energy_systems |> 
  left_join(kobo_questionnaire, by = "facility_id", suffix = c("_energy", "_quest"))

# 3) Optional diagnostics (helpful to spot join issues)
# Energy rows that didn't find a questionnaire match:
unmatched_energy <- anti_join(tidy_energy_systems, kobo_questionnaire, by = "facility_id")
# Questionnaire facilities that never appear in energy:
unmatched_questionnaire <- anti_join(kobo_questionnaire, tidy_energy_systems, by = "facility_id")

message("Unmatched energy rows: ", nrow(unmatched_energy))
message("Questionnaire-only facilities: ", nrow(unmatched_questionnaire))

# 4) Save result
write_csv(combined, file.path(base_path, "derived_data/Combined_Questionnaire_Systems.csv"))
write_rds(combined, file.path(base_path, "derived_data/Combined_Questionnaire_Systems.rds"))


