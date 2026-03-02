# Flask API: Accident Forecasting Engine

After training your **Random Forest** model, this Flask API serves as the "Forecasting Engine" for **EyeSOS**. It doesn't just show where accidents _are_—it predicts where they _might_ happen based on current conditions in Lianga, SDS.

## 1. Required Libraries & Extensions

To run this API on your computer or a server, you need to install these Python libraries:

```bash
pip install flask joblib scikit-learn pandas flask-cors
```

### Recommended VS Code Extensions:

- **Python**: (by Microsoft) Provides intellisense and debugging for your `app.py`.
- **REST Client**: (by Huachao Mao) This is the **best extension** for testing your API. It allows you to send `POST` requests directly from a `.http` file inside VS Code.
- **Thunder Client**: A GUI-based alternative to Postman that lives inside VS Code.

---

## 2. Flask API Implementation (`app.py`)

Create a file named `app.py` and paste this code. This API expects the `lianga_accident_model.pkl` and encoders you saved during training.

```python
from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd

app = Flask(__name__)
CORS(app) # Enable CORS for EyeSOS app compatibility

# 1. LOAD THE TRAINED MODEL AND ENCODERS
model = joblib.load('lianga_accident_model.pkl')
weather_le = joblib.load('weather_encoder.pkl')
road_le = joblib.load('road_encoder.pkl')

# 2. RISK LEVEL MAPPING LOGIC
def get_risk_level(probability):
    if probability >= 0.8: return "Critical"
    if probability >= 0.6: return "High"
    if probability >= 0.4: return "Moderate"
    if probability >= 0.2: return "Minor"
    return "None"

@app.route('/predict_risk', methods=['POST'])
def predict_risk():
    try:
        # Get data from EyeSOS request
        data = request.get_json()

        # Example input: {"lat": 8.631, "lng": 126.095, "weather": "Rainy", "road_type": "Curve", "hour": 22, "speed": 40}
        lat = float(data['lat'])
        lng = float(data['lng'])
        weather = data['weather']
        road_type = data['road_type']
        hour = int(data['hour'])
        speed = float(data['speed'])

        # Transform categories using saved encoders
        weather_enc = weather_le.transform([weather])[0]
        road_enc = road_le.transform([road_type])[0]

        # Prepare for prediction (Include Lat, Lng, and Speed!)
        input_data = [[lat, lng, weather_enc, road_enc, hour, speed]]

        # Get Probability
        prob = model.predict_proba(input_data)[0][1]
        risk_level = get_risk_level(prob)

        return jsonify({
            'probability': round(prob, 4),
            'risk_level': risk_level,
            'status': 'success'
        })

    except Exception as e:
        return jsonify({'error': str(e), 'status': 'failed'}), 400

if __name__ == '__main__':
    # Run the API on your local network
    app.run(host='0.0.0.0', port=5000, debug=True)
```

---

## 3. How to Test Your API (Usage Example)

### Using Python (`test_api.py`)

```python
import requests

url = "http://localhost:5000/predict_risk"
data = {
    "lat": 8.6310,
    "lng": 126.0950,
    "weather": "Rainy",
    "road_type": "Curve",
    "hour": 22,
    "speed": 40
}

response = requests.post(url, json=data)
print(response.json())
```

---

## 4. Deploying for EyeSOS (Connecting to Flutter)

When a user searches for a destination, EyeSOS calls this "Forecasting Engine" for each coordinate on the path.

```dart
// Example Flutter Call (Forecasting)
final response = await http.post(
  Uri.parse('http://YOUR_LOCAL_IP:5000/predict_risk'),
  body: jsonEncode({
    "lat": 8.6310,
    "lng": 126.0950,
    "weather": "Rainy",
    "road_type": "Curve",
    "hour": 22,
    "speed": 40
  }),
);
```

> [!IMPORTANT]
> When testing on a real phone, replace `localhost` with your computer's **Actual IP Address** (e.g., `192.168.1.5`).
