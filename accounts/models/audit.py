"""
Simple audit logger for account actions.
"""

import logging


def log_audit(user, action, object_type, object_id, details=None):
    """
    Log an audit event for a user action on an object.
    Extend to save to DB or external service as needed.
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
