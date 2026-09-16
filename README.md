# 🚲 Zen City | Urban Micro-Mobility Analytics & Fleet Optimization
**Google BigQuery SQL Pipeline & Strategic Growth Plan for Austin, Texas**[span_0](start_span)[span_0](end_span)[span_1](start_span)[span_1](end_span)  
*Developed as part of the AI Tech School program by Reichman University & Google*[span_2](start_span)[span_2](end_span)[span_3](start_span)[span_3](end_span)

---

## 📌 Executive Summary
Zen City operates a shared micro-mobility bike network across metropolitan Austin, Texas[span_4](start_span)[span_4](end_span). This project delivers an end-to-end analytical pipeline analyzing 16,585 rental transactions from Q1 2022 to eliminate operational bottlenecks, unblock dock capacity, and scale quarterly ride volume by **+47.7% (from 16,585 to 24,500+ trips)** in Q2 2022[span_5](start_span)[span_5](end_span)[span_6](start_span)[span_6](end_span)—**without capital expenditure (CAPEX) for new physical docks or price discounting**[span_7](start_span)[span_7](end_span)[span_8](start_span)[span_8](end_span).

---

## 🛠 Tech Stack & Analytical Methods
* **Data Warehouse:** Google BigQuery (`bqproj26.zen_city`)[span_9](start_span)[span_9](end_span)
* **SQL Architecture:** 
  * Unified `MasterClean` CTE for data wrangling, type casting, and anomaly tagging[span_10](start_span)[span_10](end_span).
  * Window functions (`SUM() OVER()`, `PARTITION BY`, percentile calculations via `APPROX_QUANTILES`)[span_11](start_span)[span_11](end_span).
  * Temporal feature engineering (diurnal rush hour profiling, weekday vs. weekend clustering)[span_12](start_span)[span_12](end_span).
* **Advanced Analytics:** AI-derived stress metrics, spatial-temporal corridor analysis, and time-series anomaly filtering[span_13](start_span)[span_13](end_span)[span_14](start_span)[span_14](end_span).

---

## 🔍 Key Data Insights & Business Hypotheses

### 1. Fleet Imbalance & The "Dock Blocking" Phenomenon
* **Supply vs. Demand Divergence:** While inventory is split almost evenly (299 electric vs. 281 classic bikes), **87.68% of rides occur on electric bikes**[span_15](start_span)[span_15](end_span).
* **Turnover Gap:** E-bikes generate **0.54 trips/day (48.6 trips/quarter)** vs. just **0.08 trips/day** for classic bikes—a **6.7x turnover multiplier**[span_16](start_span)[span_16](end_span)[span_17](start_span)[span_17](end_span).
* **The Problem:** 281 dormant classic bikes occupy ~48% of prime docks across the 10 departure stations, creating an artificial bike shortage[span_18](start_span)[span_18](end_span)[span_19](start_span)[span_19](end_span).
* **Actionable Fix:** Swapping dormant classic bikes to achieve an **80/20 electric fleet ratio** unlocks **+2,500 to +3,000 rides** in Q2[span_20](start_span)[span_20](end_span)[span_21](start_span)[span_21](end_span).

### 2. High-Volume Arterial Drainage & The "Core Feeder Trio"
* **Hub 2498 Centrality:** Station 2498 (*Dean Keeton & Speedway*) accounts for **18.09% of citywide departures** (3,001 trips)[span_22](start_span)[span_22](end_span)[span_23](start_span)[span_23](end_span).
* **Corridor Depletion:** Between 12:00 and 17:00, outflow surges to **250–320 trips/hour**, with up to 30% flowing unidirectionally toward PCL Library (Station 3798)[span_24](start_span)[span_24](end_span)[span_25](start_span)[span_25](end_span).
* **The Sink Mechanism:** Three stations (The Core Feeder Trio: Hubs 2498, 7125, 7188) generate **64.2% of all short micro-commutes (2–7 min)** ending at PCL Library[span_26](start_span)[span_26](end_span)[span_27](start_span)[span_27](end_span).
* **Actionable Fix:** Introducing dedicated **Peak Loop Shuttle vans** (runs at 11:30 & 14:30) returns locked inventory from PCL to Hub 2498, recovering **+1,000 trips** in Q2[span_28](start_span)[span_28](end_span).

### 3. AI-Derived Metric: Dock Churn Rate
Formulated via prompt engineering to detect dock stress independent of static network size[span_29](start_span)[span_29](end_span):
$$\text{Dock Churn Rate} = \frac{\text{Total Departures in Period}}{\text{Station Physical Dock Capacity}}$$[span_30](start_span)[span_30](end_span)[span_31](start_span)[span_31](end_span)
* Stations 2498 and 2547 exhibit a Churn Rate of **~176 departures per dock**—over **4x the network baseline** (43.3)[span_32](start_span)[span_32](end_span)[span_33](start_span)[span_33](end_span).

### 4. Academic Calendar Decoupling & The "June Bridge"
* **Student Dependency:** 77.3% of all riders are UT Austin students (median commute: 5–6 min)[span_34](start_span)[span_34](end_span)[span_35](start_span)[span_35](end_span).
* **The June Risk:** With the spring semester ending in late May, departures risk dropping by 60% (as seen during the January winter break: 102.7 trips/day vs. 253.4 in February)[span_36](start_span)[span_36](end_span).
* **Actionable Fix:** Relocate 60% of campus fleet capacity to recreational waterfront corridors (*Electric Drive*, *East 6th*) on weekends and throughout June[span_37](start_span)[span_37](end_span)[span_38](start_span)[span_38](end_span). This expands weekend volume by **60%–70%** and stabilizes June at **180–210 rides/day**[span_39](start_span)[span_39](end_span)[span_40](start_span)[span_40](end_span).

---

## 📈 Predictive Model: Hub 2498 Opening Day Forecast
* **Objective:** Predict rental volume from Hub 2498 on **Friday, April 1st, 2022** (Q2 Opening Day)[span_41](start_span)[span_41](end_span)[span_42](start_span)[span_42](end_span).
* **Methodology:** Time-series isolation of historical Q1 Fridays[span_43](start_span)[span_43](end_span)[span_44](start_span)[span_44](end_span).
* **Anomaly Filtering:** Excluded 7 irregular Fridays impacted by winter break, the Feb 4th ice storm (7 trips), and Spring Break (9 trips)[span_45](start_span)[span_45](end_span).
* **Baseline Calculation:** The 5 in-session academic routine Fridays ($73, 61, 37, 52, 59$) produced a mean of **56.4 trips**[span_46](start_span)[span_46](end_span)[span_47](start_span)[span_47](end_span).
* **Final Forecast:** **57 rentals** (rounded to nearest whole integer to minimize squared error loss)[span_48](start_span)[span_48](end_span)[span_49](start_span)[span_49](end_span).

---

## 📂 Repository Contents
```text
├── Zen City - Urban Bike Sharing Analytics.sql       # Full BigQuery SQL script (EDA, Wrangling, Analytics, Model)[span_50](start_span)[span_50](end_span)
├── Zen City - Executive Q2 Growth Strategy.pdf        # Complete 10-page analytical report and executive slide deck[span_51](start_span)[span_51](end_span)[span_52](start_span)[span_52](end_span)
└── README.md                                         # Project documentation and summary overview
