"""Serializers for subscription entities."""

from rest_framework import serializers

from accounts.models.account import Account
from billing.models.subscription import Subscription


class SubscriptionSerializer(serializers.ModelSerializer):
    """Serialize subscription records for API responses."""

    account = serializers.PrimaryKeyRelatedField(queryset=Account.objects.all())

    class Meta:
        model = Subscription
        fields = [
            "id",
            "account",
            "provider",
            "provider_id",
            "status",
            "started_at",
            "ended_at",
            "plan",
        ]


class CreateSubscriptionRequestSerializer(serializers.Serializer):
    """Validate subscription creation payloads."""

    price_id = serializers.CharField(required=False, allow_blank=False)


class SubscriptionStatusResponseSerializer(serializers.Serializer):
    """Serializer for subscription status responses."""

    status = serializers.CharField()
    provider_id = serializers.CharField(allow_null=True, required=False)
