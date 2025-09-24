"""
Model for account tiers, controlling feature limits and flags.
"""

from django.db import models


class AccountTier(models.Model):
    """Model representing a subscription tier for accounts."""

    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)
    max_members = models.PositiveIntegerField(default=10)
    max_polls = models.PositiveIntegerField(default=10)
    price_per_month = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    is_active = models.BooleanField(default=True)
    feature_flags = models.JSONField(
        default=dict,
        blank=True,
        help_text=(
            "Feature flags for tier (e.g., advanced_analytics, "
            "custom_branding, api_access)"
        ),
    )

    def __str__(self):
        """Return the tier name as string representation."""
        return self.name
