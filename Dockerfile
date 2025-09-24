# syntax=docker/dockerfile:1

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  POETRY_VIRTUALENVS_CREATE=false

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential curl netcat-traditional \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python deps
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -r requirements.txt

# App
COPY . .


# Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]

# Dev server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
