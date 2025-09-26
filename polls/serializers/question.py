"""Serializers for poll questions."""

from django.db import transaction
from django.db.models import F
from rest_framework import serializers

from polls.models.question import Question
from polls.serializers.choice import ChoiceCreateSerializer, ChoiceSerializer


class QuestionSerializer(serializers.ModelSerializer):
    """Serializer for poll questions with nested choices."""

    choices = ChoiceSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = [
            "id",
            "poll",
            "text",
            "order",
            "is_required",
            "choices",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["poll", "choices", "created_at", "updated_at"]


class QuestionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating questions within a poll."""

    order = serializers.IntegerField(required=False, min_value=0)
    is_required = serializers.BooleanField(required=False)
    choices = ChoiceCreateSerializer(many=True, required=False)

    class Meta:
        model = Question
        fields = ["text", "order", "is_required", "choices"]

    def create(self, validated_data):
        poll = self.context["poll"]
        choices_data = validated_data.pop("choices", [])
        existing_count = poll.questions.count()
        order = validated_data.pop("order", None)
        requested_is_required = validated_data.pop("is_required", True)
        if existing_count == 0:
            is_required = True
        elif poll.require_all_questions:
            is_required = True
        else:
            is_required = requested_is_required
        if order is None:
            order = existing_count
        else:
            poll.questions.filter(order__gte=order).update(order=F("order") + 1)
        with transaction.atomic():
            question = Question.objects.create(
                poll=poll, order=order, is_required=is_required, **validated_data
            )
            for choice_data in choices_data:
                serializer = ChoiceCreateSerializer(
                    data=choice_data,
                    context={"question": question},
                )
                serializer.is_valid(raise_exception=True)
                serializer.save()
        return question
