"""Invoice model definitions."""

from django.contrib.auth import get_user_model
from django.db import models

from accounts.models.account import Account


class Invoice(models.Model):
    """Represent an invoice issued to an account."""

    account = models.ForeignKey(
        Account, on_delete=models.CASCADE, related_name="invoices"
    )
    user = models.ForeignKey(
        get_user_model(), on_delete=models.SET_NULL, null=True, blank=True
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    issued_at = models.DateTimeField(auto_now_add=True)
    due_at = models.DateTimeField()
    is_paid = models.BooleanField(default=False)
    pdf_url = models.URLField(blank=True)

    def __str__(self):
        """Return a readable identifier for the invoice."""

        return f"Invoice {self.id} for {self.account.name}"
