# Import Celery app for background jobs
from .celery import app as celery_app

__all__ = ("celery_app",)
