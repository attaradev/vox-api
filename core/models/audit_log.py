"""Audit log model for recording system events."""

from django.db import models


class AuditLog(models.Model):
    """Model for storing audit log entries."""

    user = models.CharField(max_length=150)
    action = models.CharField(max_length=100)
    object_type = models.CharField(max_length=100)
    object_id = models.CharField(max_length=100)
    details = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        """Return a readable string for the audit log entry."""
        return (
            f"{self.timestamp} | {self.user} | {self.action} | "
            f"{self.object_type} | {self.object_id}"
        )
