"""
Model for account and role permissions in the accounts app.
"""

from django.db import models


class Permission(models.Model):
    """Model representing a permission code and description."""

    code = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)

    def __str__(self):
        """Return the permission code as string representation."""
        return self.code


class AccountPermission(models.Model):
    """Model linking an account to a permission, with enabled status."""

    account = models.ForeignKey(
        "accounts.Account", on_delete=models.CASCADE, related_name="permissions"
    )
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE)
    enabled = models.BooleanField(default=True)

    class Meta:
        unique_together = ("account", "permission")

    def __str__(self):
        """Return a string describing the account and permission status."""
        status = "enabled" if self.enabled else "disabled"
        return f"{self.account.name}: {self.permission.code} ({status})"


class RolePermission(models.Model):
    """Model linking a role to a permission, with enabled status."""

    role = models.CharField(max_length=20)
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE)
    enabled = models.BooleanField(default=True)

    class Meta:
        unique_together = ("role", "permission")

    def __str__(self):
        """Return a string describing the role and permission status."""
        status = "enabled" if self.enabled else "disabled"
        return f"{self.role}: {self.permission.code} ({status})"
