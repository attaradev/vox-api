"""Signal handlers for user creation and welcome email."""

from django.contrib.auth import get_user_model
from django.db.models.signals import post_save
from django.dispatch import receiver

from accounts.tasks import send_welcome_email

User = get_user_model()


@receiver(post_save, sender=User)
def send_welcome_email_signal(sender, instance, created, **kwargs):
    """Send a welcome email when a new user is created."""
    if created and instance.email:
        send_welcome_email.delay(instance.email)
