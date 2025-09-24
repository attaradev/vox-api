import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "vox_api.settings")

app = Celery("vox_api")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
