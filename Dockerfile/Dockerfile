FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY custom_scheduler.py .

CMD ["python", "/app/custom_scheduler.py"]
