# Use lightweight Python base image
FROM python:3.11-slim

# Set working directory
WORKDIR /Testator

# Install dependencies
COPY test2.txt .
RUN pip install --no-cache-dir -r test2.txt

# Copy source code
COPY .. .

# Expose port
EXPOSE 8000

# Run the app with uvicorn
CMD ["uvicorn", "main2:app", "--host", "0.0.0.0", "--port", "8100"]
