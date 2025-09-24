"""Serializers for poll API resources."""

from rest_framework import serializers

from polls.models.poll import Poll

from .choice import ChoiceSerializer


class PollSerializer(serializers.ModelSerializer):
    """Serializer for poll objects, including choices."""

    choices = ChoiceSerializer(many=True, read_only=True)

    class Meta:
        model = Poll
        fields = [
            "id",
            "account",
            "title",
            "description",
            "status",
            "created_at",
            "updated_at",
            "published_at",
            "choices",
        ]
        read_only_fields = [
            "created_at",
            "updated_at",
            "published_at",
            "status",
            "choices",
        ]

    def validate(self, attrs):
        """Validate poll creation against account quota."""
        account = attrs.get("account") or getattr(self.instance, "account", None)
        if account and self.instance is None and not account.can_add_poll():
            raise serializers.ValidationError(
                {"account": "Poll limit reached for the selected account."}
            )
        return super().validate(attrs)


class PollStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Poll.Status.choices)


__all__ = [
    "PollSerializer",
    "PollStatusUpdateSerializer",
]
