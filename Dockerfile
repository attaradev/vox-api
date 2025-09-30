# syntax=docker/dockerfile:1

FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1

ENV POETRY_VIRTUALENVS_CREATE=false \
  PATH="/home/appuser/.local/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential curl netcat-traditional libcap2-bin \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV DJANGO_SETTINGS_MODULE=vox_api.settings

COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install --no-cache-dir -r requirements.txt

COPY . .

COPY docker-entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

FROM base AS development
RUN useradd --create-home appuser
USER appuser
ENTRYPOINT ["/usr/local/bin/entrypoint"]
EXPOSE 8000
# Add health check for development containers
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')"
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

FROM base AS production
RUN useradd --create-home appuser
USER root
RUN setcap 'cap_net_bind_service=+ep' $(readlink -f $(which python3))
USER appuser
ENTRYPOINT ["/usr/local/bin/entrypoint"]
EXPOSE 80
# Add health check for production containers
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD python -c "import urllib.request, sys; \
  try: \
  urllib.request.urlopen('http://127.0.0.1:80/healthz', timeout=5); \
  sys.exit(0); \
  except: \
  sys.exit(1)"
# Optimize gunicorn for production
CMD ["gunicorn", "vox_api.wsgi:application", \
  "--bind", "0.0.0.0:80", \
  "--workers", "4", \
  "--worker-class", "sync", \
  "--worker-connections", "1000", \
  "--max-requests", "1000", \
  "--max-requests-jitter", "50", \
  "--timeout", "30", \
  "--keep-alive", "10", \
  "--access-logfile", "-", \
  "--error-logfile", "-"]
