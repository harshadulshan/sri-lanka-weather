library(tidyverse)
library(randomForest)
library(caret)
library(scales)

# THIS FIXES THE ERROR — detach terra conflicts
if("terra" %in% (.packages())) detach("package:terra", unload=TRUE)
if("raster" %in% (.packages())) detach("package:raster", unload=TRUE)

# Force use tidyverse select
select <- dplyr::select

cat("🤖 Starting ML Flood Prediction System...\n\n")

# ── Load Data ──────────────────────────────────
data <- readRDS(
  "D:/traning project/sri-lanka-weather/data/satellite/clean_data.rds"
)

# ══════════════════════════════════════════════
# STEP 9A — Prepare ML Data
# ══════════════════════════════════════════════
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 9A ► Preparing ML Data\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

ml_data <- data %>%
  drop_na(rain_3day, rain_7day, rain_30day) %>%
  dplyr::select(
    flood_risk,
    rainfall, temp, humidity, wind,
    rain_3day, rain_7day, rain_30day,
    rain_spike, humidity_spike
  ) %>%
  mutate(
    flood_risk = factor(
      flood_risk,
      levels = c("MINIMAL","LOW","MODERATE","HIGH")
    )
  )

# Print distribution nicely
dist_table <- table(ml_data$flood_risk)
cat("\n📊 Dataset Overview:\n")
cat("   Total Samples  :", nrow(ml_data), "\n")
cat("   Features Used  : 9\n")
cat("   Target Classes : 4\n\n")
cat("📈 Flood Risk Distribution:\n")
for(level in names(dist_table)) {
  pct  <- round(dist_table[level]/nrow(ml_data)*100, 1)
  bars <- paste(rep("█", round(pct/2)), collapse="")
  cat(sprintf("   %-10s %s %s%%\n", level, bars, pct))
}

# ══════════════════════════════════════════════
# STEP 9B — Train / Test Split
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 9B ► Splitting Data 80/20\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

set.seed(42)
split_idx  <- createDataPartition(ml_data$flood_risk, p=0.80, list=FALSE)
train_data <- ml_data[ split_idx, ]
test_data  <- ml_data[-split_idx, ]

cat(sprintf("\n   🟢 Training Set : %d samples (80%%)\n", nrow(train_data)))
cat(sprintf("   🔵 Testing Set  : %d samples (20%%)\n", nrow(test_data)))

# ══════════════════════════════════════════════
# STEP 9C — Train Random Forest
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 9C ► Training Random Forest\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  ⏳ Training 500 decision trees...\n\n")

flood_model <- randomForest(
  flood_risk ~ .,
  data       = train_data,
  ntree      = 500,
  mtry       = 3,
  importance = TRUE
)

cat("  ✅ Model training complete!\n")

# ══════════════════════════════════════════════
# STEP 9D — Model Accuracy
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 9D ► Model Performance\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

predictions <- predict(flood_model, test_data)
conf        <- confusionMatrix(predictions, test_data$flood_risk)
accuracy    <- round(conf$overall["Accuracy"] * 100, 1)

# Cool accuracy display
cat(sprintf("\n   🎯 Overall Accuracy : %s%%\n", accuracy))

# Rating based on accuracy
rating <- case_when(
  accuracy >= 95 ~ "🏆 EXCELLENT",
  accuracy >= 90 ~ "⭐ VERY GOOD",
  accuracy >= 85 ~ "✅ GOOD",
  accuracy >= 80 ~ "⚠️  ACCEPTABLE",
  TRUE           ~ "❌ NEEDS WORK"
)
cat(sprintf("   📊 Model Rating    : %s\n\n", rating))

# Per class accuracy
cat("   Per Class Results:\n")
class_acc <- diag(conf$table) / rowSums(conf$table) * 100
for(cls in names(class_acc)) {
  bar <- paste(rep("█", round(class_acc[cls]/5)), collapse="")
  cat(sprintf("   %-10s %s %.1f%%\n", cls, bar, class_acc[cls]))
}

