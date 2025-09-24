"""
Serializers for account resources.
"""

from rest_framework import serializers

from accounts.models.account import Account
from accounts.models.tier import AccountTier


class AccountSerializer(serializers.ModelSerializer):
    """Serializer for Account model."""

    tier = serializers.PrimaryKeyRelatedField(
        queryset=AccountTier.objects.all(), allow_null=True, required=False
    )
    billing_email = serializers.EmailField(required=False)
    subscription_status = serializers.CharField(read_only=True)
    payment_provider_id = serializers.CharField(read_only=True)
    tier_features = serializers.SerializerMethodField(read_only=True)
    member_count = serializers.SerializerMethodField(read_only=True)
    poll_limit_remaining = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Account
        fields = [
            "id",
            "name",
            "created_at",
            "tier",
            "billing_email",
            "subscription_status",
            "payment_provider_id",
            "tier_features",
            "member_count",
            "poll_limit_remaining",
        ]
        read_only_fields = [
            "created_at",
            "subscription_status",
            "payment_provider_id",
            "tier_features",
            "member_count",
            "poll_limit_remaining",
        ]

    def get_tier_features(self, obj):
        """Return tier features for the account."""
        return obj.tier_features()

    def get_member_count(self, obj):
        """Return the number of members in the account."""
        return obj.user_roles.count()

    def get_poll_limit_remaining(self, obj):
        """Return the remaining poll limit for the account tier."""
        if not obj.tier:
            return None
        from polls.models import Poll

        used = Poll.objects.filter(account=obj).count()
        return max(obj.tier.max_polls - used, 0)
