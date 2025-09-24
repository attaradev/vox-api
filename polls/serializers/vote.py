"""Serializers for poll vote resources."""

from rest_framework import serializers

from polls.models.choice import Choice
from polls.models.vote import Vote


class VoteSerializer(serializers.ModelSerializer):
    """Serializer for poll votes."""

    voter = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Vote
        fields = ["id", "poll", "choice", "voter", "voted_at"]
        read_only_fields = ["poll", "choice", "voter", "voted_at"]


class VoteCastSerializer(serializers.Serializer):
    """Serializer for casting a vote for a poll choice."""

    choice_id = serializers.PrimaryKeyRelatedField(
        source="choice",
        queryset=Choice.objects.select_related("poll"),
    )

    def validate(self, attrs):
        """Validate that the choice belongs to the poll."""
        poll = self.context["poll"]
        choice = attrs["choice"]
        if choice.poll_id != poll.id:
            raise serializers.ValidationError(
                {"choice_id": "Choice does not belong to this poll."}
            )
        return attrs
