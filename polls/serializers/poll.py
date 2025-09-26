"""Serializers for poll API resources."""

from rest_framework import serializers

from polls.models.poll import Poll

from .question import QuestionSerializer


class PollSerializer(serializers.ModelSerializer):
    """Serializer for poll objects, including ordered questions."""

    questions = QuestionSerializer(many=True, read_only=True)

    class Meta:
        model = Poll
        fields = [
            "id",
            "account",
            "title",
            "description",
            "status",
            "require_all_questions",
            "created_at",
            "updated_at",
            "published_at",
            "questions",
        ]
        read_only_fields = [
            "created_at",
            "updated_at",
            "published_at",
            "status",
            "questions",
        ]

    def validate(self, attrs):
        """Validate poll creation against account quota."""
        account = attrs.get("account") or getattr(self.instance, "account", None)
        if account and self.instance is None and not account.can_add_poll():
            raise serializers.ValidationError(
                {"account": "Poll limit reached for the selected account."}
            )
        if account and not account.is_active:
            raise serializers.ValidationError(
                {"account": "Account must be active to create polls."}
            )
        return super().validate(attrs)


class PollStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Poll.Status.choices)


__all__ = [
    "PollSerializer",
    "PollStatusUpdateSerializer",
]
