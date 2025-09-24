"""Models representing billing accounts and configuration."""

from django.db import models

from accounts.models.account import Account


class BillingAccount(models.Model):
    """Persist billing provider metadata associated with an account."""

    PROVIDER_CHOICES = [
        ("stripe", "Stripe"),
        ("paypal", "PayPal"),
    ]
    account = models.OneToOneField(
        Account, on_delete=models.CASCADE, related_name="billing"
    )
    provider = models.CharField(
        max_length=20,
        choices=PROVIDER_CHOICES,
        default="stripe",
        help_text="Payment provider for this billing account",
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
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        """Return a readable label for admin and shell usage."""

        return f"Billing for {self.account.name}"
