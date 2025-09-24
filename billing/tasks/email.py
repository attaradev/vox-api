"""Celery tasks for sending billing-related emails."""

import logging

from celery import shared_task
from django.conf import settings
from django.core.mail import EmailMultiAlternatives, send_mail

logger = logging.getLogger("billing.email")


@shared_task(bind=True, max_retries=3, default_retry_delay=60, queue="emails")
def send_billing_receipt_email(self, subject, message, recipient_list):
    """Send a plain-text billing receipt email with retry handling."""

    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=None,
            recipient_list=recipient_list,
            fail_silently=False,
        )
        logger.info(f"Billing receipt email sent to {recipient_list}")
    except Exception as exc:
        logger.error(f"Error sending billing receipt email to {recipient_list}: {exc}")
        raise self.retry(exc=exc)


@shared_task
def send_invoice_email(to_email, invoice_pdf_url):
    """Send an HTML invoice email that includes a link to the PDF."""

    subject = "Your Vox Invoice"
    text_content = f"Your invoice is ready. Download: {invoice_pdf_url}"
    html_content = f"""
        <h2>Your Invoice</h2>
        <p>Download your invoice: <a href='{invoice_pdf_url}'>{invoice_pdf_url}</a></p>
    """
    try:
        msg = EmailMultiAlternatives(
            subject,
            text_content,
            getattr(settings, "DEFAULT_FROM_EMAIL", None),
            [to_email],
        )
        msg.attach_alternative(html_content, "text/html")
        msg.send()
        logger.info(f"Invoice email sent to {to_email}")
    except Exception as e:
        logger.error(f"Failed to send invoice email to {to_email}: {e}")
