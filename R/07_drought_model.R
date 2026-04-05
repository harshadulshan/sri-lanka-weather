library(tidyverse)
library(lubridate)

select <- dplyr::select

cat("☀️ Starting Drought Prediction Model...\n\n")

# Load clean data
data <- readRDS(
  "D:/traning project/sri-lanka-weather/data/satellite/clean_data.rds"
)

# ══════════════════════════════════════════════
# STEP 11A — Calculate SPI (Drought Index)
# ══════════════════════════════════════════════
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 11A ► Calculating SPI Index\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

# SPI = Standardized Precipitation Index
# Measures how dry/wet compared to historical average
# SPI < -1.0 = moderate drought
# SPI < -1.5 = severe drought
# SPI < -2.0 = extreme drought

calculate_spi <- function(rainfall_30day, district_mean, district_sd) {
  spi <- (rainfall_30day - district_mean) / district_sd
  return(round(spi, 3))
}

# Calculate monthly rainfall per district
monthly_rain <- data %>%
  mutate(year_month = format(date, "%Y-%m")) %>%
  group_by(district, year_month) %>%
  summarise(
    monthly_rain = sum(rainfall,  na.rm=TRUE),
    avg_temp     = mean(temp,     na.rm=TRUE),
    avg_humidity = mean(humidity, na.rm=TRUE),
    date         = min(date),
    .groups      = "drop"
  )

# Calculate historical mean and SD per district
district_stats <- monthly_rain %>%
  group_by(district) %>%
  summarise(
    mean_rain = mean(monthly_rain, na.rm=TRUE),
    sd_rain   = sd(monthly_rain,   na.rm=TRUE),
    .groups   = "drop"
  )

cat("District rainfall statistics:\n")
print(district_stats)

# Calculate SPI for each month
drought_data <- monthly_rain %>%
  left_join(district_stats, by="district") %>%
  mutate(
    spi = calculate_spi(monthly_rain, mean_rain, sd_rain),
    
    # Drought classification
    drought_level = case_when(
      spi < -2.0 ~ "EXTREME",
      spi < -1.5 ~ "SEVERE",
      spi < -1.0 ~ "MODERATE",
      spi < -0.5 ~ "MILD",
      spi >= -0.5 ~ "NORMAL"
    ),
    
    # Color for visualization
    drought_color = case_when(
      drought_level == "EXTREME"  ~ "#8B0000",
      drought_level == "SEVERE"   ~ "#FF0000",
      drought_level == "MODERATE" ~ "#FF8C00",
      drought_level == "MILD"     ~ "#FFD700",
      TRUE                        ~ "#00CC44"
    )
  )

cat("\n✅ SPI calculated!\n")
cat("Drought level distribution:\n")
print(table(drought_data$drought_level))

# ══════════════════════════════════════════════
# STEP 11B — Current Drought Status
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 11B ► Current Drought Status\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

# Get latest month status
current_drought <- drought_data %>%
  group_by(district) %>%
  slice_max(date, n=1) %>%
  ungroup() %>%
  arrange(spi)

cat("\n   ╔══════════════╦══════════╦══════════╦════════════╗\n")
cat("   ║ District     ║ SPI      ║ Rain(mm) ║ Status     ║\n")
cat("   ╠══════════════╬══════════╬══════════╬════════════╣\n")
for(i in 1:nrow(current_drought)) {
  cat(sprintf(
    "   ║ %-12s ║ %8.3f ║ %8.1f ║ %-10s ║\n",
    current_drought$district[i],
    current_drought$spi[i],
    current_drought$monthly_rain[i],
    current_drought$drought_level[i]
  ))
}
cat("   ╚══════════════╩══════════╩══════════╩════════════╝\n")

# ══════════════════════════════════════════════
# STEP 11C — Drought Forecasting with Prophet
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 11C ► 6 Month Drought Forecast\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  ⏳ Training Prophet models...\n\n")

library(prophet)

forecast_results <- list()

