"""Maintenance tasks for billing data."""

import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone

from billing.models import Invoice

logger = logging.getLogger("billing.cleanup")


RETENTION_DAYS = 365


@shared_task
def cleanup_old_invoices():
    """Remove historical paid invoices beyond the retention window."""

    cutoff = timezone.now() - timedelta(days=RETENTION_DAYS)
    old_invoices = Invoice.objects.filter(is_paid=True, issued_at__lt=cutoff)
    count = old_invoices.delete()[0]
    logger.info(f"Cleaned up {count} old invoices older than {RETENTION_DAYS} days.")
