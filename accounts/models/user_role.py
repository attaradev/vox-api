"""
Model for linking users to accounts with specific roles.
"""

from django.contrib.auth import get_user_model
from django.db import models

from .account import Account


class AccountUserRole(models.Model):
    """Model representing a user's role within an account."""

    ROLE_CHOICES = [
        ("owner", "Owner"),
        ("admin", "Admin"),
        ("member", "Member"),
    ]
    user = models.ForeignKey(
        get_user_model(), on_delete=models.CASCADE, related_name="account_roles"
    )
    account = models.ForeignKey(
        Account, on_delete=models.CASCADE, related_name="user_roles"
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "account")

    def __str__(self):
        """Return a string describing the user's role in the account."""
        return f"{self.user.username} ({self.role}) in {self.account.name}"
