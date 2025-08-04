# Builds a Python-based FastAPI app using uvicorn

# Use lightweight Python base image
FROM python:3.11-slim

# Set working directory
WORKDIR /Testator

# Install dependencies
COPY test.txt .
RUN pip install --no-cache-dir -r test.txt

# Copy source code
COPY .. .

# Expose port outside
EXPOSE 8000

# Run the app with uvicorn (container)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
