from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn


app = FastAPI()

class RecordSecret(BaseModel):
    client_ip: str
    apikey: str
    url: str

@app.post("/record_secret")
async def record_secret(record_secret: RecordSecret):
    client_ip = record_secret.client_ip
    apikey = record_secret.apikey
    url = record_secret.url

    data = {
        "msg": "recv secret info",
        "client_ip": client_ip,
        "apikey": apikey,
        "url": url
        }
    print(data)
    return data


if __name__ == "__main__":
        uvicorn.run(app, host="0.0.0.0", port=18882)
