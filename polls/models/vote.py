"""Model definitions for poll votes."""

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import models

from .choice import Choice
from .poll import Poll

User = get_user_model()


class Vote(models.Model):
    """A vote cast by a user for a poll choice."""

    poll = models.ForeignKey(Poll, on_delete=models.CASCADE, related_name="votes")
    choice = models.ForeignKey(Choice, on_delete=models.CASCADE, related_name="votes")
    voter = models.ForeignKey(User, on_delete=models.CASCADE, related_name="poll_votes")
    voted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-voted_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["poll", "voter"],
                name="unique_vote_per_poll_for_user",
            )
        ]

    def clean(self):
        """Validate that the vote is for a valid choice and poll."""
        if self.choice.poll_id != self.poll_id:
            raise ValidationError("Choice must belong to the poll being voted on.")
        if not self.poll.can_receive_votes():
            raise ValidationError("Votes can only be cast on active polls.")

    def save(self, *args, **kwargs):
        """Save the vote after validation and poll assignment."""
        if self.choice_id and not self.poll_id:
            self.poll = self.choice.poll
        self.full_clean()
        return super().save(*args, **kwargs)
