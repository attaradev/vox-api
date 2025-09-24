"""Celery tasks for user account maintenance."""

import logging

from celery import shared_task
from django.contrib.auth import get_user_model

logger = logging.getLogger("accounts.user")
User = get_user_model()


@shared_task
def deactivate_inactive_users():
    """Deactivate users who have never logged in."""
    inactive_users = User.objects.filter(is_active=True, last_login__isnull=True)
    count = inactive_users.update(is_active=False)
    logger.info(f"Deactivated {count} inactive users.")
