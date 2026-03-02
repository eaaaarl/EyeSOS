# Accident Mock Data Documentation

This documentation outlines the data structure for mocking accidents and road risks in the EyeSOS application. This will serve as a guide for gathering real-world data and creating a robust testing environment.

## 1. Reporting vs. Forecasting (The Core of Your Thesis)

It is important to distinguish these two features in your **EyeSOS** app for your thesis defense:

| Feature                  | User Action                   | Data Source          | Technology            |
| :----------------------- | :---------------------------- | :------------------- | :-------------------- |
| **Accident Reporting**   | User clicks "SOS" or "Report" | Real-time user input | Firebase / Database   |
| **Accident Forecasting** | User views map or searches    | **Machine Learning** | **Random Forest API** |

### What is "Forecasting"?

In your thesis, you are **forecasting** the likelihood of an accident _before_ it happens. When a user searches for a destination, your **Random Forest** looks at the "Hidden Factors" (Weather + Time + Location) to tell the user: _"Even if there is no accident right now, this road is PRONE to accidents under these conditions."_

---

## 2. Accident Report Data Structure

Based on `AccidentReportEntity`, each accident report should contain the following fields:

| Field             | Type          | Description                                                            | Example                                            |
| :---------------- | :------------ | :--------------------------------------------------------------------- | :------------------------------------------------- |
| `id`              | String        | Unique identifier for the report                                       | `"acc-001"`                                        |
| `reportNumber`    | String        | Human-readable report number                                           | `"RPT-2024-001"`                                   |
| `createdAt`       | DateTime      | When the report was first created                                      | `"2024-03-02T10:00:00Z"`                           |
| `updatedAt`       | DateTime?     | When the report was last updated                                       | `"2024-03-02T10:30:00Z"`                           |
| `severity`        | String (Enum) | Intensity of the incident (Minor, Moderate, High, Critical, Emergency) | `"Critical"`                                       |
| `accidentStatus`  | String (Enum) | Current status (New, Verified, In Progress, Resolved, Closed, etc.)    | `"IN_PROGRESS"`                                    |
| `reporterName`    | String        | Name of the person who reported the incident                           | `"John Doe"`                                       |
| `reporterNotes`   | String?       | Additional details provided by the reporter                            | `"Multi-vehicle collision near the intersection."` |
| `latitude`        | Double        | GPS Latitude coordinate                                                | `14.5995`                                          |
| `longitude`       | Double        | GPS Longitude coordinate                                               | `120.9842`                                         |
| `locationAddress` | String        | Readable address or landmark                                           | `"Roxas Blvd, Manila"`                             |
| `imageUrls`       | List<String>  | URLs to photos of the accident                                         | `["https://example.com/img1.jpg"]`                 |
| `isSos`           | Boolean       | Whether this was an emergency SOS trigger                              | `true`                                             |

---

## 3. Road Risk & Path Data Structure

Based on `RoadRiskEntity`, road paths are visualized on the map with specific colors indicating risk levels.

| Field           | Type          | Description                                                   | Example                          |
| :-------------- | :------------ | :------------------------------------------------------------ | :------------------------------- |
| `id`            | Integer       | Unique identifier for the road segment                        | `101`                            |
| `name`          | String        | Name of the road or segment                                   | `"EDSA Southbound"`              |
| `coordinates`   | List<LatLng>  | List of GPS points forming the road path                      | `[[14.5, 121.0], [14.6, 121.1]]` |
| `riskLevel`     | String (Enum) | Visualized risk level (Critical, High, Moderate, Minor, None) | `"High"`                         |
| `riskScore`     | Integer       | Numerical score for risk calculation (e.g., 0-100)            | `85`                             |
| `accidentCount` | Integer       | Total number of accidents recorded on this segment            | `12`                             |

### Risk Level Visualization

| Risk Level   | Color  | Hex Code  | Stroke Width | Meaning                                 |
| :----------- | :----- | :-------- | :----------- | :-------------------------------------- |
| **Critical** | Red    | `#dc2626` | 7            | Extremely dangerous, avoid if possible. |
| **High**     | Orange | `#ea580c` | 6            | High accident frequency.                |
| **Moderate** | Yellow | `#ca8a04` | 5            | Average risk.                           |
| **Minor**    | Green  | `#16a34a` | 4            | Safe road, low accident count.          |
| **None**     | Blue   | `#3b82f6` | 3            | No recorded risks.                      |

---

## 4. Example Mock Dataset (JSON Format)

### Accident Reports

```json
[
  {
    "id": "acc-101",
    "reportNumber": "EYE-2024-05",
    "createdAt": "2024-03-02T08:15:00Z",
    "severity": "Emergency",
    "accidentStatus": "VERIFIED",
    "reporterName": "Alice Smith",
    "reporterNotes": "Car flipped over, smoke visible.",
    "latitude": 14.601,
    "longitude": 120.985,
    "locationAddress": "Quezon Blvd, Manila",
    "imageUrls": [],
    "isSos": true
  }
]
```

### Road Risks

```json
[
  {
    "id": 1,
    "name": "España Blvd",
    "riskLevel": "Critical",
    "riskScore": 95,
    "accidentCount": 25,
    "coordinates": [
      { "lat": 14.6072, "lng": 120.988 },
      { "lat": 14.612, "lng": 120.995 }
    ]
  }
]
```

---

