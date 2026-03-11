FROM python:3.11-slim

# evita file .pyc e buffer nei log
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# cartella di lavoro nel container
WORKDIR /app

# install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# copia il codice del servizio
COPY . .

# comando di avvio del microservizio
CMD ["python", "main.py"]