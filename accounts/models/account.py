"""
Model for representing an account and its subscription tier.
"""

from django.db import models

from .tier import AccountTier


class Account(models.Model):
    """Model representing an organization account and its tier."""

    name = models.CharField(max_length=100, unique=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    tier = models.ForeignKey(
        AccountTier,
        on_delete=models.PROTECT,
        related_name="accounts",
        null=True,
        blank=True,
        help_text="Tier controls feature limits such as members and polls",
    )
    billing_email = models.EmailField(blank=True)
    subscription_status = models.CharField(
        max_length=20,
        choices=[
            ("active", "Active"),
            ("past_due", "Past Due"),
            ("canceled", "Canceled"),
            ("trial", "Trial"),
        ],
        default="trial",
    )
    payment_provider_id = models.CharField(
        max_length=128,
        blank=True,
        help_text="ID from payment provider (e.g., Stripe customer ID)",
    )

    def __str__(self):
        """Return the account name as string representation."""
        return self.name

    def can_add_member(self) -> bool:
        """Check if a new member can be added based on tier limits."""
        if not self.tier:
            return True
        return self.user_roles.count() < self.tier.max_members

    def can_add_poll(self) -> bool:
        """Check if a new poll can be added based on tier limits."""
        if not self.tier:
            return True
        from polls.models.poll import Poll

        return Poll.objects.filter(account=self).count() < self.tier.max_polls

    def tier_features(self):
        """Return a dictionary of tier features for this account."""
        if not self.tier:
            return {}
        return {
            "max_members": self.tier.max_members,
            "max_polls": self.tier.max_polls,
            "price_per_month": self.tier.price_per_month,
            "is_active": self.tier.is_active,
        }
