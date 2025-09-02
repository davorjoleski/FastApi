import os
import math
import time
import psycopg2
from dotenv import load_dotenv
from fastapi import FastAPI, File, UploadFile, HTTPException, APIRouter
from fastapi.responses import RedirectResponse
from azure.storage.blob import BlobServiceClient
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware

# ================= Init =================
load_dotenv()
app = FastAPI(docs_url="/", redoc_url=None)
app.add_middleware(ProxyHeadersMiddleware)

@app.get("/", include_in_schema=False)
async def root():
    return RedirectResponse(url="/docs")

# ================= Azure Blob =================
AZURE_CONNECTION_STRING2 = os.getenv("AZURE_STORAGE_CONNECTION_STRING2")
CONTAINER_NAME = "intake"

@app.post("/process")
async def upload_file(file: UploadFile = File(...)):
    if not AZURE_CONNECTION_STRING2:
        raise HTTPException(status_code=500, detail="Azure connection string not configured")

    try:
        blob_service = BlobServiceClient.from_connection_string(AZURE_CONNECTION_STRING2)
        container_client = blob_service.get_container_client(CONTAINER_NAME)

        try:
            container_client.get_container_properties()
        except Exception:
            container_client.create_container()

        blob_client = container_client.get_blob_client(file.filename)
        blob_client.upload_blob(await file.read(), overwrite=True)

        return {"message": "File uploaded", "filename": file.filename}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

# ================= Utility endpoints =================
@app.get("/load")
def load_endpoint(duration: int = 10):
    end_time = time.time() + duration
    result = 0
    while time.time() < end_time:
        result += math.sqrt(12345) * math.sqrt(67890)
    return {"status": "done", "result": result}

@app.get("/healthz")
def health_check():
    return {"status": "ok", "message": "Application is healthy and running"}

@app.get("/readyz")
def readiness_check():
    return {"status": "ready", "message": "Application is ready to serve traffic"}

# ================= Postgres: Hits Counter =================
DB_NAME = os.getenv("POSTGRES_DB")
DB_USER = os.getenv("POSTGRES_USER")
DB_PASS = os.getenv("POSTGRES_PASSWORD")
DB_HOST = os.getenv("POSTGRES_HOST")  # Service name од Kubernetes
DB_PORT = os.getenv("POSTGRES_PORT", "5432")

def get_connection():
    return psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST,
        port=DB_PORT
    )

@app.get("/hits")
def read_hits():
    try:
        conn = get_connection()
        cur = conn.cursor()

        cur.execute("""
                    CREATE TABLE IF NOT EXISTS hits
                    (
                        id
                        INT
                        PRIMARY
                        KEY,
                        count
                        INT
                    );
                    """)

        # Обезбеди ред со id=1
        cur.execute("""
            INSERT INTO hits (id, count)
            VALUES (1, 0)
            ON CONFLICT (id) DO NOTHING;
        """)
        conn.commit()

        # Прочитај count
        cur.execute("SELECT count FROM hits WHERE id = 1;")
        result = cur.fetchone()
        count = result[0] if result else 0

        # Зголеми го counter-от
        cur.execute("UPDATE hits SET count = count + 1 WHERE id = 1;")
        conn.commit()

        cur.close()
        conn.close()
        return {"visits": count + 1}

    except Exception as e:
        return {"error": str(e)}