# ══════════════════════════════════════════════
# STEP 9E — Feature Importance
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 9E ► Feature Importance\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

imp_df <- data.frame(
  feature    = rownames(importance(flood_model)),
  importance = importance(flood_model)[,"MeanDecreaseGini"]
) %>%
  arrange(desc(importance)) %>%
  mutate(
    pct = round(importance / sum(importance) * 100, 1),
    bar = sapply(pct, function(x)
      paste(rep("█", round(x/2)), collapse=""))
  )

cat("\n   Which features predict floods best?\n\n")
for(i in 1:nrow(imp_df)) {
  medal <- case_when(i==1~"🥇", i==2~"🥈", i==3~"🥉", TRUE~"  ")
  cat(sprintf("   %s %-18s %s %s%%\n",
              medal, imp_df$feature[i], imp_df$bar[i], imp_df$pct[i]))
}

# ══════════════════════════════════════════════
# STEP 9F — Live District Predictions
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 9F ► Live District Predictions\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

latest_date <- max(data$date, na.rm=TRUE)
cat(sprintf("\n   📅 Prediction Date: %s\n\n", latest_date))

today_data <- data %>%
  filter(date == latest_date) %>%
  drop_na(rain_3day, rain_7day, rain_30day)

features <- today_data %>%
  dplyr::select(
    rainfall, temp, humidity, wind,
    rain_3day, rain_7day, rain_30day,
    rain_spike, humidity_spike
  )

# Predictions + probabilities
pred_class <- predict(flood_model, features)
pred_probs <- predict(flood_model, features, type="prob")

results <- today_data %>%
  dplyr::select(district) %>%
  mutate(
    risk_level = pred_class,
    prob_high  = round(pred_probs[,"HIGH"]     * 100, 1),
    prob_mod   = round(pred_probs[,"MODERATE"] * 100, 1),
    alert = case_when(
      pred_probs[,"HIGH"]     > 0.60 ~ "🔴 CRITICAL",
      pred_probs[,"HIGH"]     > 0.40 ~ "🟠 HIGH",
      pred_probs[,"MODERATE"] > 0.50 ~ "🟡 MODERATE",
      pred_probs[,"LOW"]      > 0.50 ~ "🟢 LOW",
      TRUE                           ~ "⚪ NORMAL"
    )
  ) %>%
  arrange(desc(prob_high))

# Print results as a nice table
cat("   ╔══════════════╦════════════╦══════════╦═══════════════╗\n")
cat("   ║ District     ║ Risk Level ║ High%    ║ Alert         ║\n")
cat("   ╠══════════════╬════════════╬══════════╬═══════════════╣\n")
for(i in 1:nrow(results)) {
  cat(sprintf("   ║ %-12s ║ %-10s ║ %6.1f%%  ║ %-13s ║\n",
              results$district[i],
              results$risk_level[i],
              results$prob_high[i],
              results$alert[i]
  ))
}
cat("   ╚══════════════╩════════════╩══════════╩═══════════════╝\n")

# ══════════════════════════════════════════════
# STEP 9G — Save Everything
# ══════════════════════════════════════════════
cat("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("  STEP 9G ► Saving Model\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

saveRDS(flood_model,
        "D:/traning project/sri-lanka-weather/data/flood_model.rds")
saveRDS(results,
        "D:/traning project/sri-lanka-weather/data/today_predictions.rds")

cat("\n   ✅ Model saved to data/flood_model.rds\n")
cat("   ✅ Predictions saved to data/today_predictions.rds\n")

cat("\n")
cat("╔══════════════════════════════════════╗\n")
cat("║   🎉 STEP 9 COMPLETE!               ║\n")
cat("║   🤖 Flood ML Model is LIVE!        ║\n")
cat("║   📊 Next → STEP 10: Dashboard      ║\n")
cat("╚══════════════════════════════════════╝\n")