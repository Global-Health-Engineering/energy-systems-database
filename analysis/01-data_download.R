library(googlesheets4)
library(googledrive)
library(readxl)
library(tidyverse)

#excel systems

file <- drive_get("https://docs.google.com/spreadsheets/d/1yKcnbvTo3kaeUOR_6rL8rKKvoQVtf77B/edit?usp=drive_link&ouid=113342715220771672507&rtpof=true&sd=true")  # or drive_get(as_id("<file-id>"))
tmp  <- tempfile(fileext = ".xlsx")
drive_download(file, path = tmp, overwrite = TRUE)
energy_systems <- read_excel(tmp)


# save raw data as CSV
write_csv(energy_systems, "data/raw_data/Energy Systems Excel/Complete_HC_EnergySystems.csv")

#----------------------------------------------------

#kobo questionnaire
kobo_questionnaire <- read_xlsx("data/raw_data/Kobo/Healthcare_Energy_Questionnaire_-_latest_version_-_English_en_-_2025-11-10-09-33-01.xlsx")


# save raw data as CSV
write_csv(kobo_questionnaire, "data/raw_data/Kobo/Healthcare_Questionnaire.csv")

