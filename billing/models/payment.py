"""Models for recording payment transactions."""

from django.db import models

from accounts.models.account import Account
from billing.models.invoice import Invoice


class Payment(models.Model):
    """Represent a payment tied to an account and optional invoice."""

    account = models.ForeignKey(
        Account, on_delete=models.CASCADE, related_name="payments"
    )
    invoice = models.ForeignKey(
        Invoice, on_delete=models.SET_NULL, null=True, blank=True
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_date = models.DateTimeField(auto_now_add=True)
    provider = models.CharField(max_length=50)
    provider_id = models.CharField(max_length=128, blank=True)
    status = models.CharField(max_length=20, default="completed")

    def __str__(self):
        """Return a descriptive identifier for the payment."""

        return f"Payment {self.id} for {self.account.name}"
