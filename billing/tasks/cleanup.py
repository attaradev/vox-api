"""Maintenance tasks for billing data."""

import logging

from celery import shared_task

from billing.models import Invoice

logger = logging.getLogger("billing.cleanup")


@shared_task
def cleanup_old_invoices():
    """Remove historical paid invoices beyond the retention window."""

    old_invoices = Invoice.objects.filter(is_paid=True, created__lt="2023-01-01")
    count = old_invoices.delete()[0]
    logger.info(f"Cleaned up {count} old invoices.")
