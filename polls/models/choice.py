"""Model definitions for poll choices."""

from django.db import models
from django.db.models import F, Max

from .poll import Poll
from .question import Question


class Choice(models.Model):
    """A selectable option for a poll question."""

    poll = models.ForeignKey(
        Poll,
        related_name="choices",
        on_delete=models.CASCADE,
        editable=False,
    )
    question = models.ForeignKey(
        Question,
        related_name="choices",
        on_delete=models.CASCADE,
    )
    text = models.CharField(max_length=255)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order", "id"]
        constraints = [
            models.UniqueConstraint(
                fields=["question", "text"], name="choice_unique_per_question"
            ),
            models.UniqueConstraint(
                fields=["question", "order"], name="choice_order_unique_per_question"
            ),
        ]

    def __str__(self):
        """Return the display text for this choice."""
        return self.text

    def save(self, *args, **kwargs):
        if self.question_id:
            self.poll = self.question.poll
            if self._state.adding:
                if self.order is None:
                    self.order = (
                        self.question.choices.aggregate(max_order=Max("order"))[
                            "max_order"
                        ]
                        or -1
                    ) + 1
                else:
                    self.question.choices.filter(order__gte=self.order).update(
                        order=F("order") + 1
                    )
        super().save(*args, **kwargs)

    @property
    def vote_count(self) -> int:
        """Return the number of votes for this choice."""
        return self.votes.count()
