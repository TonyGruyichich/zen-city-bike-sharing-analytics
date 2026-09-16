# 🚲 Zen City | Urban Micro-Mobility Analytics & Fleet Optimization
**Google BigQuery SQL Pipeline & Strategic Growth Plan for Austin, Texas**  
*Developed as part of the AI Tech School program by Reichman University & Google*

---

## 📌 Executive Summary
Zen City operates a shared micro-mobility bike network across metropolitan Austin, Texas. This project delivers an end-to-end analytical pipeline analyzing 16,585 rental transactions from Q1 2022 to eliminate operational bottlenecks, unblock dock capacity, and scale quarterly ride volume by **+47.7% (from 16,585 to 24,500+ trips)** in Q2 2022—**without capital expenditure (CAPEX) for new physical docks or price discounting**.

---

## 🛠 Tech Stack & Analytical Methods
* **Data Warehouse:** Google BigQuery (`bqproj26.zen_city`)
* **SQL Architecture:** 
  * Unified `MasterClean` CTE for data wrangling, type casting, and anomaly tagging
  * Window functions (`SUM() OVER()`, `PARTITION BY`, percentile calculations via `APPROX_QUANTILES`)
  * Temporal feature engineering (diurnal rush hour profiling, weekday vs. weekend clustering)
* **Advanced Analytics:** AI-derived stress metrics, spatial-temporal corridor analysis, and time-series anomaly filtering

---

## 🔍 Key Data Insights & Business Hypotheses

### 1. Fleet Imbalance & The "Dock Blocking" Phenomenon
* **Supply vs. Demand Divergence:** While inventory is split almost evenly (299 electric vs. 281 classic bikes), **87.68% of rides occur on electric bikes**.
* **Turnover Gap:** E-bikes generate **0.54 trips/day (48.6 trips/quarter)** vs. just **0.08 trips/day** for classic bikes—a **6.7x turnover multiplier**.
* **The Problem:** 281 dormant classic bikes occupy ~48% of prime docks across the 10 departure stations, creating an artificial bike shortage.
* **Actionable Fix:** Swapping dormant classic bikes to achieve an **80/20 electric fleet ratio** unlocks **+2,500 to +3,000 rides** in Q2.

### 2. High-Volume Arterial Drainage & The "Core Feeder Trio"
* **Hub 2498 Centrality:** Station 2498 (*Dean Keeton & Speedway*) accounts for **18.09% of citywide departures** (3,001 trips).
* **Corridor Depletion:** Between 12:00 and 17:00, outflow surges to **250–320 trips/hour**, with up to 30% flowing unidirectionally toward PCL Library (Station 3798).
* **The Sink Mechanism:** Three stations (The Core Feeder Trio: Hubs 2498, 7125, 7188) generate **64.2% of all short micro-commutes (2–7 min)** ending at PCL Library.
* **Actionable Fix:** Introducing dedicated **Peak Loop Shuttle vans** (runs at 11:30 & 14:30) returns locked inventory from PCL to Hub 2498, recovering **+1,000 trips** in Q2.

### 3. AI-Derived Metric: Dock Churn Rate
Formulated via prompt engineering to detect dock stress independent of static network size:
* **Formula:** `Total Departures in Period / Station Physical Dock Capacity`
* Stations 2498 and 2547 exhibit a Churn Rate of **~176 departures per dock**—over **4x the network baseline** (43.3).

### 4. Academic Calendar Decoupling & The "June Bridge"
* **Student Dependency:** 77.3% of all riders are UT Austin students (median commute: 5–6 min).
* **The June Risk:** With the spring semester ending in late May, departures risk dropping by 60% (as seen during the January winter break: 102.7 trips/day vs. 253.4 in February).
* **Actionable Fix:** Relocate 60% of campus fleet capacity to recreational waterfront corridors (*Electric Drive*, *East 6th*) on weekends and throughout June. This expands weekend volume by **60%–70%** and stabilizes June at **180–210 rides/day**.

---

## 📈 Predictive Model: Hub 2498 Opening Day Forecast
* **Objective:** Predict rental volume from Hub 2498 on **Friday, April 1st, 2022** (Q2 Opening Day).
* **Methodology:** Time-series isolation of historical Q1 Fridays.
* **Anomaly Filtering:** Excluded 7 irregular Fridays impacted by winter break, the Feb 4th ice storm (7 trips), and Spring Break (9 trips).
* **Baseline Calculation:** The 5 in-session academic routine Fridays (73, 61, 37, 52, 59) produced a mean of **56.4 trips**.
* **Final Forecast:** **57 rentals** (rounded to nearest whole integer to minimize squared error loss).

---

## 📂 Repository Contents
* `Zen City - Urban Bike Sharing Analytics.sql` — Full BigQuery SQL script (EDA, Wrangling, Analytics, Model)
* `Zen City - Executive Q2 Growth Strategy.pdf` — Complete analytical report and executive slide deck
* `README.md` — Project documentation and summary overview

---

## 🚀 How to Run the SQL Pipeline
1. Open the Google Cloud Console and navigate to **BigQuery**.
2. Ensure access to the public dataset tables:
   * `bqproj26.zen_city.rentals`
   * `bqproj26.zen_city.station_info`
3. Execute `Zen City - Urban Bike Sharing Analytics.sql` sequentially through Chapters 2 to 6.
