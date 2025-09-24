"""Signal handlers for password reset events."""

from django.dispatch import Signal, receiver

from accounts.tasks import send_password_reset_email

# Custom signal for password reset request
password_reset_requested = Signal()  # args: email, reset_url


@receiver(password_reset_requested)
def send_password_reset_email_signal(sender, email, reset_url, **kwargs):
    """Send password reset email when the signal is triggered."""
    send_password_reset_email.delay(email, reset_url)
