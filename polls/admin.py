"""Admin customizations for polls models."""

from django.contrib import admin

from core.utils.audit import log_audit

from .models import Choice, Poll, Vote


@admin.register(Poll)
class PollAdmin(admin.ModelAdmin):
    """Customize admin for poll objects."""

    list_display = ("id", "title", "account", "status", "created_at")
    list_filter = ("status", "account")
    search_fields = ("title",)
    readonly_fields = ("created_at", "updated_at", "published_at")

    def save_model(self, request, obj, form, change):
        """Audit poll creation and updates."""
        super().save_model(request, obj, form, change)
        action = "poll_update" if change else "poll_create"
        log_audit(
            user=request.user,
            action=action,
            object_type="Poll",
            object_id=obj.id,
            details={"title": obj.title, "status": obj.status},
        )

    def delete_model(self, request, obj):
        """Audit poll deletion."""
        log_audit(
            user=request.user,
            action="poll_delete",
            object_type="Poll",
            object_id=obj.id,
            details={"title": obj.title, "status": obj.status},
        )
        super().delete_model(request, obj)


@admin.register(Choice)
class ChoiceAdmin(admin.ModelAdmin):
    """Customize admin for poll choices."""

    list_display = ("id", "poll", "text", "vote_count", "created_at")
    search_fields = ("text", "poll__title")
    readonly_fields = ("created_at",)

    def vote_count(self, obj):
        """Return the number of votes for this choice."""
        return obj.vote_count

    vote_count.short_description = "Votes"

    def save_model(self, request, obj, form, change):
        """Audit choice creation and updates."""
        super().save_model(request, obj, form, change)
        action = "choice_update" if change else "choice_create"
        log_audit(
            user=request.user,
            action=action,
            object_type="Choice",
            object_id=obj.id,
            details={"poll": obj.poll_id, "text": obj.text},
        )

    def delete_model(self, request, obj):
        """Audit choice deletion."""
        log_audit(
            user=request.user,
            action="choice_delete",
            object_type="Choice",
            object_id=obj.id,
            details={"poll": obj.poll_id, "text": obj.text},
        )
        super().delete_model(request, obj)


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    """Customize admin for poll votes."""

    list_display = ("id", "poll", "choice", "voter", "voted_at")
    search_fields = ("poll__title", "choice__text", "voter__username")
    readonly_fields = ("voted_at",)

    def save_model(self, request, obj, form, change):
        """Audit vote creation and updates."""
        super().save_model(request, obj, form, change)
        action = "vote_update" if change else "vote_create"
        log_audit(
            user=request.user,
            action=action,
            object_type="Vote",
            object_id=obj.id,
            details={
                "poll": obj.poll_id,
                "choice": obj.choice_id,
                "voter": obj.voter_id,
            },
        )

    def delete_model(self, request, obj):
        """Audit vote deletion."""
        log_audit(
            user=request.user,
            action="vote_delete",
            object_type="Vote",
            object_id=obj.id,
            details={
                "poll": obj.poll_id,
                "choice": obj.choice_id,
                "voter": obj.voter_id,
            },
        )
        super().delete_model(request, obj)
