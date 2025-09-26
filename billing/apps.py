"""App configuration for the billing Django app."""

from django.apps import AppConfig


class BillingConfig(AppConfig):
    """Configure billing app defaults for Django."""

    default_auto_field = "django.db.models.BigAutoField"
    name = "billing"
    verbose_name = "Billing"
