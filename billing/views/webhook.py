"""Webhook endpoint views for billing integrations."""

from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView

from billing.providers.webhooks import handle_stripe_webhook


@method_decorator(csrf_exempt, name="dispatch")
class StripeWebhookView(APIView):
    """Receive and delegate Stripe webhook payload processing."""

    authentication_classes = []
    permission_classes = []
    serializer_class = None

    def post(self, request, *args, **kwargs):
        """Process incoming webhook notifications from Stripe."""
        return handle_stripe_webhook(request)
