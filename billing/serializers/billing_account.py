"""Serializer definitions for billing account resources."""

from rest_framework import serializers

from accounts.models.account import Account
from billing.models.billing_account import BillingAccount


class BillingAccountSerializer(serializers.ModelSerializer):
    """Serialize billing account metadata for administrative APIs."""

    account = serializers.PrimaryKeyRelatedField(queryset=Account.objects.all())
    billing_email = serializers.EmailField(required=False)
    subscription_status = serializers.CharField(read_only=True)
    payment_provider_id = serializers.CharField(read_only=True)

    provider = serializers.CharField(required=False)

    class Meta:
        model = BillingAccount
        fields = [
            "id",
            "account",
            "provider",
            "billing_email",
            "subscription_status",
            "payment_provider_id",
            "created_at",
            "updated_at",
        ]
