"""Audit logging utilities for core system events."""

import logging

from core.models.audit_log import AuditLog


def log_audit(user, action, object_type, object_id, details=None):
    """
    System-wide audit logger. Logs to console and saves to AuditLog DB.
    """
    logger = logging.getLogger("audit")
    logger.info(
        "AUDIT | user=%s | action=%s | object_type=%s | object_id=%s | details=%s",
        getattr(user, "username", user),
        action,
        object_type,
        object_id,
        details,
    )

    AuditLog.objects.create(
        user=getattr(user, "username", str(user)),
        action=action,
        object_type=object_type,
        object_id=object_id,
        details=details,
    )
