# Use lightweight Python base image
FROM python:3.11-slim

# Set working directory
WORKDIR /Testator

# Install dependencies
COPY requirement.txt .
RUN pip install --no-cache-dir -r requirement.txt

# Copy source code
COPY .. .

# Expose port
EXPOSE 8000

# Run the app with uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8100"]
