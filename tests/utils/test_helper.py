from etl.utils.helper import transform
import pandas as pd

def test_transform_basic_data():
    raw_data = {
        "location": {
            "localtime": "2025-05-26 18:05",
            "name": "Berlin",
            "country": "Germany"
        },
        "current": {
            "temperature": 20,
            "humidity": 50,
            "wind_speed": 15,
            "weather_descriptions": ["Sunny"]
        }
    }

    df = transform(raw_data)

    assert isinstance(df, pd.DataFrame)
    assert df.shape[0] == 1


def test_transform_missing_data():

    raw_data = {
        "location": {},
        "current": {}
    }

    df = transform(raw_data)
    row = df.iloc[0]

    assert isinstance(df, pd.DataFrame)
    assert pd.isna(row["temperature_c"])