for(dist in unique(drought_data$district)) {
  
  cat(sprintf("  📡 Forecasting: %s\n", dist))
  
  # Prepare prophet data
  prophet_df <- drought_data %>%
    filter(district == dist) %>%
    dplyr::select(ds=date, y=spi) %>%
    arrange(ds)
  
  # Train prophet model
  m <- prophet(
    prophet_df,
    yearly.seasonality  = TRUE,
    weekly.seasonality  = FALSE,
    daily.seasonality   = FALSE,
    seasonality.mode    = "additive",
    changepoint.prior.scale = 0.05
  )
  
  # Forecast 6 months ahead
  future   <- make_future_dataframe(m, periods=6, freq="month")
  forecast <- predict(m, future)
  
  # Get future predictions only
  future_preds <- forecast %>%
    filter(ds > max(prophet_df$ds)) %>%
    dplyr::select(ds, yhat, yhat_lower, yhat_upper) %>%
    mutate(
      district      = dist,
      spi_forecast  = round(yhat, 3),
      drought_level = case_when(
        yhat < -2.0 ~ "EXTREME",
        yhat < -1.5 ~ "SEVERE",
        yhat < -1.0 ~ "MODERATE",
        yhat < -0.5 ~ "MILD",
        TRUE        ~ "NORMAL"
      )
    )
  
  forecast_results[[dist]] <- future_preds
}

# Combine all forecasts
all_forecasts <- bind_rows(forecast_results)

cat("\n✅ Forecasting complete!\n\n")
cat("6-Month Drought Forecast:\n")
print(all_forecasts %>%
        dplyr::select(district, ds, spi_forecast, drought_level))

# ══════════════════════════════════════════════
# STEP 11D — Drought Risk Score
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 11D ► District Drought Risk Score\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

drought_scores <- drought_data %>%
  group_by(district) %>%
  summarise(
    total_months    = n(),
    extreme_months  = sum(drought_level=="EXTREME",  na.rm=TRUE),
    severe_months   = sum(drought_level=="SEVERE",   na.rm=TRUE),
    moderate_months = sum(drought_level=="MODERATE", na.rm=TRUE),
    avg_spi         = round(mean(spi, na.rm=TRUE), 3),
    min_spi         = round(min(spi,  na.rm=TRUE), 3),
    
    # Weighted drought score (0-100)
    drought_score = round(
      pmin(100, pmax(0,
                     (extreme_months  * 10 +
                        severe_months   * 5  +
                        moderate_months * 2) /
                       total_months * 100
      )), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(drought_score)) %>%
  mutate(
    risk_rating = case_when(
      drought_score >= 30 ~ "🔴 HIGH DROUGHT RISK",
      drought_score >= 15 ~ "🟠 MODERATE RISK",
      drought_score >= 5  ~ "🟡 LOW RISK",
      TRUE                ~ "🟢 MINIMAL RISK"
    )
  )

cat("\nDrought Risk Scores (2020-2024):\n\n")
for(i in 1:nrow(drought_scores)) {
  bars <- paste(
    rep("█", round(drought_scores$drought_score[i]/5)),
    collapse=""
  )
  cat(sprintf(
    "  %-12s %s %.1f  %s\n",
    drought_scores$district[i],
    bars,
    drought_scores$drought_score[i],
    drought_scores$risk_rating[i]
  ))
}

# ══════════════════════════════════════════════
# STEP 11E — Save Everything
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 11E ► Saving Results\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

saveRDS(drought_data,
        "D:/traning project/sri-lanka-weather/data/drought_data.rds")
saveRDS(all_forecasts,
        "D:/traning project/sri-lanka-weather/data/drought_forecast.rds")
saveRDS(drought_scores,
        "D:/traning project/sri-lanka-weather/data/drought_scores.rds")
saveRDS(current_drought,
        "D:/traning project/sri-lanka-weather/data/current_drought.rds")

cat("\n  ✅ drought_data.rds saved\n")
cat("  ✅ drought_forecast.rds saved\n")
cat("  ✅ drought_scores.rds saved\n")
cat("  ✅ current_drought.rds saved\n")

cat("\n")
cat("╔══════════════════════════════════════╗\n")
cat("║   ☀️  STEP 11 COMPLETE!             ║\n")
cat("║   📊 Drought model is LIVE!         ║\n")
cat("║   📈 Next → STEP 12: 7-Day Chart    ║\n")
cat("╚══════════════════════════════════════╝\n")