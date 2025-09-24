"""API views for listing, creating, and managing payments."""

from rest_framework import generics, permissions

from billing.models.payment import Payment
from billing.serializers.payment import PaymentSerializer
from core.utils.audit import log_audit


class PaymentListCreateView(generics.ListCreateAPIView):
    """Provide list and create operations for payment records."""

    queryset = Payment.objects.all()
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_create(self, serializer):
        """Persist a new payment while emitting an audit event."""

        obj = serializer.save()
        log_audit(
            user=self.request.user,
            action="payment_create",
            object_type="Payment",
            object_id=obj.id,
            details={
                "account": obj.account.id,
                "amount": str(obj.amount),
                "status": obj.status,
            },
        )


class PaymentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Expose retrieve, update, and delete endpoints for payments."""

    queryset = Payment.objects.all()
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_update(self, serializer):
        """Update a payment and record the change in the audit log."""

        obj = serializer.save()
        log_audit(
            user=self.request.user,
            action="payment_update",
            object_type="Payment",
            object_id=obj.id,
            details={
                "account": obj.account.id,
                "amount": str(obj.amount),
                "status": obj.status,
            },
        )

    def perform_destroy(self, instance):
        """Delete a payment entry after capturing an audit log."""

        log_audit(
            user=self.request.user,
            action="payment_delete",
            object_type="Payment",
            object_id=instance.id,
            details={
                "account": instance.account.id,
                "amount": str(instance.amount),
                "status": instance.status,
            },
        )
        instance.delete()
