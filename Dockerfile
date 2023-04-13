FROM python:3.9-slim-buster

RUN apt-get update \
    && apt-get -y install gcc python3-dev libpq-dev \
    && pip install --upgrade pip \
    && pip install --no-cache-dir gunicorn
    
WORKDIR /app

COPY requirements.txt .
COPY flaskapp.py .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 80

CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:80", "flaskapp:app"]
