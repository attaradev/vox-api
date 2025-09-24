"""API views for managing billing accounts."""

from rest_framework import generics, permissions

from billing.models import BillingAccount
from billing.serializers import BillingAccountSerializer
from core.utils.audit import log_audit


class BillingAccountListCreateView(generics.ListCreateAPIView):
    """Provide list and create endpoints for billing accounts."""

    queryset = BillingAccount.objects.all()
    serializer_class = BillingAccountSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_create(self, serializer):
        """Create a billing account and record an audit trail."""

        obj = serializer.save()
        log_audit(
            user=self.request.user,
            action="billing_account_create",
            object_type="BillingAccount",
            object_id=obj.id,
            details={"account": obj.account.name, "status": obj.subscription_status},
        )


class BillingAccountDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Expose retrieve, update, and delete routes for billing accounts."""

    queryset = BillingAccount.objects.all()
    serializer_class = BillingAccountSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_update(self, serializer):
        """Persist billing account updates and write an audit record."""

        obj = serializer.save()
        log_audit(
            user=self.request.user,
            action="billing_account_update",
            object_type="BillingAccount",
            object_id=obj.id,
            details={"account": obj.account.name, "status": obj.subscription_status},
        )

    def perform_destroy(self, instance):
        """Delete a billing account after auditing the action."""

        log_audit(
            user=self.request.user,
            action="billing_account_delete",
            object_type="BillingAccount",
            object_id=instance.id,
            details={
                "account": instance.account.name,
                "status": instance.subscription_status,
            },
        )
        instance.delete()
