from rest_framework import serializers

from polls.models.audit_log import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
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
