"""Model definitions for poll questions."""

from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from accounts.models.account import Account


class Poll(models.Model):
    """A poll question with selectable choices and voting workflow."""

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        ACTIVE = "active", "Active"
        CLOSED = "closed", "Closed"

    account = models.ForeignKey(
        Account,
        on_delete=models.CASCADE,
        related_name="polls",
        help_text="Owning account used for quota enforcement",
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    require_all_questions = models.BooleanField(
        default=False,
        help_text="Require answers to all questions when voting",
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.DRAFT,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["account", "title"],
                name="poll_title_unique_per_account",
            )
        ]

    def __str__(self):
        """Return a display string for the poll."""
        return f"{self.title} ({self.get_status_display()})"

    def transition_status(self, new_status: str) -> None:
        """Transition the poll to a new status following workflow rules."""
        valid_statuses = {choice[0] for choice in self.Status.choices}
        if new_status not in valid_statuses:
            raise ValidationError({"status": f"Invalid status '{new_status}'"})

        if self.status == self.Status.CLOSED and new_status != self.Status.CLOSED:
            raise ValidationError({"status": "Closed polls cannot be reopened."})

        if self.status == self.Status.DRAFT and new_status == self.Status.CLOSED:
            raise ValidationError(
                {"status": "Draft polls must be activated before closing."}
            )

        if new_status == self.Status.ACTIVE:
            if not self.questions.filter(choices__isnull=False).exists():
                raise ValidationError(
                    {"status": "Add at least one valid question before activating."}
                )

        self.status = new_status
        if new_status == self.Status.ACTIVE:
            self.published_at = timezone.now()
        self.save(update_fields=["status", "published_at", "updated_at"])

    def can_receive_votes(self) -> bool:
        """Return True if poll is open for voting."""
        return self.status == self.Status.ACTIVE
