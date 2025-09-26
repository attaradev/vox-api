"""Views for managing subscription resources and provider flows."""

from rest_framework import generics, permissions, serializers, status
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from billing.models import BillingAccount
from billing.models.subscription import Subscription
from billing.providers.paypal import PayPalProvider
from billing.providers.stripe import StripeProvider
from billing.serializers.subscription import SubscriptionSerializer
from core.utils.audit import log_audit


class SubscriptionListCreateView(generics.ListCreateAPIView):
    """List subscriptions and allow administrators to create new ones."""

    queryset = Subscription.objects.all().order_by("-started_at")
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_create(self, serializer):
        """Create a subscription record and log the audit event."""

        obj = serializer.save()
        log_audit(
            user=self.request.user,
            action="subscription_create",
            object_type="Subscription",
            object_id=obj.id,
            details={
                "account": obj.account.id,
                "provider": obj.provider,
                "status": obj.status,
            },
        )


class SubscriptionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete subscription instances."""

    queryset = Subscription.objects.all()
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_update(self, serializer):
        """Update a subscription while capturing audit metadata."""

        obj = serializer.save()
        log_audit(
            user=self.request.user,
            action="subscription_update",
            object_type="Subscription",
            object_id=obj.id,
            details={
                "account": obj.account.id,
                "provider": obj.provider,
                "status": obj.status,
            },
        )

    def perform_destroy(self, instance):
        """Delete the subscription after auditing the action."""

        log_audit(
            user=self.request.user,
            action="subscription_delete",
            object_type="Subscription",
            object_id=instance.id,
            details={
                "account": instance.account.id,
                "provider": instance.provider,
                "status": instance.status,
            },
        )
        instance.delete()


class SubscriptionStatusView(GenericAPIView):
    """Return subscription status details for the requesting account."""

    permission_classes = [IsAuthenticated]
    serializer_class = serializers.Serializer  # No input, just output

    def get(self, request, account_id):
        """Fetch subscription status for a given account or return a 404."""
        try:
            billing = BillingAccount.objects.get(account_id=account_id)
            return Response(
                {
                    "status": billing.subscription_status,
                    "provider_id": billing.payment_provider_id,
                }
            )
        except BillingAccount.DoesNotExist:
            return Response(
                {"detail": "Billing info not found."},
                status=status.HTTP_404_NOT_FOUND,
            )


class CreateSubscriptionView(GenericAPIView):
    """Create a new subscription using the configured billing provider."""

    permission_classes = [IsAuthenticated]
    serializer_class = serializers.Serializer

    def post(self, request, account_id):
        """
        Create a subscription through Stripe or PayPal based on account data."""
        price_id = request.data.get("price_id")
        try:
            billing = BillingAccount.objects.get(account_id=account_id)
            provider_name = getattr(billing, "provider", "stripe")
            if provider_name == "paypal":
                provider = PayPalProvider()
                subscription = provider.create_subscription(billing.billing_email)
            else:
                provider = StripeProvider()
                customer = provider.create_customer(billing.billing_email)
                subscription_obj = provider.create_subscription(customer.id, price_id)
                subscription = subscription_obj
            return Response(
                {"subscription": subscription["id"], "status": subscription["status"]}
            )
        except BillingAccount.DoesNotExist:
            return Response(
                {"detail": "Billing info not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
