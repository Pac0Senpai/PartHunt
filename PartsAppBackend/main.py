from fastapi import FastAPI, HTTPException
import requests

app = FastAPI()

@app.get("/api/v1/decode-vin/{vin}")
def decode_vin(vin: str):
    url = f"https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/{vin}?format=json"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        
        data = response.json()
        results = data.get("Results", [])
        car_info = {item["Variable"]: item["Value"] for item in results if item["Value"]}
        
        # Δημιουργία ενός εικονικού καταλόγου ανταλλακτικών (όπως το PartSouq)
        mock_catalog = [
            {
                "category": "Κινητήρας (Engine)",
                "diagram_url": "https://via.placeholder.com/600x400.png?text=Engine+Schematic",
                "parts": [
                    {"name": "Φίλτρο Λαδιού (Oil Filter)", "oem": "90915-YZZN1"},
                    {"name": "Αντλία Νερού (Water Pump)", "oem": "16100-39466"},
                    {"name": "Μπουζί (Spark Plugs)", "oem": "90919-01253"}
                ]
            },
            {
                "category": "Φρένα (Brakes)",
                "diagram_url": "https://via.placeholder.com/600x400.png?text=Brakes+Schematic",
                "parts": [
                    {"name": "Τακάκια Εμπρός (Front Pads)", "oem": "04465-06240"},
                    {"name": "Δισκόπλακα Εμπρός (Front Rotor)", "oem": "43512-06150"}
                ]
            }
        ]
        
        return {
            "status": "success",
            "vehicle_data": {
                "make": car_info.get("Make", "Άγνωστο"),
                "model": car_info.get("Model", "Άγνωστο"),
                "year": car_info.get("Model Year", ""),
                "engine": car_info.get("Engine Number of Cylinders", "")
            },
            "catalog": mock_catalog # Στέλνουμε τον κατάλογο στο κινητό
        }
        
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=503, detail=str(e))