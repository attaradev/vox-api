"""Subscription models and helpers."""

from django.db import models

from accounts.models.account import Account


class Subscription(models.Model):
    """Persist subscription metadata for accounts."""

    account = models.ForeignKey(
        Account, on_delete=models.CASCADE, related_name="subscriptions"
    )
    provider = models.CharField(max_length=50)
    provider_id = models.CharField(max_length=128, blank=True)
    status = models.CharField(max_length=20, default="active")
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    plan = models.CharField(max_length=50, blank=True)

    def __str__(self):
        """Return a readable summary of the subscription."""

        return f"Subscription {self.id} for {self.account.name}"
