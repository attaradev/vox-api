"""Celery tasks for sending account-related emails."""

import logging

from celery import shared_task
from django.core.mail import EmailMultiAlternatives

logger = logging.getLogger("accounts.email")


@shared_task
def send_welcome_email(to_email):
    """Send a welcome email to a new user."""
    subject = "Welcome to Vox!"
    text_content = "Thank you for registering."
    html_content = """
        <h2>Welcome to Vox API!</h2>
        <p>Thank you for registering. You can now participate in polls and teams.</p>
    """
    try:
        msg = EmailMultiAlternatives(subject, text_content, None, [to_email])
        msg.attach_alternative(html_content, "text/html")
        msg.send()
        logger.info(f"Welcome email sent to {to_email}")
    except Exception as e:
        logger.error(f"Failed to send welcome email to {to_email}: {e}")


@shared_task
def send_password_reset_email(to_email, reset_url):
    """Send a password reset email with a reset link."""
    subject = "Password Reset for Vox API"
    text_content = f"Reset your password using this link: {reset_url}"
    html_content = f"""
        <h2>Password Reset</h2>
        <p>Click the link below to reset your password:</p>
        <a href='{reset_url}'>{reset_url}</a>
        <p>If you did not request this, please ignore this email.</p>
    """
    try:
        msg = EmailMultiAlternatives(subject, text_content, None, [to_email])
        msg.attach_alternative(html_content, "text/html")
        msg.send()
        logger.info(f"Password reset email sent to {to_email}")
    except Exception as e:
        logger.error(f"Failed to send password reset email to {to_email}: {e}")
