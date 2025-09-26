"""Signal handlers that keep poll-related caches consistent."""

from __future__ import annotations

from django.db import transaction
from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from polls import cache_utils as poll_cache
from polls.models import Choice, Poll, Question, Vote


def _schedule_invalidation(poll_id: int | None) -> None:
    if poll_id is None:
        transaction.on_commit(poll_cache.invalidate_poll_list_cache)
        return

    def _invalidate() -> None:
        poll_cache.invalidate_poll_cache(poll_id)

    transaction.on_commit(_invalidate)


@receiver(post_save, sender=Poll)
@receiver(post_delete, sender=Poll)
def poll_changed(sender, instance, **kwargs):
    _schedule_invalidation(instance.pk)


@receiver(post_save, sender=Question)
@receiver(post_delete, sender=Question)
def question_changed(sender, instance, **kwargs):
    _schedule_invalidation(getattr(instance, "poll_id", None))


@receiver(post_save, sender=Choice)
@receiver(post_delete, sender=Choice)
def choice_changed(sender, instance, **kwargs):
    _schedule_invalidation(getattr(instance, "poll_id", None))


@receiver(post_save, sender=Vote)
@receiver(post_delete, sender=Vote)
def vote_changed(sender, instance, **kwargs):
    _schedule_invalidation(getattr(instance, "poll_id", None))
