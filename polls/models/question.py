"""Poll question model representing an ordered question within a poll."""

from django.db import models


class Question(models.Model):
    """A question that belongs to a poll and contains ordered choices."""

    poll = models.ForeignKey(
        "polls.Poll",
        on_delete=models.CASCADE,
        related_name="questions",
    )
    text = models.CharField(max_length=512)
    order = models.PositiveIntegerField(default=0)
    is_required = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order", "id"]
        unique_together = ("poll", "order")

    def __str__(self) -> str:  # pragma: no cover - repr helper
        return f"Question {self.order} for {self.poll}: {self.text[:32]}"
