"""Webhook handlers for third-party billing providers."""

from django.http import HttpResponse, JsonResponse

from billing.models import BillingAccount
from billing.providers.stripe import StripeProvider


def handle_stripe_webhook(request):
    """Process incoming Stripe webhook payloads and update billing state."""

    payload = request.body
    sig_header = request.META.get("HTTP_STRIPE_SIGNATURE")
    provider = StripeProvider()
    try:
        event = provider.get_event(payload, sig_header)
    except Exception:
        return HttpResponse(status=400)

    # Handle event types
    if event["type"] == "customer.subscription.updated":
        subscription = event["data"]["object"]
        customer_id = subscription["customer"]
        status = subscription["status"]
        try:
            billing = BillingAccount.objects.get(payment_provider_id=customer_id)
            billing.subscription_status = status
            billing.save()
        except BillingAccount.DoesNotExist:
            pass
    # Add more event types as needed
    return JsonResponse({"status": "success"})
