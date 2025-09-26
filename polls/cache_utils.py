"""Caching helpers tailored for poll read endpoints."""

from __future__ import annotations

import hashlib
from typing import Iterable

from vox_api.cache import (
    safe_cache_delete,
    safe_cache_delete_many,
    safe_cache_get,
    safe_cache_set,
)

LIST_INDEX_KEY = "polls:list:index"


def _scope_for_user(user) -> str:
    if user and getattr(user, "is_authenticated", False):
        user_id = getattr(user, "pk", None)
        return f"user:{user_id}" if user_id is not None else "auth"
    return "anon"


def _hash_value(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _make_key(*parts: Iterable[str]) -> str:
    return "polls:" + ":".join(str(part) for part in parts)


def _load_index(index_key: str) -> list[str]:
    cached = safe_cache_get(index_key, default=[])
    if not cached:
        return []
    return list({str(item) for item in cached})


def _store_index(index_key: str, keys: list[str]) -> None:
    safe_cache_set(index_key, list(dict.fromkeys(keys)), timeout=None)


def build_list_cache_key(user, request_path: str) -> str:
    scope = _scope_for_user(user)
    return _make_key("list", scope, _hash_value(request_path))


def build_detail_cache_key(poll_id: int, scope: str | None = None) -> str:
    scope_fragment = scope or "global"
    return _make_key("detail", poll_id, scope_fragment)


def get_cached_list_response(user, request_path: str):
    cache_key = build_list_cache_key(user, request_path)
    return safe_cache_get(cache_key)


def cache_list_response(
    user, request_path: str, payload, timeout: int | None = None
) -> None:
    cache_key = build_list_cache_key(user, request_path)
    safe_cache_set(cache_key, payload, timeout=timeout)
    keys = _load_index(LIST_INDEX_KEY)
    keys.append(cache_key)
    _store_index(LIST_INDEX_KEY, keys)


def invalidate_poll_list_cache() -> None:
    keys = _load_index(LIST_INDEX_KEY)
    safe_cache_delete_many(keys)
    safe_cache_delete(LIST_INDEX_KEY)


def get_cached_poll_detail(poll_id: int, user) -> tuple[str, object | None]:
    scope = _scope_for_user(user)
    cache_key = build_detail_cache_key(poll_id, scope)
    return cache_key, safe_cache_get(cache_key)


def cache_poll_detail(poll_id: int, user, payload, timeout: int | None = None) -> None:
    scope = _scope_for_user(user)
    cache_key = build_detail_cache_key(poll_id, scope)
    safe_cache_set(cache_key, payload, timeout=timeout)
    index_key = _make_key("detail", poll_id, "index")
    keys = _load_index(index_key)
    keys.append(cache_key)
    _store_index(index_key, keys)


def invalidate_poll_detail_cache(poll_id: int) -> None:
    index_key = _make_key("detail", poll_id, "index")
    keys = _load_index(index_key)
    safe_cache_delete_many(keys)
    safe_cache_delete(index_key)


def invalidate_poll_cache(poll_id: int | None = None) -> None:
    if poll_id is not None:
        invalidate_poll_detail_cache(poll_id)
    invalidate_poll_list_cache()


__all__ = [
    "cache_list_response",
    "cache_poll_detail",
    "get_cached_list_response",
    "get_cached_poll_detail",
    "invalidate_poll_cache",
    "invalidate_poll_detail_cache",
    "invalidate_poll_list_cache",
]
