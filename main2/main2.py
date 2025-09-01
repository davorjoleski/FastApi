import psycopg2
from dotenv import load_dotenv
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from azure.storage.blob import BlobServiceClient
import os
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware
import math
import time
load_dotenv()
from fastapi.responses import RedirectResponse

app = FastAPI(docs_url="/", redoc_url=None)


# Ова му кажува на FastAPI да ги чита правилно оригиналните headers од load balancer
app.add_middleware(ProxyHeadersMiddleware)
@app.get("/", include_in_schema=False)
async def root():
    return RedirectResponse(url="/docs")

# Azure connection string преку променлива од околина
AZURE_CONNECTION_STRING2 = os.getenv("AZURE_STORAGE_CONNECTION_STRING2")
print(f"Loaded connection string: {AZURE_CONNECTION_STRING2[:20]}...")

CONTAINER_NAME = "intake"

@app.post("/process")
async def upload_file(file: UploadFile = File(...)):
    if not AZURE_CONNECTION_STRING2:
        raise HTTPException(status_code=500, detail="Azure connection string not configured")

    try:
        # Иницијализирај Blob клиент
        blob_service = BlobServiceClient.from_connection_string(AZURE_CONNECTION_STRING2)
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


# CPU intensive endpoint
@app.get("/load")
def load_endpoint(duration: int = 10):
    """
    Burns CPU for `duration` seconds.
     /load?duration=15
    """
    end_time = time.time() + duration
    result = 0
    while time.time() < end_time:
        result += math.sqrt(12345) * math.sqrt(67890)
    return {"status": "done", "result": result}


@app.get("/healthz")
def health_check():
    # Basic liveness check
    return JSONResponse(
        status_code=200,
        content={"status": "ok", "message": "Application is healthy and running"}
    )

@app.get("/readyz")
def readiness_check():
    # Readiness check (testing for DB, Storage, Queue итн.)
    dependencies_ok = True

    if dependencies_ok:
        return JSONResponse(
            status_code=200,
            content={"status": "ready", "message": "Application is ready to serve traffic"}
        )
    else:
        return JSONResponse(
            status_code=503,
            content={"status": "not ready", "message": "Dependencies not available yet"}
        )

    # Вчитување креденцијали од environment (ќе доаѓаат од Kubernetes Secret)
    DB_NAME = os.getenv("POSTGRES_DB")
    DB_USER = os.getenv("POSTGRES_USER")
    DB_PASS = os.getenv("POSTGRES_PASSWORD")
    DB_HOST = os.getenv("POSTGRES_HOST")  # ќе дојде од Kubernetes Service
    DB_PORT = os.getenv("POSTGRES_PORT", "5432")

    def get_connection():
        return psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT
        )

    # иницијализација на табела
    @app.on_event("startup")
    def init_db():
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
                    CREATE TABLE IF NOT EXISTS hits
                    (
                        id
                        SERIAL
                        PRIMARY
                        KEY,
                        count
                        INT
                        NOT
                        NULL
                    );
                    """)
        cur.execute("INSERT INTO hits (count) VALUES (0) ON CONFLICT DO NOTHING;")
        conn.commit()
        cur.close()
        conn.close()

    @app.get("/hits")
    def read_hits():
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT count FROM hits ORDER BY id ASC LIMIT 1;")
        result = cur.fetchone()
        count = result[0]
        cur.execute("UPDATE hits SET count = count + 1 WHERE id = 1;")
        conn.commit()
        cur.close()
        conn.close()
        return {"visits": count + 1}