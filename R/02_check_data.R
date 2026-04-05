library(tidyverse)

# Load what we downloaded
data <- readRDS(
  "D:/traning project/sri-lanka-weather/data/satellite/weather_data.rds"
)

# Look at it
cat("=== YOUR REAL NASA DATA ===\n\n")

cat("Shape:", nrow(data), "rows x", ncol(data), "columns\n\n")

cat("First few rows:\n")
print(head(data, 5))

cat("\nColumn names:\n")
print(names(data))

cat("\nRainfall summary by district:\n")
data %>%
  group_by(district) %>%
  summarise(
    avg_rain_mm   = round(mean(PRECTOTCORR, na.rm=TRUE), 2),
    max_rain_mm   = round(max(PRECTOTCORR,  na.rm=TRUE), 2),
    avg_temp_c    = round(mean(T2M,         na.rm=TRUE), 1),
    avg_humidity  = round(mean(RH2M,        na.rm=TRUE), 1)
  ) %>%
  print()