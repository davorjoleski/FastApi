from dotenv import load_dotenv
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from azure.storage.blob import BlobServiceClient
import os
load_dotenv()

app = FastAPI()

# Azure connection string преку променлива од околина
AZURE_CONNECTION_STRING = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
print(f"Loaded connection string: {AZURE_CONNECTION_STRING[:20]}...")

CONTAINER_NAME = "intake"

@app.post("/process")
async def upload_file(file: UploadFile = File(...)):
    if not AZURE_CONNECTION_STRING:
        raise HTTPException(status_code=500, detail="Azure connection string not configured")

    try:
        # Иницијализирај Blob клиент
        blob_service = BlobServiceClient.from_connection_string(AZURE_CONNECTION_STRING)
        container_client = blob_service.get_container_client(CONTAINER_NAME)

        # Провери дали контејнерот постои
        try:
            container_client.get_container_properties()
        except Exception:
            container_client.create_container()

        blob_client = container_client.get_blob_client(file.filename)

        # Подигни го фајлот во Azure Blob Storage
        blob_client.upload_blob(await file.read(), overwrite=True)

        return JSONResponse(status_code=201, content={"message": "File uploaded", "filename": file.filename})

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")
