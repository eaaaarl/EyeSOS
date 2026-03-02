# Random Forest Training Guide (Google Colab)

For your thesis on predicting accident occurrence in Lianga, Surigao Del Sur, follow this guide to train your model using **Scikit-Learn** in Google Colab.

## 1. Key Hyperparameters (The "Compatibility Tweaks")

To make sure your model predicts correctly for **EyeSOS**, use these exact parameters when initializing your `RandomForestClassifier`.

| Hyperparameter | Value        | Rationale for EyeSOS Compatibility                         |
| :------------- | :----------- | :--------------------------------------------------------- |
| `n_estimators` | `100`        | Good performance/accuracy balance.                         |
| `max_depth`    | `10`         | Prevents overfitting on small datasets.                    |
| `random_state` | `42`         | **Ensures consistent results** for your thesis defense.    |
| `class_weight` | `'balanced'` | **CRITICAL**: Helps the model detect rare accident events. |

---

## 2. Model Evaluation Metrics (For Your Thesis)

In your thesis, "Accuracy" alone isn't enough. You must explain these metrics to prove your model actually identifies "Accident Prone Areas" correctly.

| Metric                   | What it measures                                        | Why it's important for your thesis                                                      |
| :----------------------- | :------------------------------------------------------ | :-------------------------------------------------------------------------------------- |
| **Accuracy**             | Overall correctness.                                    | Can be misleading if you have many "Safe" points and few "Accidents".                   |
| **Precision**            | Out of all predicted accidents, how many were real?     | High precision means fewer "False Alarms".                                              |
| **Recall (Sensitivity)** | Out of all real accidents, how many did the model find? | **CRITICAL**: High recall means the model successfully identified most dangerous areas. |
| **F1-Score**             | Balance between Precision and Recall.                   | Essential if your accident data is "Unbalanced" (which it usually is).                  |
| **AUC-ROC**              | The model's ability to distinguish between classes.     | A score of `> 0.8` means your Random Forest is very good at predicting occurrence.      |

---

## 3. Understanding the Confusion Matrix

The `confusion_matrix` output in the code below tells you EXACTLY where the model failed:

- **True Positive (TP)**: Predicted Accident, and it was an Accident. (Goal: High)
- **True Negative (TN)**: Predicted Safe, and it was Safe. (Goal: High)
- **False Positive (FP)**: Predicted Accident, but it was Safe. (False Alarm)
- **False Negative (FN)**: Predicted Safe, but it was an Accident. (**DANGEROUS**: The model missed a prone area).

---

## 4. Sample Training Code (Compatibility Version)

This version includes the code to **Save** your model and **Map** it to the "None, Minor, Moderate, High, Critical" levels in the app.

```python
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.preprocessing import LabelEncoder

# 1. LOAD YOUR THESIS MOCK DATA
data = {
    'lat': [8.6310, 8.6350, 8.6280, 8.6400, 8.6330],
    'lng': [126.0950, 126.1020, 126.0880, 126.1150, 126.0990],
    'weather': ['Rainy', 'Clear', 'Clear', 'Clear', 'Rainy'],
    'road_type': ['Curve', 'Straight', 'Intersection', 'Straight', 'Straight'],
    'hour': [22, 10, 17, 2, 14],
    'speed': [40, 30, 20, 60, 45],
    'is_accident': [1, 0, 1, 0, 1]
}
df = pd.DataFrame(data)

# 2. ENCODE CATEGORICAL DATA
weather_le = LabelEncoder()
road_le = LabelEncoder()
df['weather'] = weather_le.fit_transform(df['weather'])
df['road_type'] = road_le.fit_transform(df['road_type'])

# 3. SPLIT DATA
X = df.drop('is_accident', axis=1)
y = df['is_accident']

# 4. INITIALIZE MODEL WITH COMPATIBILITY TWEAKS
rf_model = RandomForestClassifier(
    n_estimators=100,
    max_depth=10,
    random_state=42,
    class_weight='balanced'
)

# 5. TRAIN
rf_model.fit(X, y)

# 6. HOW TO GET THE "RISK LEVEL" (EYESOS COMPATIBILITY)
def get_risk_level(probability):
    if probability >= 0.8: return "Critical (Red)"
    if probability >= 0.6: return "High (Orange)"
    if probability >= 0.4: return "Moderate (Yellow)"
    if probability >= 0.2: return "Minor (Green)"
    return "None (Blue)"

# Test prediction: Current time 10PM, Rainy, Curve, Speed 40kmh
# Assume encoded values: Curve -> 0, Straight -> 1, Intersection -> 2
# Assume encoded values: Rainy -> 1, Clear -> 0
test_input = [[8.6310, 126.0950, 1, 0, 22, 40]] # Lat, Lng, Rainy, Curve, 10PM, Speed
prob = rf_model.predict_proba(test_input)[0][1] # Get probability of Accident (class 1)

print(f"Predicted Accident Probability: {prob*100:.2f}%")
print(f"Mapped EyeSOS Risk Level: {get_risk_level(prob)}")

# 7. SAVE THE MODEL FOR DEPLOYMENT
import joblib
joblib.dump(rf_model, 'lianga_accident_model.pkl')
joblib.dump(weather_le, 'weather_encoder.pkl')
joblib.dump(road_le, 'road_encoder.pkl')
print("\n--- Model and Encoders Saved for Deployment! ---")
```

---

## 5. Best Practices for Your Thesis

1.  **Feature Importance**: After training, use `rf_model.feature_importances_` to see if **Weather** or **Road Type** is a bigger factor in Lianga. This answers your research question about _identifying_ prone areas.
2.  **Cross-Validation**: Use `cross_val_score` to ensure your model works consistently across different parts of your data, not just one split.
3.  **Data Balance**: If you have 100 accidents, make sure you also have about 100-200 "Safe" data points (Negative Samples) so the model doesn't just guess "0" (No Accident) every time.

> [!TIP]
> Use Google Colab's **`Files`** tab on the left to upload your `.csv` dataset.
