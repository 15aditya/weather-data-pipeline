import pandas as pd

def transform(raw_data):

    location_data = raw_data.get("location", {})
    current_data = raw_data.get("current", {})

    record = {
        "timestamp": location_data.get("localtime"),
        "temperature_c": current_data.get("temperature"),
        "humidity": current_data.get("humidity"),
        "wind_speed": current_data.get("wind_speed"),
        "weather_description": current_data.get("weather_descriptions", [""])[0],
        "city": location_data.get("name"),
        "country": location_data.get("country")
    }

    df = pd.DataFrame.from_dict([record])
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    df["hour"] = df["timestamp"].dt.strftime("%Y-%m-%dT%H")

    return df