## 5. Machine Learning Data (Random Forest Training)

For your thesis using **Random Forest**, the "reporting" data (like `imageUrls` or `reporterName`) is less important. You need **Predictors (Features)** that describe the _environment_ at the time of the accident.

### Recommended Features for Random Forest

To predict **Accident Occurrence**, your dataset should include:

| Feature Category   | Field Name             | Description                    | Possible Values                           |
| :----------------- | :--------------------- | :----------------------------- | :---------------------------------------- |
| **Temporal**       | `time_of_day`          | Hour of the accident           | 0-23                                      |
|                    | `day_of_week`          | Day of occurrence              | 1-7 (Mon-Sun)                             |
|                    | `is_holiday`           | Whether it was a local holiday | Boolean                                   |
| **Environmental**  | `weather_condition`    | Weather at the time            | Clear, Rainy, Foggy, Windy                |
|                    | `road_surface`         | State of the road              | Dry, Wet, Slippery, Damaged               |
|                    | `lighting`             | Visibility conditions          | Daylight, Night (lit), Night (unlit)      |
| **Geographic**     | `latitude / longitude` | Exact location                 | Coordinates                               |
|                    | `road_type`            | Category of the road           | Highway, Residential, Curve, Intersection |
| **Operational**    | `traffic_volume`       | Estimated vehicle density      | Low, Medium, High                         |
|                    | `average_speed`        | Observed speed on segment      | 10 - 100 (khm)                            |
| **Infrastructure** | `has_street_light`     | Presence of lighting           | Boolean                                   |
|                    | `has_signage`          | Warning signs nearby           | Boolean                                   |

---

## 6. Identifying Accident Prone Areas (Hotspots)

To identify "Prone Areas" in Lianga, Surigao Del Sur:

1. **Step 1: Data Aggregation**: Group all accident coordinates into a grid or by "Barangay".
2. **Step 2: Density Mapping**: Calculate which segments (Road IDs from Section 2) have the highest `accidentCount`.
3. **Step 3: Prediction**: Use the Random Forest model to input "Future Conditions" (e.g., Rain + High Traffic + Curve) to see which areas show a high probability of a new accident.

---

## 7. Data Request Guide for MDRRMC (Lianga, SDS)

To make your "Random Forest" model compatible with **EyeSOS**, your data from MDRRMC must contain specific features. Use this checklist when requesting data:

### Mandatory Fields from MDRRMC Records:

1.  **Exact Location**: (Latitude/Longitude or Specific Street/Barangay name).
2.  **Date & Exact Time**: Crucial for calculating `time_of_day` and `day_of_week`.
3.  **Accident Type**: (Collision, Self-accident, Pedestrian hit).
4.  **Weather Conditions**: Was it raining or clear at that exact moment?
5.  **Road Characteristics**: Is that spot a curve, a crossing, or a downhill?

---

## 8. Bridge: Mapping ML "Predictions" to EyeSOS "Road Risk Levels"

The user sees **Critical (Red)** or **Minor (Green)** in EyeSOS. Here is how your **Random Forest** output (Probability) maps to those levels:

When you run `rf_model.predict_proba()`, it gives a value between **0.0 (0%)** and **1.0 (100%)**.

| Predicted Probability | Risk Level (App UI) | App Color          |
| :-------------------- | :------------------ | :----------------- |
| **0.80 - 1.00**       | **Critical**        | Red (`#dc2626`)    |
| **0.60 - 0.79**       | **High**            | Orange (`#ea580c`) |
| **0.40 - 0.59**       | **Moderate**        | Yellow (`#ca8a04`) |
| **0.20 - 0.39**       | **Minor**           | Green (`#16a34a`)  |
| **0.00 - 0.19**       | **None**            | Blue (`#3b82f6`)   |

---

## 9. Lianga Thesis Mock Dataset (5 Examples)

Since your deadline is on **Wednesday**, use these 5 specific examples for your Chapter 3 demonstration in Google Colab. These represent a mix of accidents and non-accidents to show how the Random Forest learns patterns.

### Format: CSV (Compatible with Python/Colab)

| ID  | Lat    | Lng      | Weather | Road_Type    | Time_of_Day | Traffic | Speed (kmh) | **Is_Accident** |
| :-- | :----- | :------- | :------ | :----------- | :---------- | :------ | :---------- | :-------------- |
| 1   | 8.6310 | 126.0950 | Rainy   | Curve        | 22 (10PM)   | Medium  | 40          | **1**           |
| 2   | 8.6350 | 126.1020 | Clear   | Straight     | 10 (10AM)   | Low     | 30          | **0**           |
| 3   | 8.6280 | 126.0880 | Clear   | Intersection | 17 (5PM)    | High    | 20          | **1**           |
| 4   | 8.6400 | 126.1150 | Clear   | Straight     | 02 (2AM)    | Low     | 60          | **0**           |
| 5   | 8.6330 | 126.0990 | Rainy   | Straight     | 14 (2PM)    | Medium  | 45          | **1**           |

> [!TIP]
> This small 5-row dataset is perfect for showing your teachers **"Proof of Concept"** while waiting for the full MDRRMC data.

> [!IMPORTANT]
> Ensure that for every **Accident** record you get from MDRRMC, you also create 1-2 **"Non-Accident"** records for similar locations but at times when NO accident occurred. Without this, the model will be biased.
