import time

from django.conf import settings
from django.core.cache import cache
from django.db import connections
from django.http import JsonResponse


def health_check(request):
    """
    Comprehensive health check that verifies:
    - Application responsiveness
    - Database connectivity
    - Cache connectivity (if configured)
    """
    health_status = {"status": "ok", "timestamp": time.time(), "checks": {}}

    # Check database connectivity
    try:
        db_conn = connections["default"]
        db_conn.cursor()  # This will raise an exception if DB is unavailable
        health_status["checks"]["database"] = "ok"
    except Exception as e:
        health_status["status"] = "error"
        health_status["checks"]["database"] = f"error: {str(e)}"

    # Check cache connectivity (if Redis is configured)
    try:
        # Simple cache operation to test connectivity
        cache.set("health_check", "ok", 10)
        cache_value = cache.get("health_check")
        if cache_value == "ok":
            health_status["checks"]["cache"] = "ok"
        else:
            health_status["checks"]["cache"] = "error: cache not working"
            health_status["status"] = "error"
    except Exception as e:
        # Cache might not be configured or available
        health_status["checks"]["cache"] = f"warning: {str(e)}"

    # Check if we're in maintenance mode (optional)
    maintenance_mode = getattr(settings, "MAINTENANCE_MODE", False)
    if maintenance_mode:
        health_status["status"] = "maintenance"
        health_status["checks"]["maintenance"] = "active"

    # Set appropriate HTTP status code
    status_code = 200
    if health_status["status"] == "error":
        status_code = 503  # Service Unavailable
    elif health_status["status"] == "maintenance":
        status_code = 503

    return JsonResponse(health_status, status=status_code)
