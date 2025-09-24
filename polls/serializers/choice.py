"""Serializers for poll choice resources."""

from rest_framework import serializers

from polls.models.choice import Choice


class ChoiceSerializer(serializers.ModelSerializer):
    """Serializer for poll choices, including vote count."""

    vote_count = serializers.IntegerField(read_only=True)
    poll = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Choice
        fields = ["id", "poll", "text", "created_at", "vote_count"]
        read_only_fields = ["poll", "created_at", "vote_count"]


class ChoiceCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating poll choices."""

    class Meta:
        model = Choice
        fields = ["text"]
