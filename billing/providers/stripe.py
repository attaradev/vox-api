"""Stripe billing provider implementation."""

import stripe
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured

stripe_secret = getattr(settings, "STRIPE_SECRET_KEY", "")
if stripe_secret:
    stripe.api_key = stripe_secret


def _require_api_key() -> None:
    if not getattr(stripe, "api_key", None):
        raise ImproperlyConfigured("STRIPE_SECRET_KEY is not configured.")


class StripeProvider:
    """Interact with Stripe APIs for billing operations."""

    def create_customer(self, email):
        """Create a Stripe customer for the supplied email."""
        _require_api_key()
        return stripe.Customer.create(email=email)

    def create_subscription(self, customer_id, price_id):
        """Create a new Stripe subscription for the given customer."""
        _require_api_key()
        return stripe.Subscription.create(
            customer=customer_id,
            items=[{"price": price_id}],
            payment_behavior="default_incomplete",
            expand=["latest_invoice.payment_intent"],
        )

    def cancel_subscription(self, subscription_id):
        """Cancel an existing Stripe subscription."""
        _require_api_key()
        return stripe.Subscription.delete(subscription_id)

    def update_subscription(self, subscription_id, price_id):
        """Update the pricing details of an existing Stripe subscription."""
        _require_api_key()
        return stripe.Subscription.modify(
            subscription_id,
            items=[{"price": price_id}],
        )

    def get_event(self, payload, sig_header):
        """Validate and parse a Stripe webhook payload."""
        webhook_secret = getattr(settings, "STRIPE_WEBHOOK_SECRET", "")
        if not webhook_secret:
            raise ImproperlyConfigured("STRIPE_WEBHOOK_SECRET is not configured.")
        return stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
