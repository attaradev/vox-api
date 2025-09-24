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
