"""Serializers for core audit log resources."""

from rest_framework import serializers

from core.models import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
    """Serializer for audit log entries."""

    class Meta:
        model = AuditLog
        fields = [
            "id",
            "action",
            "user",
            "object_type",
            "object_id",
            "timestamp",
            "details",
        ]
