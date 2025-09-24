"""Model definitions for poll choices."""

from django.db import models

from .poll import Poll


class Choice(models.Model):
    """A selectable option for a poll question."""

    poll = models.ForeignKey(
        Poll,
        related_name="choices",
        on_delete=models.CASCADE,
    )
    text = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["poll", "text"], name="choice_unique_per_poll"
            )
        ]

    def __str__(self):
        """Return the display text for this choice."""
        return self.text

    @property
    def vote_count(self) -> int:
        """Return the number of votes for this choice."""
        return self.votes.count()
