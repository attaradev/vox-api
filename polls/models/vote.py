"""Model definitions for poll votes."""

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import models

from .choice import Choice
from .poll import Poll
from .question import Question

User = get_user_model()


class Vote(models.Model):
    """A vote cast by a user for a poll choice."""

    poll = models.ForeignKey(Poll, on_delete=models.CASCADE, related_name="votes")
    question = models.ForeignKey(
        Question, on_delete=models.CASCADE, related_name="votes"
    )
    choice = models.ForeignKey(Choice, on_delete=models.CASCADE, related_name="votes")
    voter = models.ForeignKey(User, on_delete=models.CASCADE, related_name="poll_votes")
    voted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-voted_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["question", "voter"],
                name="unique_vote_per_question_for_user",
            )
        ]

    def clean(self):
        """Validate that the vote is for a valid choice and poll."""
        if self.choice.poll_id != self.poll_id:
            raise ValidationError("Choice must belong to the poll being voted on.")
        if self.choice.question_id != self.question_id:
            raise ValidationError("Choice must belong to the question being voted on.")
        if not self.poll.can_receive_votes():
            raise ValidationError("Votes can only be cast on active polls.")

    def save(self, *args, **kwargs):
        """Save the vote after validation and poll assignment."""
        if self.choice_id:
            self.poll = self.choice.poll
            self.question = self.choice.question
        self.full_clean()
        return super().save(*args, **kwargs)
