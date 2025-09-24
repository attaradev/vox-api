"""
Serializers for account tier resources.
"""

from rest_framework import serializers

from accounts.models.tier import AccountTier


class AccountTierSerializer(serializers.ModelSerializer):
    """Serializer for AccountTier model."""

    class Meta:
        model = AccountTier
        fields = [
            "id",
            "name",
            "description",
            "max_members",
            "max_polls",
            "price_per_month",
            "is_active",
            "feature_flags",
        ]
