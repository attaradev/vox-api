"""Utility helpers around Django's cache backend with safe fallbacks."""

from __future__ import annotations

import logging
from typing import Sequence

from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger("vox_api.cache")

DEFAULT_TIMEOUT = getattr(settings, "DEFAULT_CACHE_TTL", 300)


def safe_cache_get(key: str, default=None):
    """Return a cached value, swallowing backend errors to preserve resilience."""

    try:
        return cache.get(key, default)
    except Exception as exc:  # pragma: no cover - defensive guard
        logger.debug("Cache get failed for %s: %s", key, exc, exc_info=True)
        return default


def safe_cache_set(key: str, value, timeout: int | None = None) -> None:
    """Store a value in the cache, ignoring backend failures."""

    try:
        cache.set(
            key, value, timeout=timeout if timeout is not None else DEFAULT_TIMEOUT
        )
    except Exception as exc:  # pragma: no cover - defensive guard
        logger.debug("Cache set failed for %s: %s", key, exc, exc_info=True)


def safe_cache_delete(key: str) -> None:
    """Delete a cache key, ignoring backend errors."""

    try:
        cache.delete(key)
    except Exception as exc:  # pragma: no cover - defensive guard
        logger.debug("Cache delete failed for %s: %s", key, exc, exc_info=True)


def safe_cache_delete_many(keys: Sequence[str]) -> None:
    """Delete multiple cache keys defensively."""

    if not keys:
        return
    try:
        cache.delete_many(keys)
    except Exception as exc:  # pragma: no cover - defensive guard
        logger.debug(
            "Cache delete_many failed for %s keys: %s", len(keys), exc, exc_info=True
        )


def safe_cache_incr(key: str, delta: int = 1, default: int | None = None) -> int | None:
    """Increment a numeric cache value, setting a default when necessary."""

    try:
        if default is not None and cache.add(key, default):
            return default
        return cache.incr(key, delta)
    except Exception as exc:  # pragma: no cover - defensive guard
        logger.debug("Cache incr failed for %s: %s", key, exc, exc_info=True)
        return None


__all__ = [
    "DEFAULT_TIMEOUT",
    "safe_cache_delete",
    "safe_cache_delete_many",
    "safe_cache_get",
    "safe_cache_incr",
    "safe_cache_set",
]
