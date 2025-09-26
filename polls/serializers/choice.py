"""Serializers for poll choice resources."""

from django.db.models import F
from rest_framework import serializers

from polls.models.choice import Choice


class ChoiceSerializer(serializers.ModelSerializer):
    """Serializer for poll choices, including vote count."""

    vote_count = serializers.IntegerField(read_only=True)
    poll = serializers.PrimaryKeyRelatedField(read_only=True)
    question = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Choice
        fields = [
            "id",
            "poll",
            "question",
            "text",
            "custom_fields",
            "order",
            "created_at",
            "vote_count",
        ]
        read_only_fields = [
            "poll",
            "question",
            "created_at",
            "vote_count",
        ]


class ChoiceCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating poll choices."""

    order = serializers.IntegerField(required=False, min_value=0)

    class Meta:
        model = Choice
        fields = ["text", "custom_fields", "order"]

    def create(self, validated_data):
        question = self.context["question"]
        order = validated_data.pop("order", None)
        if order is None:
            order = question.choices.count()
        else:
            question.choices.filter(order__gte=order).update(order=F("order") + 1)
        return Choice.objects.create(
            question=question,
            order=order,
            **validated_data,
        )
