library(nasapower)
library(tidyverse)
library(lubridate)

cat("🛰️ Starting NASA data download...\n")

# Sri Lanka districts with coordinates
districts <- data.frame(
  name = c("Colombo", "Kandy", "Galle",
           "Jaffna", "Badulla", "Ratnapura"),
  lat  = c(6.9271,   7.2906,  6.0535,
           9.6615,   6.9934,   6.6828),
  lon  = c(79.8612,  80.6337, 80.2210,
           80.0255,  81.0550,  80.3992)
)

# Download rainfall + temperature data
# This gets REAL NASA satellite measurements!
get_district_data <- function(district_row) {
  
  cat("📡 Downloading:", district_row$name, "\n")
  
  data <- get_power(
    community    = "ag",
    lonlat       = c(district_row$lon, district_row$lat),
    pars         = c(
      "PRECTOTCORR",  # rainfall mm/day
      "T2M",          # temperature °C
      "RH2M",         # humidity %
      "WS10M"         # wind speed m/s
    ),
    dates        = c("2020-01-01", "2024-12-31"),
    temporal_api = "daily"
  )
  
  # Add district name
  data$district <- district_row$name
  return(data)
}

# Download all districts
# Takes about 2-3 minutes
all_data <- map_df(
  1:nrow(districts),
  ~get_district_data(districts[.x, ])
)

# Save to your folder
saveRDS(
  all_data,
  "D:/traning project/sri-lanka-weather/data/satellite/weather_data.rds"
)

cat("✅ Download complete!\n")
cat("📊 Total rows downloaded:", nrow(all_data), "\n")
cat("📅 Date range: 2020-01-01 to 2024-12-31\n")
cat("🏙️ Districts covered:", n_distinct(all_data$district), "\n")
