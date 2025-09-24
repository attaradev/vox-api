"""Signal handlers for invoice lifecycle events."""

from django.db.models.signals import post_save
from django.dispatch import receiver

from billing.models import Invoice
from billing.tasks import send_invoice_email


@receiver(post_save, sender=Invoice)
def send_invoice_email_signal(sender, instance, created, **kwargs):
    """Queue an email with the invoice PDF when a new invoice is created."""

    if created and instance.user and instance.user.email:
        send_invoice_email.delay(instance.user.email, instance.pdf_url)
