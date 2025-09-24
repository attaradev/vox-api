"""Serializers for payment resources."""

from rest_framework import serializers

from accounts.models.account import Account
from billing.models.invoice import Invoice
from billing.models.payment import Payment


class PaymentSerializer(serializers.ModelSerializer):
    """Serialize payment records and related references."""

    account = serializers.PrimaryKeyRelatedField(queryset=Account.objects.all())
    invoice = serializers.PrimaryKeyRelatedField(
        queryset=Invoice.objects.all(), required=False
    )

    class Meta:
        model = Payment
        fields = [
            "id",
            "account",
            "invoice",
            "amount",
            "payment_date",
            "provider",
            "provider_id",
            "status",
        ]
