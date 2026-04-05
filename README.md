<div align="center">

# ◈ SL Weather Intelligence

*Satellite-grade flood & drought prediction for Sri Lanka — built in R, powered by NASA.*

[![Live Demo](https://img.shields.io/badge/◈_LIVE_DEMO-388bfd?style=for-the-badge&logoColor=white)](https://srilanka-weather.shinyapps.io/sl-weather-intelligence/)
[![R](https://img.shields.io/badge/Built_in_R-276DC3?style=for-the-badge&logo=r&logoColor=white)](https://www.r-project.org/)
[![NASA](https://img.shields.io/badge/NASA_POWER_API-FC3D21?style=for-the-badge&logo=nasa&logoColor=white)](https://power.larc.nasa.gov/)
[![Shiny](https://img.shields.io/badge/Shiny-deployed-3fb950?style=for-the-badge&logoColor=white)](https://shinyapps.io)

</div>

---

not a tutorial project. not a kaggle notebook.

this is a functioning early-warning system that pulls real NASA satellite measurements, runs them through a trained random forest model, and renders the output as a live dashboard — deployed, accessible, free to use.

built from scratch · six districts · five years of daily data · two prediction systems · one R file.

---

## at a glance

| | |
|---|---|
| **10,962** | daily weather records downloaded |
| **6** | Sri Lanka districts covered |
| **500** | random forest decision trees |
| **7** | dashboard tabs |
| **2020–2024** | data range |

---

## the screenshots

### ◈ live risk map
![Live Risk Map](Screenshots/map.png)
*district polygons colored by ml flood risk — click any district for full stats*

&nbsp;

### ◈ flood analysis
![Flood Analysis](Screenshots/flood.png)
*five years of high/moderate/low risk days broken down by district and month*

&nbsp;

### ◈ rainfall trends
![Rainfall Trends](Screenshots/rainfall.png)
*daily NASA rainfall measurements — 2020 to 2024 — filterable by district*

&nbsp;

### ◈ temperature & humidity
![Temperature](Screenshots/temperature.png)
*district-level temperature trends with humidity correlation scatter*

&nbsp;

### ◈ ml predictions
![ML Predictions](Screenshots/ml.png)
*random forest output — flood probability per district with confidence breakdown*

&nbsp;

### ◈ drought monitor
![Drought Monitor](Screenshots/drought.png)
*SPI index tracking + 6-month prophet forecast + monthly drought heatmap*

&nbsp;

### ◈ district stats
![District Stats](Screenshots/stats.png)
*full summary table — all weather variables — 2020 to 2024*

---

## system architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                               │
│   NASA POWER API (daily) · GADM v4.1 Boundaries · SPI Index    │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PROCESSING LAYER  (R)                        │
│   rainfall · temp · humidity · wind                             │
│   rain_3day · rain_7day · rain_30day · rain_spike               │
│                                                                 │
│   ┌──────────────────┐      ┌──────────────────────────────┐    │
│   │  Random Forest   │      │       Meta Prophet           │    │
│   │  500 trees       │      │  + SW/NE monsoon seasonality │    │
│   │  4 risk classes  │      │  6-month SPI forecast        │    │
│   └────────┬─────────┘      └──────────────┬───────────────┘    │
└────────────┼──────────────────────────────┼────────────────────┘
             │                              │
             ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OUTPUT LAYER  (Shiny)                        │
│   🗺️ Live Map · 🌊 Flood · 🌧️ Rainfall · 🌡️ Temp               │
│   📊 Stats · 🤖 ML Predictions · ☀️ Drought Monitor             │
└─────────────────────────────────────────────────────────────────┘
```

---

## languages & tools

```
R               ████████████████████░░   91.2%
CSS             ████░░░░░░░░░░░░░░░░░░    5.8%
HTML            ██░░░░░░░░░░░░░░░░░░░░    3.0%
```

| category | tools |
|---|---|
| dashboard | Shiny · shinydashboard |
| maps | leaflet · sf · GADM |
| charts | plotly · ggplot2 |
| ml model | randomForest · caret |
| forecasting | prophet (Meta) |
| data pipeline | nasapower · tidyverse · lubridate · zoo |
| deployment | rsconnect · shinyapps.io |

---

## the model

**algorithm** — Random Forest · **trees** — 500 · **classes** — 4

```
feature importance:
──────────────────────────────────────────────────────
🥇 rain_spike      ████████████████░░░░░   28%  top predictor
🥈 rain_7day       █████████████░░░░░░░░   21%  sustained rain
🥉 humidity        ███████████░░░░░░░░░░   17%  atmospheric moisture
   rainfall        █████████░░░░░░░░░░░░   13%  raw daily mm
   rain_30day      ██████░░░░░░░░░░░░░░░    9%  baseline context
   rain_3day       ████░░░░░░░░░░░░░░░░░    6%  short term trend
   humidity_spike  ███░░░░░░░░░░░░░░░░░░    4%  anomaly detection
   temp            ██░░░░░░░░░░░░░░░░░░░    2%  seasonal context
──────────────────────────────────────────────────────
```

**drought model** — Meta Prophet + SW/NE monsoon seasonality regressors  
**forecast horizon** — 6 months ahead

---

## district risk snapshot

| district | zone | risk days (HIGH) | current status |
|---|---|---|---|
| Ratnapura | wet zone | 27 | 🟠 MODERATE |
| Kandy | hill country | 22 | 🟠 MODERATE |
| Badulla | uva province | 23 | 🟡 LOW |
| Colombo | west coast | 6 | 🟢 MINIMAL |
| Galle | south coast | 1 | 🟢 MINIMAL |
| Jaffna | dry zone north | 5 | 🟢 MINIMAL |

---

## what the SPI means

```
SPI ≥  0.0   ●  NORMAL       no concern
SPI < -0.5   ●  MILD         watch closely
SPI < -1.0   ●  MODERATE  ── ── orange threshold on chart
SPI < -1.5   ●  SEVERE    ── ── red threshold on chart
SPI < -2.0   ●  EXTREME      immediate concern
```

*global meteorological standard used by WMO and national met agencies worldwide*

---

## run it yourself

```r
# 1. install dependencies
install.packages(c(
  "shiny", "shinydashboard", "tidyverse",
  "leaflet", "plotly", "DT", "sf",
  "randomForest", "caret", "prophet",
  "nasapower", "lubridate", "zoo"
))

# 2. download NASA data (~3 min)
source("R/01_get_data.R")

# 3. clean and engineer features
source("R/03_clean_data.R")

# 4. train models
source("R/05_flood_model.R")
source("R/07_drought_model.R")

# 5. launch dashboard
shiny::runApp("R/06_dashboard.R")
```

---

## file structure

```
sri-lanka-weather/
│
├── R/
│   ├── 01_get_data.R          NASA POWER API download
│   ├── 02_check_data.R        data validation
│   ├── 03_clean_data.R        feature engineering + SPI
│   ├── 04_map.R               boundary processing
│   ├── 05_flood_model.R       random forest training
│   ├── 06_dashboard.R         shiny app — main file
│   ├── 07_drought_model.R     prophet forecasting
│   └── data/                  processed .rds files
│
├── screenshots/               dashboard screenshots
└── README.md
```

---

## potential extensions

```
near term
  □  all 25 Sri Lanka districts
  □  automated daily retraining via GitHub Actions
  □  REST API via plumber for DMC integration

medium term
  □  real doppler radar integration (DMC data)
  □  Indian Ocean SST anomaly as ML feature
  □  landslide risk model — Kandy · Badulla · Ratnapura

long term
  □  SMS alert system via Dialog/Mobitel API
  □  mobile app wrapper
  □  partnership with DMC Sri Lanka
```

---

## contact

built in Negombo, Sri Lanka 🇱🇰

open to collaboration with DMC, universities, and NGOs.

&nbsp;

[![LinkedIn](https://img.shields.io/badge/Harsha_Kaldera-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/harsha-kaldera/)
[![Gmail](https://img.shields.io/badge/harshakaldera540@gmail.com-EA4335?style=for-the-badge&logo=gmail&logoColor=white)](mailto:harshakaldera540@gmail.com)

---

<div align="center">
<sub>NASA data via POWER API (power.larc.nasa.gov) · boundaries from GADM (gadm.org)<br>not affiliated with NASA or the Sri Lanka Disaster Management Centre</sub>
</div>
