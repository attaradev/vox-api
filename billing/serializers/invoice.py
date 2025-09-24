"""Serializers for the invoice domain objects."""

from django.contrib.auth import get_user_model
from rest_framework import serializers

from accounts.models.account import Account
from billing.models.invoice import Invoice


class InvoiceSerializer(serializers.ModelSerializer):
    """Serialize invoice instances for the REST API."""

    account = serializers.PrimaryKeyRelatedField(queryset=Account.objects.all())
    user = serializers.PrimaryKeyRelatedField(
        queryset=get_user_model().objects.all(), required=False
    )
    pdf_url = serializers.URLField(required=False)

    class Meta:
        model = Invoice
        fields = [
            "id",
            "account",
            "user",
            "amount",
            "issued_at",
            "due_at",
            "is_paid",
            "pdf_url",
        ]
