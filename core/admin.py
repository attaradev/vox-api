"""Admin customizations for core models."""

from django.contrib import admin

from .models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    """Customize admin for audit log entries."""

    list_display = ("timestamp", "user", "action", "object_type", "object_id")
    search_fields = ("user", "action", "object_type")
