"""Invoice API views for CRUD operations."""

from rest_framework import generics, permissions

from billing.models.invoice import Invoice
from billing.serializers.invoice import InvoiceSerializer


class InvoiceListCreateView(generics.ListCreateAPIView):
    """Expose list and create endpoints for invoices."""

    queryset = Invoice.objects.all()
    serializer_class = InvoiceSerializer
    permission_classes = [permissions.IsAdminUser]


class InvoiceDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Handle retrieve, update, and delete operations for invoices."""

    queryset = Invoice.objects.all()
    serializer_class = InvoiceSerializer
    permission_classes = [permissions.IsAdminUser]
